##################################################################################################
#
#	PacFIN Data Exploration for Canary Rockfish
# 		
#		Written by Brian Langseth
#
##################################################################################################

#devtools::install_github("nwfsc-assess/PacFIN.Utilities")
library(PacFIN.Utilities)
library(ggplot2)
library(tidyr)
library(dplyr)


dir = "//nwcfile/FRAM/Assessments/Assessment Data/2023 Assessment Cycle/canary rockfish/PacFIN data"

#User directories
if(Sys.getenv("USERNAME") == "Brian.Langseth") {
  git_dir <- "U:/Stock assessments/canary_2023/"
}

################################
#Load PacFIN BDS data, check for any issues
################################
load(file.path(dir, "PacFIN.CNRY.bds.01.Sep.2022.RData"))
pacfin = bds.pacfin

# # Load in the current weight-at-length estimates by sex
# fa = ma = ua = 1.963e-5
# fb = mb = ub = 3.016
# 
# # Read in the PacFIN catch data to base expansion on
# catch.file = read.csv(file.path(dir, "output catch", "pacfin_catch_by_area_Feb2021.csv"))
# colnames(catch.file) = c("Year", "CA", "OR", "WA")

#Assign a new field with lengths in cm - unk are cm's
table(pacfin$FISH_LENGTH_UNITS, pacfin$AGENCY_CODE)
pacfin$fish_lengthcm <- pacfin$FISH_LENGTH
mmlen <- which(pacfin$FISH_LENGTH_UNITS=="MM")
pacfin[mmlen,"fish_lengthcm"] <- pacfin[mmlen,"FISH_LENGTH"]/10

#Fork Length - assume unknown is fork length
#remove the 2 standard length values (though these are in 2022 so may be updated)
table(pacfin$AGENCY_CODE, pacfin$FISH_LENGTH_TYPE_DESC)
pacfin <- pacfin[which(pacfin$FISH_LENGTH_TYPE_CODE != "S"),]

#Assign NA sex to unknown
pacfin$SEX_CODE <- case_when(is.na(pacfin$SEX_CODE) ~ "U", TRUE ~ pacfin$SEX_CODE)


############################################################################################
#	Quickly look at the commercial and recreational samples by gear to see the amount of 
#  data for each and if there looks to be different selectivity by gear type
############################################################################################

pacfin$fleet[pacfin$PACFIN_GEAR_CODE %in% c("BMT","DNT","FFT","FTS","GFL","GFS","GFT","MDT","OTW","RLT","TWL","BTT")] <- "TWL"
pacfin$fleet[pacfin$PACFIN_GEAR_CODE %in% c("MDT","MPT")] <- "MID"
pacfin$fleet[pacfin$PACFIN_GEAR_CODE %in% c("DST","SHT","SST")] <- "TWS"
pacfin$fleet[pacfin$PACFIN_GEAR_CODE %in% c("JIG","LGL","OHL","POL","VHL","HKL")] <- "HKL"
pacfin$fleet[pacfin$PACFIN_GEAR_CODE %in% c("DGN","DPN","GLN","SEN","STN")] <- "NET"
pacfin$fleet[pacfin$PACFIN_GEAR_CODE %in% c("CLP","CPT","FPT","OPT","PRW")] <- "POT"
pacfin$fleet[pacfin$PACFIN_GEAR_CODE %in% c("BTR", "DVG", "TRL","USP","OTH")] <- "OTH"

pacfin$fleet.comb <- NA
pacfin$fleet.comb[pacfin$fleet %in% c("HKL", "NET", "OTH", "POT")] <- "NTWL"
pacfin$fleet.comb[pacfin$fleet %in% c("TWL","MID","TWS")] <- "TWL"

##
#Samples by year
##

#Length and age samples by year
Nlen <- pacfin %>% filter(.,!is.na(FISH_LENGTH)) %>%
  group_by(fleet.comb, AGENCY_CODE, SAMPLE_YEAR) %>% summarize(N = length(FISH_LENGTH)) %>%
  pivot_wider(names_from = c(fleet.comb,AGENCY_CODE), names_sep = ".", values_from = N) %>% 
  arrange(SAMPLE_YEAR)

Nage <- pacfin %>% filter(.,!is.na(FINAL_FISH_AGE_IN_YEARS)) %>%
  group_by(fleet.comb, AGENCY_CODE, SAMPLE_YEAR) %>% summarize(N = length(FINAL_FISH_AGE_IN_YEARS)) %>%
  pivot_wider(names_from = c(fleet.comb,AGENCY_CODE), names_sep = ".", values_from = N) %>% 
  arrange(SAMPLE_YEAR)

##
#Upload sample sizes to googledrive
#If want to update set overwrite to TRUE
##
xx <- googledrive::drive_create(name = 'pacfin_bds_N',
                                path = 'https://drive.google.com/drive/folders/1fleYIaLvdIYMLv14--P1804akQvnWu5J', 
                                type = 'spreadsheet', overwrite = FALSE)
