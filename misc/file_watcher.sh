#!/bin/bash

do_ocr() {
 /appenv/bin/ocrmypdf $1 $1_ocr.pdf

 rm $1
}

while [ true ]; do
  sleep 5
  find /pdf/ -iname '*.pdf' -type f -exec do_ocr {} \;
done
