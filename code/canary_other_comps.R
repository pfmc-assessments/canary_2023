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
#Load California provided MRFSS data and debWV data
#################################

##
#State provided mrfss data
##

ca_bds_mrfss <- readxl::read_excel(path = file.path(git_dir,"data-raw","conf_CA_MRFSS_Lengths_1980-2003.xlsx"),
                                   sheet = "CanLenMRFSS")

#Exclude the 45 samples from man made (1) and beach/bank mode (2). Keep just PC/PR
ca_bds_mrfss <- ca_bds_mrfss[which(ca_bds_mrfss$MODE_FX %in% c(6,7)),]
#Exclude the 1 sample from Mexico
ca_bds_mrfss <- ca_bds_mrfss[-which(ca_bds_mrfss$AREA == 6),]
#Exclude the 38 non Hook and Line gears
ca_bds_mrfss <- ca_bds_mrfss[-which(ca_bds_mrfss$GEAR != 1),]


##
#Deb Wilson-Vandenberg data - from "canary_historical_length_accessFiles.R"
##

oldCA_access <- utils::read.csv(file.path(git_dir,"data-raw","CA_rec_historical_length_accessFiles.csv"), header = T)
oldCA_access <- oldCA_access[oldCA_access$source == "debWV",]


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
or_bds_recfin$disp <- dplyr::case_when(or_bds_recfin$IS_RETAINED ~ "RETAINED",
                                       !or_bds_recfin$IS_RETAINED ~ "RELEASED")
or_bds_recfin$state <- "O" 
or_bds_recfin$source <- "or_recfin"


#CA provided MRFSS data
ca_bds_mrfss$year <- ca_bds_mrfss$YEAR
ca_bds_mrfss$lengthcm <- ca_bds_mrfss$LNGTH/10
ca_bds_mrfss$sex = "U"
ca_bds_mrfss$mode = dplyr::case_when(ca_bds_mrfss$MODE_FX == 6 ~ "PC",
                                     ca_bds_mrfss$MODE_FX == 7 ~ "PR")
ca_bds_mrfss$disp <- "RETAINED" #assumed based on lack of released in DISP3
ca_bds_mrfss$state <- "C" 
ca_bds_mrfss$source <- "ca_mrfss"


#CA Deb Wilson-Vandenberg data - already is format needed
oldCA_access$state <- "C"
oldCA_access$mode <- "PC"
colnames(oldCA_access)[1] <- "year"


##
#Combine into single data set
##

colnam <- c("year", "state", "source", "lengthcm", "sex", "mode", "disp")
out <- rbind(recfin_bds[,colnam], 
             wa_bds_sport[,colnam], 
             or_bds_recfin[,colnam], 
             or_bds_mrfss[,colnam],
             ca_bds_mrfss[,colnam],
             oldCA_access[,colnam])
#Add final SS3 grouping
#Use state provided Sport biodata for WA
#Combine across state provided MRFSS and recfin data for OR
#Use MRFSS data, but replace PC data from 1988-1998 with data from DebWV, 
#and combine with recfin for CA
out$sourceSS3 <- NA
out[out$source == "wa_sport","sourceSS3"] <- "WA"
out[out$source %in% c("or_mrfss", "or_recfin"),"sourceSS3"] <- "OR"
out[out$source == "ca_mrfss" & out$year %in% c(1979:1987,1999:2022), "sourceSS3"] <- "CA"
out[out$source == "ca_mrfss" & out$year %in% c(1988:1998) & out$mode == "PR", "sourceSS3"] <- "CA"
out[out$source == "debWV" & !out$year == 1987, "sourceSS3"] <- "CA"
out[out$source == "recfin" & out$state == "C", "sourceSS3"] <- "CA"

#Remove any NA lengths or unusual lengths
out <- out[!is.na(out$lengthcm),]

#Remove the five samples below 10 cm and one sample above 80 cm that are clearly off. 
#The 70-75 cm fish are questionable but keeping in based on max size of 76cm in Love
head(out[order(out$lengthcm),],20)
tail(out[order(out$lengthcm),],50)
out <- out[out$lengthcm > 10 & out$lengthcm < 80,]

# #Commenting these out here to have the full MRFSS set because these are replaced later
# #Remove the MRFSS lengths from 1997-98 since they are the same as those in Deb's data
# out <- out[-which(out$source == "ca_mrfss" &
#                     out$year %in% 1997:1998 &
#                     out$mode == "PC"), ]

