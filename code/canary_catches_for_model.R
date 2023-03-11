##############################################################################################################
#
# 	Purpose: Output Canary Rockfish Landings and Discards
#            into form for use in SS
#
#   Created: Mar 10, 2023
#			  by Brian Langseth 
#
#   Uses output from the following scripts, combines them, and then fills in gaps
#     scripts canary_catches_com.R
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
##
pacfin <- googlesheets4::read_sheet('https://docs.google.com/spreadsheets/d/17x0PT_vqTv1kvHAwaqgz7jmKvCvRwm7OcFb4jrh_AWo/edit#gid=2086044691',
                                    sheet = "catch_mt")
pacfin_Nvessel <- googlesheets4::read_sheet('https://docs.google.com/spreadsheets/d/17x0PT_vqTv1kvHAwaqgz7jmKvCvRwm7OcFb4jrh_AWo/edit#gid=2086044691',
                                    sheet = c("unique_vessels"))
pacfin_Ndealer <- googlesheets4::read_sheet('https://docs.google.com/spreadsheets/d/17x0PT_vqTv1kvHAwaqgz7jmKvCvRwm7OcFb4jrh_AWo/edit#gid=2086044691',
                                            sheet = c("unique_dealers"))

##
#Discard estimates from PacFIN years based on GEMM report allocated based on WCGOP state proportions
##
gemm_discard <- utils::read.csv(file = file.path(git_dir, "data", "canary_commercial_discard_mt.csv"), header = TRUE)

#Calculate 2022 and 2000-2001 discard estimates using similar (but not same) approach as in last assessment
#Sum across landings and discards for EACH FLEET in 2019-2021, take ratio, multiply that ratio by PacFIN landings for that fleet in 2022
#This differs slightly from last assessment which took sums across ALL fleets within a year
dis_rat_late <- colSums(gemm_discard[which(gemm_discard$Year %in% c(2019:2021)),c("ca_ntwl","or_ntwl","wa_ntwl","ca_twl","or_twl","wa_twl")]) /
  colSums(removals[which(removals$LANDING_YEAR %in% c(2019:2021)),-1])
#matplot((dis_rat),x=2019:2021,type="b",xlab="Years",ylab="Proportion", main = "Discard rates over time by fleet (lines)") #plot rates across years if remove colSums in line above

#Do the same for 2000 and 2001
#QUESTION: I wonder whether for 2000 its better to use the 1999 ratio (20%) since the stock was declared overfished in 2001
dis_rat_early <- colSums(gemm_discard[which(gemm_discard$Year %in% c(2002:2004)),c("ca_ntwl","or_ntwl","wa_ntwl","ca_twl","or_twl","wa_twl")]) /
  colSums(removals[which(removals$LANDING_YEAR %in% c(2002:2004)),-1])
#matplot((dis_rat),x=2002:2004,type="b",xlab="Years",ylab="Proportion", main = "Discard rates over time by fleet (lines)") #plot rates across years if remove colSums in line above


##
#Oregon commercial reconstruction - landings in MT
##
#Only need to pull from googledrive once
# googledrive::drive_download(file = "Oregon data/Oregon Commercial landings_451_2022.csv",
#                             path = file.path(git_dir,"data-raw","Oregon Commercial landings_451_2022.csv"))
or_com <- utils::read.csv(file = file.path(git_dir,"data-raw","Oregon Commercial landings_451_2022.csv"), header = TRUE)




#################################################################################################################
#---------------------------------------------------------------------------------------------------------------#
# Combine commercial landings and discard estimates to obtain total removals
#---------------------------------------------------------------------------------------------------------------#
#################################################################################################################

removals <- data.frame("Year" = 1892:2022, "NTWL.C" = 0, "NTWL.O" = 0, "NTWL.W" = 0, "TWL.C" = 0, "TWL.O" = 0, "TWL.W" = 0)

##
#Add discards to pacfin data
##

#Add 2002-2021 GEMM estimates
removals[which(removals$Year %in% pacfin$LANDING_YEAR),] <- data.frame(pacfin)
removals[is.na(removals)] <- 0
removals[which(removals$Year %in% gemm_discard$Year),-1] <- removals[which(removals$Year %in% gemm_discard$Year),-1] +
  round(gemm_discard[,c("ca_ntwl","or_ntwl","wa_ntwl","ca_twl","or_twl","wa_twl")],3)

#Add 2000, 2001, and 2022 discards based on calculated discard ratios
removals[removals$Year %in% c(2000,2001),-1] <- round(rbind((1+dis_rat_early),(1+dis_rat_early)) * removals[removals$Year %in% c(2000,2001),-1], 3)
removals[removals$Year %in% c(2022),-1] <- round((1+dis_rat_late) * removals[removals$Year %in% c(2022),-1], 3)

#Add <2000 discards based on Pikitch historical rates 
#1995-199 = 20%
#1981-1994 = 5%
removals[removals$Year %in% c(1981:1994),-1] = (1+0.2) * removals[removals$Year %in% c(1981:1994),-1]
removals[removals$Year %in% c(1995:1999),-1] = (1+0.05) * removals[removals$Year %in% c(1995:1999),-1]


##
#Add Oregon commercial reconstruction years
##








