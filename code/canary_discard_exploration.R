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

#Summaries by sectors
sector_val <- cbind(aggregate(Landings~Sector, data = gemm, FUN = function(x) round(sum(x),2)),
                    "Discards" = aggregate(Discards~Sector, data = gemm, FUN = function(x) round(sum(x),2))[,2],
                    "DiscardMortality" = aggregate(`Discard Mortality`~Sector, data = gemm, FUN = function(x) round(sum(x),2))[,2])
sector_val[order(sector_val$DiscardMortality),]

#Tribal shoreside and incidental Im not actually sure on but these dont matter
#because there are no discard mortality estimates for those sectors
ntwl <- c("Combined LE & OA CA Halibut",
          "CS - Hook & Line",
          "CS - Pot",
          "CS EM - Pot",
          "LE Fixed Gear DTL - Hook & Line", 
          "LE Fixed Gear DTL - Pot",        
          "LE Sablefish - Hook & Line",      
          "LE Sablefish - Pot",
          "OA Fixed Gear - Hook & Line",    
          "OA Fixed Gear - Pot", 
          "Directed P Halibut",
          "Nearshore",
          "Incidental")
twl <- c("CS - Bottom and Midwater Trawl",
         "CS - Bottom Trawl",
         "CS - Midwater Trawl",
         "CS EM - Bottom Trawl",
         "Limited Entry Trawl",             
         "Midwater Hake",                  
         "Midwater Hake EM",                
         "Midwater Rockfish",              
         "Midwater Rockfish EM",
         "Pink Shrimp",
         "Ridgeback Prawn Trawl",
         "LE CA Halibut",
         "OA CA Halibut",
         "Shoreside Hake",                
         "Tribal Shoreside")

#Summaries by sectors grouped into recreational and commercial)
gemm$grouped_sector = NA
gemm$grouped_sector[gemm$Sector == "Washington Recreational"] = "wa_rec"
gemm$grouped_sector[gemm$Sector == "California Recreational"] = "ca_rec"
gemm$grouped_sector[gemm$Sector == "Oregon Recreational"] = "or_rec"
gemm$grouped_sector[gemm$Sector %in% ntwl] = "commercial_ntwl"
gemm$grouped_sector[gemm$Sector %in% twl] = "commercial_twl"

landings  = aggregate(Landings ~ Year + grouped_sector, data = gemm, drop = FALSE, FUN = sum)
discards  = aggregate(Discards ~ Year + grouped_sector, data = gemm, drop = FALSE, FUN = sum)
disc_mort = aggregate(`Discard Mortality` ~ Year + grouped_sector, data = gemm, drop = FALSE, FUN = sum)
all_dead  = aggregate(`Mortality (Landings and Discard Mortality)` ~ Year + grouped_sector, data = gemm, drop = FALSE, FUN = sum)

all = data.frame(Year = landings$Year,
                 grp_sector = landings$grouped_sector,
                 Landings = landings$Landings,
                 Discard = discards$Discards,
                 Dead_Discard = disc_mort$`Discard Mortality`,
                 Tot_Dead = all_dead$`Mortality (Landings and Discard Mortality)`)
all[is.na(all)] = 0

all$Discard_Mort_Rate = round(all[,"Dead_Discard"] / all[,"Tot_Dead"], 3)
all[is.na(all)] = 0

#write.csv(all, file = file.path(git_dir, "data", "canary_gemm_mortality_and_discard.csv"), row.names = FALSE)


#-----------------------------------------------------------------------------------
# Load the WCGOP discard totals and make plots
#-----------------------------------------------------------------------------------

# #Old data (missing 2016)
# ncs = rbind(read.csv(file.path(dir,"canary_OB_DisRatios_boot_ncs_2003-2010_Gear_State_2023-01-27.csv")),
#             read.csv(file.path(dir,"canary_OB_DisRatios_boot_ncs_2011-2015_Gear_State_2023-01-27.csv")),
#             read.csv(file.path(dir,"canary_OB_DisRatios_boot_ncs_2016-2021_Gear_State_2023-01-27.csv")))
# cs = rbind(read.csv(file.path(dir,"CONFIDENTIAL_canary_OB_DisRatios_boot_cs_2011-2015_Gear_State_2023-01-27.csv")),
#            read.csv(file.path(dir,"CONFIDENTIAL_canary_OB_DisRatios_boot_cs_2016-2021_Gear_State_2023-01-27.csv")))

