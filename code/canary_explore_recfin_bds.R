##################################################################################################
#
#	RedFIN Data Exploration for Canary Rockfish
# 		
#		Written by Brian Langseth
#
##################################################################################################

library(ggplot2)
library(tidyr)
library(dplyr)

#User directories
if(Sys.getenv("USERNAME") == "Brian.Langseth") {
  dir <- "U:/Stock assessments/canary_rockfish_supporting_2023/RecFIN pulls"
  git_dir <- "U:/Stock assessments/canary_2023/"
}

################################
#LENGTH - Load RecFIN length BDS data, check for any issues
################################

recfin_bdsWA = read.csv(file.path(dir, "RecFIN_SD001_WA_canary_1983_2021.csv"),header=TRUE)
recfin_bdsOR = read.csv(file.path(dir, "RecFIN_SD001_OR_canary_1999_2021.csv"),header=TRUE)
recfin_bdsCA = read.csv(file.path(dir, "RecFIN_SD001_CA_canary_2003_2021.csv"),header=TRUE)
recfin_bds = rbind(recfin_bdsWA,recfin_bdsOR,recfin_bdsCA)

table(recfin_bds$AGENCY_LENGTH_UNITS,useNA="always")
table(recfin_bds$RECFIN_SEX_CODE,recfin_bds$STATE_NAME,useNA="always") #going to be mostly unsexed
table(recfin_bds$RECFIN_LENGTH_MM,useNA="always")
table(recfin_bds$RECFIN_IMPUTED_LENGTH,useNA="always")
table(recfin_bds$AGENCY_WATER_AREA_NAME,recfin_bds$STATE_NAME,useNA="always")
table(recfin_bds$IS_AGENCY_LENGTH_WITHIN_MAX,useNA="always")
table(recfin_bds$RECFIN_MODE_NAME,useNA="always")
table(recfin_bds$IS_RETAINED,recfin_bds$STATE_NAME,useNA="always")

#Remove 8 samples with NA lengths 
recfin_bds = recfin_bds[!is.na(recfin_bds$RECFIN_LENGTH_MM),]
#Exclude two samples with weird MM measurements and two samples with 0 length
recfin_bds = recfin_bds[-which(recfin_bds$RECFIN_LENGTH_MM<100),]
#Add cm field
recfin_bds$lengthcm = recfin_bds$RECFIN_LENGTH_MM/10

#Exclude 16 inland and 24 estuary fish
recfin_bds <- recfin_bds[-which(recfin_bds$AGENCY_WATER_AREA_NAME %in% c("ESTUARY","IN")),]

#Assign NA, "", FALSE, and U sex to unknown sex code
recfin_bds$sex <- dplyr::case_when(recfin_bds$RECFIN_SEX_CODE %in% c("U","","FALSE") ~ "U",
                            is.na(recfin_bds$RECFIN_SEX_CODE) ~ "U",
                            TRUE ~ recfin_bds$RECFIN_SEX_CODE)

#Add shorter state name
recfin_bds$state <- dplyr::case_when(recfin_bds$STATE_NAME == "CALIFORNIA" ~ "C",
                             recfin_bds$STATE_NAME == "OREGON" ~ "O",
                             recfin_bds$STATE_NAME == "WASHINGTON" ~ "W")
#Add shorter mode name
recfin_bds$mode <- dplyr::case_when(recfin_bds$RECFIN_MODE_NAME == "PARTY/CHARTER BOATS" ~ "PC",
                             recfin_bds$RECFIN_MODE_NAME == "PRIVATE/RENTAL BOATS" ~ "PR",
                             recfin_bds$RECFIN_MODE_NAME == "NOT KNOWN" ~ "Unk")

#Exclude "released" fish
recfin_bds_rel <- recfin_bds[recfin_bds$IS_RETAINED == "RELEASED",]
recfin_bds <- recfin_bds[recfin_bds$IS_RETAINED == "RETAINED",]


##
#Samples by year
##

#Length samples by year
Nlen <- recfin_bds %>% group_by(mode, state, RECFIN_YEAR) %>% 
  summarize(N = length(lengthcm)) %>%
  pivot_wider(names_from = c(state,mode), names_sep = ".", values_from = N, 
              names_glue = "{state}_{mode}_{.value}", names_sort = TRUE, ) %>% 
  arrange(RECFIN_YEAR)


################################
#AGE - Load RecFIN age BDS data, check for any issues
################################

recfin_bdsage = read.csv(file.path(dir, "conf_RecFIN_SD506_canary_1993_2021.csv"),header=TRUE)

table(recfin_bdsage$USE_THIS_AGE,useNA="always")
table(recfin_bdsage$RECFIN_SEX_CODE,recfin_bdsage$SAMPLING_AGENCY_NAME,useNA="always") #going to be mostly unsexed
table(recfin_bdsage$NUMBER_OF_READS,useNA="always")
table(recfin_bdsage$RECFIN_AGEING_METHOD_DESC,useNA="always")

