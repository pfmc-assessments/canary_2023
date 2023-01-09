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


#Distributions
ggplot(pacfin, aes(FISH_LENGTH, fill = gear, color = gear)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.75) +
  xlab("Fish Length - FL") +
  ylab("samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())



