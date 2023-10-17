#!/usr/bin/env -S Rscript --vanilla

library("optparse")
library("rjsonpath")
library("caTools")

# cmdline
parser <- OptionParser()
parser <- add_option(parser, c("-i", "--input"), type="character", default=NULL,
            help="json input file", metavar="character")
parser <- add_option(parser, c("-o", "--output"), type="character", default=NULL,
            help="html output file", metavar="character")
parser <- add_option(parser, c("-t", "--title"), type="character", default=NULL,
            help="graph/html title", metavar="character")
parser <- add_option(parser, c("-s", "--smooth"), type="integer", default=10,
            help="Number of frames to average for smoothing [default %default]",    metavar="number")
cmd_options <- parse_args(parser)

in_path=cmd_options[['input']]
out_path=cmd_options[['output']]
page_title=cmd_options[['title']]
runmean_win=cmd_options[['smooth']]

# json read / data processing
json <- read_json(in_path)

frames = json_path(json, "$.frames[*].frameNum")
vmaf_frame = json_path(json, "$.frames[*].metrics.vmaf")
vmaf_smooth=runmean(vmaf_frame,runmean_win)
vmaf_var_rms=sqrt(mean((vmaf_frame-vmaf_smooth)^2))

# Annotations / print stats
print_stats <- list(
  xref = "paper",
  yref = "paper",
  x = 1,
  y = 1,
  showarrow = F,
  text = sprintf("vmaf\nvariance=%.2f",vmaf_var_rms),
  font = list(color = '#111100',
    family = 'sans serif',
    size = 16)
)

# Convert frame numbers to timestamps
# 5 digits are required (%OS5) for proper 2 digits rounding in xaxis/tickformat below
options("digits.secs"=2)
frame_time = as.POSIXct(frames/25, origin='1970-01-01', tz='UTC')
frame_time <- format(frame_time, "%Y-%m-%d %H:%M:%OS5")

# Draw
library(plotly)
dataframe <- data.frame( frame_time, vmaf_frame, vmaf_smooth )
fig <- plot_ly(dataframe, x = ~frame_time)
fig <- fig %>% add_trace(y = ~vmaf_frame,  name = 'vmaf_frame',  mode = 'lines', type='scatter', visible='legendonly')
fig <- fig %>% add_trace(y = ~vmaf_smooth,  name = 'vmaf',  mode = 'lines', type='scatter')
#fig <- fig %>% add_trace(y = vmaf_var,  name = 'vmaf_var',  mode = 'lines', type='scatter', visible='legendonly')

fig <- fig %>% layout(title = page_title,
         plot_bgcolor='#e5ecf6',
         xaxis = list(
           type='date', tickformat='%H:%M:%S.%L',
           title = 'Time',
           scaleanchor  = FALSE,
           zerolinecolor = '#ffff',
           zerolinewidth = 2,
           gridcolor = 'ffff'),
         yaxis = list(
           title = 'Quality',
           type='linear',
           scaleanchor  = FALSE,
           zerolinecolor = '#ffff',
           zerolinewidth = 2,
           gridcolor = 'ffff'),
         showlegend = TRUE,
         annotations = print_stats
         )

htmlwidgets::saveWidget(fig,out_path,title=page_title,selfcontained=FALSE)
