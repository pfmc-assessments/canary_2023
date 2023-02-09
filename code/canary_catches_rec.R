##############################################################################################################
#
# 	Purpose: Output Canary Rockfish Landings 
#            into form for use in SS for recreational fleets
#
#   Created: Jan 23, 2022
#			  by Brian Langseth 
#
##############################################################################################################

library(dplyr)
library(tidyr)
library(ggplot2)

#User directories
if(Sys.getenv("USERNAME") == "Brian.Langseth") {
  dir <- "U:/Stock assessments/canary_rockfish_supporting_2023/RecFIN pulls"
  git_dir <- "U:/Stock assessments/canary_2023"
}

#################################################################################################################
#---------------------------------------------------------------------------------------------------------------#
# Load RecFIN and state provided data
#---------------------------------------------------------------------------------------------------------------#
#################################################################################################################
# RecFIN - 2021-2021 Landings mtons
# 2022 is incomplete yet
recfin <- read.csv(file.path(dir, "RecFIN_CTE001_canary_2001_2021.csv"),header=TRUE)

#WA sport catch - only need to pull from googledrive once
# googledrive::drive_download(file = "Canary_WA_RecCatch_2023Updates.xlsx",
#                             path = file.path(git_dir,"data-raw","Canary_WA_RecCatch_2023Updates.xlsx"))
wa_rec <- readxl::read_excel(path = file.path(git_dir,"data-raw","Canary_WA_RecCatch_2023Updates.xlsx"),
                             col_names = c("YEAR","RETAINED_N","RELEASED_TOTAL_N","REL1_10ftm",
                                           "REL10_20ftm","REL20_30ftm","REL30plusftm","RELUNKftm"),skip=3)

#OR rec catch - only need to pull from googledrive once
# googledrive::drive_download(file = "Oregon data/Oregon Recreational landings_451_2022.xlsx",
#                             path = file.path(git_dir,"data-raw","Oregon Recreational landings_451_2022.xlsx"))
or_rec <- readxl::read_excel(path = file.path(git_dir,"data-raw","Oregon Recreational landings_451_2022.xlsx"),
                             sheet = "Oregon Recreational landings_45")


#################################################################################################################
# Evaluate the data 
#################################################################################################################

##RecFIN

#Check categories
table(recfin$AGENCY,useNA="always")
table(recfin$RECFIN_MODE_NAME,useNA="always") #nearly all PC or PR
recfin %>% group_by(RECFIN_MODE_NAME) %>% summarize(sum = sum(SUM_TOTAL_MORTALITY_MT))
table(recfin$RECFIN_WATER_AREA_NAME,useNA="always")
table(recfin$RECFIN_WATER_AREA_NAME,recfin$AGENCY,useNA="always")
recfin %>% group_by(RECFIN_WATER_AREA_NAME) %>% summarize(sum = sum(SUM_TOTAL_MORTALITY_MT))
table(recfin$RECFIN_TRIP_TYPE_NAME,useNA="always")
recfin %>% group_by(RECFIN_TRIP_TYPE_NAME) %>% summarize(sum = sum(SUM_TOTAL_MORTALITY_MT))

#Summary of catch categories by year, mode, and state
recfin$mode <- rep(NA, nrow(recfin))
recfin$mode[recfin$RECFIN_MODE_NAME %in% c("Beach/Bank","Man-Made/Jetty")] <- "OTH"
recfin$mode[recfin$RECFIN_MODE_NAME %in% c("Party/Charter Boats")] <- "PC"
recfin$mode[recfin$RECFIN_MODE_NAME %in% c("Private/Rental Boats")] <- "PR"

tmp <- recfin %>% group_by(mode, AGENCY, RECFIN_YEAR) %>% 
  summarize(sum_ret = sum(SUM_RETAINED_MT), sum_rel = sum(SUM_RELEASED_ALIVE_MT), sum_rel_mort = sum(SUM_RELEASED_DEAD_MT), sum_total = sum(SUM_TOTAL_MORTALITY_MT))
