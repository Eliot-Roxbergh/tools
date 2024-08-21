#!/bin/bash

if [ "$#" -ne "1" ]; then
	echo "Enter an URL you'd like to stream"
	exit 0
fi

QUALITY="best"
#QUALITY="worst"

echo 'TODO!! NOT TESTED FOR yt-dlp'
yt-dlp "${1}"  -f ${QUALITY} -o - 2>/dev/null | vlc -vvv - &>/dev/null
