##############################################################################################################
#
# 	Purpose: Output Canary Rockfish Landings and Discards
#            into form for use in SS
#
#   Created: Mar 10, 2023
#			  by Brian Langseth 
#
#   Uses output from the following scripts, combines them, and then fills in gaps
#     canary_catches_com.R
#     canary_catches_rec.R
#     canary_discard_exploration.R
#
#   See discussion #47 in github repo for descriptions
#     https://github.com/pfmc-assessments/canary_2023/discussions/47
#
##############################################################################################################

library(dplyr)
library(tidyr)
library(ggplot2)

#User directories
if(Sys.getenv("USERNAME") == "Brian.Langseth") {
  git_dir <- "U:/Stock assessments/canary_2023"
}


#################################################################################################################
#---------------------------------------------------------------------------------------------------------------#
# Load commercial data
#---------------------------------------------------------------------------------------------------------------#
#################################################################################################################

##
#PacFIN LANDINGS in MT (entrys with <3 veseels or dealers are CONFIDENTIAL)
#This is output from canary_catches_com.R
##
pacfin <- googlesheets4::read_sheet('https://docs.google.com/spreadsheets/d/17x0PT_vqTv1kvHAwaqgz7jmKvCvRwm7OcFb4jrh_AWo/edit#gid=2086044691',
                                    sheet = "catch_mt")
pacfin_Nvessel <- googlesheets4::read_sheet('https://docs.google.com/spreadsheets/d/17x0PT_vqTv1kvHAwaqgz7jmKvCvRwm7OcFb4jrh_AWo/edit#gid=2086044691',
                                    sheet = c("unique_vessels"))
pacfin_Ndealer <- googlesheets4::read_sheet('https://docs.google.com/spreadsheets/d/17x0PT_vqTv1kvHAwaqgz7jmKvCvRwm7OcFb4jrh_AWo/edit#gid=2086044691',
                                            sheet = c("unique_dealers"))

##
#Discard estimates from PacFIN years based on GEMM report allocated based on WCGOP state proportions
#This is output from canary_discard_exploration.R
##
gemm_discard <- utils::read.csv(file = file.path(git_dir, "data", "canary_commercial_discard_mt.csv"), header = TRUE)


##
#Oregon commercial reconstruction - landings in MT
##
#Only need to pull from googledrive once
# googledrive::drive_download(file = "Oregon data/Oregon Commercial landings_451_2022.csv",
#                             path = file.path(git_dir,"data-raw","Oregon Commercial landings_451_2022.csv"))
or_com <- utils::read.csv(file = file.path(git_dir,"data-raw","Oregon Commercial landings_451_2022.csv"), header = TRUE)


##
#California historical commercial
##

####Reconstruction from Ralston - sent by EJ Dick

ca_hist_com <- utils::read.csv(file = file.path(git_dir,"data-raw","Canary_CA_Catch_Reconstruction_Ralston_et_al_2010.csv"), header = TRUE)
ca_hist_com$mt <- ca_hist_com$pounds*0.000453592

#Per EJ's email, for 2021 Vermillion (page 10), he allocated annual catches
#from unknown locations (Region 0) and unknown gear types proportional to the 
#catches from known regions and gears. Catches from known regions, but unknown
#gears, were allocated proportional to catches by known gears within the same region 
table(ca_hist_com$region,ca_hist_com$gear) #gears 2 and 4
table(ca_hist_com$year,ca_hist_com$gear) #every year

#Allocate UNK from known regions first
#Because UNK regions dont have TWL or OTH amounts, the below gives amounts only for known regions
ca_hist_com_ag <- ca_hist_com %>% group_by(year, region, gear) %>% summarize(sum = sum(mt)) %>% 
  pivot_wider(names_from = gear, values_from = sum)
ca_hist_com_ag$UNK_twl <- ca_hist_com_ag$UNK * (ca_hist_com_ag$TWL / rowSums(ca_hist_com_ag[,c("TWL","OTH")], na.rm=T))
ca_hist_com_ag$UNK_oth <- ca_hist_com_ag$UNK * (ca_hist_com_ag$OTH / rowSums(ca_hist_com_ag[,c("TWL","OTH")], na.rm=T))

