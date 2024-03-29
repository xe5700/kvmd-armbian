#!/bin/bash
source libs/checksum.sh
download(){
    tryCount=0
    echo Downloading $1 To $2
    download2 $1 $2 $3 $4
    unset tryCount
}
download2() {
    if [ ! -f "$2" ]; then
        echo "wget $1 -O $2"
        wget $1 -O $2
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