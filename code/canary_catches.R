##############################################################################################################
#
# 	Purpose: Output Canary Rockfish Landings 
#            into form for use in SS
#
#   Created: Oct 28, 2022
#			  by Brian Langseth 
#
##############################################################################################################

library(dplyr)
library(tidyr)

dir = "//nwcfile/FRAM/Assessments/Assessment Data/2023 Assessment Cycle/canary rockfish/PacFIN data"


#################################################################################################################
#---------------------------------------------------------------------------------------------------------------#
# Load the commercial data
#---------------------------------------------------------------------------------------------------------------#
#################################################################################################################
# PacFIN Commercial - 1981-2022 Landings lbs
# 2022 is incomplete yet
load(file.path(dir, "PacFIN.CNRY.CompFT.01.Sep.2022.RData"))
com = catch.pacfin
rm(catch.pacfin)


#################################################################################################################
# Evaluate the commercial data 
#################################################################################################################

catch = com 
catch = catch[!catch$REMOVAL_TYPE_CODE %in% c("R"),] #remove research catches

#Assign gear codes based on what was used in the 2015 assessment. 
#Removed any codes that dont show up in current pacfin data.
#Added unknown gear (USP) into "OTH" category
catch$fleet <- rep(NA, nrow(catch))
catch$fleet[catch$PACFIN_GEAR_CODE %in% c("BMT","DNT","FFT","FTS","GFL","GFS","GFT","MDT","OTW","RLT")] <- "TWL"
catch$fleet[catch$PACFIN_GEAR_CODE %in% c("DST","SHT","SST")] <- "TWS"
catch$fleet[catch$PACFIN_GEAR_CODE %in% c("JIG","LGL","OHL","POL","VHL")] <- "HKL"
catch$fleet[catch$PACFIN_GEAR_CODE %in% c("DGN","DPN","GLN","SEN","STN")] <- "NET"
catch$fleet[catch$PACFIN_GEAR_CODE %in% c("CLP","CPT","FPT","OPT","PRW")] <- "POT"
catch$fleet[catch$PACFIN_GEAR_CODE %in% c("BTR", "DVG", "TRL","USP")] <- "OTH"

#SOME NON TRAWL GEAR DURING 2003-2016 HAVE FEWER THAN 3 UNIQUE VESSELS
#NEED TO CONFIRM NO PUGET SOUND RECORDS ARE INCLUDED

#Assign to grouped fleets designations
catch$fleet.comb <- rep(NA, nrow(catch))
catch$fleet.comb[catch$fleet %in% c("HKL", "NET", "OTH", "POT", "TWS")] <- "NTWL"
catch$fleet.comb[catch$fleet %in% c("TWL","MID")] <- "TWL"

##
#Summaries
##

#Grouped fleets categories
tmp <- catch %>% group_by(fleet.comb, AGENCY_CODE, LANDING_YEAR) %>% summarize(sum = sum(LANDED_WEIGHT_MTONS))
tmpN <- catch %>% group_by(fleet.comb,AGENCY_CODE,LANDING_YEAR) %>% summarize(N = length(unique(VESSEL_NAME)))
tmp_wider_group <- pivot_wider(tmp, names_from = c(fleet.comb,AGENCY_CODE), names_sep = ".", values_from = sum)
tmp_wider_groupN <- pivot_wider(tmpN, names_from = c(fleet.comb,AGENCY_CODE), names_sep = ".", values_from = N)
#There are years (2003-2016) for NTWL gear where less than 3 vessels are fishing. 

#Fleet categories
tmp <- catch %>% group_by(fleet, AGENCY_CODE, LANDING_YEAR) %>% summarize(sum = sum(LANDED_WEIGHT_MTONS))
tmpN <- catch %>% group_by(fleet, AGENCY_CODE, LANDING_YEAR) %>% summarize(N = length(unique(VESSEL_NAME)))
tmp_wider_fleet <- pivot_wider(tmp, names_from = c(fleet, AGENCY_CODE), names_sep = ".", values_from = sum)
tmp_wider_fleetN <- pivot_wider(tmpN, names_from = c(fleet, AGENCY_CODE), names_sep = ".", values_from = N)
#There are many years for NTWL gear where less than 3 vessels are fishing. 

