#!/bin/bash
source checksum.sh
download() {
    echo Downloading $1 To $2
    filename=$(readlink -f $2)
    echo "aria2c -x 16 -s 16 --file-allocation=falloc --min-split-size 2M $1 -o $filename -d /"
    if [ ! -f "$2" ]; then
        aria2c -x 16 -s 16 --file-allocation=falloc --min-split-size 2M $1 -o $filename -d /
    else
        if [ ! -n "$3" ]; then
            echo "File $2 is exists, skip download."
        else
            echo "Checksum for $2"
            sum=$(checksum $3 $2 $4)
            if [ sum != 0 ]; then
                echo "File checksum failed, try redownload file."
                rm $2
                return $(download $1 $2 $3 $4)
            fi
        fi
    fi
}