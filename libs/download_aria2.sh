#!/bin/bash
source checksum.sh
download(){
    tryCount=0
    echo Downloading $1 To $2
    download2 $1 $2 $3 $4
    unset tryCount
}
download2() {
    filename=$(readlink -f $2)
    echo "aria2c -x 16 -s 16 --file-allocation=falloc --min-split-size 2M $1 -o $filename -d /"
    if [ ! -f "$2" ]; then
        aria2c -x 16 -s 16 --file-allocation=falloc --min-split-size 2M $1 -o $filename -d /
    else
        if [ ! -n "$3" ]; then
            echo "File $2 is exists, skip download."
            return
        fi
    fi
    echo "Checksum for $2"
    checksum $3 $2 $4
    if [ "$sumRet" != 0 ]; then
        echo "File checksum failed, try redownload file. Result is $sumRet"
        if [[ "$tryCount" -lt 3 ]]; then
            tryCount=`expr $tryCount + 1`
            rm $2
            download2 $1 $2 $3 $4
        else
            echo "Try $tryCount times, download failed."
        fi
    else
        echo "File checksum successful."
    fi
    unset sumRet
}