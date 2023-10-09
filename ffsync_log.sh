log ()
{
    echo "$1" >&2
}

exit_fail ()
{
    log "Fail: $1"
    exit 1
}
