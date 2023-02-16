##############################################################################################################
#
# 	Purpose: Evaluate canary rockfish discarding
# 		by source, fishery, and across time.
#
#			  by Brian Langseth
#
##############################################################################################################

library(dplyr)
library(tidyr)
library(ggplot2)

#User directories
if(Sys.getenv("USERNAME") == "Brian.Langseth") {
  git_dir <- "U:/Stock assessments/canary_2023/"
  dir <- "//nwcfile/FRAM/Assessments/Assessment Data/2023 Assessment Cycle/canary rockfish/WCGOP"
}

#-----------------------------------------------------------------------------------
# Load the GEMM report for canary rockfish
#-----------------------------------------------------------------------------------

gemm_all <- readxl::read_excel(path = "//nwcfile/FRAM/Assessments/GEMM Report/GMR_2021/g-1-b-nwfsc-report-2-groundfish-mortality-report-tables-electronic-only (2).xlsx",
                             sheet = "Table 3", skip=2)
gemm = gemm_all[gemm_all$Species == "Canary Rockfish", ]

# Remove the research removals -- 
# Research removals are generally not included with commercial landings (although this does not need to be the case)
# however, removing them here allows you to correctly calculate the discard rate based on commercial data only
# Also remove the At-Sea Hake removals
gemm = gemm[!gemm$Sector %in% c("Research",grep("At-Sea Hake", unique(gemm$Sector), value =TRUE)), ] 

gemm$dis_mort_rate = round(gemm[,"Discard Mortality"] / gemm[,"Mortality (Landings and Discard Mortality)"], 3)
data.frame(gemm[,c("Year","Sector","dis_mort_rate")])

##<<<<<<<<<<<<< TO CONFIRM - KEEP OR REMOVE ANY OTHER SECTIONS (e.g. At-sea-hake, tribal)?? <<<<<<<<<<<<<<<

aggregate(Landings~Sector, data = gemm, FUN = function(x) round(sum(x),2))
aggregate(Discards~Sector, data = gemm, FUN = function(x) round(sum(x),2))
aggregate(`Discard Mortality`~Sector, data = gemm, FUN = function(x) round(sum(x),2))

gemm$grouped_sector = NA
gemm$grouped_sector[gemm$Sector == "Washington Recreational"] = "wa_rec"
gemm$grouped_sector[gemm$Sector == "California Recreational"] = "ca_rec"
gemm$grouped_sector[gemm$Sector == "Oregon Recreational"] = "or_rec"
gemm$grouped_sector[is.na(gemm$grouped_sector)] = "commercial"

landings  = aggregate(Landings ~ Year + grouped_sector, data = gemm, drop = FALSE, FUN = sum)
discards  = aggregate(Discards ~ Year + grouped_sector, data = gemm, drop = FALSE, FUN = sum)
disc_mort = aggregate(`Discard Mortality` ~ Year + grouped_sector, data = gemm, drop = FALSE, FUN = sum)
all_dead  = aggregate(`Mortality (Landings and Discard Mortality)` ~ Year + grouped_sector, data = gemm, drop = FALSE, FUN = sum)

all = data.frame(Year = landings$Year,
                 Area = landings$grouped_sector,
                 Landings = landings$Landings,
                 Discard = discards$Discards,
                 Dead_Discard = disc_mort$`Discard Mortality`,
                 Tot_Dead = all_dead$`Mortality (Landings and Discard Mortality)`)
all[is.na(all)] = 0

all$Discard_Mort_Rate = round(all[,"Dead_Discard"] / all[,"Tot_Dead"], 3)
all[is.na(all)] = 0

#write.csv(all, file = file.path(git_dir, "data", "quillback_gemm_mortality_and_discard.csv"), row.names = FALSE)


#-----------------------------------------------------------------------------------
# Load the WCGOP discard totals and make plots
#-----------------------------------------------------------------------------------

ncs = rbind(read.csv(file.path(dir,"canary_OB_DisRatios_boot_ncs_2003-2010_Gear_State_2023-01-27.csv")),
            read.csv(file.path(dir,"canary_OB_DisRatios_boot_ncs_2011-2015_Gear_State_2023-01-27.csv")),
            read.csv(file.path(dir,"canary_OB_DisRatios_boot_ncs_2016-2021_Gear_State_2023-01-27.csv")))
cs = rbind(read.csv(file.path(dir,"CONFIDENTIAL_canary_OB_DisRatios_boot_cs_2011-2015_Gear_State_2023-01-27.csv")),
           read.csv(file.path(dir,"CONFIDENTIAL_canary_OB_DisRatios_boot_cs_2016-2021_Gear_State_2023-01-27.csv")))

