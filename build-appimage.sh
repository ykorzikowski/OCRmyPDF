#! /bin/bash

set -x
set -e

# use RAM disk if possible
if [ "$CI" == "" ] && [ -d /dev/shm ]; then
    TEMP_BASE=/dev/shm
else
    TEMP_BASE=/tmp
fi

BUILD_DIR=$(mktemp -d -p "$TEMP_BASE" OCRmyPDF-AppImage-build-XXXXXX)

cleanup () {
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
    fi
}

trap cleanup EXIT

# store repo root as variable
REPO_ROOT=$(readlink -f "$(dirname "$(dirname "$0")")")
OLD_CWD=$(readlink -f .)

pushd "$BUILD_DIR"

mkdir -p AppDir
mkdir -p PackageDir
mkdir -p jbig2

# download linuxdeploy AppImage and python3 AppImage
wget https://github.com/TheAssassin/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
wget https://github.com/niess/linuxdeploy-plugin-python/releases/download/continuous/python3-x86_64.AppImage

chmod +x linuxdeploy*.AppImage python3*.AppImage

# extract python3 AppImage, copy usr folder to AppDir and remove pyton3*.AppImage related files
./python3-x86_64.AppImage --appimage-extract > /dev/null 2>&1
cp -a squashfs-root/usr AppDir
if [ -d AppDir/usr/share/applications ] ; then rm -rf AppDir/usr/share/applications ; fi
if [ -d AppDir/usr/share/icons ] ; then rm -rf AppDir/usr/share/icons ; fi
if [ -d AppDir/usr/share/metainfo ] ; then rm -rf AppDir/usr/share/metainfo ; fi


ARCH=$(uname -i)
export ARCH


# .desktop file
cat > ocrmypdf.desktop <<\EOF
[Desktop Entry]
Name=ocrmypdf
Type=Application
Exec=ocrmypdf
Icon=ocrmypdf
Terminal=true
Comment=OCRmyPDF adds an OCR text layer to scanned PDF files, allowing them to be searched
Categories=Graphics;Scanning;OCR;
EOF


# download logo and convert it to desktop icon
# requires Imagemagick (convert)
wget https://raw.githubusercontent.com/jbarlow83/OCRmyPDF/master/docs/images/logo-social.png
convert logo-social.png -resize 512x512\> -size 512x512 xc:white +swap -gravity center -composite ocrmypdf.png


# download and intsall packages required by OCRmyPDF
pushd PackageDir
packages=(tesseract-ocr tesseract-ocr-all libexempi3 libffi6  ghostscript qpdf pngquant unpaper)

for i in "${packages[@]}"
do
    apt-get -d -o dir::cache="$PWD" -o Debug::NoLocking=1 --reinstall install "$i" -y
done

# wget -q 'https://www.dropbox.com/s/vaq0kbwi6e6au80/unpaper_6.1-1.deb?raw=1' -O unpaper_6.1-1.deb

find . -type f -name \*.deb -exec dpkg-deb -X {} "$BUILD_DIR"/AppDir \;
popd


# compile and install jbig2
# requires libleptonica-dev, zlib1g-dev
wget -q https://github.com/agl/jbig2enc/archive/0.29.tar.gz -O - | \
     tar xz -C jbig2 --strip-components=1
pushd jbig2
./autogen.sh
./configure --prefix="$BUILD_DIR"/AppDir/usr
make && make install
popd


pushd "$BUILD_DIR"/AppDir
# remove unnecessary data from AppDir
[ -d bin ] && rm -rf ./bin
[ -d etc ] && rm -rf ./etc
[ -d var ] && rm -rf ./var

# install OCRmyPDF
./usr/python/bin/python3.7 -m pip install --upgrade pip
./usr/python/bin/python3.7 -m pip install ocrmypdf=="$OCRMYPDF_VERSION"
popd

# sanitize the shebangs of local Python scripts
pushd "$BUILD_DIR"/AppDir/usr/python/bin
find . -type f -perm /111 -exec sed -i '1s|^#!.*\(python[0-9.]*\)|#!/bin/sh\n"exec" "$(dirname $(readlink -f $\{0\}))/../../bin/\1" "$0" "$@"|' {} ";"
popd


# export LD_LIBRARY_PATH so that dependencies of shared libraries can be deployed by linuxdeploy-x86_64.AppImage
export LD_LIBRARY_PATH="$BUILD_DIR/AppDir/usr/lib:$BUILD_DIR/AppDir/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"

export VERSION="$OCRMYPDF_VERSION"
export OUTPUT=OCRmyPDF-"$VERSION"-"$ARCH".AppImage

./linuxdeploy-x86_64.AppImage --appdir AppDir  \
    -d ocrmypdf.desktop -i ocrmypdf.png \
    --custom-apprun "$REPO_ROOT"/appimage/AppRun.sh --output appimage

# move AppImage back to old CWD
mv "$OUTPUT" "$OLD_CWD"/

popd
