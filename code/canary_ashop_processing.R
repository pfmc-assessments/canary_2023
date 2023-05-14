##############################################################################################################
#
# 	Purpose: Process and output Canary Rockfish removals, and
#             length and age comps from ASHOP into form for use in SS
#
#   Created: Apr 25, 2023
#			  by Brian Langseth 
#
##############################################################################################################

library(dplyr)
library(tidyr)
library(ggplot2)

#User directories
if(Sys.getenv("USERNAME") == "Brian.Langseth") {
  git_dir <- "U:/Stock assessments/canary_2023"
}

#################################################################################################################
#---------------------------------------------------------------------------------------------------------------#
# Load data
#---------------------------------------------------------------------------------------------------------------#
#################################################################################################################

##Catches

early <- readxl::read_excel(path = file.path(git_dir,"data-raw","ASHOP_Canary_Catch_1975-1990_040323.xlsx"), 
                            sheet = "1975-1989", guess_max = Inf)
early_exp <- readxl::read_excel(path = file.path(git_dir,"data-raw","ASHOP_Canary_Catch_1975-1990_040323.xlsx"), 
                                sheet = "Expansion factors", range = "A1:B15", guess_max = Inf) %>% arrange(YEAR)
#Add 1975 and 1990 expansion value same as 1976-1983 values and as from form A-SHOP Expansion factors_updated_050123 in google drive
early_exp <- rbind(cbind("YEAR" = 1975, early_exp[2,2]),
                   early_exp,
                   cbind("YEAR" = 1990, "HAULS_SAMPLED_EXPANSION_FACTOR" = 1.478930759))

late <- readxl::read_excel(path = file.path(git_dir,"data-raw","ASHOP_Canary_Catch_1990-2022_033123.xlsx"), 
                            sheet = "1990-2022", guess_max = Inf)
late_exp <- readxl::read_excel(path = file.path(git_dir,"data-raw","ASHOP_Canary_Catch_1990-2022_033123.xlsx"), 
                               sheet = "Expansion factors", guess_max = Inf)

##Lengths

length <- readxl::read_excel(path = file.path(git_dir,"data-raw","ASHOP_Canary_Length_040423.xlsx"), 
                             sheet = "Canary Lengths 2003-2022", guess_max = Inf)

##Ages

age <- readxl::read_excel(path = file.path(git_dir,"data-raw","ASHOP_Canary_Age_updated_050123.xlsx"), 
                             sheet = "Canary Age Data 2003-2022", guess_max = Inf)


#################################################################################################################
#---------------------------------------------------------------------------------------------------------------#
# Process Catch data
#---------------------------------------------------------------------------------------------------------------#
#################################################################################################################

#Add needed variables (year, state)
#Use retrieval data as most are R in early and more entries for end in late period
table(early$LOCATION_ID)
table(is.na(late$LATDD_END),is.na(late$LATDD_START))

early$year <- as.numeric(format(early$HAUL_DATE, "%Y"))
late$year <- late$YEAR

early$state <- dplyr::case_when(early$LATITUDE < 4200 ~ "CA", #order of these is crucial
                                early$LATITUDE < 4615 ~ "OR", 
                                early$LATITUDE < 4900 ~ "WA")
late$state <- dplyr::case_when(late$LATDD_END < 42.00 ~ "CA",
                               late$LATDD_END < 46.25 ~ "OR", 
                               late$LATDD_END < 49.00 ~ "WA")

late$PERCENT_RETAINED[is.na(late$PERCENT_RETAINED)] = 100 #assume all retained if no information on it

#Add expansions
early <- left_join(early, early_exp, join_by("year" == "YEAR"))
late <- left_join(late, late_exp, join_by("year" == "YEAR"))

#Plot locations - regulations changed in 1992. No CA processing starting in 1992
early$LATDD = as.numeric(substr(early$LATITUDE,1,2)) + as.numeric(substr(early$LATITUDE,3,4))/60
early$LONDD = as.numeric(substr(early$LONGITUDE,1,3)) + as.numeric(substr(early$LONGITUDE,4,5))/60
plot(-early$LONDD, early$LATDD, col = as.factor(early$state))
plot(late$LONDD_END, late$LATDD_END, col = as.factor(late$state))
ggplot(late, aes(x=LONDD_END, y=LATDD_END, col = as.factor(state))) + 
  geom_point() + facet_wrap("year")
