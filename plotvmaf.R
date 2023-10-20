#!/usr/bin/env -S Rscript --vanilla

library("argparse")
library("caTools")
library("rjsonpath")
msg.trap <- capture.output( suppressMessages( library(plotly) ))

# cmdline
parser <- ArgumentParser(description='Render vmaf json to dynamic (web) graphs')
parser$add_argument( '-i', '--input',  action='append', help="json input file",  required=TRUE )
parser$add_argument( '-o', '--output',                  help="html output file", required=TRUE )
parser$add_argument( '-t', '--title',  type="character",help="graph/html title", default=NULL )
parser$add_argument( '-s', '--smooth', type="integer",  help="Number of frames to average for smoothing [default %(default)s]", default=10 )

args <- parser$parse_args()

out_path=args$output
page_title=args$title
runmean_win=args$smooth

if (is.null(page_title) ) {
    page_title=out_path
}

# Loop/inputs
for (in_path in args$input) {

    # Json read / data processing
    json <- read_json(in_path)
    frames = suppressMessages( json_path(json, "$.frames[*].frameNum") )
    vmaf_frame = suppressMessages( json_path(json, "$.frames[*].metrics.vmaf") )
    vmaf_smooth = runmean(vmaf_frame, runmean_win)
    vmaf_var_rms = sqrt(mean( (vmaf_frame-vmaf_smooth)^2 ))

    # Annotations / print stats
    print_stats <- list(
      xref = "paper", yref = "paper", x = 1, showarrow = F, font = list(color = '#111100', family = 'sans serif', size = 16),
      y = 1,
      text = sprintf("vmaf\nvariance=%.2f",vmaf_var_rms)
    )

    # Plot init
    if (!exists("fig")) {
        # Convert frame numbers to timestamps
        # 5 digits are required (%OS5) for proper 2 digits rounding in xaxis/tickformat below
        options("digits.secs"=2)
        frame_time = as.POSIXct(frames/25, origin='1970-01-01', tz='UTC')
        frame_time <- format(frame_time, "%Y-%m-%d %H:%M:%OS5")

        # Draw
        dataframe <- data.frame( frame_time )
        fig <- plot_ly(dataframe, x = ~frame_time)
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
            showlegend = TRUE,
            annotations = print_stats
         )
    }
    fig <- fig %>% add_trace(y = vmaf_frame,  mode = 'lines', type='scatter', name = 'vmaf_frame', visible='legendonly')
    fig <- fig %>% add_trace(y = vmaf_smooth, mode = 'lines', type='scatter', name = in_path)
}

htmlwidgets::saveWidget( fig, out_path, title=page_title, selfcontained=FALSE )