#Allocate UNK from unknown regions next
#Determine proportion of catch made up by OTH and TWO across all KNOWN regions within a year 
ca_hist_com_ag2 <- ca_hist_com %>% dplyr::filter(gear %in% c("OTH","TWL")) %>% group_by(year, gear) %>% summarize(sum = sum(mt)) %>% 
  pivot_wider(names_from = gear, values_from = sum)
ca_hist_com_ag2$perc_twl_KNOWNreg <- (ca_hist_com_ag2$TWL / rowSums(ca_hist_com_ag2[,c("TWL","OTH")], na.rm=T))
ca_hist_com_ag2$perc_oth_KNOWNreg <- (ca_hist_com_ag2$OTH / rowSums(ca_hist_com_ag2[,c("TWL","OTH")], na.rm=T))
#Use proportions across all known regions to allocation unknown catches in unknown regions
ca_hist_com_ag[ca_hist_com_ag$region == 0,]$UNK_twl <- ca_hist_com_ag[ca_hist_com_ag$region == 0,]$UNK * ca_hist_com_ag2$perc_twl_KNOWNreg
ca_hist_com_ag[ca_hist_com_ag$region == 0,]$UNK_oth <- ca_hist_com_ag[ca_hist_com_ag$region == 0,]$UNK * ca_hist_com_ag2$perc_oth_KNOWNreg

#Sum up total TWL and OTH gear across regions
ca_hist_com_ag$TOT_TWL = ca_hist_com_ag$TWL + ca_hist_com_ag$UNK_twl
ca_hist_com_ag$TOT_OTH = ca_hist_com_ag$OTH + ca_hist_com_ag$UNK_oth
ca_hist_com_out <- ca_hist_com_ag %>% group_by(year) %>% 
  summarize(TWL = sum(TOT_TWL, na.rm = T), NTWL = sum(TOT_OTH, na.rm=T)) %>% data.frame()


####Additional landings in CA caught in OR/WA waters

ca_hist_inORWA <- readxl::read_excel(path = file.path(git_dir,"data-raw","CAlandingsCaughtORWA.xlsx"), 
                                     skip = 10, sheet = "Rockfish.estimator")
ca_hist_inORWA_canary <- ca_hist_inORWA[,c("Row Labels...1","Canary")]

#Add these to historical Ralston values

ca_hist_com_out[ca_hist_com_out$year %in% ca_hist_inORWA_canary$`Row Labels...1`,]$TWL <- ca_hist_inORWA_canary$Canary + 
  ca_hist_com_out[ca_hist_com_out$year %in% ca_hist_inORWA_canary$`Row Labels...1`,]$TWL


####Landings from 1969-1980 - sent by EJ Dick

ca_com_70s <- utils::read.csv(file = file.path(git_dir,"data-raw","Canary_CA_Comm_1969-1980.csv"), header = TRUE)
ca_com_70s$mt <- ca_com_70s$POUNDS*0.000453592
table(ca_com_70s$GEAR_GRP)

ca_com_70s_out <- ca_com_70s %>% group_by(YEAR, GEAR_GRP) %>% 
  summarize(sum = sum(mt)) %>% pivot_wider(names_from = GEAR_GRP, values_from = sum) %>%
  data.frame()
names(ca_com_70s_out)[1] <- "year"

#Sum together the HKL and NET gear catches
ca_com_70s_out$NTWL <- ca_com_70s_out$HKL + ca_com_70s_out$NET


####Combine California historical periods
ca_hist_out  <- rbind(ca_hist_com_out, ca_com_70s_out[,c("year","TWL","NTWL")])

#write.csv(ca_hist_out, file = file.path(git_dir, "data", "canary_CA_hist_catch.csv"), row.names = FALSE)


#################################################################################################################
#---------------------------------------------------------------------------------------------------------------#
# Load recreational data
#---------------------------------------------------------------------------------------------------------------#
#################################################################################################################

##
#California historical recreational landings - file copied from 2015 assessment catch history file
##

ca_hist_rec <- utils::read.csv(file = file.path(git_dir, "data", "CA_canary_rec_1928_1979_PulledFrom2015Assessment.csv"), header = TRUE)

##
#Recreational data
#This is output from canary_catches.rec.R
##

rec <- utils::read.csv(file = file.path(git_dir, "data", "canary_rec_catch.csv"), header = TRUE)
#Extend rec to incorporate CA historical time period
rec <- rbind(data.frame("Year" = c(1928:1966), "wa_N" = 0, "or_MT" = 0, "ca_MT" = 0), rec)