ggplot(early, aes(x=LONDD, y=LATDD, col = as.factor(state))) + 
  geom_point() + facet_wrap("year")

#Sum total catches and determine number of vessels
#Confidentiality is based on vessel catching all species, but I only have vessels catching canary
#Based on email from Vanessa Tuttle, CA 1975 and 1976 are the only year-region combos that are truly confidential
early_agg <- early %>% group_by(state,year) %>% 
  summarize(sum = sum(SPECIES_EXTRAPOLATED_WT_KG * HAULS_SAMPLED_EXPANSION_FACTOR)/1000)
early_aggN <- early %>% group_by(state,year) %>%
  summarize(Nv = length(unique(VESSEL_CODE)), #Catcher boats aren't recorded until 1984 so still have issues with CA < 1984
            Nc = length(unique(CATCHER_BOAT_ADFG))) 
late_agg <- late %>% group_by(state,year) %>% 
  summarize(sum = sum(EXTRAPOLATED_WEIGHT_KG * `WEIGHT-BASED_EXPANSION_FACTOR`)/1000, 
            "just_landed" = sum(EXTRAPOLATED_WEIGHT_KG * PERCENT_RETAINED/100 * `WEIGHT-BASED_EXPANSION_FACTOR`)/1000)
late_aggN <- late %>% group_by(state,year) %>%
  summarize(Np = length(unique(PERMIT)),
            Nc = length(unique(CATCHER_BOAT_ADFG)))

#Combine and regroup because 1990 is in both datasets
ashop_agg <- rbind(early_agg, late_agg[,c("state","year","sum")])
ashop_agg <- ashop_agg %>% group_by(state,year) %>% summarize(sum = sum(sum))
ashop_wider <- ashop_agg %>% pivot_wider(names_from = state, values_from = sum) %>% arrange(year)
ashop_wider[is.na(ashop_wider)] <- 0

#Starting in 1992, no hake processing was allowed south of 42 degrees (in CA). 
#Combine CA landings after 1992 into Oregon
ashop_final <- ashop_wider
ashop_final[ashop_wider$year >= 1992,"OR"] <- ashop_wider[ashop_wider$year >= 1992, "CA"] + ashop_wider[ashop_wider$year >= 1992, "OR"]
ashop_final[ashop_wider$year >= 1992,"CA"] <- 0
#Due to confidentiality concerns remove 1975 and combine 1976 CA and OR
ashop_final[ashop_wider$year %in% c(1976),"OR"] <- ashop_final[ashop_wider$year %in% c(1976),"OR"] + ashop_final[ashop_wider$year %in% c(1976),"CA"]
ashop_final[ashop_wider$year %in% c(1975,1976),"CA"] <- 0

#write.csv(ashop_final, file = file.path(git_dir, "data", "canary_ashop_catch.csv"), row.names = FALSE)


#################################################################################################################
#---------------------------------------------------------------------------------------------------------------#
# Process Length data
#---------------------------------------------------------------------------------------------------------------#
#################################################################################################################

#Add needed variables (state)
length$state <- dplyr::case_when(#length$LATDD_END < 42.00 ~ "CA", #These are recent years so no CA fleet
                                 length$LATDD_END < 46.25 ~ "OR", 
                                 length$LATDD_END < 49.00 ~ "WA")
length$fleet <- length$state
length$source <- "ASHOP"

#Duplicate rows with multiple frequency in the bin
length <- length[rep(1:(dim(length)[1]), length$FREQUENCY),]

#Output number of lengths
trips_sample <- length %>%
  dplyr::group_by(YEAR, state) %>%
  dplyr::summarise(
    nhaul = length(unique(HAUL_JOIN)),
    N = length(LENGTH_CM)) %>%
  tidyr::pivot_wider(names_from = c(state), values_from = c(N,nhaul), 
                   names_glue = "{state}_{.value}", names_sort = TRUE)
