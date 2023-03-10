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
library(ggplot2)

dir = "//nwcfile/FRAM/Assessments/Assessment Data/2023 Assessment Cycle/canary rockfish/PacFIN data"

#User directories
if(Sys.getenv("USERNAME") == "Brian.Langseth") {
  git_dir <- "U:/Stock assessments/canary_2023/"
}

#################################################################################################################
#---------------------------------------------------------------------------------------------------------------#
# Load the commercial data
#---------------------------------------------------------------------------------------------------------------#
#################################################################################################################
# PacFIN Commercial - 1981-2022 Landings mtons
# 2022 is incomplete yet
load(file.path(dir, "PacFIN.CNRY.CompFT.01.Sep.2022.RData"))
com = catch.pacfin


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
table(catch$PACFIN_CATCH_AREA_CODE, catch$ORIG_PACFIN_CATCH_AREA_CODE) #but original code for 44 records was 4A - keep these

#Summary of catch assigned to canary from Original pacfin codes to look specifically at URCK
tmp <- catch %>% group_by(AGENCY_CODE,LANDING_YEAR, ORIG_PACFIN_SPECIES_CODE) %>% summarize(sum = sum(LANDED_WEIGHT_MTONS)) %>% data.frame()
tmp$sum = round(tmp$sum,3)
spec_by_year = pivot_wider(tmp,names_from = c(AGENCY_CODE,LANDING_YEAR), values_from = sum)
#The percentage of landings assigned to canary from unspecified rockfish, unspecified rockfish N/A, and rockfish unspecified 
#It is high between 1981 to 1994
perc_urck = round(100*colSums(spec_by_year[which(spec_by_year$ORIG_PACFIN_SPECIES_CODE %in% 
                                                   c("URCK")),-1],na.rm=TRUE) / colSums(spec_by_year[,-1],na.rm=T),3)

#Assign gear codes based on what was used in the 2015 assessment. 
#Removed any codes that dont show up in current pacfin data.
#Added unknown gear (USP) into "OTH" category
catch$fleet <- rep(NA, nrow(catch))
catch$fleet[catch$PACFIN_GEAR_CODE %in% c("BMT","DNT","FFT","FTS","GFL","GFS","GFT","MDT","OTW","RLT")] <- "TWL"
catch$fleet[catch$PACFIN_GEAR_CODE %in% c("MDT","MPT")] <- "MID"
catch$fleet[catch$PACFIN_GEAR_CODE %in% c("DST","SHT","SST")] <- "TWS"
catch$fleet[catch$PACFIN_GEAR_CODE %in% c("JIG","LGL","OHL","POL","VHL")] <- "HKL"
catch$fleet[catch$PACFIN_GEAR_CODE %in% c("DGN","DPN","GLN","SEN","STN")] <- "NET"
catch$fleet[catch$PACFIN_GEAR_CODE %in% c("CLP","CPT","FPT","OPT","PRW")] <- "POT"
catch$fleet[catch$PACFIN_GEAR_CODE %in% c("BTR", "DVG", "TRL","USP")] <- "OTH"

#SOME NON TRAWL GEAR DURING 2003-2016 HAVE FEWER THAN 3 UNIQUE VESSELS
#For WA these vessels are not included, but registered as NA. Vessel names are adequate

#Assign to grouped fleets designations
#In issue 9 on github, Ali suggests TWS (shrimp trawls) be added to trawl gear,
#which differs from how it has been done in the past. 
#Separate out TWS to check difference with 2015 model estimates.
catch$fleet.comb <- rep(NA, nrow(catch))
catch$fleet.comb[catch$fleet %in% c("HKL", "NET", "OTH", "POT")] <- "NTWL"
catch$fleet.comb[catch$fleet %in% c("TWL","MID","TWS")] <- "TWL"


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
#One more years is added for CA if dealer ID is used.


# ##
# #Upload to googledrive
# #Must go in CONFIDENTIAL folder because of landings from fewer than 3 vessels
# ##
# xx <- googledrive::drive_create(name = 'pacfin_catch',
#                                 path = 'https://drive.google.com/drive/folders/179mhykZRxnXFLp81sFOAYsPtLfVOUtKB', 
#                                 type = 'spreadsheet', overwrite = FALSE)
# googlesheets4::sheet_write(round(tmp_wider_group,3), ss = xx, sheet = "catch_mt")
# googlesheets4::sheet_write(tmp_wider_groupID, ss = xx, sheet = "unique_vessels")
# googlesheets4::sheet_write(tmp_wider_groupDealer, ss = xx, sheet = "unique_dealers")
# googlesheets4::sheet_delete(ss = xx, sheet = "Sheet1")