#Add shorter state name
recfin_bdsage$state = dplyr::case_when(recfin_bdsage$SAMPLING_AGENCY_NAME == "ODFW" ~ "O",
                                recfin_bdsage$SAMPLING_AGENCY_NAME == "WDFW" ~ "W")

#Add shorter mode name
recfin_bdsage$mode = dplyr::case_when(recfin_bdsage$RECFIN_MODE_NAME == "PARTY/CHARTER BOATS" ~ "PC",
                            recfin_bdsage$RECFIN_MODE_NAME == "PRIVATE/RENTAL BOATS" ~ "PR",
                            recfin_bdsage$RECFIN_MODE_NAME == "NOT KNOWN" ~ "Unk")

#Age samples by year
Nage <- recfin_bdsage %>% filter(., !is.na(USE_THIS_AGE)) %>% group_by(mode, state, SAMPLE_YEAR) %>% 
  summarize(N = length(USE_THIS_AGE)) %>%
  pivot_wider(names_from = c(state,mode), names_sep = ".", values_from = N, 
              names_glue = "{state}_{mode}_{.value}", names_sort = TRUE, ) %>% 
  arrange(SAMPLE_YEAR)


# ##
# #Upload sample sizes to googledrive
# ##
# xx <- googledrive::drive_create(name = 'recfin_bds_N',
#                                 path = 'https://drive.google.com/drive/folders/1Lx4JN-nmJkWtcqmelODZYoVrHyVLzegP',
#                                 type = 'spreadsheet', overwrite = TRUE)
# googlesheets4::sheet_write(Nlen, ss = xx, sheet = "Nlen")
# googlesheets4::sheet_write(Nage, ss = xx, sheet = "Nage")
# googlesheets4::sheet_delete(ss = xx, sheet = "Sheet1")


################################
#Load Oregon provided BDS data, check for any issues
#################################

#From Ali email on 1/25/2023
#"The MRFSS data have been filtered for ocean boat fish only, and the RecFIN data are already
#ocean boat only but have been filtered to exclude the discarded CPFV fish and fish that are
#aged (source code=ORA) so as to not double count fish.  I would further recommend filtering 
#the MRFSS data to only have directly measured fish by using the “Length_Flag” field and 
#filtering for “measured” fish. I would not recommend using lengths imputed from weights but 
#from total length would probably be just fine."

##
#MRFSS era data
##

#Only need to pull from googledrive once
# googledrive::drive_download(file = "Oregon data/OR_MRFSS_Lengths_1980-2003.xlsx",
#                             path = file.path(git_dir,"data-raw","OR_MRFSS_Lengths_1980-2003.xlsx"))
or_bds_mrfss <- readxl::read_excel(path = file.path(git_dir,"data-raw","OR_MRFSS_Lengths_1980-2003.xlsx"),
                             sheet = "OR_MRFSS_Lengths_1980-2003")
or_bds_mrfss$Length <- as.numeric(or_bds_mrfss$Length)
or_bds_mrfss$Total.Length <- as.numeric(or_bds_mrfss$Total.Length)

table(or_bds_mrfss$MRFSS_MODE_FX,useNA="always") #6 = PC #7 = PR
table(or_bds_mrfss$Area_X_Name,useNA="always")
table(or_bds_mrfss$Gear,useNA="always") #some spear/spear gun, all are ocean so keep
table(or_bds_mrfss$Length_Flag,useNA="always") #appears to be fork length
table(or_bds_mrfss$Total.Length_Flag,useNA="always") #appears to be total length
plot(or_bds_mrfss$Total.Length-or_bds_mrfss$Length)
plot(or_bds_mrfss$Total.Length,or_bds_mrfss$Length)
table(or_bds_mrfss$MRFSS_WGT_FLAG,useNA="always") 
table(or_bds_mrfss$WGT_FLAG_ALT,useNA="always") 
#there are 16 samples where length wasn't measured, but rather taken from weight, and 2 where neither length nor weight was measured. 
table(or_bds_mrfss$Length_Flag,or_bds_mrfss$Total.Length_Flag, or_bds_mrfss$WGT_FLAG_ALT,useNA="always")
table(or_bds_mrfss$Fleet,useNA="always")
table(or_bds_mrfss$Year,useNA="always")

#add length in cm based on fork length
or_bds_mrfss$lengthcm <- or_bds_mrfss$Length/10

#Add shorter mode name
or_bds_mrfss$mode = dplyr::case_when(or_bds_mrfss$Mode_FX_Name == "charter" ~ "PC",
                                     or_bds_mrfss$Mode_FX_Name == "private boat" ~ "PR")

