#####################
#Script to read in historical abundance from past canary assessments
#
#Copied from 2017 yelloweye thanks to Ian Taylor: 
#https://github.com/iantaylor-NOAA/YTRK_doc/blob/master/Rcode/historical_assessment_timeseries.R#L17
#####################




# define directory on a specific computer
if (system("hostname", intern=TRUE) %in% c("NWCLW04223033") ){
  YTdir <- "C:/SS/Yellowtail/Yellowtail2017"
  YTdir.doc <- file.path(YTdir, "YTRK_doc")
  setwd(YTdir.doc)
  # load models
  if(!exists("mod1")){
    load("r4ss/SS_output.RData")
  }
}

totcatch <- aggregate(mod1$catch$kill_bio, by=list(mod1$catch$Yr), FUN=sum)
names(totcatch) <- c("Yr","kill_bio")
png(filename="Figures/historical_assessment_timeseries.png",
    width=7, height=5.5, res=300, units='in')
par(mar=c(4,4,1,1))
# compare summary biomass across previous stock assessments
stocks <- read.csv('./txt_files/Yellowtail_historical_assessment_time_series.csv')
# subset to just columns with Age.4.summary.bio (excluding spawning biomass cols)
stocks2 <- stocks[,c(1,grep("Age.4", names(stocks)))]
# get assessment year from first row and then remove that row
assess.yrs <- as.numeric(stocks2[1,-1])
assess.colors <- rich.colors.short(8)
stocks2 <- stocks2[-1, ]
# empty plot
plot(0, type='n', xlim=c(1940, 2018), ylim=c(0, 200000),
     axes=FALSE, xaxs='i', yaxs='i', xlab="Year", ylab="Age 4+ biomass (x1000 mt)")
axis(1)
axis(1, at=2016, label=2016)
axis(2, at=pretty(c(0,200000)), lab=pretty(c(0,200000))/1000, las=1)
# add lines for the older assessments
for(istock in 1:6){
  assess.yr <- sort(unique(assess.yrs))[istock]
  matplot(x=stocks2$Year, y=stocks2[ ,1+which(assess.yrs==assess.yr)],
          col=assess.colors[1+istock], type='l', lty=1,
          lwd=2, add=TRUE)
}
# read data-moderate results
DMresults <- read.csv('./txt_files/age4plus_bio_from_Yellowtail_2013_DataModerate.csv')
# subset to remove forecast
DMresults <- DMresults[DMresults$Yr <= 2013,]
# add polygon showing uncertainty
## polygon(x=c(DMresults$Yr, rev(DMresults$Yr)),
##         y=c(DMresults$Age4plus_bio.025, rev(DMresults$Age4plus_bio.975)),
##         col=gray(0, alpha=0.1), border=NA)
# add median data-moderate estimates
lines(x=DMresults$Yr, DMresults$Age4plus_bio.median, col=assess.colors[8], lwd=2)

# add current model estimate
lines(mod1$timeseries[mod1$timeseries$Yr <= 2017, c("Yr","Bio_smry")],
      col=assess.colors[1], lwd=3)
abline(h=mod1$timeseries$Bio_smry[1], col=assess.colors[1], lwd=1, lty=3)
text(x=2007, y=mod1$timeseries$Bio_smry[1], col=1,
     labels="unfished equilibrium\nin base model")
legendnames <- c("Base model for Northern area",
                 "2013 assmt (data moderate, median)",
                 paste(sort(unique(assess.yrs), decreasing=TRUE), "assmt"))
legendnames[c(1,3:4)] <- paste(legendnames[c(1,3:4)], "(mid)")
legendnames[5:8] <- paste(legendnames[5:8], "(low & high)")
points(x=totcatch$Yr, y=totcatch$kill_bio, type='h', lwd=6, lend=3)
text(x=2007, y=0, col=1,
     labels="total catch\nin base model", pos=3)
legend('bottomleft', legend=legendnames,
       col=c(1, rev(assess.colors)), lwd=c(3, rep(2, 7)), bty='n')
box()
dev.off()