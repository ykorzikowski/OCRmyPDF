e!/bin/bash

do_ocr() {
  if [[  $1 == *'ocr'* ]]; then
    return 0
  fi

  # remove .pdf ending from string
  filename=$(basename "$1")
  filename=$(echo $filename|sed 's/\.pdf//g')

  /appenv/bin/ocrmypdf "$1" $(dirname "$1")/"$filename"_ocr.pdf

  if [ $? -ne 0 ]; then
    return 0
  fi

  rm "$1"
}

export -f do_ocr

while [ true ]; do
  sleep 5
  find /pdf/ -iname '*.pdf' -type f -exec bash -c 'do_ocr "$0"' {} \;
done