#################################################################################################################
#Plotting
#################################################################################################################
##
#Combined fleet plots
##
dontShow = unique(c(which(tmpN$N<3),which(tmpDealer$N<3),which(tmpID$N<3)))
ggplot(filter(tmp[-dontShow,], AGENCY_CODE=="C"), aes(fill=fleet.comb, y=sum, x=LANDING_YEAR)) + 
  geom_bar(position="stack", stat="identity") +
  xlab("Year") +
  ylab("Landings (MT)") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","CA_com_landings_fleetGroup.png"),
       width = 6, height = 4)

ggplot(filter(tmp[-dontShow,], AGENCY_CODE=="O"), aes(fill=fleet.comb, y=sum, x=LANDING_YEAR)) + 
  geom_bar(position="stack", stat="identity") +
  xlab("Year") +
  ylab("Landings (MT)") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","OR_com_landings_fleetGroup.png"),
       width = 6, height = 4)

ggplot(filter(tmp[-dontShow,], AGENCY_CODE=="W"), aes(fill=fleet.comb, y=sum, x=LANDING_YEAR)) + 
  geom_bar(position="stack", stat="identity") +
  xlab("Year") +
  ylab("Landings (MT)") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","WA_com_landings_fleetGroup.png"),
       width = 6, height = 4)

lab_val = c("California", "Oregon", "Washington")
names(lab_val) = c("C","O","W")
ggplot(tmp[-dontShow,], aes(fill=fleet.comb, y=sum, x=LANDING_YEAR)) + 
  geom_bar(position="stack", stat="identity") +
  facet_wrap("AGENCY_CODE", ncol = 1, labeller = labeller(AGENCY_CODE = lab_val)) + 
  xlab("Year") +
  ylab("Landings (MT)") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","com_landings_fleetGroup.png"),
       width = 6, height = 8)


##
#More refined landings by fleet and plots
##

#Pot never really shows up to a large degree so combining with Other for sake of 
#pre-assessment workshop plotting
catch$fleet[catch$fleet %in% c("POT")] <- "OTH"

tmp_fleet <- catch %>% group_by(fleet, AGENCY_CODE, LANDING_YEAR) %>% summarize(sum = sum(LANDED_WEIGHT_MTONS))
tmpN_fleet <- catch %>% group_by(fleet,AGENCY_CODE,LANDING_YEAR) %>% summarize(N = length(unique(VESSEL_NAME)))
tmpID_fleet <- catch %>% group_by(fleet,AGENCY_CODE,LANDING_YEAR) %>% summarize(N = length(unique(VESSEL_ID)))
tmpDealer_fleet <- catch %>% group_by(fleet,AGENCY_CODE,LANDING_YEAR) %>% summarize(N = length(unique(DEALER_ID)))

dontShow = unique(c(which(tmpN_fleet$N<3),which(tmpDealer_fleet$N<3),which(tmpID_fleet$N<3)))

#California
ggplot(filter(tmp_fleet[-dontShow,], AGENCY_CODE=="C"), aes(y=sum, x=LANDING_YEAR)) + 
  facet_wrap("fleet") + 
  geom_bar(aes(fill = fleet), position="stack", stat="identity") +
  xlab("Year") +
  ylab("Landings (MT)") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","CA_com_landings_fleet.png"),
       width = 6, height = 4)

#Oregon
ggplot(filter(tmp_fleet[-dontShow,], AGENCY_CODE=="O"), aes(y=sum, x=LANDING_YEAR)) + 
  facet_wrap("fleet") + 
  geom_bar(aes(fill = fleet), position="stack", stat="identity") +
  xlab("Year") +
  ylab("Landings (MT)") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","OR_com_landings_fleet.png"),
       width = 6, height = 4)

#Washington
ggplot(filter(tmp_fleet[-dontShow,], AGENCY_CODE=="W"), aes(y=sum, x=LANDING_YEAR)) + 
  facet_wrap("fleet") + 
  geom_bar(aes(fill = fleet), position="stack", stat="identity") +
  xlab("Year") +
  ylab("Landings (MT)") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","WA_com_landings_fleet.png"),
       width = 6, height = 4)

