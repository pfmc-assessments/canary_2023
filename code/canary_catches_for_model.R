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
#     canary_ashop_processing.R
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
pacfin <- googlesheets4::read_sheet(googledrive::drive_get("pacfin_catch"),
                                    sheet = "catch_mt")
pacfin_Nvessel <- googlesheets4::read_sheet(googledrive::drive_get("pacfin_catch"),
                                    sheet = c("unique_vessels"))
pacfin_Ndealer <- googlesheets4::read_sheet(googledrive::drive_get("pacfin_catch"),
                                            sheet = c("unique_dealers"))

##
#Discard estimates from PacFIN years based on GEMM report allocated based on WCGOP state proportions
#This is output from canary_discard_exploration.R
##
gemm_discard <- googlesheets4::read_sheet(googledrive::drive_get("CONFIDENTIAL_canary_commercial_discard_mt"),
                                          sheet = "discard_mt")


##
#Oregon commercial reconstruction - landings in MT
##
#Only need to pull from googledrive once
# googledrive::drive_download(file = "Oregon data/Oregon Commercial landings_451_2022_FINAL.csv",
#                             path = file.path(git_dir,"data-raw","Oregon Commercial landings_451_2022_FINAL.csv"))
or_com <- utils::read.csv(file = file.path(git_dir,"data-raw","Oregon Commercial landings_451_2022_FINAL.csv"), header = TRUE)


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
ca_hist_com_ag$TOT_TWL = rowSums(ca_hist_com_ag[,c('TWL','UNK_twl')],na.rm=T)
ca_hist_com_ag$TOT_OTH = rowSums(ca_hist_com_ag[,c('OTH', 'UNK_oth')],na.rm=T)
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


##
#Washington historical commercial landings - file copied from 2015 assessment catch history file
##

wa_hist_com <- utils::read.csv(file = file.path(git_dir, "data-raw", "WA_canary_com_1932_1980_PulledFrom2015Assessment.csv"), header = TRUE)


#################################################################################################################
#---------------------------------------------------------------------------------------------------------------#
# Load recreational data
#---------------------------------------------------------------------------------------------------------------#
#################################################################################################################

##
#California historical recreational landings - file copied from 2015 assessment catch history file
##

ca_hist_rec <- utils::read.csv(file = file.path(git_dir, "data-raw", "CA_canary_rec_1928_1979_PulledFrom2015Assessment.csv"), header = TRUE)

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
#matplot((dis_rat_late),x=2019:2021,type="b",xlab="Years",ylab="Proportion", main = "Discard rates over time by fleet (lines)") #plot rates across years if remove colSums in line above

#Do the same for 2000 and 2001
#QUESTION: I wonder whether for 2000 its better to use the 1999 ratio (20%) since the stock was declared overfished in 2001
dis_rat_early <- colSums(gemm_discard[which(gemm_discard$Year %in% c(2002:2004)),c("ca_ntwl","or_ntwl","wa_ntwl","ca_twl","or_twl","wa_twl")]) /
  colSums(removals[which(removals$Year %in% c(2002:2004)),-1])
#matplot((dis_rat_early),x=2002:2004,type="b",xlab="Years",ylab="Proportion", main = "Discard rates over time by fleet (lines)") #plot rates across years if remove colSums in line above

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
#Add Washington commercial reconstruction years <1981
##

removals[removals$Year %in% wa_hist_com$Year,"TWL.W"] <- wa_hist_com$TWL.W.mt


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
#CA proxy values already applied in "canary_catches_rec.R"

#Ramp down OR rec to 0 in 1972
or_ramp <- rec[rec$Year == 1979,]$or_MT/(1979-1972) * length(1973:1978):1
rec[rec$Year %in% c(1973:1978),]$or_MT <- rec[rec$Year==1979,]$or_MT - or_ramp

#Linear ramps for WA in 1968-1974. Values for 1987-1989 filled in by RecFIN form CTE503
wa_ramp_early <- (rec[rec$Year == 1975,]$wa_N - rec[rec$Year == 1967,]$wa_N)/(1975-1967) * length(1968:1974):1
rec[rec$Year %in% c(1968:1974),]$wa_N <- rec[rec$Year==1975,]$wa_N - wa_ramp_early

#wa_ramp_late <- (rec[rec$Year == 1990,]$wa_N - rec[rec$Year == 1986,]$wa_N)/(1990-1986) * length(1987:1989):1
#rec[rec$Year %in% c(1987:1989),]$wa_N <- rec[rec$Year==1990,]$wa_N - wa_ramp_late

#Add CA historical estimates
rec[rec$Year %in% ca_hist_rec$Year, c("ca_MT")] <- ca_hist_rec$ca_MT

#Replace 1980 MRFSS estimate with average of 1979 CA historical estimate and 1981 MRFSS estimate
rec[rec$Year == 1980, c("ca_MT")] <- mean(rec[rec$Year %in% c(1979,1981), c("ca_MT")])

