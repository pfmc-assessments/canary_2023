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

#Confirm that no Puget sound records are included
#Issue #19 in github clarifies that state area 29 should be included. It was in PFMC area 4A
#and so the 44 records with that original designation are now listed as 3B. 
table(catch$REGION_NAME) #these are where landed...
table(catch$PACFIN_CATCH_AREA_CODE) #these show no Puget Sound areas (in the 4's)
table(catch$PACFIN_CATCH_AREA_CODE, catch$ORIG_PACFIN_CATCH_AREA_CODE)

#Summary of catch assigned to canary from various species codes
tmp <- catch %>% group_by(LANDING_YEAR, SPECIES_CODE_NAME) %>% summarize(sum = sum(LANDED_WEIGHT_MTONS)) %>% data.frame()
tmp$sum = round(tmp$sum,3)
spec_by_year = pivot_wider(tmp,names_from = c(LANDING_YEAR), values_from = sum)
#The percentage of landings assigned to canary from unspecified rockfish, unspecified rockfish N/A, and rockfish unspecified 
#It is high between 1981 to 1994
perc_urck = round(100*colSums(spec_by_year[which(spec_by_year$SPECIES_CODE_NAME %in% 
                                 c("UNSPECIFIED ROCKFISH              --N/A--",
                                   "ROCKFISH, UNSPECIFIED",
                                   "UNSPECIFIED ROCKFISH")),-1],na.rm=TRUE) / colSums(spec_by_year[,-1],na.rm=T),3)

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
#For WA these vessels are not included, but registered as NA. Vessel names are adequate

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
tmpID <- catch %>% group_by(fleet.comb,AGENCY_CODE,LANDING_YEAR) %>% summarize(N = length(unique(VESSEL_ID)))
tmpDealer <- catch %>% group_by(fleet.comb,AGENCY_CODE,LANDING_YEAR) %>% summarize(N = length(unique(DEALER_ID)))
tmp_wider_group <- pivot_wider(tmp, names_from = c(fleet.comb,AGENCY_CODE), names_sep = ".", values_from = sum) %>% arrange(LANDING_YEAR)
tmp_wider_groupN <- pivot_wider(tmpN, names_from = c(fleet.comb,AGENCY_CODE), names_sep = ".", values_from = N) %>% arrange(LANDING_YEAR)
tmp_wider_groupID <- pivot_wider(tmpID, names_from = c(fleet.comb,AGENCY_CODE), names_sep = ".", values_from = N) %>% arrange(LANDING_YEAR)
tmp_wider_groupDealer <- pivot_wider(tmpDealer, names_from = c(fleet.comb,AGENCY_CODE), names_sep = ".", values_from = N) %>% arrange(LANDING_YEAR)

#There are years (2003-2016) for NTWL gear where less than 3 vessels are fishing. 
#Vessel names show WA VesselID's are ALL NA. 
#Two more years are added for CA if dealer ID is used.

#Fleet categories
tmp <- catch %>% group_by(fleet, AGENCY_CODE, LANDING_YEAR) %>% summarize(sum = sum(LANDED_WEIGHT_MTONS))
tmpN <- catch %>% group_by(fleet, AGENCY_CODE, LANDING_YEAR) %>% summarize(N = length(unique(VESSEL_NAME)))
tmp_wider_fleet <- pivot_wider(tmp, names_from = c(fleet, AGENCY_CODE), names_sep = ".", values_from = sum) %>% arrange(LANDING_YEAR)
tmp_wider_fleetN <- pivot_wider(tmpN, names_from = c(fleet, AGENCY_CODE), names_sep = ".", values_from = N) %>% arrange(LANDING_YEAR)
#There are many years for NTWL gear where less than 3 vessels are fishing. 

