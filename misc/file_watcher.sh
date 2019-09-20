#!/bin/bash

do_ocr() {
  if [[  $1 == *'ocr'* ]]; then
    exit 0
  fi

  /appenv/bin/ocrmypdf $1 $1_ocr.pdf

  rm $1
}

export -f do_ocr

while [ true ]; do
  sleep 5
  find /pdf/ -iname '*.pdf' -type f -exec bash -c 'do_ocr "$0"' {} \;
done