plot(tmp$sum_total - (tmp$sum_rel_mort+tmp$sum_ret)) #totals sum properly
tmp_wider <- pivot_wider(tmp, names_from = c(AGENCY,mode), names_sep = ".", values_from = c(sum_ret,sum_rel,sum_rel_mort,sum_total), names_glue = "{AGENCY}_{mode}_{.value}", names_sort = TRUE) %>% arrange(RECFIN_YEAR)
tmp_wider <- tmp_wider %>% select(c("RECFIN_YEAR",sort(colnames(tmp_wider[,-1]))))

# ##
# #Upload to googledrive
# #Based on pull of public forms so not confidential
# ##
# xx <- googledrive::drive_create(name = 'recfin_catch',
#                                 path = 'https://drive.google.com/drive/folders/1Lx4JN-nmJkWtcqmelODZYoVrHyVLzegP', 
#                                 type = 'spreadsheet', overwrite = TRUE)
# googlesheets4::sheet_write(round(tmp_wider,3), ss = xx, sheet = "catch_mt")
# googlesheets4::sheet_delete(ss = xx, sheet = "Sheet1")


## WA provided data

#Add discard by depth amounts
#Discard rates are found in Table 1-10 of Council doc linked in issue #10
#Use surface rates. Dont have information on amount of releases at depth
wa_rec$DEAD_RELEASED_TOTAL_N = wa_rec$REL1_10ftm*0.21 + 
                               wa_rec$REL10_20ftm*0.37 + 
                               wa_rec$REL20_30ftm*0.53 + 
                               wa_rec$REL30plusftm*1.00 +
                               #Divide unknown depths based on proportions of releases for each known depth
                               wa_rec$RELUNKftm*(wa_rec$REL1_10ftm/(wa_rec$RELEASED_TOTAL_N-wa_rec$RELUNKftm))*0.21 +
                               wa_rec$RELUNKftm*(wa_rec$REL10_20ftm/(wa_rec$RELEASED_TOTAL_N-wa_rec$RELUNKftm))*0.37 +
                               wa_rec$RELUNKftm*(wa_rec$REL20_30ftm/(wa_rec$RELEASED_TOTAL_N-wa_rec$RELUNKftm))*0.53 +
                               wa_rec$RELUNKftm*(wa_rec$REL30plusftm/(wa_rec$RELEASED_TOTAL_N-wa_rec$RELUNKftm))*1.00
#Take averages to fill in mortality for released fish in 2002-2004, which dont have released by depth information
rel_mort_rate <- wa_rec$DEAD_RELEASED_TOTAL_N/wa_rec$RELEASED_TOTAL_N
avg_rate2005_2007 <- mean(rel_mort_rate[29:31], na.rm=TRUE)
plot(x=wa_rec$YEAR, rel_mort_rate, type="b", xlab= "Year", "ylab" = "Release Mortality Reate")
abline(h=avg_rate2005_2007,lty=2) #mean over most recent three years of data
wa_rec[wa_rec$YEAR%in%c(2002:2004),]$DEAD_RELEASED_TOTAL_N <- avg_rate2005_2007 * wa_rec[wa_rec$YEAR%in%c(2002:2004),]$RELEASED_TOTAL_N

wa_rec_longer <- pivot_longer(wa_rec, cols = names(wa_rec)[-1], names_to = "disposition")
wa_rec_longer$state = "W"


## OR provided data

or_rec_longer <- pivot_longer(or_rec[,-which(names(or_rec)=="Total_MT")], cols = c("Retained_MT","Released_MT"), names_to = "disposition")
or_rec_longer$state = "O"


#################################################################################################################
#Plotting
#################################################################################################################
lab_val = c("California", "Oregon", "Washington")
names(lab_val) = c("C","O","W")

##
#Totals for recfin
##
#Total landings by mode
ggplot(tmp, aes(fill=mode, y=sum_total, x=RECFIN_YEAR)) + 
  geom_bar(position="stack", stat="identity") +
  facet_wrap("AGENCY", ncol = 1, labeller = labeller(AGENCY = lab_val)) + 
  xlab("Year") +
  ylab("Total Removals (MT)") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_removals.png"),
       width = 6, height = 8)

