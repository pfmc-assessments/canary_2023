##################################################################################################
#
#	PacFIN Data Exploration for Canary Rockfish
# 		
#		Written by Brian Langseth
#
##################################################################################################

#devtools::install_github("pfmc-assessments/PacFIN.Utilities")
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
pacfin <- bds.pacfin

# pacfin2 <- cleanPacFIN(Pdata=pacfin,CLEAN=TRUE,verbose=TRUE)
# N SAMPLE_TYPEs changed from M to S for special samples from OR: 0
# N not in keep_sample_type (SAMPLE_TYPE): 9108
# N with SAMPLE_TYPE of NA: 0
# N not in keep_sample_method (SAMPLE_METHOD): 199
# N with SAMPLE_NO of NA: 0
# N without length: 148
# N without Age: 61600
# N without length and Age: 61614
# N sample weights not available for OR: 584
# N records: 133621
# N remaining if CLEAN: 115486
# N removed if CLEAN: 18135

#cleanPacFIN removes:
#9108 samples from special request data (from Oregon) and commercial on-board samples (from Washington)
#199 samples with purposive sample (from Washington)
#8830 samples from non-US areas 1412-5A, 1726-5B, 15-4A, and 5677-3D
#Total is 18135 (because 2 of the Commercial on-board samples were in area 4A)

#Assign a new field with lengths in cm - unk are cm's
table(pacfin$FISH_LENGTH_UNITS, pacfin$AGENCY_CODE)
pacfin$fish_lengthcm <- pacfin$FISH_LENGTH
mmlen <- which(pacfin$FISH_LENGTH_UNITS=="MM")
pacfin[mmlen,"fish_lengthcm"] <- pacfin[mmlen,"FISH_LENGTH"]/10

#Fork Length - assume unknown is fork length
#remove the 2 standard length values (though these are in 2022 so may be updated)
#also removes samples without lengths
table(pacfin$AGENCY_CODE, pacfin$FISH_LENGTH_TYPE_DESC)
pacfin <- pacfin[which(pacfin$FISH_LENGTH_TYPE_CODE != "S"),]

#Assign NA sex to unknown
pacfin$SEX_CODE <- dplyr::case_when(is.na(pacfin$SEX_CODE) ~ "U", TRUE ~ pacfin$SEX_CODE)

##
#Incorporate the changes from cleanPacFIN but 
#keep existing approach for the pre-assessment workshop
##
pacfin_preclean <- pacfin #keep uncleaned version
#Use market type - California samples are assumed to be market type
#Keep oregon special project data before 1986
pacfin_othertype <- pacfin[pacfin$SAMPLE_TYPE %in% c("C","S"),]
pacfin_OSPkeep <- pacfin[pacfin$SAMPLE_TYPE %in% c("S") & pacfin$SAMPLE_YEAR<=1986,]
pacfin <- pacfin[!pacfin$SAMPLE_TYPE %in% c("C","S"),]
pacfin <- rbind(pacfin,pacfin_OSPkeep)
#Use random samples
pacfin_othermethod <- pacfin[pacfin$SAMPLE_METHOD_CODE %in% c("P"),]
pacfin <- pacfin[pacfin$SAMPLE_METHOD_CODE=="R",]
#Exclude non US samples
pacfin_otherareas <- pacfin[pacfin$PSMFC_CATCH_AREA_CODE %in% c("5A","5B","4A","3D"),]
pacfin <- pacfin[!pacfin$PSMFC_CATCH_AREA_CODE %in% c("5A","5B","4A","3D"),]
##If FINAL_FISH_AGE_IN_YEARS is na, use algorithm in getAge to give it an age based on age1, age2, or age3
#Does so by taking ceiling of ages in age1-3
pacfin$Age <- PacFIN.Utilities::getAge(pacfin,
                                    verbose=TRUE,
                                    keep=unique(unlist(pacfin[, grep("AGE_METHOD[0-9]*$", colnames(pacfin))])),
                                    col.bestage="FINAL_FISH_AGE_IN_YEARS")
  #Of these 696 samples with adjusted ages, all are from WA, and 211 are surface reads (which are from 1980 and 1981)
  #There are some large differences between surface reads and break and burn reads and break and burn and break and burn
  a=pacfin[which(is.na(pacfin$FINAL_FISH_AGE_IN_YEARS) & !is.na(pacfin$Age)),]
  table(a$SAMPLE_YEAR,a$AGE_METHOD1,a$AGE_METHOD2,a$AGE_METHOD3,useNA="always")
  plot(a$age1-a$age2,col=(as.numeric(a$AGE_METHOD1=="S")+1),ylab="Difference among age 1, 2, and 3")
  points(a$age2-a$age3,col=(as.numeric(a$AGE_METHOD1=="S")+1))
  points(a$age1-a$age3,col=(as.numeric(a$AGE_METHOD1=="S")+1))