#Add sex (which is all unknown)
or_bds_mrfss$sex = "U"

#Remove 18 samples with lengths based on weight to length conversions (16 with measured weight and 2 with computed weight)
or_bds_mrfss = or_bds_mrfss[-which(or_bds_mrfss$Length_Flag=="computed" & or_bds_mrfss$Total.Length_Flag=="computed"),]

#Remove the 579 samples without any length provided
or_bds_mrfss = or_bds_mrfss[!is.na(or_bds_mrfss$lengthcm),]


##
#RecFIN era data
##

#Only need to pull from googledrive once
# googledrive::drive_download(file = "Oregon data/OR_RecFIN_OceanBoat_lengths_20230125.csv",
#                             path = file.path(git_dir,"data-raw","OR_RecFIN_OceanBoat_lengths_20230125.csv"))
or_bds_recfin <- read.csv(file = file.path(git_dir,"data-raw","OR_RecFIN_OceanBoat_lengths_20230125.csv"),header=TRUE)

table(or_bds_recfin$AGENCY_LENGTH_UNITS,useNA="always")
table(or_bds_recfin$FISH_SEX,useNA="always") #all unsexed
table(or_bds_recfin$RECFIN_MODE_NAME,useNA="always")
table(or_bds_recfin$RECFIN_LENGTH_TYPE,useNA="always")
table(or_bds_recfin$FISHING_DEPTH,useNA="always")
table(or_bds_recfin$RECFIN_WATER_AREA_NAME,useNA="always")
table(or_bds_recfin$IS_AGENCY_LENGTH_WITHIN_MAX,useNA="always")
table(or_bds_recfin$RECFIN_LENGTH_MM,useNA="always") #all have a length
table(or_bds_recfin$IS_RETAINED,useNA="always")
table(or_bds_recfin$DESCENDING_DEVICE_USED,useNA="always")
table(or_bds_recfin$RECFIN_YEAR,useNA="always")

#Remove 24 estuary fish
or_bds_recfin <- or_bds_recfin[-which(or_bds_recfin$RECFIN_WATER_AREA_NAME=="ESTUARY"),]

#Assign NA to unknown sex code
or_bds_recfin$sex <- dplyr::case_when(is.na(or_bds_recfin$FISH_SEX) ~ "U",
                            TRUE ~ "Unk")
#Add length in cm
or_bds_recfin$lengthcm <- or_bds_recfin$RECFIN_LENGTH_MM/10

#Add shorter mode name
or_bds_recfin$mode = dplyr::case_when(or_bds_recfin$RECFIN_MODE_NAME == "PARTY/CHARTER BOATS" ~ "PC",
                                     or_bds_recfin$RECFIN_MODE_NAME == "PRIVATE/RENTAL BOATS" ~ "PR")

#Rename year
or_bds_recfin$Year <- or_bds_recfin$RECFIN_YEAR


##
#Combine Oregon data into one dataset
#There are samples in both datasets in 2001-2003. Per Ali, these are separate samples so they can be combined
##

or_bds <- rbind(or_bds_mrfss[,c("Year","mode","lengthcm","sex")], or_bds_recfin[,c("Year","mode","lengthcm","sex")])
or_bds$state <- "O"



################################
#Load Washington provided Sport and Research BDS data, check for any issues
#################################

#Only need to pull from googledrive once
# googledrive::drive_download(file = "WA_CanaryBiodata2023_Feb7version.xlsx",
#                             path = file.path(git_dir,"data-raw","WA_CanaryBiodata2023.xlsx"))
wa_bds_sport <- readxl::read_excel(path = file.path(git_dir,"data-raw","WA_CanaryBiodata2023.xlsx"),
                                   sheet = "Sport")
wa_bds_research <- readxl::read_excel(path = file.path(git_dir,"data-raw","WA_CanaryBiodata2023.xlsx"),
                                   sheet = "Research")

wa_bds <- rbind(wa_bds_sport, wa_bds_research[,which(names(wa_bds_research)!="fish_sample_date")])

table(wa_bds$data_type_code,useNA="always")
table(wa_bds$data_source_agency_name,useNA="always")
table(wa_bds$sample_year,useNA="always")
table(wa_bds$species_name,useNA="always")
table(wa_bds$fish_length_cm,useNA="always")
table(wa_bds$best_age,useNA="always")
table(wa_bds$age_structure_name,useNA="always")
table(wa_bds$sex_name,useNA="always")
table(wa_bds$mfbds_v_sample.punch_card_area_code,useNA="always")
table(wa_bds$stock_region,useNA="always")
table(wa_bds$gear_name,useNA="always")
table(wa_bds$boat_mode_code,useNA="always")
table(wa_bds$length_type_name,useNA="always") #assume all are fork length
table(wa_bds$age_method_name_1,useNA="always")
table(wa_bds$age_method_name_2,useNA="always")
table(wa_bds$sample_method_code,useNA="always") #guessing R is random and P is purposive. Theresa and Kristen say (on Feb 7) assume NA is random
table(wa_bds$gear_name,wa_bds$sample_method_code,useNA="always") #guessing R is random and P is purposive
table(wa_bds$sample_year, wa_bds$gear_name, wa_bds$data_type_code,useNA="always")