#Add 2004 estimate for CA rec
#Last assessment appears to have only used landings, not landings + otherwise dead
#Thus use value provided by John Budrick (via email on 3/16) based on download for another species when 2004 data were present
rec[rec$Year == 2004,]$ca_MT <- 10.59

#Add in rec fleets
removals$rec.C <- 0
removals$rec.O <- 0
removals$rec.W.N <- 0
removals[removals$Year %in% rec$Year, c("rec.W.N","rec.O","rec.C")] <- rec[,-1]


#################################################################################################################
#---------------------------------------------------------------------------------------------------------------#
# Convert WA recreational removals in numbers of fish to MT - see github issue #52
#---------------------------------------------------------------------------------------------------------------#
#################################################################################################################

#Read in sport bio data - samples sizes differ slightly with recfin, and are low in most years
wa_bds <- readxl::read_excel(path = file.path(git_dir,"data-raw","WA_CanaryBiodata2023_Apr27version.xlsx"), sheet = "Sport")
wa_bds_len <- wa_bds %>% group_by(sample_year) %>% summarize(avgL = mean(fish_length_cm, na.rm=T), N = length(fish_length_cm)) %>% data.frame()
table(wa_bds$sample_year,is.na(wa_bds$fish_length_cm))
wa_bds_len <- right_join(x = wa_bds_len, y = data.frame("sample_year" = c(1967:2022))) %>% arrange(sample_year)

####Options for how to calculate average weight

##1. No assumptions, let the data stand as they are. For any years without length data use an average
par(mar = c(5, 4, 4, 4) + 0.3)
h=barplot(height = wa_bds_len$N, names.arg = wa_bds_len$sample_year, xlab = "Year", ylab = "Number of samples (bars)")
box()
par(new = TRUE)
plot(y = wa_bds_len$avgL, x = h, axes = FALSE, bty = "n", xlab = "", ylab = "", type = "b")
abline(h=mean(wa_bds_len$avgL, na.rm = T), lty = 2)
axis(side=4)
mtext("Mean length in cm (points)", side=4, line=3)
legend(x=20, y=45, c("Unweighted mean length \n across all years"), col=c(1), lty=c(2), pch=c(NA), bty = "n")

#Enter in this approach's estimate for WA rec in MT if choosing (We are choosing option 2 though)
wa_rec_avgW <- wa_bds_len
wa_rec_avgW[is.na(wa_rec_avgW$avgL),"avgL"] <- mean(wa_rec_avgW$avgL, na.rm=T)
wa_rec_avgW$avgW1 <- (1.04058E-08 * (wa_rec_avgW$avgL*10)^3.084136662)*0.001
# removals$rec.W.mt.1 <- 0 
# removals[removals$Year %in% c(1967:2022),]$rec.W.mt.1 <- wa_rec_avgW$avgW*removals[removals$Year %in% c(1967:2022),"rec.W"]


##2. Do borrowing for low sample years (<25 per Dick et al 2021 definition of small sampmle size) using weighted mean. 
#Assume blocking based on rec regulations (2017-2022, 2004-2016, 2000-2003, <1999)
#Exception to weighted mean for the single datum in 1987. Its far enough away from other points so use overall mean for the block with no weighting
wa_bds_len$avgL2 = wa_bds_len$avgL
for(i in 2006:2014){
  wa_bds_len[wa_bds_len$sample_year == i,]$avgL2 = weighted.mean(wa_bds_len[wa_bds_len$sample_year %in% c(i-1, i, i+1),]$avgL, wa_bds_len[wa_bds_len$sample_year %in% c(i-1, i, i+1),]$N)
}
# wa_bds_len[wa_bds_len$sample_year == 1998,]$avgL2 = weighted.mean(wa_bds_len[wa_bds_len$sample_year %in% c(1996,1997,1998),]$avgL, wa_bds_len[wa_bds_len$sample_year %in% c(1996,1997,1998),]$N)
# for(i in 1996:1997){
#   wa_bds_len[wa_bds_len$sample_year == i,]$avgL2 = weighted.mean(wa_bds_len[wa_bds_len$sample_year %in% c(i-1, i, i+1),]$avgL, wa_bds_len[wa_bds_len$sample_year %in% c(i-1, i, i+1),]$N)
# }
wa_bds_len[wa_bds_len$sample_year %in% c(1996:1997),]$avgL2 = weighted.mean(wa_bds_len[wa_bds_len$sample_year %in% c(1995,1996,1997),]$avgL, wa_bds_len[wa_bds_len$sample_year %in% c(1995,1996,1997),]$N)
wa_bds_len[wa_bds_len$sample_year %in% c(1987),]$avgL2 = mean(wa_bds_len[wa_bds_len$sample_year <= 1999,]$avgL, na.rm = T)
wa_bds_len[wa_bds_len$sample_year %in% c(1982:1983),]$avgL2 = weighted.mean(wa_bds_len[wa_bds_len$sample_year %in% c(1981:1983),]$avgL, wa_bds_len[wa_bds_len$sample_year %in% c(1981:1983),]$N)
wa_bds_len[wa_bds_len$sample_year %in% c(1980),]$avgL2 = weighted.mean(wa_bds_len[wa_bds_len$sample_year %in% c(1979:1981),]$avgL, wa_bds_len[wa_bds_len$sample_year %in% c(1979:1981),]$N)

