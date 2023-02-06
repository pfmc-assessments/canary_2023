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

bdsWA = read.csv(file.path(dir, "RecFIN_SD001_WA_canary_1983_2021.csv"),header=TRUE)
bdsOR = read.csv(file.path(dir, "RecFIN_SD001_OR_canary_1999_2021.csv"),header=TRUE)
bdsCA = read.csv(file.path(dir, "RecFIN_SD001_CA_canary_2003_2021.csv"),header=TRUE)
bds = rbind(bdsWA,bdsOR,bdsCA)

table(bds$AGENCY_LENGTH_UNITS,useNA="always")
table(bds$RECFIN_SEX_CODE,bds$STATE_NAME,useNA="always") #going to be mostly unsexed
table(bds$RECFIN_LENGTH_MM,useNA="always")
table(bds$RECFIN_IMPUTED_LENGTH,useNA="always")
table(bds$AGENCY_WATER_AREA_NAME,bds$STATE_NAME,useNA="always")
table(bds$IS_AGENCY_LENGTH_WITHIN_MAX,useNA="always")
table(bds$RECFIN_MODE_NAME,useNA="always")
table(bds$IS_RETAINED,bds$STATE_NAME,useNA="always")

#Remove 8 samples with NA lengths 
bds = bds[!is.na(bds$RECFIN_LENGTH_MM),]
#Exclude two samples with weird MM measurements and two samples with 0 length
bds = bds[-which(bds$RECFIN_LENGTH_MM<100),]
#Add cm field
bds$lengthcm = bds$RECFIN_LENGTH_MM/10

#Exclude 16 inland and 24 estuary fish
bds <- bds[-which(bds$AGENCY_WATER_AREA_NAME %in% c("ESTUARY","IN")),]

#Assign NA, "", FALSE, and U sex to unknown sex code
bds$sex <- dplyr::case_when(bds$RECFIN_SEX_CODE %in% c("U","","FALSE") ~ "U",
                            is.na(bds$RECFIN_SEX_CODE) ~ "U",
                            TRUE ~ bds$RECFIN_SEX_CODE)

#Add shorter state name
bds$state <- dplyr::case_when(bds$STATE_NAME == "CALIFORNIA" ~ "C",
                             bds$STATE_NAME == "OREGON" ~ "O",
                             bds$STATE_NAME == "WASHINGTON" ~ "W")
#Add shorter mode name
bds$mode <- dplyr::case_when(bds$RECFIN_MODE_NAME == "PARTY/CHARTER BOATS" ~ "PC",
                             bds$RECFIN_MODE_NAME == "PRIVATE/RENTAL BOATS" ~ "PR",
                             bds$RECFIN_MODE_NAME == "NOT KNOWN" ~ "Unk")

#Exclude "released" fish
bds_rel <- bds[bds$IS_RETAINED == "RELEASED",]
bds <- bds[bds$IS_RETAINED == "RETAINED",]


##
#Samples by year
##

#Length samples by year
Nlen <- bds %>% group_by(mode, state, RECFIN_YEAR) %>% 
  summarize(N = length(lengthcm)) %>%
  pivot_wider(names_from = c(state,mode), names_sep = ".", values_from = N, 
              names_glue = "{state}_{mode}_{.value}", names_sort = TRUE, ) %>% 
  arrange(RECFIN_YEAR)


################################
#AGE - Load RecFIN age BDS data, check for any issues
################################

bdsage = read.csv(file.path(dir, "conf_RecFIN_SD506_canary_1993_2021.csv"),header=TRUE)

table(bdsage$USE_THIS_AGE,useNA="always")
table(bdsage$RECFIN_SEX_CODE,bdsage$SAMPLING_AGENCY_NAME,useNA="always") #going to be mostly unsexed
table(bdsage$NUMBER_OF_READS,useNA="always")
table(bdsage$RECFIN_AGEING_METHOD_DESC,useNA="always")

#Add shorter state name
bdsage$state = dplyr::case_when(bdsage$SAMPLING_AGENCY_NAME == "ODFW" ~ "O",
                                bdsage$SAMPLING_AGENCY_NAME == "WDFW" ~ "W")

#Add shorter mode name
bdsage$mode = dplyr::case_when(bdsage$RECFIN_MODE_NAME == "PARTY/CHARTER BOATS" ~ "PC",
                            bdsage$RECFIN_MODE_NAME == "PRIVATE/RENTAL BOATS" ~ "PR",
                            bdsage$RECFIN_MODE_NAME == "NOT KNOWN" ~ "Unk")

#Age samples by year
Nage <- bdsage %>% filter(., !is.na(USE_THIS_AGE)) %>% group_by(mode, state, SAMPLE_YEAR) %>% 
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
#There are samples in both datasets in 2001-2003. Per Ali, 
#these are separate samples so they can be combined
##

or_bds <- rbind(or_bds_mrfss[,c("Year","mode","lengthcm","sex")],or_bds_recfin[,c("Year","mode","lengthcm","sex")])
or_bds$state <- "O"

############################################################################################
#Plots
############################################################################################

