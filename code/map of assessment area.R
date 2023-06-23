###################################################################
# Create Map of Assessment Area
#
# Pulled from the copper 2023 assessment and repurposed for canary rockfish
# Thanks to Chantel and Melissa
###################################################################

# load packages
require(maps)
require(mapdata)
library(here)
library(viridis)


savedir = here('documents', "figures")

# define names and colors for each area
mod.names <- c("Management  Range and Assessment Area", 
               "Fleet Ranges",
               "Survey Ranges")
mod.cols <- viridis::viridis(6)

# open PNGfile
png(filename=file.path(savedir, "assessment_map.png"), width=5.5, height=7, res=300, units='in')

# map with Canada and Mexico (not sure how to add states on this one)
map('worldHires', regions=c("Canada","Mexico"),
    xlim=c(-130, -114), ylim=c(31, 51),
    col='grey', fill=TRUE, interior=TRUE, , lwd=1)
# map with US states
map('state', regions=c("Wash","Oreg","Calif","Idaho",
                       "Montana","Nevada","Arizona","Utah"),
    add=TRUE,
    col='grey', fill=TRUE, interior=TRUE, lwd=1)
axis(2, at=seq(32,50,2), lab=paste0(seq(32,50,2), "°N"), las=1)
axis(1, at=seq(-130,-114,4), lab=paste0(abs(seq(-130,-114,4)), "°W"))

## add vertical lines indicating range for each stock
latrange <- c(32.5, 48.5) + c(.2, -.2)
lines(rep(-128.5,2), latrange, lwd=10, col=mod.cols[1])
text(-128-1.2, mean(latrange), mod.names[1], srt=90)
latrange <- c(32.5, 42.0) + c(.2, -.2)
lines(rep(-127,2), latrange, lwd=10, col=mod.cols[2])
latrange <- c(42.0, 46.25) + c(.2, -.2)
lines(rep(-127,2), latrange, lwd=10, col=mod.cols[3])
latrange <- c(46.25, 48.5) + c(.2, -.2)
lines(rep(-127, 2), latrange, lwd=10, col=mod.cols[4])
text(-126-1.7, 41, mod.names[2], srt=90)
latrange <- c(32.5, 48.5) + c(.2, -.2)
lines(rep(-125.5, 2), latrange, lwd=10, col=mod.cols[5])
latrange <- c(34.5, 48.5) + c(.2, -.2)
lines(rep(-125.5, 2), latrange, lwd=9, col=mod.cols[6])
text(-124-2.1, 41, mod.names[3], srt=90)
#
text(-120, 50, "Canada")
text(-120, 47, "Washington")
text(-121, 44, "Oregon")
text(-119.5, 37, "California")
text(-115.5, 32.1, "Mexico")
#
box()
dev.off()