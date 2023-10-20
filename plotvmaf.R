#!/usr/bin/env -S Rscript --vanilla

library("argparse")
library("caTools")
library("rjsonpath")
msg.trap <- capture.output( suppressMessages( library(plotly) ))

# cmdline
parser <- ArgumentParser(description='Render vmaf json to dynamic (web) graphs')
parser$add_argument( '-i', '--input',  action='append', help="json input file",  required=TRUE )
parser$add_argument( '-o', '--output',                  help="html output file", required=TRUE )
parser$add_argument( '-d', '--duration', type="integer",help="Number of frames to process [default all]. Also a turnaround when sizes differ [use any value]", default=0 )
parser$add_argument( '-t', '--title',  type="character",help="graph/html title", default=NULL )
parser$add_argument( '-s', '--smooth', type="integer",  help="Number of frames to average for smoothing [default %(default)s]", default=10 )
parser$add_argument( '-f', '--perframe', action="store_true", help="Enable frame-level plot", default=FALSE )

args <- parser$parse_args()

out_path=args$output
duration=args$duration
page_title=args$title
runmean_win=args$smooth
perframe=args$perframe

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
    vmaf_smooth = runmean(vmaf_frame, runmean_win)
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
    if (perframe)
        fig <- fig %>% add_trace( y = vmaf_frame,  mode = 'lines', type='scatter', name = id, visible='legendonly' )
    fig <- fig %>% add_trace(     y = vmaf_smooth, mode = 'lines', type='scatter', name = sprintf("%s\nvar=%.2f", id, vmaf_var_rms))
}

htmlwidgets::saveWidget( fig, out_path, title=page_title, selfcontained=FALSE )
