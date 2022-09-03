#!/bin/bash
download($url, $path){
    echo Downloading $url To $path
    echo "wget $url -O $path"
    wget $url -O $path
}