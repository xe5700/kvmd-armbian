#!/bin/bash
source checksum.sh
download() {
    echo Downloading $1 To $2
    if [ ! -f "$2" ]; then
        echo "wget $1 -O $2"
        wget $1 -O $2
    else
        if [ ! -n "$3" ]; then
            echo "File $2 is exists, skip download."
        else
            echo "Check sum for $2"
        fi
    fi
}