trips_sample[is.na(trips_sample)] <- 0
colnames(trips_sample)[1] <- "Year"
# write.csv(trips_sample, row.names = FALSE, file = file.path(git_dir, "data", "Canary_ashop_LengthComps_hauls_and_samples.csv"))


####
# Length comps
####

#Choose to do unexpanded comps. Currently getExpansion_1 utilizes the weight of sampled fish
#and the weight of all fish for that species. Extrapolated weight of fish is available
#and weight of sampled fish could be calculated but work does not seem worthwhile given the 
#low percentage of catches the ASHOP fleet make up. Use unexpanded comps. Future work
#could be to develop an expansion conversion to get ASHOP data into a form to use with 
#PacFIN.UTILITIES

out <- length

# Add expected column names to work with nwfscSurvey package
out$age <- NA
out$sex_group <- "u"
out$sex_group[out$SEX %in% c("M", "F")] <- 'b'

length_bins <- c(seq(12, 66, 2))

#get sample size by sex group
n <- out %>% dplyr::group_by(YEAR, fleet, sex_group) %>%
  dplyr::summarise(
    nhaul = length(unique(HAUL_JOIN)),
    N = length(LENGTH_CM))
names(n)[1] <- "year"

#This creates the composition data for each ashop fleet. 
#Right now the script for sexed comps is in the unsexed_comps branch of nwfscSurvey
#so need to navigate to there and then load_all
# devtools::load_all("U:/Other github repos/nwfscSurvey") ###IMPORTANT TO UNCOMMENT THIS IF RERUN
for(s in unique(na.omit(out$fleet))) {
  
  use_n <- n[n$fleet %in% s, ]
  df <- data.frame(out[out$fleet %in% s, -which(colnames(out) %in% c("sex_group"))])
  
  if(dim(df)[1] > 0) {
    lfs <-  nwfscSurvey::UnexpandedLFs.fn(
      datL = df, 
      lgthBins = length_bins,
      partition = 0, 
      fleet = s, 
      month = 7)
    
    if(!is.null(lfs$unsexed) & is.null(lfs$sexed)){
      lfs$unsexed[,"InputN"] <- use_n[use_n$sex_group == "u", 'nhaul']
      write.csv(lfs$unsexed[,c(1:6,63,7:62)], 
                file = file.path(git_dir, "data", "forSS", paste0(s,"_ashop_not_expanded_Lcomp",length_bins[1],"_", tail(length_bins,1),"_formatted.csv")),
                row.names = FALSE) 
    } 
    if(!is.null(lfs$sexed) & is.null(lfs$unsexed)){
      lfs$sexed[,"InputN"] <- use_n[use_n$sex_group == "b", 'nhaul']
      write.csv(lfs$sexed[,c(1:6,63,7:62)], 
                file = file.path(git_dir, "data", "forSS", paste0(s,"_ashop_not_expanded_Lcomp",length_bins[1],"_", tail(length_bins,1),"_formatted.csv")),
                row.names = FALSE) 
    }
    
    if(!is.null(lfs$sexed) & !is.null(lfs$unsexed)){
      lfs$sexed[,"InputN"] <- use_n[use_n$sex_group == "b", 'nhaul']
      lfs$unsexed[,"InputN"] <- use_n[use_n$sex_group == "u", 'nhaul']
      colnames(lfs$unsexed) <- colnames(lfs$sexed)
      write.csv(rbind(lfs$unsexed, lfs$sexed)[,c(1:6,63,7:62)], 
                file = file.path(git_dir, "data", "forSS", paste0(s,"_ashop_not_expanded_Lcomp",length_bins[1],"_", tail(length_bins,1),"_formatted.csv")),
                row.names = FALSE) 
    }
    
    lfs <- NULL
  } #if loop from dim(df)
}


#################################################################################################################
#---------------------------------------------------------------------------------------------------------------#
# Process Age data
#---------------------------------------------------------------------------------------------------------------#
#################################################################################################################