#################################################################################################################
#---------------------------------------------------------------------------------------------------------------#
# Combine commercial landings and discard estimates to obtain total removals
#---------------------------------------------------------------------------------------------------------------#
#################################################################################################################

removals <- data.frame("Year" = 1892:2022, "NTWL.C" = 0, "NTWL.O" = 0, "NTWL.W" = 0, "TWL.C" = 0, "TWL.O" = 0, "TWL.W" = 0)

##
#Add discards to pacfin data >=2000
##

#Add 2002-2021 GEMM estimates
removals[which(removals$Year %in% pacfin$LANDING_YEAR),] <- data.frame(pacfin)
removals[is.na(removals)] <- 0
removals[which(removals$Year %in% gemm_discard$Year),-1] <- removals[which(removals$Year %in% gemm_discard$Year),-1] +
  round(gemm_discard[,c("ca_ntwl","or_ntwl","wa_ntwl","ca_twl","or_twl","wa_twl")],3)

#Calculate 2022 and 2000-2001 discard estimates using similar (but not same) approach as in last assessment
#Sum across landings and discards for EACH FLEET in 2019-2021, take ratio, multiply that ratio by PacFIN landings for that fleet in 2022
#This differs slightly from last assessment which took sums across ALL fleets within a year
dis_rat_late <- colSums(gemm_discard[which(gemm_discard$Year %in% c(2019:2021)),c("ca_ntwl","or_ntwl","wa_ntwl","ca_twl","or_twl","wa_twl")]) /
  colSums(removals[which(removals$Year %in% c(2019:2021)),-1])
#matplot((dis_rat),x=2019:2021,type="b",xlab="Years",ylab="Proportion", main = "Discard rates over time by fleet (lines)") #plot rates across years if remove colSums in line above

#Do the same for 2000 and 2001
#QUESTION: I wonder whether for 2000 its better to use the 1999 ratio (20%) since the stock was declared overfished in 2001
dis_rat_early <- colSums(gemm_discard[which(gemm_discard$Year %in% c(2002:2004)),c("ca_ntwl","or_ntwl","wa_ntwl","ca_twl","or_twl","wa_twl")]) /
  colSums(removals[which(removals$Year %in% c(2002:2004)),-1])
#matplot((dis_rat),x=2002:2004,type="b",xlab="Years",ylab="Proportion", main = "Discard rates over time by fleet (lines)") #plot rates across years if remove colSums in line above

#Add 2000, 2001, and 2022 discards based on calculated discard ratios
removals[removals$Year %in% c(2000,2001),-1] <- round(rbind((1+dis_rat_early),(1+dis_rat_early)) * removals[removals$Year %in% c(2000,2001),-1], 3)
removals[removals$Year %in% c(2022),-1] <- round((1+dis_rat_late) * removals[removals$Year %in% c(2022),-1], 3)


##
#Add Oregon commercial reconstruction years <2000
#Although last assessment used <1987 only, Ali has updated the proportions of nomial canary
#with a different reconstruction that runs from 1987-1999, so we use that one for this cycle
##

removals[removals$Year %in% c(1892:1999),"NTWL.O"] <- or_com[or_com$YEAR %in% c(1892:1999),"NTRW"]
removals[removals$Year %in% c(1892:1999),"TWL.O"] <- or_com[or_com$YEAR %in% c(1892:1999),"TRW"]

##
#Add California commercial reconstruction years <1981
##

removals[removals$Year %in% ca_hist_out$year,"NTWL.C"] <- ca_hist_out$NTWL
removals[removals$Year %in% ca_hist_out$year,"TWL.C"] <- ca_hist_out$TWL


##
#Add Washington commercial reconstruction years <2000 - TO DO
##


##
#Add <2000 discards based on Pikitch historical rates 
##

#1995-1999 = 20%
#1981-1994 = 5%
#<1981 = 1%
removals[removals$Year %in% c(1892:1980),-1] = (1+0.01) * removals[removals$Year %in% c(1892:1980),-1]
removals[removals$Year %in% c(1981:1994),-1] = (1+0.05) * removals[removals$Year %in% c(1981:1994),-1]
removals[removals$Year %in% c(1995:1999),-1] = (1+0.2) * removals[removals$Year %in% c(1995:1999),-1]


