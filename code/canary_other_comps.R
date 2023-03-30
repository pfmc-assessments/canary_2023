##################################################################################################
#
#	Create composition data for recreational fleets
# 		
#		Written by Brian Langseth
#
##################################################################################################

#devtools::install_github("pfmc-assessments/PacFIN.Utilities")
library(PacFIN.Utilities)
library(ggplot2)

#User directories
if(Sys.getenv("USERNAME") == "Brian.Langseth") {
  dir <- "U:/Stock assessments/canary_rockfish_supporting_2023/RecFIN pulls"
  git_dir <- "U:/Stock assessments/canary_2023/"
}


################################
#Load RecFIN data
################################

##
#Length data
##
recfin_bdsWA = read.csv(file.path(dir, "RecFIN_SD001_WA_canary_1983_2021.csv"),header=TRUE)
recfin_bdsOR = read.csv(file.path(dir, "RecFIN_SD001_OR_canary_1999_2021.csv"),header=TRUE)
recfin_bdsCA = read.csv(file.path(dir, "RecFIN_SD001_CA_canary_2003_2021.csv"),header=TRUE)
recfin_bds = rbind(recfin_bdsWA,recfin_bdsOR,recfin_bdsCA)

#Exclude 16 inland and 24 estuary fish
recfin_bds <- recfin_bds[-which(recfin_bds$AGENCY_WATER_AREA_NAME %in% c("ESTUARY","IN")),]


##
#Age data for later
##
recfin_bdsage = read.csv(file.path(dir, "conf_RecFIN_SD506_canary_1993_2021.csv"),header=TRUE)


################################
#Load Washington provided Sport length data and set up
#################################

#Dont need research data per "canary_explore_recfin_bds.R"
wa_bds_sport <- readxl::read_excel(path = file.path(git_dir,"data-raw","WA_CanaryBiodata2023.xlsx"),
                                   sheet = "Sport")


################################
#Load Oregon provided data from RecFIN and MRFSS
#################################

##
#State provided recfin data
##
or_bds_recfin <- read.csv(file = file.path(git_dir,"data-raw","OR_RecFIN_OceanBoat_lengths_20230125.csv"),header=TRUE)

#Remove 24 estuary fish
or_bds_recfin <- or_bds_recfin[-which(or_bds_recfin$RECFIN_WATER_AREA_NAME=="ESTUARY"),]


##
#State provided mrfss data
##
or_bds_mrfss <- readxl::read_excel(path = file.path(git_dir,"data-raw","OR_MRFSS_Lengths_1980-2003.xlsx"),
                                   sheet = "OR_MRFSS_Lengths_1980-2003")
or_bds_mrfss$Length <- as.numeric(or_bds_mrfss$Length)
or_bds_mrfss$Total.Length <- as.numeric(or_bds_mrfss$Total.Length)

#Remove 18 samples with lengths based on weight to length conversions (16 with measured weight and 2 with computed weight)
or_bds_mrfss = or_bds_mrfss[-which(or_bds_mrfss$Length_Flag=="computed" & or_bds_mrfss$Total.Length_Flag=="computed"),]


################################
#Load California provided MRFSS data
#################################




############################################################################################
#	Set up fields for combining across datasets
############################################################################################

#RecFIN
recfin_bds$year <- recfin_bds$RECFIN_YEAR
recfin_bds$lengthcm = recfin_bds$RECFIN_LENGTH_MM/10
recfin_bds$sex <- dplyr::case_when(recfin_bds$RECFIN_SEX_CODE %in% c("U","","FALSE") ~ "U",
                                   is.na(recfin_bds$RECFIN_SEX_CODE) ~ "U",
                                   TRUE ~ recfin_bds$RECFIN_SEX_CODE)
recfin_bds$state <- dplyr::case_when(recfin_bds$STATE_NAME == "CALIFORNIA" ~ "C",
                                     recfin_bds$STATE_NAME == "OREGON" ~ "O",
                                     recfin_bds$STATE_NAME == "WASHINGTON" ~ "W")
recfin_bds$mode <- dplyr::case_when(recfin_bds$RECFIN_MODE_NAME == "PARTY/CHARTER BOATS" ~ "PC",
                                    recfin_bds$RECFIN_MODE_NAME == "PRIVATE/RENTAL BOATS" ~ "PR",
                                    recfin_bds$RECFIN_MODE_NAME == "NOT KNOWN" ~ "Unk")
recfin_bds$disp <- recfin_bds$IS_RETAINED
recfin_bds$source <- "recfin"


#WA sport data
wa_bds_sport$year <- wa_bds_sport$sample_year
wa_bds_sport$lengthcm <- wa_bds_sport$fish_length_cm
wa_bds_sport$sex <- dplyr::case_when(wa_bds_sport$sex_name == "Female" ~ "F",
                               wa_bds_sport$sex_name == "Male" ~ "M",
                               wa_bds_sport$sex_name == "Unknown" ~ "U",
                               is.na(wa_bds_sport$sex_name) ~ "U")