#Add needed variables (state)
age$state <- dplyr::case_when(#age$LATDD_END < 42.00 ~ "CA", #These are recent years so no CA fleet
                              age$LATDD_END < 46.25 ~ "OR", 
                              age$LATDD_END < 49.00 ~ "WA")
age$fleet <- age$state
age$source <- "ASHOP"

#drop samples without ages
age <- age[!is.na(age$AGE),]

#Output number of ages
trips_sample <- age %>%
  dplyr::group_by(YEAR, state) %>%
  dplyr::summarise(
    nhaul = length(unique(HAUL_JOIN)),
    N = length(AGE)) %>%
  tidyr::pivot_wider(names_from = c(state), values_from = c(N,nhaul), 
                     names_glue = "{state}_{.value}", names_sort = TRUE)
trips_sample[is.na(trips_sample)] <- 0
colnames(trips_sample)[1] <- "Year"
# write.csv(trips_sample, row.names = FALSE, file = file.path(git_dir, "data", "Canary_ashop_AgeComps_hauls_and_samples.csv"))

####
# Age comp
####

out <- age

# Add expected column names to work with nwfscSurvey package
out$sex_group <- "u"
out$sex_group[out$SEX %in% c("M", "F")] <- 'b'

age_bins <- c(seq(1, 35, 1))

#get sample size by sex group
n <- out %>% dplyr::group_by(YEAR, fleet, sex_group) %>%
  dplyr::summarise(
    nhaul = length(unique(HAUL_JOIN)),
    N = length(AGE))
names(n)[1] <- "year"

#This creates the composition data for each ashop fleet. 
#Right now the script for sexed comps is in the unsexed_comps branch of nwfscSurvey
#so need to navigate to there and then load_all
# devtools::load_all("U:/Other github repos/nwfscSurvey") ###IMPORTANT TO UNCOMMENT THIS IF RERUN
for(s in unique(na.omit(out$fleet))) {
  
  use_n <- n[n$fleet %in% s, ]
  df <- data.frame(out[out$fleet %in% s, -which(colnames(out) %in% c("sex_group"))])
  
  if(dim(df)[1] > 0) {
    afs <-  nwfscSurvey::UnexpandedAFs.fn(
      datA = df, 
      ageBins = age_bins,
      partition = 0, 
      fleet = s,
      ageErr = 0,
      month = 7)
    
    if(!is.null(afs$unsexed) & is.null(afs$sexed)){
      afs$unsexed[,"InputN"] <- use_n[use_n$sex_group == "u", 'nhaul']
      write.csv(afs$unsexed[,c(1:9,80,10:79)], 
                file = file.path(git_dir, "data", "forSS", paste0(s,"_ashop_not_expanded_Acomp",age_bins[1],"_", tail(age_bins,1),"_formatted.csv")),
                row.names = FALSE) 
    } 
    if(!is.null(afs$sexed) & is.null(afs$unsexed)){
      afs$sexed[,"InputN"] <- use_n[use_n$sex_group == "b", 'nhaul']
      write.csv(afs$sexed[,c(1:9,80,10:79)], 
                file = file.path(git_dir, "data", "forSS", paste0(s,"_ashop_not_expanded_Acomp",age_bins[1],"_", tail(age_bins,1),"_formatted.csv")),
                row.names = FALSE) 
    }
    
    if(!is.null(afs$sexed) & !is.null(afs$unsexed)){
      afs$sexed[,"InputN"] <- use_n[use_n$sex_group == "b", 'nhaul']
      afs$unsexed[,"InputN"] <- use_n[use_n$sex_group == "u", 'nhaul']
      colnames(afs$unsexed) <- colnames(afs$sexed)
      write.csv(rbind(afs$unsexed, afs$sexed)[,c(1:9,80,10:79)], 
                file = file.path(git_dir, "data", "forSS", paste0(s,"_ashop_not_expanded_Acomp",age_bins[1],"_", tail(age_bins,1),"_formatted.csv")),
                row.names = FALSE) 
    }
    
    afs <- NULL
  } #if loop from dim(df)
}

