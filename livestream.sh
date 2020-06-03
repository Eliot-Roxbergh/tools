#!/bin/bash

if [ "$#" -ne "1" ]; then
	echo "Enter an URL you'd like to stream"
	exit 0
fi

QUALITY="best"
#QUALITY="worst"

youtube-dl "${1}"  -f ${QUALITY} -o - 2>/dev/null | vlc -vvv - &>/dev/null