#Expand out to every combination of year, state, and gear
ret_ncs = aggregate(Observed_RETAINED.MTS ~ ryear + State + gear2, data = ncs, drop = FALSE,FUN = sum)
dis_ncs = aggregate(Observed_DISCARD.MTS  ~ ryear + State + gear2, data = ncs, drop = FALSE,FUN = sum)
ret_cs  = aggregate(Observed_RETAINED.MTS ~ ryear + State + gear2, data = cs, drop = FALSE, FUN = sum)
dis_cs  = aggregate(Observed_DISCARD.MTS  ~ ryear + State + gear2, data = cs, drop = FALSE,FUN = sum)

#Combine across sectors
tot_ncs = cbind(ret_ncs,"Observed_DISCARD.MTS"=dis_ncs$Observed_DISCARD.MTS)
tot_cs = cbind(ret_cs,"Observed_DISCARD.MTS"=dis_cs$Observed_DISCARD.MTS)
tot_ncs[is.na(tot_ncs)] = tot_cs[is.na(tot_cs)] = 0

#Create discard ratios
tot_ncs$ratio = tot_ncs$Observed_DISCARD.MTS/(tot_ncs$Observed_RETAINED.MTS+tot_ncs$Observed_DISCARD.MTS)
tot_cs$ratio = tot_cs$Observed_DISCARD.MTS/(tot_cs$Observed_RETAINED.MTS+tot_cs$Observed_DISCARD.MTS)

##
#Plots of discards ratios
##
ggplot(tot_ncs, aes(x=ryear, y=ratio, col = gear2)) +
  geom_line(linetype = "solid") +
  facet_wrap("State", ncol = 1) +
  geom_point() +
  xlab("Year") +
  ylab("Ratio of discards to total catches (dis + ret)") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_explore_figs","CONFIDENTIAL_WCGOP_discard_rates_ncs.png"),
       width = 6, height = 8)

ggplot(tot_cs, aes(x=ryear, y=ratio, col = gear2)) +
  geom_line(linetype = "solid") +
  facet_wrap("State", ncol = 1) +
  geom_point() +
  xlab("Year") +
  ylab("Ratio of discards to total catches (dis + ret)") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_explore_figs","CONFIDENTIAL_WCGOP_discard_rates_cs.png"),
       width = 6, height = 8)


#-----------------------------------------------------------------------------------
# Load the WCGOP catch totals 
# Kayleigh suggested:
# multiply by proportion of catch observed in an area compared to coastwide -- 
# not the proportion discarded in a given area. To do that, I suggest calculating the 
# proportion of observed catch (D+R) within each area (compared to coastwide) in each year. 
# So, for example, for 2018 it might be 5% of observed in WA, 10% observed in OR, 
# 40% observed N of Pt Conc, and 45% observed S of Pont Conc (adding up to 100% coastwide). 
# We could then multiply the total discard from the GEMM by each of those area proportions to
# estimate the discard in each area. We could also explore using the same method but with 
# only observed discard rather than observed discard AND retained together.
#-----------------------------------------------------------------------------------

#Arrange ncs catch and discard by state
tot_fix = data.frame(Year = sort(unique(ret_ncs$ryear)),
                     ca = ret_ncs[which(ret_ncs$State == "CA" & ret_ncs$gear2 == "FixedGears"),4] + dis_ncs[which(dis_ncs$State == "CA" & ret_ncs$gear2 == "FixedGears"),4],
                     or = ret_ncs[which(ret_ncs$State == "OR" & ret_ncs$gear2 == "FixedGears"),4] + dis_ncs[which(dis_ncs$State == "OR" & ret_ncs$gear2 == "FixedGears"),4],
                     wa = ret_ncs[which(ret_ncs$State == "WA" & ret_ncs$gear2 == "FixedGears"),4] + dis_ncs[which(dis_ncs$State == "WA" & ret_ncs$gear2 == "FixedGears"),4])
tot_twl = data.frame(Year = sort(unique(ret_ncs$ryear)),
                     ca = ret_ncs[which(ret_ncs$State == "CA" & ret_ncs$gear2 == "Trawl"),4] + dis_ncs[which(dis_ncs$State == "CA" & ret_ncs$gear2 == "Trawl"),4],
                     or = ret_ncs[which(ret_ncs$State == "OR" & ret_ncs$gear2 == "Trawl"),4] + dis_ncs[which(dis_ncs$State == "OR" & ret_ncs$gear2 == "Trawl"),4],
                     wa = ret_ncs[which(ret_ncs$State == "WA" & ret_ncs$gear2 == "Trawl"),4] + dis_ncs[which(dis_ncs$State == "WA" & ret_ncs$gear2 == "Trawl"),4])
