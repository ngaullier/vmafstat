ffprobe2json ()
{
    local file_in="$1"
    local json_out="$2"

    local INI__ffprobe_binary="ffprobe"
    local INI__ff_global="-hide_banner -probesize 10000000"

    local cmd_check_in="""$INI__ffprobe_binary"" $INI__ff_global ""$file_in"" -show_format -show_streams -o ""$json_out"" -print_format json"
    [[ ${verbose} -gt 2 ]] && log "  $cmd_check_in"
    $cmd_check_in 2>/dev/null || exit_fail "ffprobe failed for $file_in"
}