googlesheets4::sheet_write(Nlen, ss = xx, sheet = "Nlen")
googlesheets4::sheet_write(Nage, ss = xx, sheet = "Nage")
googlesheets4::sheet_delete(ss = xx, sheet = "Sheet1")


############################################################################################
#Plots
############################################################################################

lab_val = c("California", "Oregon", "Washington")
names(lab_val) = c("C","O","W")


##
#Sample size plots
##

#Length
ggplot(filter(pacfin,!is.na(FISH_LENGTH)), aes(fill=fleet.comb, x=SAMPLE_YEAR)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("AGENCY_CODE", ncol=1, labeller = labeller(AGENCY_CODE = lab_val)) +
  xlab("Year") +
  ylab("# of length samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","com_lenN_fleetGroup.png"),
       width = 6, height = 8)

ggplot(filter(pacfin,!is.na(FISH_LENGTH)), aes(fill = fleet, x=SAMPLE_YEAR)) + 
  geom_bar(aes(fill = fleet), position="stack", stat="count") +
  facet_wrap("AGENCY_CODE",ncol=1, labeller = labeller(AGENCY_CODE = lab_val)) +
  xlab("Year") +
  ylab("# of length samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","com_lenN_fleet.png"),
       width = 6, height = 8)

#Age
ggplot(filter(pacfin,!is.na(FINAL_FISH_AGE_IN_YEARS)), aes(fill=fleet.comb, x=SAMPLE_YEAR)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap("AGENCY_CODE",ncol=1, labeller = labeller(AGENCY_CODE = lab_val)) + 
  xlab("Year") +
  ylab("# of age samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","com_ageN_fleetGroup.png"),
       width = 6, height = 8)

ggplot(filter(pacfin,!is.na(FINAL_FISH_AGE_IN_YEARS)), aes(fill=fleet, x=SAMPLE_YEAR)) + 
  geom_bar(position="stack", stat="count") +
  facet_wrap(c("AGENCY_CODE"),ncol=1, labeller = labeller(AGENCY_CODE = lab_val)) + 
  xlab("Year") +
  ylab("# of age samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","com_ageN_fleet.png"),
       width = 6, height = 8)


##
#Distributions
##