#Compared to bdsWA (my recfin pull) this dataset is missing some 1990s data.
#Other than sport missing some 1990s data (which Theresa and Kristen say they 
#can reproduce only if they pull Puget Sound fish), and recfin missing 1980s data and 2006, 
#the sport sample sizes only differ by 2 fewer samples in 2017 and 3 fewer in 2018
table(wa_bds[wa_bds$data_type_code=="S",]$sample_year,useNA="always") #sport only
table(recfin_bdsWA$RECFIN_YEAR,useNA="always")

#Rename length field
wa_bds$lengthcm <- wa_bds$fish_length_cm

#Reorganize sex field, with unknown or NA being "U" 
wa_bds$sex <- dplyr::case_when(wa_bds$sex_name == "Female" ~ "F",
                               wa_bds$sex_name == "Male" ~ "M",
                               wa_bds$sex_name == "Unknown" ~ "U",
                               is.na(wa_bds$sex_name) ~ "U")

#Reorganize mode name
wa_bds$mode <- dplyr::case_when(wa_bds$boat_mode_code == "C" ~ "PC",
                                wa_bds$boat_mode_code == "B" ~ "PR",
                                wa_bds$boat_mode_code == "?" ~ "Unk",
                                is.na(wa_bds$boat_mode_code) ~ "Unk")

#Remove samples without a length (these do not have an age)
wa_bds <- wa_bds[!is.na(wa_bds$fish_length_cm),]

wa_bds$state <- "W"

#Lengths are really varied based on gear (used to support removal of research samples) 
samp_val = c("Research", "Sport")
names(samp_val) = c("R","S")
ggplot(wa_bds, aes(fish_length_cm, fill = gear_name, color = sample_method_code)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("data_type_code", ncol=1, labeller = labeller(data_type_code = samp_val)) +
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  scale_color_manual(labels = c("Purposive", "Random"), values = c("#F8766D","#00BFC4")) +
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_explore_figs","WA_SportResearch_lenDensity.png"),
       width = 6, height = 8)

#what about ages - they are too (used to support removal of research samples)
samp_val = c("Research", "Sport")
names(samp_val) = c("R","S")
ggplot(wa_bds, aes(best_age, fill = gear_name, color = sample_method_code)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap(c("data_type_code","sex"), ncol=2, labeller = labeller(data_type_code = samp_val)) +
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  scale_color_manual(labels = c("Purposive", "Random"), values = c("#F8766D","#00BFC4")) +
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_explore_figs","WA_SportResearch_lenDensity.png"),
       width = 6, height = 8)

#Use only sport data as research are specifically targeting small and big fish to 
#try to get decent growth estimates
wa_bds <- wa_bds[wa_bds$data_type_code == "S",]



############################################################################################
#Plots
############################################################################################

lab_val = c("California", "Oregon", "Washington")
names(lab_val) = c("C","O","W")


##
#Sample size plots for RecFIN pull
##

#Length
ggplot(filter(recfin_bds,mode%in%c("PC","PR")), aes(fill=mode, x=RECFIN_YEAR)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of length samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenN_mode.png"),
       width = 6, height = 8)

ggplot(filter(recfin_bds,mode%in%c("PC","PR")), aes(x=RECFIN_YEAR)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of length samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenN.png"),
       width = 6, height = 8)

table(recfin_bds$sex,recfin_bds$state)
ggplot(filter(recfin_bds,mode%in%c("PC","PR")), aes(fill=sex, x=RECFIN_YEAR)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of length samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenN_sex.png"),
       width = 6, height = 8)

recfin_bds_all <- rbind(recfin_bds,recfin_bds_rel)
ggplot(filter(recfin_bds_all,mode%in%c("PC","PR")), aes(fill=IS_RETAINED, x=RECFIN_YEAR)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of length samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenN_retained.png"),
       width = 6, height = 8)

