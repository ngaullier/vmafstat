usage()
{
    echo "Usage: $(basename "$0") [-h] -r reference_input -i main_input" 1>&2
    echo "      [-ffsync_opt opt1=val1:opt2=val2..]" 1>&2
    echo 1>&2
    echo "Synch files with ffsync, and ffplay them side by side." 1>&2
    echo 1>&2
    echo "Options:" 1>&2
    echo "  -h              display this help text." 1>&2
    echo "  -r --ref        reference input file." 1>&2
    echo "  -i --main       processed input file." 1>&2
    echo "  --ffsync_opt    pairs of long_name=value, semicolon-delimited." 1>&2
    echo 1>&2
    echo "Example:" 1>&2
    echo "./ffsyncplay -i encoded.mp4 -r source.mxf --ffsync_opt \"start_ref=6:max_offset=0.08:duration=0.2\"" 1>&2
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
    file_ref=
    file_main=
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
            --ffsync_opt)
                check_arg_value "$key" $#
                ffsync_opt="$2"
                shift 2 && continue;;
            -h|--help)
                usage
                exit;;
        esac
        echo "$key: unexpected option"
        exit 1
    done
}