#Remove 6135 released fish from recfin (based on pre-assessment workshop these are likely to little effect)
#Of these 3880 are from CA - and these are the only impact because the OR state provided recfin
#data do not have released fish included
out <- out[-which(out$disp == "RELEASED"),]



############################################################################################
#	Convert into format for SS3 model to use
############################################################################################

#Based on non duplicated data across datasets
out_sample_size <- out %>%
  dplyr::group_by(year, state, source, sex) %>%
  dplyr::summarise(
    #ntrip = length(unique(trip)),
    N = length(lengthcm)) %>%
  pivot_wider(names_from = c(source, state,sex), values_from = N, 
              names_glue = "{state}_{source}_{sex}", names_sort = TRUE) %>%
  data.frame()
write.csv(out_sample_size, file = file.path(git_dir,"data", "Canary_recLen_sample_size_allSources.csv"), row.names = FALSE)

#Based on data to use in SS3
out_sample_size_ss3 <- out %>% filter(!is.na(sourceSS3)) %>%
  dplyr::group_by(year, sourceSS3, sex) %>%
  dplyr::summarise(
    #ntrip = length(unique(trip)),
    N = length(lengthcm)) %>%
  pivot_wider(names_from = c(sourceSS3, sex), values_from = N) %>%
  data.frame()
write.csv(out_sample_size, file = file.path(git_dir,"data", "forSS", "Canary_recLen_sample_size_forSS.csv"), row.names = FALSE)



############################################################################################
#	Create un-weighted composition data for recreational lengths
############################################################################################

# Add expected column names to work with nwfscSurvey package
out$age = NA
length_bins <- c(seq(12, 66, 2))

out$sex_group <- "u"
out$sex_group[out$sex %in% c("M", "F")] <- 'b'

#get sample size by sex group
n <- out %>% filter(!is.na(sourceSS3)) %>%
  dplyr::group_by(year, sourceSS3, sex_group) %>%
  dplyr::summarise(
    #ntrip = length(unique(trip)),
    N = length(lengthcm))

#This creates the composition data for each SS3 fleet
#Right now the script for sexed comps is in the unsexed_comps branch of nwfscSurvey
#so need to navigate to their and then load_all
# devtools::load_all("U:/Other github repos/nwfscSurvey")
for(s in unique(na.omit(out$sourceSS3))) {

  use_n <- n[n$sourceSS3 %in% s, ]
  df <- out[out$sourceSS3 %in% s, -which(colnames(out)=="sex_group")]
  
  if(dim(df)[1] > 0) {
    lfs <-  nwfscSurvey::UnexpandedLFs.fn(
      datL = df, 
      lgthBins = length_bins,
      partition = 0, 
      fleet = s, 
      month = 7)
    
    if(!is.null(lfs$unsexed) & is.null(lfs$sexed)){
      #lfs$unsexed[,"InputN"] <- use_n[use_n$sex_group == "u", 'ntrip']
      write.csv(lfs$unsexed, 
                file = file.path(git_dir, "data", "forSS", paste0(s,"_rec_not_expanded_Lcomp",length_bins[1],"_", tail(length_bins,1),"_formatted.csv")),
                row.names = FALSE) 
    } 
    if(!is.null(lfs$sexed) & is.null(lfs$unsexed)){
      #lfs$sexed[,"InputN"] <- use_n[use_n$sex_group == "b", 'ntrip']
      write.csv(lfs$sexed, 
                file = file.path(git_dir, "data", "forSS", paste0(s,"_rec_not_expanded_Lcomp",length_bins[1],"_", tail(length_bins,1),"_formatted.csv")),
                row.names = FALSE) 
    }
    
    if(!is.null(lfs$sexed) & !is.null(lfs$unsexed)){
      #lfs$sexed[,"InputN"] <- use_n[use_n$sex_group == "b", 'ntrip']
      #lfs$unsexed[,"InputN"] <- use_n[use_n$sex_group == "u", 'ntrip']
      colnames(lfs$unsexed) <- colnames(lfs$sexed)
      write.csv(rbind(lfs$unsexed, lfs$sexed), 
                file = file.path(git_dir, "data", "forSS", paste0(s,"_rec_not_expanded_Lcomp_",length_bins[1],"_", tail(length_bins,1),"_formatted.csv")),
                row.names = FALSE) 
    }
    
    lfs <- NULL
  } #if loop from dim(df)
}
















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
