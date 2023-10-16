log ()
{
    [[ ${verbose} -gt $1 ]] && echo "$2" >&2
    return 0
}

exit_fail ()
{
    log -1 "Fail: $1"
    exit 1
}
