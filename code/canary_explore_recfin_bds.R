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

#Remove 8 samples with NA lengths 
bds = bds[!is.na(bds$RECFIN_LENGTH_MM),]
#Exclude two samples with weird MM measurements and two samples with 0 length
bds = bds[-which(bds$RECFIN_LENGTH_MM<100),]
#Add cm field
bds$lengthcm = bds$RECFIN_LENGTH_MM/10

#Assign NA, "", FALSE, and U sex to unknown sex code
bds$sex <- dplyr::case_when(bds$RECFIN_SEX_CODE %in% c("U","","FALSE") ~ "U",
                            is.na(bds$RECFIN_SEX_CODE) ~ "U",
                            TRUE ~ bds$RECFIN_SEX_CODE)

#Add shorter state name
bds$state = dplyr::case_when(bds$STATE_NAME == "CALIFORNIA" ~ "C",
                             bds$STATE_NAME == "OREGON" ~ "O",
                             bds$STATE_NAME == "WASHINGTON" ~ "W")
#Add shorter mode name
bds$mode = dplyr::case_when(bds$RECFIN_MODE_NAME == "PARTY/CHARTER BOATS" ~ "PC",
                             bds$RECFIN_MODE_NAME == "PRIVATE/RENTAL BOATS" ~ "PR",
                             bds$RECFIN_MODE_NAME == "NOT KNOWN" ~ "Unk")

##
#Samples by year
##

#Length and age samples by year
Nlen <- bds %>% group_by(mode, state, RECFIN_YEAR) %>% 
  summarize(N = length(lengthcm)) %>%
  pivot_wider(names_from = c(state,mode), names_sep = ".", values_from = N, 
              names_glue = "{state}_{mode}_{.value}", names_sort = TRUE, ) %>% 
  arrange(RECFIN_YEAR)


################################
#AGE - Load RecFIN age BDS data, check for any issues
################################

bdsage = read.csv(file.path(dir, "conf_RecFIN_SD506_canary_1993_2021.csv"),header=TRUE)

#Add shorter state name
bdsage$state = dplyr::case_when(bdsage$SAMPLING_AGENCY_NAME == "ODFW" ~ "O",
                                bdsage$SAMPLING_AGENCY_NAME == "WDFW" ~ "W")

#Add shorter mode name
bdsage$mode = dplyr::case_when(bdsage$RECFIN_MODE_NAME == "PARTY/CHARTER BOATS" ~ "PC",
                            bdsage$RECFIN_MODE_NAME == "PRIVATE/RENTAL BOATS" ~ "PR",
                            bdsage$RECFIN_MODE_NAME == "NOT KNOWN" ~ "Unk")



Nage <- NA 

# ##
# #Upload sample sizes to googledrive
# ##
# xx <- googledrive::drive_create(name = 'pacfin_bds_N',
#                                 path = 'https://drive.google.com/drive/folders/1fleYIaLvdIYMLv14--P1804akQvnWu5J', 
#                                 type = 'spreadsheet', overwrite = TRUE)
# googlesheets4::sheet_write(Nlen, ss = xx, sheet = "Nlen")
# googlesheets4::sheet_write(Nage, ss = xx, sheet = "Nage")
# googlesheets4::sheet_delete(ss = xx, sheet = "Sheet1")


############################################################################################
#Plots
############################################################################################

lab_val = c("California", "Oregon", "Washington")
names(lab_val) = c("C","O","W")


##
#Sample size plots
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

table(bds$sex,bds$state)
ggplot(filter(bds,mode%in%c("PC","PR")), aes(fill=sex, x=RECFIN_YEAR)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of length samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenN_sex.png"),
       width = 6, height = 8)

ggplot(filter(bds,mode%in%c("PC","PR")), aes(fill=IS_RETAINED, x=RECFIN_YEAR)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of length samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenN_retained.png"),
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
#Distributions
##

#Lengths by mode - pretty similar
ggplot(filter(bds,mode%in%c("PC","PR")), aes(lengthcm, fill = mode, color = mode)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenDensity_mode.png"),
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

table(bds$IS_RETAINED,bds$mode,bds$state)
ggplot(filter(bds,mode%in%c("PC","PR")), aes(lengthcm, fill = IS_RETAINED, color = IS_RETAINED)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_lenDensity_retained.png"),
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