#Lengths
ggplot(pacfin, aes(fish_lengthcm, fill = fleet.comb, color = fleet.comb)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("AGENCY_CODE", ncol=1, labeller = labeller(AGENCY_CODE = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","com_lenDensity_fleetGroup.png"),
       width = 6, height = 8)

ggplot(pacfin, aes(fish_lengthcm, fill = fleet, color = fleet)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("AGENCY_CODE", ncol=1, labeller = labeller(AGENCY_CODE = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","com_lenDensity_fleet.png"),
       width = 6, height = 8)

# #by sex - not very informative
# ggplot(pacfin, aes(fish_lengthcm, fill = SEX_CODE, color = SEX_CODE)) +
#   geom_density(alpha = 0.4, lwd = 0.8, adjust = 1.5) +
#   facet_wrap(c("AGENCY_CODE","fleet.comb"), ncol=2, labeller = labeller(AGENCY_CODE = lab_val)) + 
#   xlab("Fish Length (cm)") +
#   ylab("Proportion") + 
#   theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
# #Check sample sizes
# #Oregon has very few (72) U as does Washington NTWL (7). California has mostly U 
# table(pacfin$AGENCY_CODE,pacfin$fleet.comb,pacfin$SEX_CODE)
# ggsave(file.path(git_dir,"data_workshop_figs","com_lenDensity_fleetSex.png"),
#        width = 6, height = 6)

# #by depth - not very informative
# ggplot(pacfin, aes(y = fish_lengthcm, x = DEPTH_AVERAGE_FATHOMS, color = SEX_CODE)) +
#   geom_point(size = 1, shape = 1, alpha = 0.5) +
#   facet_wrap(c("AGENCY_CODE","fleet.comb"), ncol=2, labeller = labeller(AGENCY_CODE = lab_val)) +
#   xlab("Depth average (fathoms)") +
#   ylab("Fish length (cm)") +
#   theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
# ggsave(file.path(git_dir,"data_workshop_figs","com_len_by_depth.png"),
#        width = 6, height = 6)


#Ages
ggplot(pacfin, aes(FINAL_FISH_AGE_IN_YEARS, fill = fleet.comb, color = fleet.comb)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("AGENCY_CODE", ncol=1, labeller = labeller(AGENCY_CODE = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","com_ageDensity_fleetGroup.png"),
       width = 6, height = 8)

ggplot(pacfin, aes(FINAL_FISH_AGE_IN_YEARS, fill = fleet, color = fleet)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("AGENCY_CODE", ncol=1, labeller = labeller(AGENCY_CODE = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","com_ageDensity_fleet.png"),
       width = 6, height = 8)

#Age over time
#very big difference between surface and break and burn sample reads
pacfin$surface = NA
pacfin[pacfin$AGE_METHOD1%in%c("1","B","BB"),"surface"]="N"
pacfin[pacfin$AGE_METHOD1%in%c("2","S"),"surface"]="Y"
pacfin[pacfin$AGE_METHOD2%in%c("1","B","BB"),"surface"]="N"
pacfin[pacfin$AGE_METHOD3%in%c("1","B","BB"),"surface"]="N"
ggplot(filter(pacfin,!is.na(FINAL_FISH_AGE_IN_YEARS)), aes(y=FINAL_FISH_AGE_IN_YEARS, x=factor(SAMPLE_YEAR), color = surface)) + 
  geom_violin(trim="FALSE") +
  stat_summary(fun.y=median, geom="point", shape=18, size=3, color="blue") + 
  facet_wrap("SEX_CODE") +
  scale_color_manual(values=c("#00BFC4","#F8766D")) + 
  scale_x_discrete(breaks=c("1975","1985","1995","2005","2015","2025")) + 
  xlab("Year") +
  ylab("Age") 
ggsave(file.path(git_dir,"data_workshop_figs","com_age_year_by_read.png"),
       width = 8, height = 4)

# #with less differences in length and actually generally larger fish by length for surface reads
# ggplot(filter(pacfin,!is.na(FINAL_FISH_AGE_IN_YEARS)), aes(y=fish_lengthcm, x=factor(SAMPLE_YEAR), color = surface)) + 
#   geom_violin(trim="FALSE") +
#   stat_summary(fun.y=median, geom="point", shape=18, size=3, color="blue") + 
#   facet_wrap("SEX_CODE") +
#   scale_color_manual(values=c("#00BFC4","#F8766D")) + 
#   scale_x_discrete(breaks=c("1975","1985","1995","2005","2015","2025")) + 
#   xlab("Year") +
#   ylab("Length (cm)") 
# ggsave(file.path(git_dir,"data_workshop_figs","com_len_year_by_read.png"),
#        width = 8, height = 4)

# #by sex - not very informative
# ggplot(pacfin, aes(FINAL_FISH_AGE_IN_YEARS, fill = SEX_CODE, color = SEX_CODE)) +
#   geom_density(alpha = 0.4, lwd = 0.8, adjust = 1.5) +
#   facet_wrap(c("AGENCY_CODE","fleet.comb"), ncol=2, labeller = labeller(AGENCY_CODE = lab_val)) +
#   xlab("Fish Length (cm)") +
#   ylab("Proportion") +
#   theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
# #Check sample sizes - altogether very few U
# table(pacfin$AGENCY_CODE,pacfin$fleet.comb,pacfin$SEX_CODE,is.na(pacfin$FINAL_FISH_AGE_IN_YEARS))
# ggsave(file.path(git_dir,"data_workshop_figs","com_ageDensity_fleetSex.png"),
#        width = 6, height = 6)

# #by depth - not very informative
# ggplot(pacfin, aes(y = FINAL_FISH_AGE_IN_YEARS, x = DEPTH_AVERAGE_FATHOMS, color = SEX_CODE)) +
#   geom_point(size = 1, shape = 1, alpha = 0.5) +
#   facet_wrap(c("AGENCY_CODE","fleet.comb"), ncol=2, labeller = labeller(AGENCY_CODE = lab_val)) +
#   xlab("Depth average (fathoms)") +
#   ylab("Fish age") +
#   theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
# ggsave(file.path(git_dir,"data_workshop_figs","com_age_by_depth.png"),
#      width = 6, height = 6)


############################################################################################
#Explorations
############################################################################################
##
#Aging methods - see issue #11 in github
##

#looking at the ones with ages (e.g. ', ,  = FALSE')
table(pacfin$AGE_METHOD1,pacfin$AGENCY_CODE,is.na(pacfin$FINAL_FISH_AGE_IN_YEARS),useNA="always")
#The NA values in WA appear to be during years were break and burn
table(pacfin$SAMPLE_YEAR,pacfin$AGE_METHOD1,pacfin$AGENCY_CODE,is.na(pacfin$FINAL_FISH_AGE_IN_YEARS),useNA="always")

#Ages by ageing method - Only relevant for Oregon and Washington TWL gear
ggplot(filter(pacfin,AGENCY_CODE!="C" & fleet.comb=="TWL"), aes(FINAL_FISH_AGE_IN_YEARS, fill = AGE_METHOD1, color = AGE_METHOD1)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap(c("AGENCY_CODE","fleet.comb")) +
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())


#There are also a few samples with an ageing method1 but no FINAL_FISH_AGE_IN_YEARS
#These are samples with other age reads but no final age read
#WHAT TO DO WITH THESE?????
head(pacfin[which(is.na(pacfin$FINAL_FISH_AGE_IN_YEARS) & !is.na(pacfin$age1)),])


##
#Sampling type
##
table(pacfin$AGENCY_CODE,pacfin$SAMPLE_TYPE_DESC)
#WHAT TO DO WITH SPECIAL_REQUEST DATA???


##
#Condition - very few sampled 'alive' so ignore for commercial
##
table(pacfin$AGENCY_CODE,pacfin$PACFIN_CONDITION_CODE)