#Updated data - change field names to match original files fields
ncs <- read.csv(file.path(dir,"canary_ncs_wcgop_discard_all_years_Gear_State_2023-02-15.csv"))
cs <- read.csv(file.path(dir,"canary_cs_wcgop_discard_all_years_Gear_State_2023-02-15.csv"))
names(ncs)[c(1:3,10,11)] <- c("ryear","State","gear2","Observed_DISCARD.MTS","Observed_RETAINED.MTS")
names(cs)[c(1:3,11,12)] <- c("ryear","State","gear2","Observed_DISCARD.MTS","Observed_RETAINED.MTS")
#remove redacted values and set as numerica
cs <- cs[-which(!cs$nonconfidential),]
cs$Observed_RETAINED.MTS <- as.numeric(cs$Observed_RETAINED.MTS)
cs$Observed_DISCARD.MTS <- as.numeric(cs$Observed_DISCARD.MTS)


#Expand out to every combination of year, state, and gear
ret_ncs = aggregate(Observed_RETAINED.MTS ~ ryear + State + gear2, data = ncs, drop = FALSE, FUN = sum)
dis_ncs = aggregate(Observed_DISCARD.MTS  ~ ryear + State + gear2, data = ncs, drop = FALSE, FUN = sum)
ret_cs  = aggregate(Observed_RETAINED.MTS ~ ryear + State + gear2, data = cs, drop = FALSE, FUN = sum)
dis_cs  = aggregate(Observed_DISCARD.MTS  ~ ryear + State + gear2, data = cs, drop = FALSE, FUN = sum)

#Combine across sectors
tot_ncs = cbind(ret_ncs,"Observed_DISCARD.MTS"=dis_ncs$Observed_DISCARD.MTS)
tot_cs = cbind(ret_cs,"Observed_DISCARD.MTS"=dis_cs$Observed_DISCARD.MTS)
tot_ncs[is.na(tot_ncs)] = tot_cs[is.na(tot_cs)] = 0

#Combine across ncs and cs
tot_tot = tot_ncs
tot_tot[which(tot_tot$ryear %in% tot_cs$ryear),"Observed_RETAINED.MTS"] = tot_tot[which(tot_tot$ryear %in% tot_cs$ryear),"Observed_RETAINED.MTS"] + tot_cs[,"Observed_RETAINED.MTS"]
tot_tot[which(tot_tot$ryear %in% tot_cs$ryear),"Observed_DISCARD.MTS"] = tot_tot[which(tot_tot$ryear %in% tot_cs$ryear),"Observed_DISCARD.MTS"] + tot_cs[,"Observed_DISCARD.MTS"]

#Create discard ratios
tot_ncs$ratio = tot_ncs$Observed_DISCARD.MTS/(tot_ncs$Observed_RETAINED.MTS+tot_ncs$Observed_DISCARD.MTS)
tot_cs$ratio = tot_cs$Observed_DISCARD.MTS/(tot_cs$Observed_RETAINED.MTS+tot_cs$Observed_DISCARD.MTS)
tot_tot$ratio = tot_tot$Observed_DISCARD.MTS/(tot_tot$Observed_RETAINED.MTS+tot_tot$Observed_DISCARD.MTS)


##
#Plots of discards ratios - Unsure how helpful these are because WCGOP is used to pull
#total discards PLUS retained, not the ratios shown here. If want to look at values
#replace 'y = ratio' with Observed_RETAINED.MTS + Observed_DISCARD.MTS
##
ggplot(tot_ncs, aes(x=ryear, y=ratio, col = gear2)) +
  geom_line(linetype = "solid") +
  facet_wrap("State", ncol = 1) +
  geom_point() +
  xlab("Year") +
  ylab("Ratio of discards to total catches (dis + ret)") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_explore_figs","WCGOP_discard_rates_ncs_newData.png"),
       width = 6, height = 8)

