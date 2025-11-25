usage()
{
    echo "Usage: $(basename "$0") [-h] [-v] [-q] [-V] -r reference_input -i main_input -o output_json" 1>&2
    echo "      [-d duration] [-ffsync_opt opt1=val1:opt2=val2..]" 1>&2
    echo 1>&2
    echo "Synch files with ffsync, then compute vmaf score." 1>&2
    echo 1>&2
    echo "Options:" 1>&2
    echo "  -h              display this help text." 1>&2
    echo "  -v              display version." 1>&2
    echo "  -q, --quiet     only display ffmpeg's output." 1>&2
    echo "  -V, --verbose   increase verbosity level (-V -V means debug and is the max verbose level)." 1>&2
    echo "  -r --ref        reference input file." 1>&2
    echo "  -i --main       processed input file." 1>&2
    echo "  -o --output     json output file." 1>&2
    echo "  -d --duration   interrupt analysis before end of file (ffmpeg's format)." 1>&2
    echo "  --ffsync_opt    pairs of long_name=value, semicolon-delimited." 1>&2
    echo 1>&2
    echo "Example:" 1>&2
    echo "./ffvmaf -i encoded.mp4 -r source.mxf --ffsync_opt \"start_ref=6:max_offset=0.08:duration=0.2\" -o /tmp/vmaf.json -d 3" 1>&2
    exit 1
}

version()
{
    echo "Current version: $VERSION"
}

check_arg_value()
{
    local key=$1
    local argn=$2
    if [[ $argn -lt 2 ]]
    then
        echo "$key: missing parameter value"
        usage
        exit
    fi
}

get_opts()
{
    verbose=1
    file_ref=
    file_main=
    file_out=
    duration=
    ffsync_opt=
    while [[ $# -gt 0 ]]
    do
        local key="$1"
        case $key in
            -r|--ref)
                check_arg_value "$key" $#
                file_ref="$2"
                shift 2 && continue;;
            -i|--main)
                check_arg_value "$key" $#
                file_main="$2"
                shift 2 && continue;;
            -o|--output)
                check_arg_value "$key" $#
                file_out="$2"
                shift 2 && continue;;
            -d|--duration)
                check_arg_value "$key" $#
                duration="$2"
                shift 2 && continue;;
            --ffsync_opt)
                check_arg_value "$key" $#
                ffsync_opt="$2"
                shift 2 && continue;;
            -q|--brief)
                verbose=0
                shift && continue;;
            -V|--verbose)
                verbose=$verbose+1
                shift && continue;;
            -h|--help)
                usage
                exit;;
            -v|--version)
                version
                exit;;
        esac
        echo "$key: unexpected option"
        exit 1
    done
}
