#!/bin/bash
download() {
    echo Downloading $1 To $2
    echo "wget $1 -O $2"
    wget $1 -O $2
}