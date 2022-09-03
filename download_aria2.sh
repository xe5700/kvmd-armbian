#!/bin/bash
download() {
    echo Downloading $1 To $2
    echo "aria2c -x 64 -s 64 --file-allocation=falloc --min-split-size 2M $1 -o $2"
    aria2c -x 64 -s 64 --file-allocation=falloc --min-split-size 2M $1 -o $2
}