par(mar = c(5, 4, 4, 4) + 0.3)
h=barplot(height = wa_bds_len$N, names.arg = wa_bds_len$sample_year, xlab = "Year", ylab = "Number of samples (bars)")
box()
par(new = TRUE)
plot(y = wa_bds_len$avgL, x = h, axes = FALSE, bty = "n", xlab = "", ylab = "", type = "b") #original
points(y = wa_bds_len$avgL2, x = h, pch=19, col = as.numeric(wa_bds_len$N<25)+1) #adjusted based on borrowing
segments(x0 = 0, x1 = 39, lty = 2, #have to convert year to location along the barplot
         y0 = mean(wa_bds_len[wa_bds_len$sample_year <= 1999,]$avgL, na.rm = T))
segments(x0 = 39, x1 = 44, lty = 2, #have to convert year to location along the barplot
         y0 = mean(wa_bds_len[wa_bds_len$sample_year %in% c(2000:2003),]$avgL, na.rm = T))
axis(side=4)
mtext("Mean length in cm (points)", side=4, line=3)
legend(x=25, y=47.5, c("Sample size <25 - Original L", "Sample size <25 - Adjusted L", "Sample size >=25 - Keep", "Non-weighted mean length by block"), 
       col=c(1,2,1,1), lty=c(NA,NA,NA,3), pch=c(1,19,19,NA), bty = "n", cex = 0.8)

#Add average lengths in for years with missing length data and enter in this approach's estimate for WA rec in MT
wa_rec_avgW$avgL2 <- wa_bds_len$avgL2
wa_rec_avgW[which(is.na(wa_rec_avgW[wa_rec_avgW$sample_year <= 1999,]$avgL2)),]$avgL2 <- mean(wa_bds_len[wa_bds_len$sample_year <= 1999,]$avgL, na.rm = T)
wa_rec_avgW[which(is.na(wa_rec_avgW[wa_rec_avgW$sample_year <= 2003,]$avgL2)),]$avgL2 <- mean(wa_bds_len[wa_bds_len$sample_year %in% c(2000:2003),]$avgL, na.rm = T) #first block is already filled in so just for 2000 and 2001
wa_rec_avgW$avgW2 <- (1.04058E-08 * (wa_rec_avgW$avgL2*10)^3.084136662)*0.001
removals$rec.W.mt.2 <- 0 
removals[removals$Year %in% c(1967:2022),]$rec.W.mt.2 <- wa_rec_avgW$avgW2*removals[removals$Year %in% c(1967:2022),"rec.W.N"]


# ##3. Use the average weight that comes from recfin (2004-2022)
# recMT <- googlesheets4::read_sheet(googledrive::drive_get("recfin_catch"),
#                                    sheet = "catch_mt")
# recN <- googlesheets4::read_sheet(googledrive::drive_get("recfin_catch"),
#                                    sheet = "catch_N")
# tmp <- data.frame("Year" = recMT$RECFIN_YEAR, "avgW" = rowSums(recMT[,c("W_OTH_sum_total","W_PC_sum_total","W_PR_sum_total")], na.rm = T) / 
#   rowSums(recN[,c("W_OTH_sum_totalN","W_PC_sum_totalN","W_PR_sum_totalN")], na.rm = T))
# wa_rec_avgW$avgW3 <- 0
# wa_rec_avgW[wa_rec_avgW$sample_year %in% tmp$Year,]$avgW3 <- tmp$avgW
# #Need MRFSS values to complete this method


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
# Load ASHOP removals (from canary_ashop_processing.R)
#---------------------------------------------------------------------------------------------------------------#
#################################################################################################################

ashop <- utils::read.csv(file = file.path(git_dir,"data","canary_ashop_catch.csv"), header = TRUE)

#Add to rest of removals
removals$ASHOP.C <- 0
removals$ASHOP.O <- 0
removals$ASHOP.W <- 0
removals[removals$Year %in% ashop$year, c("ASHOP.C","ASHOP.O","ASHOP.W")] <- ashop[,-1]


#################################################################################################################
#---------------------------------------------------------------------------------------------------------------#
# Output final total removals file
#---------------------------------------------------------------------------------------------------------------#
#################################################################################################################

#Upload to data folder
# write.csv(round(removals,2), file = file.path(git_dir, "data", "canary_total_removals.csv"), row.names = FALSE)

