# shellcheck disable=SC2120
mktemp_auto () {
    cmd_mktemp="mktemp -dt cji_bash-XXXXXXXXXX"
    [[ $# -gt 0 ]] && cmd_mktemp="$cmd_mktemp -p $1"
    tmp_folder="$($cmd_mktemp)"
    echo "$tmp_folder"
}
mktemp_cleanup() { rm -rf -- "$1"; }
mktemp_trap() {
    trap "mktemp_cleanup ""$1""" EXIT
    trap "mktemp_cleanup ""$1""" ERR
}

ffprobe2json ()
{
    local file_in="$1"
    local json_out="$2"

    local INI__ffprobe_binary="ffprobe"
    local INI__ff_global="-hide_banner -probesize 10000000"

    local cmd_check_in="""$INI__ffprobe_binary"" $INI__ff_global ""$file_in"" -show_format -show_streams -o ""$json_out"" -print_format json"
    log 2 "  $cmd_check_in"
    $cmd_check_in 2>/dev/null || exit_fail "ffprobe failed for $file_in"
}
