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


#################################################################################################################
#---------------------------------------------------------------------------------------------------------------#
# Load recreational data
#---------------------------------------------------------------------------------------------------------------#
#################################################################################################################

##
#Recreational data
#This is output from canary_catches.rec.R
##

rec <- utils::read.csv(file = file.path(git_dir, "data", "canary_rec_catch.csv"), header = TRUE)



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
##

removals[removals$Year %in% c(1892:1999),"NTWL.O"] <- or_com[or_com$YEAR %in% c(1892:1999),"NTRW"]
removals[removals$Year %in% c(1892:1999),"TWL.O"] <- or_com[or_com$YEAR %in% c(1892:1999),"TRW"]

##
#Add California commercial reconstruction years <2000 - TO DO
##



##
#Add Washington commercial reconstruction years <2000 - TO DO
##


##
#Add <2000 discards based on Pikitch historical rates 
##

#1995-199 = 20%
#1981-1994 = 5%
#<1981 = 1%
removals[removals$Year %in% c(1892:1980),-1] = (1+0.01) * removals[removals$Year %in% c(1892:1980),-1]
removals[removals$Year %in% c(1981:1994),-1] = (1+0.2) * removals[removals$Year %in% c(1981:1994),-1]
removals[removals$Year %in% c(1995:1999),-1] = (1+0.05) * removals[removals$Year %in% c(1995:1999),-1]


#################################################################################################################
#---------------------------------------------------------------------------------------------------------------#
# Add in recreational total removals and fill in missing years
#---------------------------------------------------------------------------------------------------------------#
#################################################################################################################

#CA MRFSS 1990-1992 already filled in in "canary_catches_rec.R"
#and was a linear ramp between 1989 and 1993

#Ramp down OR rec to 0 in 1972
or_ramp <- rec[rec$Year == 1979,]$or_MT/(1979-1972) * length(1973:1978):1
rec[rec$Year %in% c(1973:1978),]$or_MT <- rec[rec$Year==1979,]$or_MT - or_ramp

#Linear ramps for WA in 1987-1989 and 1968-1974
wa_ramp_early <- (rec[rec$Year == 1975,]$wa_N - rec[rec$Year == 1967,]$wa_N)/(1975-1967) * length(1968:1974):1
rec[rec$Year %in% c(1968:1974),]$wa_N <- rec[rec$Year==1975,]$wa_N - wa_ramp_early

wa_ramp_late <- (rec[rec$Year == 1990,]$wa_N - rec[rec$Year == 1986,]$wa_N)/(1990-1986) * length(1987:1989):1
rec[rec$Year %in% c(1987:1989),]$wa_N <- rec[rec$Year==1990,]$wa_N - wa_ramp_late

#Add in rec fleets
removals$rec.C <- 0
removals$rec.O <- 0
removals$rec.W <- 0
removals[removals$Year %in% rec$Year, c("rec.W","rec.O","rec.C")] <- rec[,-1]


#################################################################################################################
#---------------------------------------------------------------------------------------------------------------#
# Output final total removals file
#---------------------------------------------------------------------------------------------------------------#
#################################################################################################################

##
#Upload to googledrive
##
# xx <- googledrive::drive_create(name = 'total_removals',
#                                 path = 'https://drive.google.com/drive/folders/1Lx4JN-nmJkWtcqmelODZYoVrHyVLzegP',
#                                 type = 'spreadsheet', overwrite = FALSE)
# googlesheets4::sheet_write(round(removals,2), ss = xx, sheet = "Sheet1")

#Upload to network drive
# write.csv(round(removals,2), file = file.path(git_dir, "data", "canary_total_removals.csv"), row.names = FALSE)

