##################################################################################################
#
#	PacFIN Data Exploration for Canary Rockfish
# 		
#		Written by Brian Langseth
#
##################################################################################################

#devtools::install_github("nwfsc-assess/PacFIN.Utilities")
library(PacFIN.Utilities)
library(ggplot2)
library(tidyr)

dir = "//nwcfile/FRAM/Assessments/Assessment Data/2023 Assessment Cycle/canary rockfish/PacFIN data"
setwd(dir)


################################
#Load PacFIN BDS data, check for any issues, and set it up for expansion - UPDATED FOR NEW PACFIN VERSION
################################
load(file.path(dir, "PacFIN.CNRY.bds.01.Sep.2022.RData"))
pacfin = bds.pacfin

#Dealing with CA right now
pacfin = pacfin[pacfin$AGENCY_CODE=="C",]

# # Load in the current weight-at-length estimates by sex
# fa = ma = ua = 1.963e-5
# fb = mb = ub = 3.016
# 
# # Read in the PacFIN catch data to base expansion on
# catch.file = read.csv(file.path(dir, "output catch", "pacfin_catch_by_area_Feb2021.csv"))
# colnames(catch.file) = c("Year", "CA", "OR", "WA")


############################################################################################
#	Quickly look at the commercial and recreational samples by gear to see if the amount of data for each
#   and if there looks to be different selectivity by gear type
############################################################################################

pacfin$fleet[pacfin$PACFIN_GEAR_CODE %in% c("BMT","DNT","FFT","FTS","GFL","GFS","GFT","MDT","OTW","RLT","TWL")] <- "TWL"
pacfin$fleet[pacfin$PACFIN_GEAR_CODE %in% c("DST","SHT","SST")] <- "TWS"
pacfin$fleet[pacfin$PACFIN_GEAR_CODE %in% c("JIG","LGL","OHL","POL","VHL","HKL")] <- "HKL"
pacfin$fleet[pacfin$PACFIN_GEAR_CODE %in% c("DGN","DPN","GLN","SEN","STN")] <- "NET"
pacfin$fleet[pacfin$PACFIN_GEAR_CODE %in% c("CLP","CPT","FPT","OPT","PRW")] <- "POT"
pacfin$fleet[pacfin$PACFIN_GEAR_CODE %in% c("BTR", "DVG", "TRL","USP","OTH")] <- "OTH"

pacfin$gear <- NA
pacfin$gear[pacfin$fleet %in% c("HKL", "NET", "OTH", "POT")] <- "NTWL"
pacfin$gear[pacfin$fleet %in% c("TWL","MID","TWS")] <- "TWL"

#Length samples by year
ggplot(filter(pacfin,!is.na(FISH_LENGTH)), aes(fill=gear, x=SAMPLE_YEAR)) + 
  geom_bar(position="stack", stat="count") +
  xlab("Year") +
  ylab("# of length samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())

#Age samples by year
ggplot(filter(pacfin,!is.na(FINAL_FISH_AGE_IN_YEARS)), aes(fill=gear, x=SAMPLE_YEAR)) + 
  geom_bar(position="stack", stat="count") +
  xlab("Year") +
  coord_cartesian(xlim = c(1977,2021)) +
  ylab("# of age samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())


# #Distributions
# ggplot(pacfin, aes(FISH_LENGTH, fill = gear, color = gear)) +
#   geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.75) +
#   xlab("Fish Length - FL") +
#   ylab("samples") + 
#   theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())



##
#Load RecFIN data into R
##
recfin <- read.csv("U:/Stock assessments/canary_rockfish_supporting_2023/RecFIN pulls/RecFIN_CTE001_canary_2001_2021.csv",header=T)
recfin_len <- read.csv("U:/Stock assessments/canary_rockfish_supporting_2023/RecFIN pulls/RecFIN_SD001_CA_canary_2003_2021.csv",header=T)
recfin_age <- read.csv("U:/Stock assessments/canary_rockfish_supporting_2023/RecFIN pulls/conf_RecFIN_SD506_canary_1993_2021.csv",header=T)

#Catches
dontShow = unique(c(which(tmpN$N<3),which(tmpDealer$N<3),which(tmpID$N<3)))
ggplot(filter(tmp[-dontShow,], AGENCY_CODE=="C"), aes(fill=fleet.comb, y=sum, x=LANDING_YEAR)) + 
  geom_bar(position="stack", stat="identity") +
  xlab("Year") +
  ylab("Landings (MT)") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())



#Length samples by year
ggplot(subset(recfin_len,!recfin_len$RECFIN_MODE_NAME %in% c("NOT KNOWN") & !is.na(recfin_len$RECFIN_LENGTH_MM)), 
       aes(fill=SOURCE_CODE, x=RECFIN_YEAR)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("RECFIN_MODE_NAME") + 
  xlab("Year") +
  ylab("# of length samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())


#There are no age samples