recfin_bds_all <- rbind(recfin_bds,recfin_bds_rel)
ggplot(filter(recfin_bds_all,mode%in%c("PC","PR")), aes(fill=IS_RETAINED, x=RECFIN_YEAR)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap(c("state","mode"), ncol=2, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of length samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenN_retained_mode.png"),
       width = 6, height = 8)


#Age
ggplot(filter(recfin_bdsage,!is.na(USE_THIS_AGE) & mode%in%c("PC","PR")), aes(fill=mode, x=SAMPLE_YEAR)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of age samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_ageN_mode.png"),
       width = 6, height = 8)

ggplot(filter(recfin_bdsage,!is.na(USE_THIS_AGE) & mode%in%c("PC","PR")), aes(x=SAMPLE_YEAR)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of age samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_ageN.png"),
       width = 6, height = 8)

table(recfin_bdsage$RECFIN_SEX_CODE,recfin_bdsage$state,is.na(recfin_bdsage$USE_THIS_AGE))
ggplot(filter(recfin_bdsage,!is.na(USE_THIS_AGE) & mode%in%c("PC","PR")), aes(fill=RECFIN_SEX_CODE, x=SAMPLE_YEAR)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of age samples") + 
  scale_fill_discrete(name = "Sex", labels = c("F","M","U")) + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_ageN_sex.png"),
       width = 6, height = 8)



##
#Distributions for RecFIN pull
##

#Lengths by mode - pretty similar without released fish
ggplot(filter(recfin_bds,mode%in%c("PC","PR")), aes(lengthcm, fill = mode, color = mode)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenDensity_mode.png"),
       width = 6, height = 8)

recfin_bds_all <- rbind(recfin_bds,recfin_bds_rel) #if including released fish
ggplot(filter(recfin_bds_all,mode%in%c("PC","PR")), aes(lengthcm, fill = mode, color = mode)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenDensity_mode_withreleased.png"),
       width = 6, height = 8)

#Lengths by retention
recfin_bds_all <- rbind(recfin_bds,recfin_bds_rel)
table(recfin_bds_all$RECFIN_YEAR, recfin_bds_all$mode, recfin_bds_all$IS_RETAINED)
ggplot(filter(recfin_bds_all,mode%in%c("PC", "PR")), aes(lengthcm, fill = IS_RETAINED, color = IS_RETAINED)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenDensity_retained.png"),
       width = 6, height = 8)

#Lengths by retention - only in years (>=2003) and modes (PC) where each exists
recfin_bds_all <- rbind(recfin_bds,recfin_bds_rel)
table(recfin_bds_all$RECFIN_YEAR, recfin_bds_all$mode, recfin_bds_all$IS_RETAINED)
ggplot(filter(recfin_bds_all,mode%in%c("PC") & RECFIN_YEAR >= 2003), aes(lengthcm, fill = IS_RETAINED, color = IS_RETAINED)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenDensity_retained_PC2003.png"),
       width = 6, height = 8)

#Lengths by retention - only in years dominated by releases (CA 2009-2016 and OR 2004-2014)
recfin_bds_all <- rbind(recfin_bds,recfin_bds_rel)
table(recfin_bds_all$RECFIN_YEAR, recfin_bds_all$mode, recfin_bds_all$IS_RETAINED)
recfin_bds_all_CAshort <- filter(recfin_bds_all, mode%in%c("PC","PR") & RECFIN_YEAR %in% c(2009:2016) & state == "C")
recfin_bds_all_ORshort <- filter(recfin_bds_all, mode%in%c("PC","PR") & RECFIN_YEAR %in% c(2004:2014) & state == "O")
recfin_bds_all_WA <- filter(recfin_bds_all, mode%in%c("PC","PR") & state == "W")
recfin_bds_all_short <- rbind(recfin_bds_all_CAshort, recfin_bds_all_ORshort, recfin_bds_all_WA)
ggplot(recfin_bds_all_short, aes(lengthcm, fill = IS_RETAINED, color = IS_RETAINED)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenDensity_retained_WA_CA09-16_OR04-14.png"),
       width = 6, height = 8)

#Lengths by sex - pretty similar
ggplot(filter(recfin_bds,mode%in%c("PC","PR")), aes(lengthcm, fill = sex, color = sex)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenDensity_sex.png"),
       width = 6, height = 8)

#Ages by mode - pretty similar
ggplot(filter(recfin_bdsage,mode%in%c("PC","PR")), aes(USE_THIS_AGE, fill = mode, color = mode)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) + 
  xlab("Fish Age") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_ageDensity_mode.png"),
       width = 6, height = 8)

#Ages by sex - pretty similar
ggplot(filter(recfin_bdsage,mode%in%c("PC","PR")), aes(USE_THIS_AGE, fill = RECFIN_SEX_CODE, color = RECFIN_SEX_CODE)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) + 
  xlab("Fish Age") +
  ylab("Proportion") +
  scale_fill_discrete(name = "Sex", labels = c("F","M","U")) + 
  scale_color_discrete(name = "Sex", labels = c("F","M","U")) +
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_ageDensity_sex.png"),
       width = 6, height = 8)


##
#Sample sizes for Oregon provided data
##

