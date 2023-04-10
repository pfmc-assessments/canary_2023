##############################################################################################################
#
# 	Purpose: Explore expanding recreational comps
#
#		Created: April 7, 2023
#         by Brian Langseth
#
##############################################################################################################

#Have views from Jason Edwards (sent XXXX) for WA and OR
#Have data from Nick Grunlo (sent XXXX) for CA

#First order of business is to determine how different 
#expanding comps versus non-expanding comps is. If its 
#not different than I dont see the need to do rec comp
#expansions. 

library(ggplot2)
library(tidyr)
library(dplyr)

#User directories
if(Sys.getenv("USERNAME") == "Brian.Langseth") {
  dir <- "U:/Stock assessments/canary_rockfish_supporting_2023/RecFIN pulls"
  git_dir <- "U:/Stock assessments/canary_2023/"
}

############################################################################################
#	Load data for Oregon and generate comps
############################################################################################

or <- read.csv(file.path(dir,"catch_weighted_length_comp_or_v.csv"), header = TRUE)
or <- or[or$SPECIES_NAME == "CANARY ROCKFISH",]
or <- or[!is.na(or$BIN_NAME),] #only values with length bins
or$lengthcm <- or$BIN_NAME/10

####
#Unexpanded - copying from canary_recreational_comps.R
####

#Expand out by counts in each bin (BIN_CNT)
out <- or[rep(1:(dim(or)[1]), or$BIN_CNT),]

# Add expected column names to work with nwfscSurvey package
out$age = NA
length_bins <- c(seq(12, 66, 2))

out$sex <- "U" #assume all are unsexed

#get sample size by sex group
n <- out %>% 
  dplyr::group_by(YEAR) %>%
  dplyr::summarise(
    N = length(lengthcm))

#This creates the composition data for each SS3 fleet. 
#Right now the script for sexed comps is in the unsexed_comps branch of nwfscSurvey
#so if have sexes need to navigate to there and then load_all
#devtools::load_all("U:/Other github repos/nwfscSurvey") ###IMPORTANT TO UNCOMMENT THIS IF RERUN

use_n <- n
df <- out

lfs <-  nwfscSurvey::UnexpandedLFs.fn(
  datL = df, 
  lgthBins = length_bins,
  partition = 0, 
  fleet = "ORrec", 
  month = 7)

write.csv(lfs$unsexed, 
            file = file.path(dir, paste0("OR_catch_weigthed_Lcomp_BINS.csv")),
            row.names = FALSE) 



####
#Expanded - copying from canary_recreational_comps.R
####

#Expand out by catch weighting counts in each bin (BIN_CATCH)
#BIN_CATCH is a non-integer so rep automatically uses floor
out <- or[rep(1:(dim(or)[1]), or$BIN_CATCH),]

# Add expected column names to work with nwfscSurvey package
out$age = NA
length_bins <- c(seq(12, 66, 2))

out$sex <- "U" #assume all are unsexed

#get sample size by sex group
n <- out %>% 
  dplyr::group_by(YEAR) %>%
  dplyr::summarise(
    N = length(lengthcm))

use_n <- n
df <- out

lfs <-  nwfscSurvey::UnexpandedLFs.fn(
  datL = df, 
  lgthBins = length_bins,
  partition = 0, 
  fleet = "ORrec", 
  month = 7)

write.csv(lfs$unsexed, 
          file = file.path(dir, "OR_catch_weigthed_Lcomp_CATCH.csv"),
          row.names = FALSE) 


############################################################################################
#	Load data for Washington and generate comps
############################################################################################

wa <- read.csv(file.path(dir,"catch_weighted_length_comp_wa_v.csv"), header = TRUE)
wa <- wa[wa$SPECIES_NAME == "CANARY ROCKFISH",]
wa <- wa[!is.na(wa$BIN_NAME),] #only values with length bins
wa <- wa[!is.na(wa$BIN_CATCH),] #somehow for WA I need to do this too to remove all NA
wa$lengthcm <- wa$BIN_NAME/10

####
#Unexpanded - copying from canary_recreational_comps.R
####

#Expand out by counts in each bin (BIN_CNT)
out <- wa[rep(1:(dim(wa)[1]), wa$BIN_CNT),]

# Add expected column names to work with nwfscSurvey package
out$age = NA
length_bins <- c(seq(12, 66, 2))

out$sex <- "U" #assume all are unsexed

#get sample size by sex group
n <- out %>% 
  dplyr::group_by(YEAR) %>%
  dplyr::summarise(
    N = length(lengthcm))