tot_fix[is.na(tot_fix)] = tot_twl[is.na(tot_twl)] = 0


#Add cs catch and discard by state to ncs in the years they overlap for fixed gear
tot_fix[which(tot_fix$Year %in% ret_cs$ryear), "ca"] = colSums(rbind(tot_fix[which(tot_fix$Year %in% ret_cs$ryear), "ca"],  
   ret_cs[which(ret_cs$State == "CA" & ret_cs$gear2 == "FixedGears"), 4], dis_cs[which(dis_cs$State == "CA" & dis_cs$gear2 == "FixedGears"), 4]), na.rm=TRUE)
tot_fix[which(tot_fix$Year %in% ret_cs$ryear), "or"] = colSums(rbind(tot_fix[which(tot_fix$Year %in% ret_cs$ryear), "or"],  
   ret_cs[which(ret_cs$State == "OR" & ret_cs$gear2 == "FixedGears"), 4], dis_cs[which(dis_cs$State == "OR" & dis_cs$gear2 == "FixedGears"), 4]), na.rm=TRUE)
tot_fix[which(tot_fix$Year %in% ret_cs$ryear), "wa"] = colSums(rbind(tot_fix[which(tot_fix$Year %in% ret_cs$ryear), "wa"],  
   ret_cs[which(ret_cs$State == "WA" & ret_cs$gear2 == "FixedGears"), 4], dis_cs[which(dis_cs$State == "WA" & dis_cs$gear2 == "FixedGears"), 4]), na.rm=TRUE)

#Add cs catch and discard by state to ncs in the years they overlap for trawl gear
tot_twl[which(tot_twl$Year %in% ret_cs$ryear), "ca"] = colSums(rbind(tot_twl[which(tot_twl$Year %in% ret_cs$ryear), "ca"],  
   ret_cs[which(ret_cs$State == "CA" & ret_cs$gear2 == "Trawl"), 4], dis_cs[which(dis_cs$State == "CA" & dis_cs$gear2 == "Trawl"), 4]), na.rm=TRUE)
tot_twl[which(tot_twl$Year %in% ret_cs$ryear), "or"] = colSums(rbind(tot_twl[which(tot_twl$Year %in% ret_cs$ryear), "or"],  
   ret_cs[which(ret_cs$State == "OR" & ret_cs$gear2 == "Trawl"), 4], dis_cs[which(dis_cs$State == "OR" & dis_cs$gear2 == "Trawl"), 4]), na.rm=TRUE)
tot_twl[which(tot_twl$Year %in% ret_cs$ryear), "wa"] = colSums(rbind(tot_twl[which(tot_twl$Year %in% ret_cs$ryear), "wa"],  
   ret_cs[which(ret_cs$State == "WA" & ret_cs$gear2 == "Trawl"), 4], dis_cs[which(dis_cs$State == "WA" & dis_cs$gear2 == "Trawl"), 4]), na.rm=TRUE)

#Ratio of total retained + discards by state for each gear and over both gears
ratio_fix = cbind("Year" = tot_fix$Year, tot_fix[,-1] / apply(tot_fix[,-1], 1, sum))
ratio_twl = cbind("Year" = tot_twl$Year, tot_twl[,-1] / apply(tot_twl[,-1], 1, sum))
ratio_all = cbind("Year" = tot_fix$Year, (tot_fix[,-1] + tot_twl[,-1]) / apply((tot_fix[,-1] + tot_twl[,-1]), 1, sum))


#Dead discard values (mt) by state

#<<<<<<<<<<<< WAITING ON GETTING 2016 DATA FROM CHANTEL <<<<<<<<<<<<<<<<<<<<<<<<#
#Once obtained can run the following
dead = data.frame(Year = ratio_all$Year,
                  ca = ratio_all$ca * all[which(all$Area == "commercial"), "Dead_Discard"],
                  or = ratio_all$or * all[which(all$Area == "commercial"), "Dead_Discard"],
                  wa = ratio_all$wa * all[which(all$Area == "commercial"), "Dead_Discard"] ) 

#write.csv(dead, file = file.path(git_dir, "data", "quillback_commercial_discard.csv"), row.names = FALSE)




