#!/usr/bin/env -S Rscript --vanilla

library("argparse")
library("caTools")
library("rjsonpath")
msg.trap <- capture.output( suppressMessages( library(this.path) ))
msg.trap <- capture.output( suppressMessages( library(plotly) ))

# cmdline
parser <- ArgumentParser(description='Render vmaf json to dynamic (web) graphs')
parser$add_argument( '-i', '--input',  action='append', help="json input file",  required=TRUE )
parser$add_argument( '-o', '--output',                  help="html output file", required=TRUE )
parser$add_argument( '-d', '--duration', type="integer",help="Number of frames to process [default all]. Also a turnaround when sizes differ [use any value]", default=0 )
parser$add_argument( '-t', '--title',  type="character",help="graph/html title", default=NULL )
parser$add_argument( '-s', '--smooth', type="integer",  help="Number of frames to average for smoothing [default %(default)s]", default=50 )
parser$add_argument( '-f', '--perframe', action="store_true", help="Enable frame-level plot", default=FALSE )
parser$add_argument( '-F', '--perframeonly', action="store_true", help="Enable only frame-level plot", default=FALSE )

args <- parser$parse_args()

out_path=args$output
duration=args$duration
page_title=args$title
runmean_win=args$smooth
perframe=args$perframe
perframeonly=args$perframeonly
smooth_visible='TRUE'
if (perframe)
    smooth_visible='legendonly'

if (is.null(page_title) ) {
    page_title=out_path
}

# Loop/inputs
for (in_path in args$input) {

    # Json read / data processing
    json <- read_json(in_path)
    vmaf_frame = suppressMessages( json_path(json, "$.frames[*].metrics.vmaf") )
    if (duration > 0)
        vmaf_frame <- vmaf_frame[1:duration]
    # it is required to handle 1/(1/0)=0 as VMAF score 0 may happen in some cases (ex: desync)
    # alg='R' should have worked but it is buggy, so just replace zeroes...
    vmaf_frame[ vmaf_frame==0 ] <- 0.01
    vmaf_smooth = 1/runmean(1/vmaf_frame, runmean_win)
    vmaf_var_rms = sqrt(mean( (vmaf_frame-vmaf_smooth)^2 ))

    # Plot init
    if (!exists("fig")) {
        frames = suppressMessages( json_path(json, "$.frames[*].frameNum") )
        if (duration > 0)
            frames <- frames[1:duration]
        # Convert frame numbers to timestamps
        # 5 digits are required (%OS5) for proper 2 digits rounding in xaxis/tickformat below
        options("digits.secs"=2)
        frame_time = as.POSIXct(frames/25, origin='1970-01-01', tz='UTC')
        frame_time <- format(frame_time, "%Y-%m-%d %H:%M:%OS5")
        fig <- plot_ly(x = frame_time)
        fig <- fig %>% layout(title = page_title,
            xaxis = list(
                title = 'Time', type='date', tickformat='%H:%M:%S.%L',
                scaleanchor  = FALSE, zerolinecolor = '#ffff', zerolinewidth = 2, gridcolor = 'ffff'
                ),
            yaxis = list(
                title = 'Quality', type='linear',
                scaleanchor  = FALSE, zerolinecolor = '#ffff', zerolinewidth = 2, gridcolor = 'ffff'
                ),
            plot_bgcolor='#e5ecf6',
            showlegend = TRUE
         )
    }
    id <- basename(tools::file_path_sans_ext( in_path ))
    if (perframe || perframeonly)
        fig <- fig %>% add_trace( y = vmaf_frame,  mode = 'lines+markers', type='scatter', name = id )
    if (!perframeonly)
        fig <- fig %>% add_trace(     y = vmaf_smooth, mode = 'lines', type='scatter', name = sprintf("%s\nvar=%.2f", id, vmaf_var_rms), visible=smooth_visible )
}

htmlwidgets::saveWidget( fig, out_path, title=page_title, selfcontained=FALSE )

# Add keyboard shortcuts using zoom_pan.js from https://github.com/mzechmeister/csvplotter/blob/main/zoom_pan.js
add_js_path = dirname(this.path())
add_js_name = "zoom_pan.js"
out_dir = dirname(out_path)
system(sprintf( "[ -f '%s/%s' ] || cp '%s/%s' '%s'", out_dir, add_js_name, add_js_path, add_js_name, out_dir ))
system(sprintf( "sed -i '/^<\\/body/ s/^/  <script src=\"%s\"><\\/script><script>zoompan(\".plotly\")<\\/script>/' %s", add_js_name, out_path ))