#Length
ggplot(filter(or_bds,mode%in%c("PC","PR")), aes(fill=mode, x=Year)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of length samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","OR_rec_lenN_mode.png"),
       width = 6, height = 3)

ggplot(filter(or_bds,mode%in%c("PC","PR")), aes(x=Year)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of length samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","OR_rec_lenN.png"),
       width = 6, height = 3)

#Lengths by mode - pretty similar
ggplot(or_bds, aes(lengthcm, fill = mode, color = mode)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","OR_rec_lenDensity_mode.png"),
       width = 6, height = 3)

#Done yet have ages from Oregon


##
#Sample sizes and lengths for Washington provided data
##

#Length
ggplot(filter(wa_bds,mode%in%c("PC","PR")), aes(fill=mode, x=sample_year)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of length samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())

#Ages
ggplot(filter(wa_bds,mode%in%c("PC","PR") & !is.na(wa_bds$best_age)), aes(fill=mode, x=sample_year)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of age samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())

#Lengths by mode - pretty similar
ggplot(wa_bds, aes(lengthcm, fill = mode, color = mode)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())

#Ages by mode - pretty similar
ggplot(wa_bds, aes(best_age, fill = mode, color = mode)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) + 
  xlab("Fish age") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())


################################
#Load California provided MRFSS data, check for any issues
#This occurred after the pre-assessment data workshop
#################################

#Only need to pull from googledrive once
# googledrive::drive_download(file = "CONFIDENTIAL_MRFSS_CA/conf_CanLenMRFSS.xlsx",
#                             path = file.path(git_dir,"data-raw","conf_CA_MRFSS_Lengths_1980-2003.xlsx"))
ca_bds_mrfss <- readxl::read_excel(path = file.path(git_dir,"data-raw","conf_CA_MRFSS_Lengths_1980-2003.xlsx"),
                                   sheet = "CanLenMRFSS")
#Multiple length columns are present (per github issue #5 in california-data repo - should use LNGTH)
table(ca_bds_mrfss$LEN)
table(ca_bds_mrfss$LENGTH)
table(ca_bds_mrfss$T_LEN)
table(ca_bds_mrfss$LNGTH)
table(ca_bds_mrfss$LEN_FLAG,useNA="always") #there are only 0. No clear documentation
plot(as.numeric(ca_bds_mrfss$T_LEN) - as.numeric(ca_bds_mrfss$LNGTH)) #T_LEN is always larger
#Could assume lengths with decimals are inferred and those without are measured
table(ca_bds_mrfss$YEAR,nchar(ca_bds_mrfss$LNGTH)) #started being measured in 1993
table(ca_bds_mrfss$YEAR,nchar(ca_bds_mrfss$T_LEN)) #mostly measured before 1993
#But if use relationship in Echeverria and Lenarz 1986
#it looks like for T_LEN is converted from LNGTH even though LNGTH had decimals before 1993 
tlen <- (-4.107+1.070*as.numeric(ca_bds_mrfss$LNGTH))
plot(ca_bds_mrfss$YEAR, as.numeric(ca_bds_mrfss$T_LEN)-tlen)
#Converting the other way suggests that LNGTH was not converted from T_LEN
flen <- (4.108+0.934*as.numeric(ca_bds_mrfss$T_LEN))
plot(ca_bds_mrfss$YEAR, as.numeric(ca_bds_mrfss$LNGTH)-flen)
#Canary have a fork so differences in fork and total are expected.
#I think the most straight forward approach is to use LNGTH regardless of the number of decimals
ca_bds_mrfss$LNGTH <- as.numeric(ca_bds_mrfss$LNGTH)

#Other fields
table(ca_bds_mrfss$MODE_FX,useNA="always") #6 = PC #7 = PR
table(ca_bds_mrfss$AREA_X,useNA="always") 
table(ca_bds_mrfss$AREA,useNA="always") #4-5 = inland, #6 = Mexico 
table(ca_bds_mrfss$GEAR,useNA="always") #4 = gill, #6 = trawl, #8 = spear, #10 = Other
table(ca_bds_mrfss$WGT_FLAG,useNA="always") 
table(ca_bds_mrfss$ST,useNA="always") 
table(ca_bds_mrfss$DISPO,useNA="always") 
table(ca_bds_mrfss$F_SEX,useNA="always") #Should be 1-3. Not sure what 8 is. Assume all "U"

#Exclude the 45 samples from man made (1) and beach/bank mode (2). Keep just PC/PR
ca_bds_mrfss <- ca_bds_mrfss[which(ca_bds_mrfss$MODE_FX %in% c(6,7)),]

#Exclude the 1 sample from Mexico
ca_bds_mrfss <- ca_bds_mrfss[-which(ca_bds_mrfss$AREA == 6),]

