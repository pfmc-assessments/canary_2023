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

#Assign a new field with lengths in cm 
table(pacfin$FISH_LENGTH_UNITS, pacfin$AGENCY_CODE)
pacfin$fish_lengthcm <- pacfin$FISH_LENGTH
mmlen <- which(pacfin$FISH_LENGTH_UNITS=="MM")
pacfin[mmlen,"fish_lengthcm"] <- pacfin[mmlen,"FISH_LENGTH"]/10

#Fork Length - assume unknown is fork length
#remove the 2 standard length values
table(pacfin$AGENCY_CODE, pacfin$FISH_LENGTH_TYPE_DESC)
pacfin <- pacfin[which(pacfin$FISH_LENGTH_TYPE_CODE != "S"),]


############################################################################################
#	Quickly look at the commercial and recreational samples by gear to see if the amount of data for each
#   and if there looks to be different selectivity by gear type
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

#Length samples by year
Nlen <- pacfin %>% 
  group_by(fleet.comb, AGENCY_CODE, SAMPLE_YEAR) %>% summarize(N = length(FISH_LENGTH)) %>%
  pivot_wider(names_from = c(fleet.comb,AGENCY_CODE), names_sep = ".", values_from = N) %>% 
  arrange(SAMPLE_YEAR)

lab_val = c("California", "Oregon", "Washington")
names(lab_val) = c("C","O","W")

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

#Age samples by year
Nage <- pacfin %>% 
  group_by(fleet.comb, AGENCY_CODE, SAMPLE_YEAR) %>% summarize(N = length(FINAL_FISH_AGE_IN_YEARS)) %>%
  pivot_wider(names_from = c(fleet.comb,AGENCY_CODE), names_sep = ".", values_from = N) %>% 
  arrange(SAMPLE_YEAR)

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
  facet_wrap(c("AGENCY_CODE",ncol=1, labeller = labeller(AGENCY_CODE = lab_val)) + 
  xlab("Year") +
  ylab("# of age samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","com_ageN_fleet.png"),
       width = 6, height = 8)


##
#Plot distributions
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

#Lengths by sex

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

#Ages by sex