ggplot(tot_cs, aes(x=ryear, y=ratio, col = gear2)) +
  geom_line(linetype = "solid") +
  facet_wrap("State", ncol = 1) +
  geom_point() +
  xlab("Year") +
  ylab("Ratio of discards to total catches (dis + ret)") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_explore_figs","WCGOP_discard_rates_cs_newData.png"),
       width = 6, height = 8)

#For combining across cs and ncs, if used discard rates would probably want to set the WA fixed gear value in 2012 to 1.0
ggplot(tot_tot, aes(x=ryear, y=ratio, col = gear2)) +
  geom_line(linetype = "solid") +
  facet_wrap("State", ncol = 1) +
  geom_point() +
  xlab("Year") +
  ylab("Ratio of discards to total catches (dis + ret)") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
ggsave(file.path(git_dir,"data_explore_figs","WCGOP_discard_rates_cs plus ncs_newData.png"),
       width = 6, height = 8)


wcgop_ratios = pivot_wider(tot_tot[,-c(4,5)], 
                     names_from = c(State,gear2), values_from = ratio)
#write.csv(wcgop_ratios, file = file.path(git_dir, "data", "canary_wcgop_discardRatios.csv"), row.names = FALSE)



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

##
#Plots of ratios
##
#Fixed
matplot(x=ratio_fix$Year, y=ratio_fix[,-1], type = "l", col = c(1,2,5), lty = 1, lwd = 3, 
        ylab = "Proportion of WCGOP discards + retained", xlab = "Year", main = "Fixed Gear Proportion")
legend("topright", legend = c("CA", "OR", "WA"), col = c(1,2,5), lty = 1, lwd = 3, horiz=T, bty = "n")
#Trawl
matplot(x=ratio_twl$Year, y=ratio_twl[,-1], type = "l", col = c(1,2,5), lty = 1, lwd = 3, 
        ylab = "Proportion of WCGOP discards + retained", xlab = "Year", main = "Trawl Gear Proportion")
legend("topright", legend = c("CA", "OR", "WA"), col = c(1,2,5), lty = 1, lwd = 3, horiz=T, bty = "n")
#All
matplot(x=ratio_all$Year, y=ratio_all[,-1], type = "l", col = c(1,2,5), lty = 1, lwd = 3, 
        ylab = "Proportion of WCGOP discards + retained", xlab = "Year", main = "All Proportion")
legend("topright", legend = c("CA", "OR", "WA"), col = c(1,2,5), lty = 1, lwd = 3, horiz=T, bty = "n")


#Dead discard values (mt) by state
dead = data.frame("Year" = ratio_all$Year,
                  "ca_twl" = ratio_twl$ca * all[which(all$grp_sector == "commercial_twl"), "Dead_Discard"],
                  "or_twl" = ratio_twl$or * all[which(all$grp_sector == "commercial_twl"), "Dead_Discard"],
                  "wa_twl" = ratio_twl$wa * all[which(all$grp_sector == "commercial_twl"), "Dead_Discard"],
                  "ca_ntwl" = ratio_fix$ca * all[which(all$grp_sector == "commercial_ntwl"), "Dead_Discard"],
                  "or_ntwl" = ratio_fix$or * all[which(all$grp_sector == "commercial_ntwl"), "Dead_Discard"],
                  "wa_ntwl" = ratio_fix$wa * all[which(all$grp_sector == "commercial_ntwl"), "Dead_Discard"]) 

##
#Upload to google drive because this can be used to back calculate PacFIN landings and thus should be 
#considered confidential even though its not stricly confidential on its own
##
xx <- googledrive::drive_create(name = 'CONFIDENTIAL_canary_commercial_discard_mt',
                                path = 'https://drive.google.com/drive/folders/179mhykZRxnXFLp81sFOAYsPtLfVOUtKB',
                                type = 'spreadsheet', overwrite = TRUE)
googlesheets4::sheet_write(dead, ss = xx, sheet = "discard_mt")
googlesheets4::sheet_delete(ss = xx, sheet = "Sheet1")




