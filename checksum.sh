checksum(){
    case $1 in
        gpg) return checksum_gpg $1 $2;;
    esac
    return 0;
}
checksum_gpg(){
    gpg --verify $1 $2 2> /dev/null
    return $?
}