#Breakdown of disposition of dead fish (retained or dead releases) 
tmp_longer <- pivot_longer(tmp, cols = c(sum_ret,sum_rel,sum_rel_mort,sum_total), names_to = "type")
ggplot(filter(tmp_longer,type%in%c("sum_rel_mort","sum_ret")), aes(fill=type, y=value, x=RECFIN_YEAR)) + 
  geom_bar(position="stack", stat="identity") +
  facet_wrap("AGENCY", ncol = 1, labeller = labeller(AGENCY = lab_val)) + 
  xlab("Year") +
  ylab("Removals (MT)") + 
  scale_fill_discrete(name = "Disposition", labels = c("Dead releases","Retained")) + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_removals_retain_releaseMort.png"),
       width = 6, height = 8)

#Breakdown of disposition of dead fish (retained or dead releases) by mode
ggplot(filter(tmp_longer,type%in%c("sum_rel_mort","sum_ret") & mode %in%c("PC","PR")), aes(fill=type, y=value, x=RECFIN_YEAR)) + 
  geom_bar(position="stack", stat="identity") +
  facet_wrap(c("AGENCY","mode"), ncol = 2, labeller = labeller(AGENCY = lab_val)) + 
  xlab("Year") +
  ylab("Removals (MT)") + 
  scale_fill_discrete(name = "Disposition", labels = c("Dead releases","Retained")) + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_removals_mode_retain_releaseMort.png"),
       width = 6, height = 8)

#Percentage of total releases that are dead by mode
tmp_perc <- tmp %>% mutate(perc = sum_rel_mort/(sum_rel+sum_rel_mort))
tmp_perc[which(is.na(tmp_perc$perc)),"perc"] <- 0
ggplot(filter(tmp_perc[,c("mode","AGENCY","RECFIN_YEAR","perc")],mode%in%c("PR","PC")), aes(col=mode, y=perc, x=RECFIN_YEAR)) + 
  geom_line(position="identity", stat="identity") +
  facet_wrap("AGENCY", ncol = 1, labeller = labeller(AGENCY = lab_val)) + 
  xlab("Year") +
  ylab("Proportion of releases that are dead") + 
  ylim(c(0,1)) + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","rec_perc_mode_releaseMort.png"),
       width = 6, height = 8)

##
#Totals for washington
##
ggplot(wa_rec_longer, aes(y=value, x=YEAR)) + 
  geom_bar(position="stack", stat="identity") +
  facet_wrap("state",labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("Total Removals and Releses (N)") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","WA_rec_removalsN.png"),
       width = 6, height = 3)

ggplot(filter(wa_rec_longer, disposition %in% c("RETAINED_N","RELEASED_TOTAL_N")), aes(fill = disposition, y=value, x=YEAR)) + 
  geom_bar(position="stack", stat="identity") +
  facet_wrap("state",labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("Total Removals (N)") + 
  theme_bw() + theme(legend.position = c(0.2,0.8), panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","WA_rec_retained_releaseN.png"),
       width = 6, height = 3)

ggplot(filter(wa_rec_longer, disposition %in% c("RETAINED_N","DEAD_RELEASED_TOTAL_N")), aes(fill = disposition, y=value, x=YEAR)) + 
  geom_bar(position="stack", stat="identity") +
  facet_wrap("state",labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("Total Removals (N)") + 
  theme_bw() + theme(legend.position = c(0.2,0.8), panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_explore_figs","WA_rec_retained_deadreleaseN.png"),
       width = 6, height = 3)

ggplot(filter(wa_rec_longer, !disposition %in% c("RETAINED_N","RELEASED_TOTAL_N","DEAD_RELEASED_TOTAL_N")), aes(fill = disposition, y=value, x=YEAR)) + 
  geom_bar(position="fill", stat="identity") +
  facet_wrap("state",labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("Proportion") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","WA_rec_releaseDepth.png"),
       width = 6, height = 3)

##
#Totals for Oregon
##
ggplot(or_rec, aes(y=Total_MT, x=Year)) + 
  geom_bar(position="stack", stat="identity") +
  facet_wrap("state",labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("Total removals (MT)") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","OR_rec_total.png"),
       width = 6, height = 3)

ggplot(or_rec_longer, aes(y=value, x=Year, fill = disposition)) + 
  geom_bar(position="stack", stat="identity") +
  facet_wrap("state",labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("Total removals (MT)") + 
  scale_fill_discrete(labels=c("Released dead","Retained")) +
  theme_bw() + theme(legend.position = c(0.7,0.8), panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_workshop_figs","OR_rec_disposition.png"),
       width = 6, height = 3)