wa_bds_sport$mode <- dplyr::case_when(wa_bds_sport$boat_mode_code == "C" ~ "PC",
                                wa_bds_sport$boat_mode_code == "B" ~ "PR",
                                wa_bds_sport$boat_mode_code == "?" ~ "Unk",
                                is.na(wa_bds_sport$boat_mode_code) ~ "Unk")
wa_bds_sport$disp <- "RETAINED"
wa_bds_sport$state <- "W"
wa_bds_sport$source <- "wa_sport"


#OR provided MRFSS data
or_bds_mrfss$year <- or_bds_mrfss$Year
or_bds_mrfss$lengthcm <- or_bds_mrfss$Length/10
or_bds_mrfss$sex = "U"
or_bds_mrfss$mode = dplyr::case_when(or_bds_mrfss$Mode_FX_Name == "charter" ~ "PC",
                                     or_bds_mrfss$Mode_FX_Name == "private boat" ~ "PR")
or_bds_mrfss$disp <- "RETAINED" #assume all are retained
or_bds_mrfss$state <- "O" 
or_bds_mrfss$source <- "or_mrfss"


#OR provided RecFIN data
or_bds_recfin$year <- or_bds_recfin$RECFIN_YEAR
or_bds_recfin$lengthcm <- or_bds_recfin$RECFIN_LENGTH_MM/10
or_bds_recfin$sex <- "U" #all are unsexed - TO DO: CONFIRM WITH ALI. RecFIN has OR sexes in. 
or_bds_recfin$mode = dplyr::case_when(or_bds_recfin$RECFIN_MODE_NAME == "PARTY/CHARTER BOATS" ~ "PC",
                                      or_bds_recfin$RECFIN_MODE_NAME == "PRIVATE/RENTAL BOATS" ~ "PR")
or_bds_recfin$disp <- or_bds_recfin$IS_RETAINED
or_bds_recfin$state <- "O" 
or_bds_recfin$source <- "or_recfin"














############################################################################################
#	Convert into format for SS3 model to use
############################################################################################

################################
#Washington provided sport data
#################################

wa = out[which(out$State == "WA"), ]
wa$Length_cm = wa$Length

# create a table of the samples available by year
wa$Trawl_id = 1:nrow(wa)
GetN.fn(dir = file.path(dir, "data"), dat = wa, type = "length", species = 'others')
n = read.csv(file.path(dir, "data", "forSS", "length_SampleSize.csv"))
n = n[,c('Year', 'All_Fish', 'Sexed_Fish', 'Unsexed_Fish')]
write.csv(n, file = file.path(dir, "data", "forSS", "wa_rec_samples.csv"), row.names = FALSE)

GetN.fn(dir = file.path(dir, "data"), dat = wa, type = "age", species = 'others')
n = read.csv(file.path(dir, "data", "forSS", "age_SampleSize.csv"))
n = n[,c('Year', 'All_Fish', 'Sexed_Fish', 'Unsexed_Fish')]
write.csv(n, file = file.path(dir, "data", "forSS", "wa_rec_age_samples.csv"), row.names = FALSE)

wa$Sex = "U" #UnexpandedLFs.fn and UnexpandedAFs.fn will only do comps for Unsexed fish in sex = 0 and ignore male and female. So assign all as U

lfs = UnexpandedLFs.fn(dir = file.path(dir, "data"), #puts into "forSS" folder in this location
                       datL = wa, lgthBins = len_bin,
                       sex = 0,  partition = 0, fleet = 1, month = 1) #Fleet is 1 for WA
file.rename(from = file.path(dir, "data", "forSS", "Survey_notExpanded_Length_comp_Sex_0_bin=10-50.csv"), 
            to= file.path(dir, "data", "forSS", "wa_rec_notExpanded_Length_comp_Sex_0_bin=10-50_Feb2021.csv")) 

PlotFreqData.fn(dir = file.path(dir, "data", "forSS"), 
                dat = lfs$comps, ylim=c(0, max(len_bin)+4), 
                main = "WA Recreational - Unsexed_Feb2021", yaxs="i", ylab="Length (cm)", dopng = TRUE)

#Washington length comps 10-56
lfs = UnexpandedLFs.fn(dir = file.path(dir, "data"), #puts into "forSS" folder in this location
                       datL = wa, lgthBins = seq(10,56,2),
                       sex = 0,  partition = 0, fleet = 1, month = 1) #Fleet is 1 for WA
file.rename(from = file.path(dir, "data", "forSS", "Survey_notExpanded_Length_comp_Sex_0_bin=10-56.csv"), 
            to= file.path(dir, "data", "forSS", "wa_rec_notExpanded_Length_comp_Sex_0_bin=10-56.csv")) 


#Washington age comps
afs = UnexpandedAFs.fn(dir = file.path(dir, "data"), #puts into "forSS" folder in this location
                       datA = wa, ageBins = 5:70,
                       sex = 0,  partition = 0, fleet = 1, month = 1, ageErr = 1) #Fleet is 1 for WA
file.rename(from = file.path(dir, "data", "forSS", "Survey_notExpanded_Age_comp_Sex_0_bin=5-70.csv"), 
            to= file.path(dir, "data", "forSS", "wa_rec_notExpanded_Age_comp_Sex_0_bin=5-70_Feb2021.csv")) 
