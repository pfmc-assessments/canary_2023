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
#                                 path = 'https://drive.google.com/drive/folders/1fleYIaLvdIYMLv14--P1804akQvnWu5J',
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
#filtering for “measured” fish."

#NOTE: I have not filtered based on whether fish are measured or not

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

#Remove samples with lengths based on weight to length conversions (16 with measured weight and 2 with computed weight)
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