#CoastWide
ggplot(filter(tmp_fleet[-dontShow,]), aes(y=sum, x=LANDING_YEAR)) + 
  facet_wrap("AGENCY_CODE", ncol = 1, labeller = labeller(AGENCY_CODE = lab_val)) + 
  geom_bar(aes(fill = fleet), position="stack", stat="identity") +
  xlab("Year") +
  ylab("Landings (MT)") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","com_landings_fleet.png"),
       width = 6, height = 8)




#################################################################################################################
#---------------------------------------------------------------------------------------------------------------#
# Load the commercial data for URCK to check totals - Only exploration so commenting out
#---------------------------------------------------------------------------------------------------------------#
#################################################################################################################
# # PacFIN Commercial - 1981-2022 Landings mtons
# # 2022 is incomplete yet
# load(file.path(dir, "PacFIN.URCK.CompFT.09.Nov.2022.Rdata"))
# com = catch.pacfin
# rm(catch.pacfin)
# 
# catch = com
# catch = catch[!catch$REMOVAL_TYPE_CODE %in% c("R"),] #remove research catches
# 
# tmp <- catch %>% group_by(LANDING_YEAR, SPECIES_CODE_NAME) %>% summarize(sum = sum(LANDED_WEIGHT_MTONS)) %>% data.frame()
# tmp$sum = round(tmp$sum,3)
# spec_by_year = pivot_wider(tmp,names_from = c(LANDING_YEAR), values_from = sum)
# 
# #Sum across all species contributing to URCK
# urck = spec_by_year %>% select(-1) %>% replace(is.na(.),0) %>% summarise(across(everything(), sum))
# 
# #Group by states
# tmp <- catch %>% group_by(AGENCY_CODE, LANDING_YEAR) %>% summarize(sum = sum(LANDED_WEIGHT_MTONS))
# tmpN <- catch %>% group_by(AGENCY_CODE,LANDING_YEAR) %>% summarize(N = length(unique(VESSEL_NAME)))
# tmpID <- catch %>% group_by(AGENCY_CODE,LANDING_YEAR) %>% summarize(N = length(unique(VESSEL_ID)))
# tmpDealer <- catch %>% group_by(AGENCY_CODE,LANDING_YEAR) %>% summarize(N = length(unique(DEALER_ID)))
# tmp_wider_group <- pivot_wider(tmp, names_from = c(AGENCY_CODE), names_sep = ".", values_from = sum) %>% arrange(LANDING_YEAR)
# tmp_wider_groupN <- pivot_wider(tmpN, names_from = c(AGENCY_CODE), names_sep = ".", values_from = N) %>% arrange(LANDING_YEAR)
# tmp_wider_groupID <- pivot_wider(tmpID, names_from = c(AGENCY_CODE), names_sep = ".", values_from = N) %>% arrange(LANDING_YEAR)
# tmp_wider_groupDealer <- pivot_wider(tmpDealer, names_from = c(AGENCY_CODE), names_sep = ".", values_from = N) %>% arrange(LANDING_YEAR)
# #In most recent years, where URCK is sparse, there are fewer than 3 vessels/dealers
# #If oNly show for before 2000 is fine
# 
# xx <- googledrive::drive_create(name = 'pacfin_catch_urck',
#                                 path = 'https://drive.google.com/drive/folders/179mhykZRxnXFLp81sFOAYsPtLfVOUtKB',
#                                 type = 'spreadsheet', overwrite = TRUE)
# googlesheets4::sheet_write(round(tmp_wider_group,3), ss = xx, sheet = "catch_mt")
# googlesheets4::sheet_write(tmp_wider_groupID, ss = xx, sheet = "unique_vessels")
# googlesheets4::sheet_write(tmp_wider_groupDealer, ss = xx, sheet = "unique_dealers")
# googlesheets4::sheet_delete(ss = xx, sheet = "Sheet1")
# 
# 
# #Biological data is ALL from California
# load(file.path(dir, "PacFIN.URCK.bds.10.Jan.2023.Rdata"))
# bds = bds.pacfin
# rm(bds.pacfin)
# bds %>% group_by(AGENCY_CODE, SAMPLE_YEAR) %>% summarize(N = length(unique(FISH_LENGTH)))


