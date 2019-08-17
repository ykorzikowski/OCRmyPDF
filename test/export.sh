#! bin/bash

HERE="$(dirname "$(readlink -f "${0}")")"

export APPDIR="$HERE"
export PATH="$HERE/usr/bin:$HERE/usr/local/bin:$HERE/usr/python/bin:$PATH"
export LD_PRELOAD="$HERE/usr/lib/liblept.so.5"
export LD_LIBRARY_PATH="$HERE/usr/lib:$HERE/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
export TESSDATA_PREFIX="$HERE/usr/share/tesseract-ocr/4.00/tessdata"
export GS_LIB="$HERE/usr/share/ghostscript/9.26/lib:$HERE/usr/share/ghostscript/9.26/Resource:$HERE/usr/share/ghostscript/9.26/Resource/Init"
