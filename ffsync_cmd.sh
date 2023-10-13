usage()
{
    echo "Usage: $(basename "$0") [-h] [-v] [-q] [-V] -r reference_input -i main_input" 1>&2
    echo "      [-s start_time] [--start-main start_time_main] [-o max_time_offset] [-d segment_duration]" 1>&2
    echo "      [-l confidence_level]" 1>&2
    echo 1>&2
    echo "Determine the alignment between two inputs using psnr maximization." 1>&2
    echo "The segments to analyze are determined by their start positions (see -s and --start-main)," 1>&2
    echo "+/- an additionnal offset applied to main_input (see -o)." 1>&2
    echo "If the reference_input fps is greater than that of the main_input (ex: 50p->25p)," 1>&2
    echo "an additionnal test is to try a +1 offset of the reference_input to take frame drops into account." 1>&2
    echo "Frame-psnr values shall fluctuate enough within the duration to make sure alignment is achieved (see -d and -l)." 1>&2
    echo "If the psnr difference is below the confidence level, the start points will be moved ${trim_retry_shift_s} seconds later for another try," 1>&2
    echo "and there is a total of 3 tries before failing definetely." 1>&2
    echo 1>&2
    echo "On success, raw integer parsable values are displayed on stdout: trim_ref, trim_main, psnr_diff, psnr." 1>&2
    echo "Messages are always printed to stderr." 1>&2
    echo "If sync is not achieved, or in case of any other error, the exit code is non zero." 1>&2
    echo 1>&2
    echo "Options:" 1>&2
    echo "  -h              display this help text." 1>&2
    echo "  -v              display version." 1>&2
    echo "  -q, --quiet     only display raw parsable values on stdout and errors on stderr." 1>&2
    echo "  -V, --verbose   increase verbosity level." 1>&2
    echo "  -r --ref        reference input file." 1>&2
    echo "  -i --main       processed input file." 1>&2
    echo "  -s --start-ref  position (seconds) in the reference file. Defaults ${trim_ref_base_s}." 1>&2
    echo "     --start-main position (seconds) in the main file. Defaults=same start as reference file." 1>&2
    echo "  -o --max-offset max advance/delay (seconds). Defaults ${max_delta_s}." 1>&2
    echo "  -d --duration   duration (seconds) of the segment for psnr computation. Defaults ${seg_duration_s}." 1>&2
    echo "  -l --level      integer value, minimum of (max psnr - min psnr) * 1000 to assume successfull sync. Defaults ${min_psnr_diff}." 1>&2
    echo 1>&2
    echo "Example:" 1>&2
    echo "  readarray sync_info <<< \\" 1>&2
    echo "    \$(ffsync -i /mnt/encoded.mp4 -r /mnt/source.mxf -V -s 5.00 -d 0.8 -l 7000)" 1>&2
    echo "  trim_main=\${sync_info[0]}" 1>&2
    echo "  trim_ref=\${sync_info[1]}" 1>&2
    echo "  ffmpeg -i encoded.mp4 -i source.mxf -lavfi \\" 1>&2
    echo "    \"[0:v]trim=start_frame=\${trim_main},settb=AVTB,setpts=PTS-STARTPTS[main];" 1>&2
    echo "     [1:v]trim=start_frame=\${trim_ref}:,settb=AVTB,setpts=PTS-STARTPTS[ref];" 1>&2
    echo "     [main][ref]psnr\" ..." 1>&2
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
    trim_ref_base_s=0.2
    trim_main_base_s=auto
    trim_retry_shift_s=3
    max_delta_s=0.12
    seg_duration_s=1
    min_psnr_diff=8000
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
            -s|--start-ref)
                check_arg_value "$key" $#
                trim_ref_base_s="$2"
                shift 2 && continue;;
            --start-main)
                check_arg_value "$key" $#
                trim_main_base_s="$2"
                shift 2 && continue;;
            -o|--max-offset)
                check_arg_value "$key" $#
                max_delta_s="$2"
                shift 2 && continue;;
            -d|--duration)
                check_arg_value "$key" $#
                seg_duration_s="$2"
                shift 2 && continue;;
            -l|--level)
                check_arg_value "$key" $#
                min_psnr_diff="$2"
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
    [[ $trim_main_base_s = "auto" ]] && trim_main_base_s=$trim_ref_base_s
}
