usage()
{
    echo " $(basename "$0") [-h] [-v] [-q] [-V] -r reference_input -i main_input" 1>&2
    echo "      [-s probe_position_frames] [-c probe_range_frames] [-d probe_duration_sec]" 1>&2
    echo "      [-m min_psnr_diff_x1000]" 1>&2
    echo 1>&2
    echo "Maximize psnr to determine the alignment between two inputs." 1>&2
    echo "The segment to analyze is determined by its position in 'ref' (see -s) +/- a maximum shift in 'main' (see -c)." 1>&2
    echo "Frame-psnr values shall fluctuate enough in the segment to make sure alignment is achieved (see -d and -m)." 1>&2
    echo "Report the frame shift as an integer value if successfull (positive if 'main' is delayed) or an error code." 1>&2
    echo "-h display this help text." 1>&2
    echo "-v display version." 1>&2
    echo "-q, --brief display only the raw value." 1>&2
    echo "-V, --verbose increase verbosity level." 1>&2
    echo "-r --ref reference input file." 1>&2
    echo "-i --main processed input file." 1>&2
    echo "-s --start position (frames) in the reference file. Defaults ${probe_position_frames}." 1>&2
    echo "-c --count max +/- shift (frames) in the main file. Defaults ${probe_range_frames}." 1>&2
    echo "-d --duration duration (seconds) duration of the sequence to analyze. Defaults ${probe_duration_sec}." 1>&2
    echo "-m --psnrdiff integer value, minimum of (max psnr - min psnr) * 1000 to assume successfull sync. Defaults ${probe_min_psnr_diff_x1000}." 1>&2
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
    probe_position_frames=5
    probe_range_frames=3
    probe_duration_sec=2
    probe_min_psnr_diff_x1000=2000
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
            -s|--start)
                check_arg_value "$key" $#
                probe_position_frames="$2"
                shift 2 && continue;;
            -c|--count)
                check_arg_value "$key" $#
                probe_range_frames="$2"
                shift 2 && continue;;
            -d|--duration)
                check_arg_value "$key" $#
                probe_duration_sec="$2"
                shift 2 && continue;;
            -m|--psnrdiff)
                check_arg_value "$key" $#
                probe_min_psnr_diff_x1000="$2"
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
