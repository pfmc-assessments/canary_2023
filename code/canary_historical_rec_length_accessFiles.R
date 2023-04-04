#########
#For Canary 2023 assessment
#
#Script to read in all of the needed Access files for the historical CA lengths
#HAVE TO USE R-32BIT VERSION
#These files are confidential, so access is restricted.
#Link to "CA CPFV historical data" is in drive folder, for those with access. 
#
#Output of this script a single csv file with identifying information removed. 
#File is into data-raw and the google drive
#
#Author: Brian Langseth (brian.langseth@noaa.gov)
#########

library(RODBC)

if(Sys.getenv("USERNAME") == "Brian.Langseth") {
  dir <- "C:/Users/Brian.Langseth/Desktop/lingcod_2021/Lingcod_2021"
  git_dir <- "U:/Stock assessments/canary_2023/"
}

#################
#DebWV files
#Onboard Party Boat > CPFV-Onboard Data-Central California_DebWV
#################
deb <- file.path(dir,"data-raw","CPFV-Onboard Data.mdb")
conDeb <- RODBC::odbcConnectAccess(deb)
RODBC::sqlTables(conDeb)
deb.trip <- RODBC::sqlFetch(conDeb, "AllTrp")
deb.len <- RODBC::sqlFetch(conDeb, "Length")
deb.loc <- RODBC::sqlFetch(conDeb, "CPFV_Party_LOCAS")
RODBC::odbcCloseAll()

#Keep only canary
deb.len.can <- deb.len[deb.len$SP == 2335,]

deb.data <- merge(deb.len.can,deb.trip,by = "TRIPNOSAMP")
table(deb.data$FATE) #all kept
deb.data$disp = "RETAINED"
deb.data$source = "debWV"
deb.data$lengthcm = (4.108 + 0.934*deb.data$TL)/10 #get to FL. From echeverria and lenarz 1984
plot(deb.data$lengthcm-deb.data$TL/10)
deb.data$sex = "U"
deb.data$trip= paste0(deb.data$YEAR, deb.data$AllTRPID)

deb.out = deb.data[,c("YEAR", "lengthcm", "sex", "disp", "source", "trip")]


#################
#Crooke and Ally
#Onboard Party Boat > CPFV-Southern California_Crooke+Ally (for 1970s data)
#Onboard Party Boat > CPFV-Southern California_Crooke+Ally > 
#HK_Archive 1985-1989 Southern California > 86-88 Data  (for 1980s data)
#################

#Data from 1970s
ca <- file.path(dir,"data-raw","CPFV.mdb")
conca <- RODBC::odbcConnectAccess(ca)
RODBC::sqlTables(conca)
ca.trip <- RODBC::sqlFetch(conca, "Tbl_70strip")
ca.len <- RODBC::sqlFetch(conca, "Tbl_70scatch")
RODBC::odbcCloseAll()

#Keep canary. Locations are all in southern california
ca.len.can <- ca.len[ca.len$SpCode == 2335,]

ca.data <- merge(ca.len.can,ca.trip, by = "TripID")
ca.data$disp = "RETAINED" #Dont actually know but assume so, thus add this
ca.data$YEAR = format(ca.data$date, format="%Y")
ca.data$source = "Crooke-CPFV"
ca.data$lengthcm <- ca.data$Length/10
ca.data$sex = "U"
ca.data$trip <- paste0(ca.data$YEAR, ca.data$TripID)

ca.70.out <- ca.data[,c("YEAR", "lengthcm", "sex", "disp", "source", "trip")]


#Data from 1980s
ca <- file.path(dir,"data-raw","86-88 Data.mdb")
conca <- RODBC::odbcConnectAccess(ca)
RODBC::sqlTables(conca)
ca.len <- RODBC::sqlFetch(conca, "Length_Tbl")
RODBC::odbcCloseAll()

ca.data.can <- ca.len[ca.len$L_SPECODE == 2335,]

ca.data.can$disp = "RELEASED"
ca.data.can$disp[which(ca.data.can$L_KEPTREL=="K")] = "RETAINED" #all are retained
ca.data.can$YEAR = ca.data.can$L_DATE_YY + 1900
ca.data.can$lengthcm = ca.data.can$L_LENGTH1/10
ca.data.can$source = "Crooke-86-88"
ca.data.can$sex = "U"
ca.data.can$trip <- NA #boatnum has some NAs

ca.80.out = ca.data.can[,c("YEAR", "lengthcm", "sex", "disp","source","trip")]


#################
#Dockside sampling
#Northern California 59-72 Dockside > CCRS_LF_77-86
#Northern California 59-72 Dockside > FPB_LF_59-72 
#Northern California 59-72 Dockside > Skiff_LF_59-72
#################

#These datasets are already read in in "canary_explore_recfin_bds.R"

####
#Combine datasets and output into data-raw folder
####
ca.hist = rbind(deb.out, ca.70.out, ca.80.out)
write.csv(ca.hist, file = file.path(git_dir, "data-raw", "CA_rec_historical_length_accessFiles.csv"), row.names = FALSE)
