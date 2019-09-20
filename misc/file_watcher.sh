#!/bin/bash

while [ true ]; do
  sleep 5
  find /pdf/ -iname '*.pdf' -type f -exec /appenv/bin/ocrmypdf {} {} \;
done