#################################################################################################################
#---------------------------------------------------------------------------------------------------------------#
# Add in recreational total removals and fill in missing years
#---------------------------------------------------------------------------------------------------------------#
#################################################################################################################

#CA MRFSS 1990-1992 already filled in in "canary_catches_rec.R"
#and was an average of previous 3 years of data for 1990, previous 3 and later 3 for 1991, and later 3 for 1992

#Ramp down OR rec to 0 in 1972
or_ramp <- rec[rec$Year == 1979,]$or_MT/(1979-1972) * length(1973:1978):1
rec[rec$Year %in% c(1973:1978),]$or_MT <- rec[rec$Year==1979,]$or_MT - or_ramp

#Linear ramps for WA in 1987-1989 and 1968-1974
wa_ramp_early <- (rec[rec$Year == 1975,]$wa_N - rec[rec$Year == 1967,]$wa_N)/(1975-1967) * length(1968:1974):1
rec[rec$Year %in% c(1968:1974),]$wa_N <- rec[rec$Year==1975,]$wa_N - wa_ramp_early

wa_ramp_late <- (rec[rec$Year == 1990,]$wa_N - rec[rec$Year == 1986,]$wa_N)/(1990-1986) * length(1987:1989):1
rec[rec$Year %in% c(1987:1989),]$wa_N <- rec[rec$Year==1990,]$wa_N - wa_ramp_late

#Add CA historical estimates
rec[rec$Year %in% ca_hist_rec$Year, c("ca_MT")] <- ca_hist_rec$ca_MT

#Replace 1980 MRFSS estimate with average of 1979 CA historical estimate and 1981 MRFSS estimate
rec[rec$Year == 1980, c("ca_MT")] <- mean(rec[rec$Year %in% c(1979,1981), c("ca_MT")])

#Add 2004 estimate for CA rec
#Last assessment appears to have only used landings, not landings + otherwise dead
#Thus use value provided by John Budrick (via email on 3/16) based on download for another species when 2004 data were present
rec[rec$Year == 2004,]$ca_MT <- 10.59

#Add 2020 CA updated values to account for undersampling to the CA recfin estimate. 
#Updated values pulled on March 21, 2023 from 
#https://github.com/pfmc-assessments/california-data/blob/main/recreational-fishery/proxy%202020%20data/genus_allocate.csv
#See discussion #8 for guidance (https://github.com/pfmc-assessments/california-data/discussions/8)
update2020 <- utils::read.csv(file = file.path(git_dir, "data-raw", "CA_rec_genus_allocate_2020.csv"), header = TRUE)
alloc_val <- update2020 %>% filter(orig_allocated == "allocated") %>% 
  group_by(year) %>% summarize(sum = sum(canary_kg) * 0.001) #0.001 to get into MT
rec[rec$Year %in% c(2020, 2021),]$ca_MT <- alloc_val$sum + rec[rec$Year %in% c(2020, 2021),]$ca_MT

#Add in rec fleets
removals$rec.C <- 0
removals$rec.O <- 0
removals$rec.W <- 0
removals[removals$Year %in% rec$Year, c("rec.W","rec.O","rec.C")] <- rec[,-1]


#################################################################################################################
#---------------------------------------------------------------------------------------------------------------#
# Load foreign fleet landings (from Table 7 in Rogers 2003 report)
#---------------------------------------------------------------------------------------------------------------#
#################################################################################################################

#Same as the 2015 stock assessment values
for_fleet <- data.frame("Year" = c(1966:1976),
                        "FOR.C" = c(41,103,415,5,0,0,13,372,150,63,49),
                        "FOR.O" = c(1445,658,286,50,73,118,318,525,81,141,114),
                        "FOR.W" = c(113,90,109,12,28,70,68,68,288,0,0))
#Add to rest of removals
removals$FOR.C <- 0
removals$FOR.O <- 0
removals$FOR.W <- 0
removals[removals$Year %in% for_fleet$Year, c("FOR.C","FOR.O","FOR.W")] <- for_fleet[,-1]


#################################################################################################################
#---------------------------------------------------------------------------------------------------------------#
# Output final total removals file
#---------------------------------------------------------------------------------------------------------------#
#################################################################################################################

#Upload to data folder
# write.csv(round(removals,2), file = file.path(git_dir, "data", "canary_total_removals.csv"), row.names = FALSE)