#Conclude that differences occur across all samples, regardless of aging method, so keep all methods in.
#Ultimately, given the small relative percentage these samples make, their generally variable estimates, and 
#that an average doesn't result in using an estimate (see issue #11 in github), I dont include an age for these. 
#Run based on using FINAL_FISH_AGE_IN_YEARS

############################################################################################
#	Quickly look at the commercial and recreational samples by gear to see the amount of 
#  data for each and if there looks to be different selectivity by gear type
############################################################################################

#There is no POT gear (based on codes from 2015 assessment) in bds data, so exclude 
pacfin$fleet[pacfin$PACFIN_GEAR_CODE %in% c("BMT","DNT","FFT","FTS","GFL","GFS","GFT","MDT","OTW","RLT","TWL","BTT")] <- "TWL"
pacfin$fleet[pacfin$PACFIN_GEAR_CODE %in% c("MDT","MPT")] <- "MID"
pacfin$fleet[pacfin$PACFIN_GEAR_CODE %in% c("DST","SHT","SST")] <- "TWS"
pacfin$fleet[pacfin$PACFIN_GEAR_CODE %in% c("JIG","LGL","OHL","POL","VHL","HKL")] <- "HKL"
pacfin$fleet[pacfin$PACFIN_GEAR_CODE %in% c("DGN","DPN","GLN","SEN","STN")] <- "NET"
#pacfin$fleet[pacfin$PACFIN_GEAR_CODE %in% c("CLP","CPT","FPT","OPT","PRW")] <- "POT" 
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

