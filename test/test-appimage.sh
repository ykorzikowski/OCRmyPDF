#! /bin/bash

set -x
set -e

chmod +x OCRmyPDF*.AppImage

# run OCRmyPDF to test if the AppImage can ocr a test file
run_appimage()
{
    echo ""
    ./OCRmyPDF*.AppImage --help
    echo ""
    ./OCRmyPDF*.AppImage --list-programs
    echo ""
    ./OCRmyPDF*.AppImage --list-licenses
    echo ""
    ./OCRmyPDF*.AppImage ocrmypdf -l deu -s -d --jbig2-lossy --optimize 1 "$TRAVIS_BUILD_DIR"/test/test.pdf output.pdf
    echo ""
}


# check AppImage for common issues
run_appimagelint()
{
    wget https://github.com/TheAssassin/appimagelint/releases/download/continuous/appimagelint-x86_64.AppImage
    chmod +x appimagelint-x86_64.AppImage
    ./appimagelint-x86_64.AppImage OCRmyPDF*.AppImage
}


# extract the OCRmyPDF AppImage, install pytest & test requirements and run pytest
run_pytest()
{
    git clone --depth=1 --branch "v$OCRMYPDF_VERSION" https://github.com/jbarlow83/OCRmyPDF.git
    ./OCRmyPDF*.AppImage --appimage-extract > /dev/null 2>&1

    pushd squashfs-root

    # HERE="$(dirname "$(readlink -f "${0}")")"

    # export APPDIR="$HERE"
    # export PATH="$HERE/usr/bin:$HERE/usr/local/bin:$HERE/usr/python/bin:$PATH"
    # export LD_PRELOAD="$HERE/usr/lib/liblept.so.5"
    # export LD_LIBRARY_PATH="$HERE/usr/lib:$HERE/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
    # export TESSDATA_PREFIX="$HERE/usr/share/tesseract-ocr/4.00/tessdata"
    # export GS_LIB="$HERE/usr/share/ghostscript/9.26/lib:$HERE/usr/share/ghostscript/9.26/Resource:$HERE/usr/share/ghostscript/9.26/Resource/Init"

    ./usr/python/bin/python3 -m pip install -r ../OCRmyPDF/requirements/test.txt
    ./AppRun python3 -m pytest ../OCRmyPDF -n auto
    popd
}


run_appimage

run_appimagelint

run_pytest