#Exclude the 38 non Hook and Line gears
ca_bds_mrfss <- ca_bds_mrfss[-which(ca_bds_mrfss$GEAR != 1),]

#add length in cm based on fork length
ca_bds_mrfss$lengthcm <- ca_bds_mrfss$LNGTH/10

#Add shorter mode name
ca_bds_mrfss$mode = dplyr::case_when(ca_bds_mrfss$MODE_FX == 6 ~ "PC",
                                     ca_bds_mrfss$MODE_FX == 7 ~ "PR")

#Add sex (which is all unknown)
ca_bds_mrfss$sex = "U"

#Remove the 309 samples without any length provided
ca_bds_mrfss = ca_bds_mrfss[!is.na(ca_bds_mrfss$lengthcm),]

ca_bds_mrfss$state <- "C"
ca_bds_mrfss$source <- "mrfss"


##
#Plots for CA MRFSS lengths - These were done after the pre-assessment workshop
##

#Length - Maybe a little more PR in the 80s and PC in the 90s 
ggplot(dplyr::filter(ca_bds_mrfss, mode%in%c("PC","PR")), aes(fill=mode, x=YEAR)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of length samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())

#Lengths by mode - In contrast to recfin, PC tends to catch larger fish
ggplot(ca_bds_mrfss, aes(lengthcm, fill = mode, color = mode)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())

#Get average and sd lengths across years
agg_ca_mrfss <- ca_bds_mrfss %>% group_by(YEAR) %>% 
  summarise("avg"= mean(lengthcm), "sd" = sd(lengthcm), N = length(lengthcm))
agg_ca_mrfss$source <- "mrfss"
ggplot(agg_ca_mrfss, aes(x=YEAR, y=avg)) + 
  geom_errorbar(aes(ymin=avg-sd, ymax=avg+sd), width=.1, position = position_dodge(0.5)) +
  geom_line(position = position_dodge(0.5)) +
  geom_point(position = position_dodge(0.5))


################################
#Load historical California data, check for any issues
#This occurred after the pre-assessment data workshop
#################################

##
#CCRS data from 1977-1986
#This is the same data as in the lingcod_2021 folder (CCRS_LF_77-86.mdb)
##

#Only need to pull from googledrive once
# googledrive::drive_download(file = "CONFIDENTIAL_historical_CA/conf_CCRS.xlsx",
#                             path = file.path(git_dir,"data-raw","conf_CCRS.xlsx"))
ccrs_bds <- readxl::read_excel(path = file.path(git_dir,"data-raw","conf_CCRS.xlsx"),
                                   sheet = "Data")
ccrs_bds$YEAR <- as.numeric(ccrs_bds$Year) + 1900
table(ccrs_bds$Fish_Type) #1 = PC
table(ccrs_bds$Flag) #no idea what this is
ccrs_bds$mode <- "PC"
ccrs_bds$sex <- ccrs_bds$Sex
ccrs_bds[which(!ccrs_bds$sex %in% c("M","F")),]$sex <- "U"
ccrs_bds$lengthcm <- ccrs_bds$Length/10
ccrs_bds$state <- "C"


##
#Dockside data from the 50s-60s data from 1977-1986
#This is the same data as in the lingcod_2021 folder (FPB_LF_59-72 AND Skiff_LF_59-72)
##

#Only need to pull from googledrive once
# googledrive::drive_download(file = "CONFIDENTIAL_historical_CA/conf_California PRPC Dockside 1950s-60s.xlsx",
#                             path = file.path(git_dir,"data-raw","conf_California PRPC Dockside 1950s-60s.xlsx"))
dockside_bds_skiff <- readxl::read_excel(path = file.path(git_dir,"data-raw","conf_California PRPC Dockside 1950s-60s.xlsx"),
                               sheet = "PRLen")
dockside_bds_fpb <- readxl::read_excel(path = file.path(git_dir,"data-raw","conf_California PRPC Dockside 1950s-60s.xlsx"),
                                         sheet = "PCLen")
#can combine because Fish_Type separates these two
dockside_bds = rbind(dockside_bds_skiff, dockside_bds_fpb)

#These two datasets have length and count. Need to duplicate lengths by "count" times to get 
#full distribution of lengths. I did not do this for lingcod.
dockside_bds <- dockside_bds[rep(1:(dim(dockside_bds)[1]), dockside_bds$Count),]

#Update fields
dockside_bds$YEAR <- dockside_bds$Year + 1900
table(dockside_bds$Sex) #no information
table(dockside_bds$Fish_Type) #1 = PC, 3 = PR bottomfish, 4 = PR troll, 5 = PR bottomfish and troll
dockside_bds$mode <- dplyr::case_when(dockside_bds$Fish_Type %in% c(1,2) ~ "PC",
                                      dockside_bds$Fish_Type %in% c(3,4,5) ~ "PR")
