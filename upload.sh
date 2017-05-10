#!/bin/bash

DEVICE="/dev/ttyUSB0"
BAUD="115200"
FILES="*.lua *.html css/*.css bundle.js"

usage() {
  echo ""
  echo "$0 [-d serial_device] [-b baud] [files_to_upload]"
  echo ""
  echo "  If files_to_upload is not specified,"
  echo "  defaults to all relevant project files."
  echo ""
}

OPTIND=1
while getopts "h?d:b:" opt; do
    case "$opt" in
    h|\?)
        usage
        exit 0
        ;;
    d)  DEVICE=$OPTARG
        ;;
    B)  BAUD=$OPTARG
        ;;
    esac
done
shift $((OPTIND-1))

if [ "$#" -gt "0" ]; then
  FILES=$@
fi

nodemcu-uploader --port $DEVICE --baud $BAUD upload $FILES