ggplot(filter(pacfin,fleet %in% c("HKL","MID","TWL")), aes(fish_lengthcm, fill = fleet, color = fleet)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("AGENCY_CODE", ncol=1, labeller = labeller(AGENCY_CODE = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","com_lenDensity_fleet_reduced.png"),
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
  xlab("Age") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","com_ageDensity_fleetGroup.png"),
       width = 6, height = 8)

ggplot(pacfin, aes(FINAL_FISH_AGE_IN_YEARS, fill = fleet, color = fleet)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("AGENCY_CODE", ncol=1, labeller = labeller(AGENCY_CODE = lab_val)) + 
  xlab("Age") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","com_ageDensity_fleet.png"),
       width = 6, height = 8)

ggplot(filter(pacfin,fleet %in% c("HKL","MID","TWL")), aes(FINAL_FISH_AGE_IN_YEARS, fill = fleet, color = fleet)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("AGENCY_CODE", ncol=1, labeller = labeller(AGENCY_CODE = lab_val)) + 
  xlab("Age") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","com_ageDensity_fleet_reduced.png"),
       width = 6, height = 8)

#Age over time
#very big difference between surface and break and burn sample reads
#Only age_method1 includes surface reads so use age1 instead of final age
pacfin$surface = NA
pacfin[pacfin$AGE_METHOD1%in%c("1","B","BB"),"surface"]="N"
pacfin[pacfin$AGE_METHOD1%in%c("2","S"),"surface"]="Y"
pacfin[pacfin$AGE_METHOD2%in%c("1","B","BB"),"surface"]="N"
pacfin[pacfin$AGE_METHOD3%in%c("1","B","BB"),"surface"]="N"
ggplot(filter(pacfin,!is.na(FINAL_FISH_AGE_IN_YEARS)&SEX_CODE!="U"), aes(y=age1, x=factor(SAMPLE_YEAR), color = surface)) + 
  geom_violin(trim="FALSE") +
  stat_summary(fun.y=median, geom="point", shape=18, size=3, color="blue") + 
  facet_wrap(c("SEX_CODE","AGENCY_CODE"), labeller = labeller(AGENCY_CODE = lab_val)) +
  scale_color_manual(values=c("#00BFC4","#F8766D")) + 
  scale_x_discrete(breaks=c("1975","1985","1995","2005","2015","2025")) + 
  xlab("Year") +
  ylab("Age") 
ggsave(file.path(git_dir,"data_workshop_figs","com_age_year_by_read_by_state.png"),
       width = 8, height = 4)

# #What if dont clean data
# pacfin_preclean$surface = NA
# pacfin_preclean[pacfin_preclean$AGE_METHOD1%in%c("1","B","BB"),"surface"]="N"
# pacfin_preclean[pacfin_preclean$AGE_METHOD1%in%c("2","S"),"surface"]="Y"
# pacfin_preclean[pacfin_preclean$AGE_METHOD2%in%c("1","B","BB"),"surface"]="N"
# pacfin_preclean[pacfin_preclean$AGE_METHOD3%in%c("1","B","BB"),"surface"]="N"
# ggplot(filter(pacfin_preclean,!is.na(FINAL_FISH_AGE_IN_YEARS)&SEX_CODE!="U"), aes(y=age1, x=factor(SAMPLE_YEAR), color = surface)) +
#   geom_violin(trim="FALSE") +
#   stat_summary(fun.y=median, geom="point", shape=18, size=3, color="blue") +
#   facet_wrap(c("SEX_CODE","AGENCY_CODE"), labeller = labeller(AGENCY_CODE = lab_val)) +
#   scale_color_manual(values=c("#00BFC4","#F8766D")) +
#   scale_x_discrete(breaks=c("1975","1985","1995","2005","2015","2025")) +
#   xlab("Year") +
#   ylab("Age")
# ggsave(file.path(git_dir,"data_workshop_figs","com_age_year_by_read_by_state_notcleaned.png"),
#        width = 8, height = 4)

# #Oregon has surface reads that show this pattern too among special projects samples
# #Samples with surface reads have age1 read the same as final age so use age1
# pacfin_othertype$surface = NA
# pacfin_othertype[pacfin_othertype$AGE_METHOD1%in%c("1","B","BB"),"surface"]="N"
# pacfin_othertype[pacfin_othertype$AGE_METHOD1%in%c("2","S"),"surface"]="Y"
# pacfin_othertype[pacfin_othertype$AGE_METHOD2%in%c("1","B","BB"),"surface"]="N"
# pacfin_othertype[pacfin_othertype$AGE_METHOD3%in%c("1","B","BB"),"surface"]="N"
# ggplot(filter(pacfin_othertype,!is.na(FINAL_FISH_AGE_IN_YEARS)), aes(y=age1, x=factor(SAMPLE_YEAR), color = surface)) +
#   geom_violin(trim="FALSE") +
#   stat_summary(fun.y=median, geom="point", shape=18, size=3, color="blue") +
#   facet_wrap(c("SEX_CODE","AGENCY_CODE")) +
#   scale_color_manual(values=c("#00BFC4","#F8766D")) +
#   scale_x_discrete(breaks=c("1975","1985","1995","2005","2015","2025")) +
#   xlab("Year") +
#   ylab("Age")

#Compare Oregon special projects data with rest of oregon data in years where both overlap
ggplot(filter(pacfin,AGENCY_CODE=="O" & SAMPLE_YEAR <= 1986 & SAMPLE_YEAR >= 1973), aes(fish_lengthcm, fill = SAMPLE_TYPE, color = SAMPLE_TYPE)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap("AGENCY_CODE", ncol=1, labeller = labeller(AGENCY_CODE = lab_val)) + 
  xlab("Fish Length (cm)") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","com_O_SPlength.png"),
       width = 6, height = 4)
lab_surf = c("Break & Burn", "Surface")
names(lab_surf) = c("N","Y")
ggplot(filter(pacfin,AGENCY_CODE=="O" & SAMPLE_YEAR <= 1986 & SAMPLE_YEAR >= 1973 & surface %in% c("Y","N")), aes(FINAL_FISH_AGE_IN_YEARS, fill = SAMPLE_TYPE, color = SAMPLE_TYPE)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap(c("AGENCY_CODE","surface"), ncol=1, labeller = labeller(AGENCY_CODE = lab_val, surface = lab_surf)) + 
  xlab("Age") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","com_O_SPage.png"),
       width = 6, height = 8)

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
#   xlab("Age") +
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
#Surface reads are of larger fish (probably because done in earliest years), though really these are pretty similar
ggplot(filter(pacfin,AGENCY_CODE!="C" & fleet.comb=="TWL"), aes(FINAL_FISH_AGE_IN_YEARS, fill = surface, color = surface)) +
  geom_density(alpha = 0.4, lwd = 0.8, adjust = 0.9) +
  facet_wrap(c("AGENCY_CODE","fleet.comb")) +
  xlab("Age") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())


##
#Condition - very few sampled 'alive' so ignore for commercial
##
table(pacfin$AGENCY_CODE,pacfin$PACFIN_CONDITION_CODE)