lab_val = c("California", "Oregon", "Washington")
names(lab_val) = c("C","O","W")


##
#Sample size plots for RecFIN pull
##

#Length
ggplot(filter(bds,mode%in%c("PC","PR")), aes(fill=mode, x=RECFIN_YEAR)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of length samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenN_mode.png"),
       width = 6, height = 8)

ggplot(filter(bds,mode%in%c("PC","PR")), aes(x=RECFIN_YEAR)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of length samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenN.png"),
       width = 6, height = 8)

table(bds$sex,bds$state)
ggplot(filter(bds,mode%in%c("PC","PR")), aes(fill=sex, x=RECFIN_YEAR)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of length samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenN_sex.png"),
       width = 6, height = 8)

bds_all <- rbind(bds,bds_rel)
ggplot(filter(bds_all,mode%in%c("PC","PR")), aes(fill=IS_RETAINED, x=RECFIN_YEAR)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of length samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenN_retained.png"),
       width = 6, height = 8)

bds_all <- rbind(bds,bds_rel)
ggplot(filter(bds_all,mode%in%c("PC","PR")), aes(fill=IS_RETAINED, x=RECFIN_YEAR)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap(c("state","mode"), ncol=2, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of length samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenN_retained_mode.png"),
       width = 6, height = 8)


#Age
ggplot(filter(bdsage,!is.na(USE_THIS_AGE) & mode%in%c("PC","PR")), aes(fill=mode, x=SAMPLE_YEAR)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of age samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_ageN_mode.png"),
       width = 6, height = 8)

ggplot(filter(bdsage,!is.na(USE_THIS_AGE) & mode%in%c("PC","PR")), aes(x=SAMPLE_YEAR)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of age samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_ageN.png"),
       width = 6, height = 8)

table(bdsage$RECFIN_SEX_CODE,bdsage$state,is.na(bdsage$USE_THIS_AGE))
ggplot(filter(bdsage,!is.na(USE_THIS_AGE) & mode%in%c("PC","PR")), aes(fill=RECFIN_SEX_CODE, x=SAMPLE_YEAR)) + 
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
ggplot(filter(bds,mode%in%c("PC","PR")), aes(lengthcm, fill = mode, color = mode)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenDensity_mode.png"),
       width = 6, height = 8)

bds_all <- rbind(bds,bds_rel) #if including released fish
ggplot(filter(bds_all,mode%in%c("PC","PR")), aes(lengthcm, fill = mode, color = mode)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenDensity_mode_withreleased.png"),
       width = 6, height = 8)

#Lengths by retention
bds_all <- rbind(bds,bds_rel)
table(bds_all$RECFIN_YEAR, bds_all$mode, bds_all$IS_RETAINED)
ggplot(filter(bds_all,mode%in%c("PC", "PR")), aes(lengthcm, fill = IS_RETAINED, color = IS_RETAINED)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenDensity_retained.png"),
       width = 6, height = 8)

#Lengths by retention - only in years (>=2003) and modes (PC) where each exists
bds_all <- rbind(bds,bds_rel)
table(bds_all$RECFIN_YEAR, bds_all$mode, bds_all$IS_RETAINED)
ggplot(filter(bds_all,mode%in%c("PC") & RECFIN_YEAR >= 2003), aes(lengthcm, fill = IS_RETAINED, color = IS_RETAINED)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenDensity_retained_PC2003.png"),
       width = 6, height = 8)

#Lengths by retention - only in years dominated by releases (CA 2009-2016 and OR 2004-2014)
bds_all <- rbind(bds,bds_rel)
table(bds_all$RECFIN_YEAR, bds_all$mode, bds_all$IS_RETAINED)
bds_all_CAshort <- filter(bds_all, mode%in%c("PC","PR") & RECFIN_YEAR %in% c(2009:2016) & state == "C")
bds_all_ORshort <- filter(bds_all, mode%in%c("PC","PR") & RECFIN_YEAR %in% c(2004:2014) & state == "O")
bds_all_WA <- filter(bds_all, mode%in%c("PC","PR") & state == "W")
bds_all_short <- rbind(bds_all_CAshort, bds_all_ORshort, bds_all_WA)
ggplot(bds_all_short, aes(lengthcm, fill = IS_RETAINED, color = IS_RETAINED)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenDensity_retained_WA_CA09-16_OR04-14.png"),
       width = 6, height = 8)

#Lengths by sex - pretty similar
ggplot(filter(bds,mode%in%c("PC","PR")), aes(lengthcm, fill = sex, color = sex)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenDensity_sex.png"),
       width = 6, height = 8)

#Ages by mode - pretty similar
ggplot(filter(bdsage,mode%in%c("PC","PR")), aes(USE_THIS_AGE, fill = mode, color = mode)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) + 
  xlab("Fish Age") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_ageDensity_mode.png"),
       width = 6, height = 8)

#Ages by sex - pretty similar
ggplot(filter(bdsage,mode%in%c("PC","PR")), aes(USE_THIS_AGE, fill = RECFIN_SEX_CODE, color = RECFIN_SEX_CODE)) +
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









