#! /bin/bash

set -x
set -e

# use RAM disk if possible
if [ "$CI" == "" ] && [ -d /dev/shm ]; then
    TEMP_BASE=/dev/shm
else
    TEMP_BASE=/tmp
fi

APPIMAGE_BUILD_DIR=$(mktemp -d -p "$TEMP_BASE" OCRmyPDF-AppImage-build-XXXXXX)

cleanup () {
    if [ -d "$APPIMAGE_BUILD_DIR" ]; then
        rm -rf "$APPIMAGE_BUILD_DIR"
    fi
}

trap cleanup EXIT

pushd "$APPIMAGE_BUILD_DIR"

mkdir -p AppDir
mkdir -p PackageDir
mkdir -p jbig2

# download linuxdeploy AppImage and linuxdeploy-plugin-python AppImage
wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
# wget https://github.com/niess/linuxdeploy-plugin-python/releases/download/continuous/linuxdeploy-plugin-python-x86_64.AppImage

# use forked linuxdeploy-plugin-python instead of the original one (otherwise OCRmyPDF breaks)
wget https://github.com/FPille/linuxdeploy-plugin-python/releases/download/continuous/linuxdeploy-plugin-python-x86_64.AppImage

chmod +x linuxdeploy*.AppImage


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
convert $TRAVIS_BUILD_DIR/docs/images/logo-social.png -resize 512x512\> -size 512x512 xc:white +swap -gravity center -composite ocrmypdf.png


# download and install packages required by OCRmyPDF
pushd PackageDir
packages=(tesseract-ocr tesseract-ocr-all libexempi3 libffi6 ghostscript qpdf pngquant unpaper)

for i in "${packages[@]}"
do
    apt-get -d -o dir::cache="$PWD" -o Debug::NoLocking=1 --reinstall install "$i" -y
done

find . -type f -name \*.deb -exec dpkg-deb -X {} "$BUILD_DIR"/AppDir \;
popd


# compile and install jbig2
# requires libleptonica-dev, zlib1g-dev
wget -q https://github.com/agl/jbig2enc/archive/0.29.tar.gz -O - | \
     tar xz -C jbig2 --strip-components=1
pushd jbig2
./autogen.sh
./configure --prefix="$APPIMAGE_BUILD_DIR"/AppDir/usr
make && make install
popd


pushd "$BUILD_DIR"/AppDir
# remove unnecessary data from AppDir
[ -d bin ] && rm -rf ./bin
[ -d etc ] && rm -rf ./etc
[ -d var ] && rm -rf ./var
popd


# export LD_LIBRARY_PATH so that dependencies of shared libraries can be deployed by linuxdeploy-x86_64.AppImage
export LD_LIBRARY_PATH="$APPIMAGE_BUILD_DIR/AppDir/usr/lib:$APPIMAGE_BUILD_DIR/AppDir/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"

export PIP_REQUIREMENTS="ocrmypdf==$OCRMYPDF_VERSION"
export VERSION="$OCRMYPDF_VERSION"
export OUTPUT=OCRmyPDF-"$VERSION"-"$ARCH".AppImage

./linuxdeploy-x86_64.AppImage --appdir AppDir --plugin python \
    -d ocrmypdf.desktop -i ocrmypdf.png \
    --custom-apprun "$TRAVIS_BUILD_DIR"/misc/appimage/AppRun.sh --output appimage

# move AppImage
mv "$OUTPUT" $TRAVIS_BUILD_DIR

popd
