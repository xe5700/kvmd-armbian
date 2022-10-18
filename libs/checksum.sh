checksum(){
    export sumRet=0
    case $1 in
        gpg) checksum_gpg $2 $3;;
    esac
}
checksum_gpg(){
    gpg --verify $2 $1 2> /dev/null
    case $? in
        1) export sumRet=0;echo bad signature, skip checksum.;;
        *) export sumRet=$?;;
    esac
    return;
}