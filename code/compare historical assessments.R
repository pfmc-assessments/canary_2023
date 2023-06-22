#####################
#Script to read in historical abundance from past canary assessments
#
#Copied from 2017 yelloweye thanks to Ian Taylor: 
#https://github.com/iantaylor-NOAA/YTRK_doc/blob/master/Rcode/historical_assessment_timeseries.R#L17
#####################

library(r4ss)

setwd("\\\\nwcfile/FRAM/Assessments/Archives/CanaryRF")

##
#Read in old report files where I can from updates and full assessments
##

pp_2015 <- SS_output("CanaryRf_2015\\post-SSC base model")
pp_2015 <- pp_2015$timeseries[,c("Yr","Area","Bio_all","Bio_smry","SpawnBio","Recruit_0")]

pp_2011 <- SS_output("CanaryRf_2011\\Canary base case model files")
pp_2011 <- pp_2011$timeseries[,c("Yr","Bio_all","Bio_smry","SpawnBio","Recruit_0")]

####
#Copy and paste files from before 2009. All from time series part of the report
#Capabilities for reading in 2007 and 2005 
####

#2009: CanaryRf_2009\\base case model files Summary biomass at age 5
#2007: CanaryRf_2007\\ss2.rep Summary biomass at age 5
#2005: CanaryRf_2005\\Canary Models_2005\\ss2.rep Summary biomass at age 3

#2009 Smy biomass at age 5
rep_2009 <- file.path("CanaryRf_2009\\base case model files\\Report.sso")
lines2009 <- readLines(rep_2009)

pp_2009 <- read.table(rep_2009,
                      skip = grep("TIME_SERIES", lines2009)[2],
                      nrows = grep("SPR_series", lines2009)[2] - grep("TIME_SERIES", lines2009)[2] - 3,
                      header = TRUE,
                      fill = TRUE)[,c(2,3,5:8)]

#2007 Smy biomass at age 5
# rep_2007 <- file.path("CanaryRf_2007\\ss2.rep")
# lines2007 <- readLines(rep_2007)
# 
# pp_2007 <- read.table(rep_2007,
#                       skip = grep("TIME_SERIES", lines2007),
#                       nrows = grep("SPR_series", lines2007) - grep("TIME_SERIES", lines2007) - 3,
#                       header = TRUE,
#                       fill = TRUE)[,c(2,3,5:8)]

#2005 Smy biomass at age 3
# rep_2005 <- file.path("CanaryRf_2005\\Canary Models_2005\\ss2.rep")
# lines2005 <- readLines(rep_2005)
# 
# pp_2005 <- read.table(rep_2005,
#                       skip = grep("TIME_SERIES", lines2005),
#                       nrows = grep("SPR_series", lines2005) - grep("TIME_SERIES", lines2005) - 3,
#                       header = TRUE,
#                       fill = TRUE)[,c(2:7)]


####
#Copy and paste files from excel sheets - cant get readlines to work
####

#2002: CanaryRf_2002\\CanaryRf_2002_Models\\model\\canary2002-summary-output.csv
#1999: CanaryRf_1999\CanaryRf_1999_Model_Crone\Canary\Docs\Result_displays.xls Scenario 1

#2002 Smy biomass at age 3 - Doesnt work well
# rep_2002 <- file.path("CanaryRf_2002\\CanaryRf_2002_Models\\model\\canary2002-summary-output.csv")
# lines2002 <- readLines(rep_2002)
# 
# pp_2002 <- read.table(rep_2002,
#                       skip = grep(" SUM-BIO IS FOR AGES  3 -  25  IN PERIOD   1", lines2002) + 6,
#                       nrows = 60,
#                       header = TRUE,
#                       fill = TRUE)[,c(2:7)]


##
#Only for Oregon and Washington
##

#1996: Recognize text on tables 14 (scenario 1 M constant) and 15 (scenario 2 M age varying) in CanaryRf_1996\Canary rockfish.1996.SAFE.pdf
#1994: Recognize text on tables 21 (scenario 1 M constant) and 22 (scenario 2 M age varying) in CanaryRf_1996\Canary rockfish.1996.SAFE.pdf



####
#Copied values are stored
####
historical_values <- read.csv(here('literature','previous assessments','historical_biomass_comparison.csv'), header = TRUE)





plot(model$timeseries$Yr, model$timeseries$Bio_smry, 
     type = 'l', lwd = 3, ylim = c(0, 5e4), yaxs = 'i')
lines(ts2005$year[ts2005$season == 1], ts2005$bio.smry[ts2005$season == 1], col = 2, lwd = 3)




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
     axes=FALSE, xaxs='i', yaxs='i', xlab="Year", ylab="Age 5+ biomass (x1000 mt)")
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