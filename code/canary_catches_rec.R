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
  git_dir <- "U:/Stock assessments/canary_2023/"
}

#################################################################################################################
#---------------------------------------------------------------------------------------------------------------#
# Load RecFIN data
#---------------------------------------------------------------------------------------------------------------#
#################################################################################################################
# RecFIN - 2021-2021 Landings mtons
# 2022 is incomplete yet
recfin = read.csv(file.path(dir, "RecFIN_CTE001_canary_2001_2021.csv"),header=TRUE)


#################################################################################################################
# Evaluate the recreational data 
#################################################################################################################

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



#################################################################################################################
#Plotting
#################################################################################################################
tmp_longer <- pivot_longer(tmp, cols = c(sum_ret,sum_rel,sum_rel_mort,sum_total), names_to = "type")

lab_val = c("California", "Oregon", "Washington")
names(lab_val) = c("C","O","W")

##
#Totals
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
  scale_fill_discrete(name = "Breakdown", labels = c("Dead releases","Retained")) + 
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




