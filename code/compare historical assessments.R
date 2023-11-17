#####################
#Script to read in historical abundance from past canary assessments
#
#Copied from 2017 yelloweye thanks to Ian Taylor: 
#https://github.com/iantaylor-NOAA/YTRK_doc/blob/master/Rcode/historical_assessment_timeseries.R#L17
#####################

library(r4ss)
library(here)
library(dplyr)

setwd("\\\\nwcfile/FRAM/Assessments/Archives/CanaryRF")

base_2023 <- here('models','7_3_5_reweight')

##
#Read in current files
##
pp_2023 <- SS_output(base_2023)
pp_2023 <- pp_2023$timeseries[,c("Yr","Area","Bio_all","Bio_smry","SpawnBio","Recruit_0")]
colnames(pp_2023)[3:6] <- paste0("X2023_",colnames(pp_2023)[3:6])


##
#Read in old report files where I can from updates and full assessments
##

pp_2015 <- SS_output("CanaryRf_2015\\post-SSC base model")
pp_2015 <- pp_2015$timeseries[pp_2015$timeseries$Era!="FORE",c("Yr","Area","Bio_all","Bio_smry","SpawnBio","Recruit_0")]
pp_2015_agg <- pp_2015 %>% group_by(Yr) %>% summarize_all(sum)
colnames(pp_2015_agg)[3:6] <- paste0("X2015_",colnames(pp_2015_agg)[3:6])

pp_2011 <- SS_output("CanaryRf_2011\\Canary base case model files")
pp_2011 <- pp_2011$timeseries[pp_2011$timeseries$Era!="FORE",c("Yr","Bio_all","Bio_smry","SpawnBio","Recruit_0")]
colnames(pp_2011)[2:5] <- paste0("X2011_",colnames(pp_2011)[2:5])


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
                      fill = TRUE)
pp_2009 <- pp_2009[pp_2009$Era!="FORE",c(2,3,5:8)]
colnames(pp_2009)[3:6] <- paste0("X2009_",colnames(pp_2009)[3:6])


#2007 Smy biomass at age 5
rep_2007 <- file.path("CanaryRf_2007\\ss2.rep")
lines2007 <- readLines(rep_2007)

pp_2007 <- read.table(rep_2007,
                      skip = grep("TIME_SERIES", lines2007),
                      nrows = grep("SPR_series", lines2007) - grep("TIME_SERIES", lines2007) - 3,
                      header = TRUE,
                      fill = TRUE)
pp_2007 <- pp_2007[pp_2007$period!="FORE",c(2,3,5:8)]

#2005 Smy biomass at age 3
rep_2005 <- file.path("CanaryRf_2005\\Canary Models_2005\\ss2.rep")
lines2005 <- readLines(rep_2005)

pp_2005 <- read.table(rep_2005,
                      skip = grep("TIME_SERIES", lines2005),
                      nrows = grep("SPR_series", lines2005) - grep("TIME_SERIES", lines2005) - 3,
                      header = TRUE,
                      fill = TRUE)[,c(2:7)]


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
#need to fix summary biomass in 1984 for scneario 2 and in 1991 for scenario 1


####
#Copied values are stored
####
hist_values <- read.csv(here('literature','previous assessments','historical_biomass_comparison.csv'), header = TRUE)


####
#Combine copied and recent values
####
all_values <- left_join(pp_2015_agg[-2],
                        left_join(pp_2011,
                                  left_join(pp_2009[,-2], hist_values, by = join_by("Yr" == "year")),
                                  by = "Yr"),
                        by = "Yr") %>% data.frame()

# compare summary biomass across previous stock assessments

smry <- all_values[,grep("Yr|smry",colnames(all_values))]
bio <- all_values[,grep("Yr|all|.stock",colnames(all_values))]
spawn <- all_values[,grep("Yr|SpawnBio",colnames(all_values))]
recruit <- all_values[,grep("Yr|Recruit|recruit",colnames(all_values))]

par(mar=c(4,4,1,1))
assess.colors <- rich.colors.short(10)


# empty plot for all biomass
plot(0, type='n', xlim=c(1892, 2022), ylim=c(0, 100000),
     axes=FALSE, xaxs='i', yaxs='i', xlab="Year", ylab="Total biomass (x1000 mt)")