#This creates the composition data for each SS3 fleet. 
#Right now the script for sexed comps is in the unsexed_comps branch of nwfscSurvey
#so if have sexes need to navigate to there and then load_all
#devtools::load_all("U:/Other github repos/nwfscSurvey") ###IMPORTANT TO UNCOMMENT THIS IF RERUN

use_n <- n
df <- out

lfs <-  nwfscSurvey::UnexpandedLFs.fn(
  datL = df, 
  lgthBins = length_bins,
  partition = 0, 
  fleet = "WArec", 
  month = 7)

write.csv(lfs$unsexed, 
          file = file.path(dir, paste0("WA_catch_weigthed_Lcomp_BINS.csv")),
          row.names = FALSE) 



####
#Expanded - copying from canary_recreational_comps.R
####

#Expand out by catch weighting counts in each bin (BIN_CATCH)
#BIN_CATCH is a non-integer so rep automatically uses floor
#For WASHINGTON, 31 of these are less than 1 so get excluded
out <- wa[rep(1:(dim(wa)[1]), wa$BIN_CATCH),]

# Add expected column names to work with nwfscSurvey package
out$age = NA
length_bins <- c(seq(12, 66, 2))

out$sex <- "U" #assume all are unsexed

#get sample size by sex group
n <- out %>% 
  dplyr::group_by(YEAR) %>%
  dplyr::summarise(
    N = length(lengthcm))

use_n <- n
df <- out

lfs <-  nwfscSurvey::UnexpandedLFs.fn(
  datL = df, 
  lgthBins = length_bins,
  partition = 0, 
  fleet = "WArec", 
  month = 7)

write.csv(lfs$unsexed, 
          file = file.path(dir, "WA_catch_weigthed_Lcomp_CATCH.csv"),
          row.names = FALSE) 


############################################################################################
#	Plot and compare the weighted and unweighted comps
############################################################################################

##Oregon
uwOR <- read.csv(file.path(dir, "OR_catch_weigthed_Lcomp_BINS.csv"), header = TRUE )
uwOR <- cbind(uwOR[, 1:6], uwOR[,7:34]/apply(uwOR[,7:34], 1, sum))

wOR <- read.csv(file.path(dir, "OR_catch_weigthed_Lcomp_CATCH.csv"), header = TRUE )
wOR <- cbind(wOR[, 1:6], wOR[,7:34]/apply(wOR[,7:34], 1, sum))

pdf(file.path(git_dir, "data_explore_figs", "compare_OR_RecFIN_weighted_Lcomps.pdf"), 
    width = 12, height = 12)
par(mfrow = c(4, 5), mar = c(1, 1,1,1), oma = c(2,2,2, 2))
for(y in sort(unique(or$YEAR))){
  plot(0, bty = 'n', ylim = c(0,1), xlim = c(12, 66), ylab = "Density", xlab = "Length (cm)")
  lines(length_bins, uwOR[uwOR$year == y, 7:34], lty = 1, lwd = 2)
  lines(length_bins, wOR[wOR$year == y, 7:34], lty = 2, lwd = 2, col = 'blue')
  mtext(y, line = -1)
}
legend('topright', bty = 'n', col = c(1, 'blue'), legend = c("unweighted", "weighted"), lwd = 2, lty = c(1,2), 
       cex = 2)
dev.off()


##Washington
uwWA <- read.csv(file.path(dir, "WA_catch_weigthed_Lcomp_BINS.csv"), header = TRUE )
uwWA <- cbind(uwWA[, 1:6], uwWA[,7:34]/apply(uwWA[,7:34], 1, sum))

wWA <- read.csv(file.path(dir, "WA_catch_weigthed_Lcomp_CATCH.csv"), header = TRUE )
wWA <- cbind(wWA[, 1:6], wWA[,7:34]/apply(wWA[,7:34], 1, sum))

pdf(file.path(git_dir, "data_explore_figs", "compare_WA_RecFIN_weighted_Lcomps.pdf"), 
    width = 12, height = 12)
par(mfrow = c(4, 5), mar = c(1, 1,1,1), oma = c(2,2,2, 2))
for(y in sort(unique(wa$YEAR))){
  plot(0, bty = 'n', ylim = c(0,1), xlim = c(12, 66), ylab = "Density", xlab = "Length (cm)")
  lines(length_bins, uwWA[uwWA$year == y, 7:34], lty = 1, lwd = 2)
  lines(length_bins, wWA[wWA$year == y, 7:34], lty = 2, lwd = 2, col = 'blue')
  mtext(y, line = -1)
}
legend('topright', bty = 'n', col = c(1, 'blue'), legend = c("unweighted", "weighted"), lwd = 2, lty = c(1,2), 
       cex = 2)
dev.off()