dockside_bds$lengthcm <- dockside_bds$Length/10
dockside_bds$sex <- "U"
dockside_bds$state <- "C"

#CCRS Length - Mostly unsexed fish. I suggest just reading in as unsexed if used
#This really only adds about 3 years (1977-1979) and around 50 samples per year other than 1977. 
ggplot(ccrs_bds, aes(fill=sex, x=Year)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of length samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())

#CCRS Lengths by mode - Unsexed a little smaller. Male and Female are similar is the key.
ggplot(ccrs_bds, aes(lengthcm, fill = sex)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())

#Dockside Length - Lots of samples but few years
ggplot(dockside_bds, aes(fill=mode, x=Year)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of length samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())

#Dockside Lengths by mode - Similar to mrfss with PC catching larger fish
ggplot(dockside_bds, aes(lengthcm, fill = mode)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())

#Get average and sd lengths across years
agg_ccrs <- ccrs_bds %>% filter(!is.na(lengthcm)) %>% group_by(YEAR) %>% 
  summarise("avg"= mean(lengthcm), "sd" = sd(lengthcm), N = length(lengthcm))
agg_ccrs$source = "ccrs"
agg_dockside <- dockside_bds %>% filter(!is.na(lengthcm)) %>% group_by(YEAR) %>% 
  summarise("avg"= mean(lengthcm), "sd" = sd(lengthcm), N = length(lengthcm))
agg_dockside$source = "dockside"


##
#Other historical data from access files. 
#Data in southern california come from Crooke and Alley
#Didn't think south of Pt. Conception would be relevant but there are
#some samples of canary in these data
#
#Data in north/central california come from Deb Wilson-Vandenberg
##

oldCA_access <- utils::read.csv(file.path(git_dir,"data-raw","CA_rec_historical_length_accessFiles.csv"), header = T)
oldCA_access$state = "C"

#Length - Lots of debWV samples
ggplot(oldCA_access, aes(fill=source, x=YEAR)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of length samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())

#Length distributions are odd
ggplot(oldCA_access, aes(lengthcm, fill = source)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())

#Get average and sd lengths across years
agg_access <- oldCA_access %>% filter(!is.na(lengthcm)) %>% group_by(YEAR, source) %>% 
  summarise("avg"= mean(lengthcm), "sd" = sd(lengthcm), N = length(lengthcm))


##
#Combine historical averages and sd across all older CA datasets
##

agg_oldCA <- rbind(agg_ca_mrfss, agg_ccrs, agg_dockside, agg_access[,c("YEAR","avg","sd","N","source")]) %>% arrange(YEAR)

#Exclude southern CA data when plotting average length 
ggplot(agg_oldCA %>% filter(source %in% c("ccrs", "dockside", "mrfss")), aes(x=YEAR, y=avg, color = source)) + 
  geom_errorbar(aes(ymin=avg-sd, ymax=avg+sd), width=.1, position = position_dodge(0.5)) +
  geom_line(position = position_dodge(0.5)) +
  geom_point(position = position_dodge(0.5)) +
  xlab("Year") +
  ylab("Mean length +/- one sd")
ggsave(file.path(git_dir,"data_explore_figs","CA_historical_recLen_comparison_noDebWV.png"),
       width = 6, height = 8)

#Exclude southern CA data when plotting average length 
ggplot(agg_oldCA %>% filter(source %in% c("mrfss", "debWV")), aes(x=YEAR, y=avg, color = source)) + 
  geom_errorbar(aes(ymin=avg-sd, ymax=avg+sd), width=.1, position = position_dodge(0.5)) +
  geom_line(position = position_dodge(0.5)) +
  geom_point(position = position_dodge(0.5)) +
  xlab("Year") +
  ylab("Mean length +/- one sd")
ggsave(file.path(git_dir,"data_explore_figs","CA_historical_recLen_comparison_withDebWV.png"),
       width = 6, height = 8)

#Length densities are very similar between mrfss and debwv
ggplot(rbind(ca_bds_mrfss[,c("YEAR","source","lengthcm")],
             oldCA_access[oldCA_access$source == "debWV",c("YEAR","source","lengthcm")]),
       aes(lengthcm, fill = source)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_explore_figs","CA_lengths_comparison_MRFSS_DebWV.png"),
       width = 6, height = 8)

#Show sample sizes of ALL data
ggplot(agg_oldCA, aes(x=YEAR, y=N, fill=source)) +
  geom_col()
oldCA_sampleSizes <- agg_oldCA %>% select(c(YEAR,N,source)) %>% 
  pivot_wider(names_from = c(source), values_from = N) %>%
  data.frame()
write.csv(oldCA_sampleSizes, file.path(git_dir,"data","canary_CAhistorical_recLength_samples.csv"), row.names=F)
            