axis(1)
axis(2, at=pretty(c(0,100000)), lab=pretty(c(0,100000))/1000, las=1)
# add lines for the older assessments
matplot(x=bio[,"Yr"], y=bio[,-1],
        col=assess.colors, type='l', lty=1,
        lwd=2, add=TRUE)
lines(pp_2023$Yr, pp_2023$X2023_Bio_all,
      col='red', lwd=3)
#Add legend
legendnames <- substr(sub(".*X", "", 
                          c(colnames(bio[,-c(1,grep("scen2",colnames(smry)))]),"X2023")), 
                      1, 4)
legend('bottomleft', legend=legendnames, ncol = 3,
       col=c(assess.colors[1:(length(legendnames)-1)],'red'), lwd=c(3, rep(2, 7)), bty='n')
box()


# # empty plot for spawning biomass. Not good because 2015 and 2023 is in millions of eggs
# plot(0, type='n', xlim=c(1892, 2022), ylim=c(0, 50000),
#      axes=FALSE, xaxs='i', yaxs='i', xlab="Year", ylab="Spawning biomass (x1000 mt)")
# axis(1)
# axis(2, at=pretty(c(0,50000)), lab=pretty(c(0,50000))/1000, las=1)
# # add lines for the older assessments
# matplot(x=spawn[,"Yr"], y=spawn[,-1],
#         col=assess.colors, type='l', lty=1,
#         lwd=2, add=TRUE)
# #add current model estimate
# lines(pp_2023$Yr, pp_2023$X2023_SpawnBio,
#       col=assess.colors[1], lwd=3)
# #Add legend
# legendnames <- c(colnames(spawn)[-1],"current")
# legend('bottomleft', legend=legendnames,
#        col=c(assess.colors,assess.colors[1:(
#          length(legendnames)-length(assess.colors)-1)],assess.colors[1]), lwd=c(3, rep(2, 7)), bty='n')
# box()


##
#For report here
##

png(filename=here('documents','Figures','historical_assessment_smry_biomss.png'),
    width=5.5, height=7, res=300, units='in')
par(mfrow=c(2,1),mar=c(4,4,1,1))
assess.colors <- rich.colors.short(10)

# empty plot for summary biomass
# 2002 has summary biomass starting at age 3, 1999 doesn't report summary biomass where I looked
plot(0, type='n', xlim=c(1892, 2022), ylim=c(0, 100000),
     axes=FALSE, xaxs='i', yaxs='i', xlab="Year", ylab="Summary biomass (x1000 mt)")
axis(1)
axis(2, at=pretty(c(0,100000)), lab=pretty(c(0,100000))/1000, las=1)
# add lines for the older assessments
matplot(x=smry[,"Yr"], y=smry[,-c(1,grep("smry3|scen2",colnames(smry)))],
        col=assess.colors, type='l', lty=1,
        lwd=2, add=TRUE)
# add current model estimate
lines(pp_2023$Yr, pp_2023$X2023_Bio_smry,
      col="red", lwd=3)
#Add legend
legendnames <- substr(sub(".*X", "", 
                          c("X2023", colnames(smry[,-c(1,grep("smry3|scen2",colnames(smry)))]))), 
                      1, 4)
legend('bottomleft', legend=legendnames, ncol = 3,
       col=c("red",assess.colors[1:(length(legendnames)-1)]), lwd=c(3, rep(2, 7)), bty='n')
box()


# empty plot for recruits
plot(0, type='n', xlim=c(1892, 2022), ylim=c(0, 10000),
     axes=FALSE, xaxs='i', yaxs='i', xlab="Year", ylab="Recruits (millions)")
axis(1)
axis(2, at=pretty(c(0,10000)), lab=pretty(c(0,10000))/1000, las=1)
# add lines for the older assessments
matplot(x=recruit[,"Yr"], y=recruit[,-c(1,grep("smry3|scen2",colnames(smry)))],
        col=assess.colors, type='l', lty=1,
        lwd=2, add=TRUE)
# add current model estimate
lines(pp_2023$Yr, pp_2023$X2023_Recruit_0,
      col='red', lwd=3)
#Add legend
legendnames <- substr(sub(".*X", "", 
                          c("X2023", colnames(recruit[,-c(1,grep("smry3|scen2",colnames(smry)))]))), 
                      1, 4)
legend('topleft', legend=legendnames, ncol =3,
       col=c("red", assess.colors[1:(length(legendnames)-1)]), lwd=c(3, rep(2, 7)), bty='n')
box()
dev.off()
