[[_TOC_]]

This is a collection of several tools for benchmarking video codecs.

# Dependencies

* for vmaf computing: [ffmpeg](http://dml.common.qa.tvvideoms.com/CodecBench/ffmpeg) supporting [libvmaf](https://debian.pkgs.org/11/multimedia-main-amd64/libvmaf1_2.2.0-dmo1+deb11u1_amd64.deb.html)
* for vmaf analysis and ploting: use [R_install](R_install)
* basic dependencies: ffprobe, jq

# Main tools

These cli tools are the only commands required for a typical benchmark.

## ffsyncplay

Check the detected sync with ffplay and side by side display.

```
Usage: ffsyncplay [-h] -r reference_input -i main_input
      [-ffsync_opt opt1=val1:opt2=val2..]

Synch files with ffsync, and ffplay them side by side.

Options:
  -h              display this help text.
  -r --ref        reference input file.
  -i --main       processed input file.
  --ffsync_opt    pairs of long_name=value, semicolon-delimited.

Example:
./ffsyncplay -i encoded.mp4 -r source.mxf --ffsync_opt "start_ref=6:max_offset=0.08:duration=0.2"
```

## ffvmafs

Batch **vmaf computing** on all files of a media folder.

```
Usage: ffvmafs REFERENCE_FOLDER MAIN_FOLDER OUTPUT_FOLDER [FFVMAF_OPT]

Call ffvmaf for each file present in both REFERENCE_FOLDER and MAIN_FOLDER.
MAIN_FOLDER files are expected to be suffixed with the MAIN_FOLDER name.
ex: foo.mxf in /test/src corresponding to foo_mc_3500.mp4 in /test/mc_3500
  ffvmafs /test/src/ /test/mc_3500/ /test/jsons/ -d 3
```

## vmafstats

**Print** vmaf values from one or more jsons.

```
usage: vmafstats JSON_FILE|JSON_FOLDER

Print vmaf min/max/mean/harmonic_mean from a JSON_FILE or all json in JSON_FOLDER.
If JSON_FOLDER contains *, it is interpreted as a glob.

Example:
  vmafstats /test/json
  vmafstats '/test/json/XDCAM*'
  vmafstats '/test/json/XDCAM_mc_15.json'
```

## plotvmafs

**Plots** a folder or a glob-selection of jsons into a web page.

```
usage: plotvmafs JSON_FOLDER -o OUTPUT [OPT_PLOTVMAF_ARGS]

Call plotmaf.R for each input json found in JSON_FOLDER.
If JSON_FOLDER contains *, it is interpreted as a glob.
For optional arguments, see plotvmaf.R  --help
Note that -d is required if the input json lengths differ.

Example:
  plotvmafs /test/json  -o /test/all.html
  plotvmafs '/test/json/XDCAM*' -o /test/xdcam_30s.html -d 30
```

## fflog2cputabs

Extract **cpu consumption stats** from an `ffmpeg -benchmark` stdout log.

```
usage: fflog2cputabs FFMPEG_STDOUT

Grep -benchmark output in ffmpeg stdout logs, get usertime and realtime in two tab-delimited columns.
Output next to the inputfile, with suffix '_cpu.txt'.
```

---

# Backstage-tools

These tools are used internally by the main tools, but they could be used directly for a specific need.\
For example: ffvmafs calls ffvmaf which calls ffsync.

## ffvmaf

Compute vmaf of a single processed file.

```
Usage: ffvmaf [-h] [-v] [-q] [-V] -r reference_input -i main_input -o output_json
      [-d duration] [-ffsync_opt opt1=val1:opt2=val2..]

Synch files with ffsync, then compute vmaf score.

Options:
  -h              display this help text.
  -v              display version.
  -q, --quiet     only display ffmpeg's output.
  -V, --verbose   increase verbosity level (-V -V means debug and is the max verbose level).
  -r --ref        reference input file.
  -i --main       processed input file.
  -o --output     json output file.
  -d --duration   interrupt analysis before end of file (ffmpeg's format).
  --ffsync_opt    pairs of long_name=value, semicolon-delimited.

Example:
./ffvmaf -i encoded.mp4 -r source.mxf --ffsync_opt "start_ref=6:max_offset=0.08:duration=0.2" -o /tmp/vmaf.json -d 3
```

## ffsync

Get the start times of two videos to read them in sync.

```
Usage: ffsync [-h] [-v] [-q] [-V] -r reference_input -i main_input
      [-s start_time] [--start_main start_time_main] [-o max_time_offset] [-d segment_duration]
      [-l confidence_level]

Determine the alignment between two inputs using psnr maximization.
The segments to analyze are determined by their start positions (see -s and --start_main),
+/- an additionnal offset applied to main_input (see -o).
If the reference_input fps is greater than that of the main_input (ex: 50p->25p),
an additionnal test is to try a +1 offset of the reference_input to take frame drops into account.
Frame-psnr values shall fluctuate enough within the duration to make sure alignment is achieved (see -d and -l).
If the psnr difference is below the confidence level, the start points will be moved later (see --retry_shift) for another try,
and there is a total of 3 tries before failing definetely.

On success, raw integer parsable values are displayed on stdout: trim_ref, trim_main, psnr_diff, psnr.
Messages are always printed to stderr.
If sync is not achieved, or in case of any other error, the exit code is non zero.

Options:
  -h              display this help text.
  -v              display version.
  -q, --quiet     only display raw parsable values on stdout and errors on stderr.
  -V, --verbose   increase verbosity level (-V -V means debug and is the max verbose level).
  -r --ref        reference input file.
  -i --main       processed input file.
  -s --start_ref  position (seconds) in the reference file. Defaults 0.12.
     --start_main position (seconds) in the main file. Defaults=same start as reference file.
  -o --max_offset max advance/delay (seconds). Defaults 0.12.
  -d --duration   duration (seconds) of the segment for psnr computation. Defaults 1.
  -l --level       integer value, minimum of (max psnr - min psnr) * 100 to assume successfull sync. Defaults 400.
     --retry_shift after sync failed: shift (seconds) to apply to start times before trying again. Defaults 3.

Example:
  readarray -t sync_info <<< \
    $(ffsync -i encoded.mp4 -r source.mxf -q -s 5.00 -o 0.2 -d 0.8 -l 700)
  start_main=${sync_info[0]}
  start_ref=${sync_info[1]}
  ffmpeg -i encoded.mp4 -i source.mxf -lavfi \
    "[0:v]trim=start_frame=${start_main},settb=AVTB,setpts=PTS-STARTPTS[main];
     [1:v]trim=start_frame=${start_ref},settb=AVTB,setpts=PTS-STARTPTS[ref];
     [main][ref]psnr" ...
```

## plotvmaf.R

Plots some jsons into a web page.

```
usage: ./plotvmaf.R [-h] -i INPUT -o OUTPUT [-d DURATION] [-t TITLE]
                    [-s SMOOTH] [-f]

Render vmaf json to dynamic (web) graphs

optional arguments:
  -h, --help            show this help message and exit
  -i INPUT, --input INPUT
                        json input file
  -o OUTPUT, --output OUTPUT
                        html output file
  -d DURATION, --duration DURATION
                        Number of frames to process [default all]. Also a
                        turnaround when sizes differ [use any value]
  -t TITLE, --title TITLE
                        graph/html title
  -s SMOOTH, --smooth SMOOTH
                        Number of frames to average for smoothing [default 10]
  -f, --perframe        Enable frame-level plot
```