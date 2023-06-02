##########################################################################################
#
# Bridging model runs for 2023 Canary rockfish 
#   By: Kiva Oken and Brian Langseth
#
##########################################################################################

#devtools::install_github("r4ss/r4ss")
library(r4ss)
#devtools::install_github("pfmc-assessments/PEPtools")
library(PEPtools)
library(here)
library(dplyr)

#Add file managing section here 
#I will try to get 'here' to work but if I cant I will go with what I had
if(Sys.getenv("USERNAME") == "Brian.Langseth") {
  wd = "L:/"
}
if(Sys.getenv("USERNAME") == "Kiva.Oken") {
  wd = "Q:/"
}

source(here('code/selexComp.R'))


##########################################################################################
#                         Set up from 2015 base to current version
##########################################################################################


####------------------------------------------------####
### 3_1_1_update_data ----
####------------------------------------------------####

##
#Copy inputs
##

# I suggest not touching converted, or transition. That was just for updating SS3
# version, and plus just enough changes so that it actually ran. It was not 100% reproducible.
copy_SS_inputs(dir.old = here('models/converted'), 
               dir.new = here('models/Bridging coastwide/3_1_1_update_data'),
               overwrite = TRUE)

mod <- SS_read(here('models/Bridging coastwide/3_1_1_update_data'))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)


##
#Make Changes
##

mod$start$detailed_age_structure <- 1 #all output

# Extend year specific inputs to 2022 ------------------------------------------------

mod$dat$endyr <- 2022
mod$ctl$Block_Design[[1]][2] <- 2022
mod$ctl$Block_Design[[2]][4] <- 2022
mod$ctl$MainRdevYrLast <- 2022
mod$ctl$last_yr_fullbias_adj <- 2020
mod$ctl$first_recent_yr_nobias_adj <- 2022
mod$ctl$MG_parms[c('RecrDist_Area_2','RecrDist_Area_3'),'dev_maxyr'] <- 2022


# Extend catch time series ------------------------------------------------

catches <- read.csv(here('data/canary_total_removals.csv')) 
updated.catch.df <- catches |>
  dplyr::select(-rec.W.N) |>
  tidyr::pivot_longer(cols = -Year, names_to = 'fleet', values_to = 'catch') |>
  tidyr::separate(col = fleet, into = c('gear', 'state'), sep = '\\.') |> 
  # warning is ok, cuts off units in WA rec catch column name
  dplyr::mutate(gear = stringr::str_to_upper(gear),
                state = dplyr::case_when(state == 'W' ~ 'WA',
                                         state == 'O' ~ 'OR',
                                         state == 'C' ~ 'CA'),
                fleet_no_num = paste(state, gear, sep = '_')) |>
  dplyr::left_join(fleet.converter) |>
  dplyr::mutate(seas = 1, 
                catch_se = 0.05) |>
  dplyr::select(year = Year, seas, fleet, catch, catch_se) |>
  #rbind(c(-999, 1, 1, 0, 0.05)) |>
  dplyr::arrange(fleet, year) |>
  as.data.frame()

mod$dat$catch <- updated.catch.df

# Change survey fleets to non-catch fleets
survey.ind <- grep(mod$dat$fleetinfo$fleetname, pattern = 'Tri|NWFSC')
mod$dat$fleetinfo$type[survey.ind] <- 3

# Change fishing mortality to year-round, gets rid of ss3 warnings
mod$dat$fleetinfo$surveytiming[mod$dat$fleetinfo$type==1] <- -1

# Update survey indices ----------------------------------------------------------

wcgbts.cpue <- read.csv(file.path(wd,'Assessments/Assessment Data/2023 Assessment Cycle/canary rockfish/wcgbts/delta_lognormal/index/est_by_area.csv')) |>
  dplyr::mutate(fleet_no_num = paste0(area, '_NWFSC')) |>
  dplyr::left_join(fleet.converter) |> 
  dplyr::mutate(seas = 7) |>
  dplyr::select(year, seas, index = fleet, obs = est, se_log = se)

tri.cpue <- read.csv(file.path(wd,'Assessments/Assessment Data/2023 Assessment Cycle/canary rockfish/triennial/delta_lognormal_mix/index/est_by_area.csv')) |>
  dplyr::mutate(fleet_no_num = paste0(area, ifelse(year <= 1992, '_Tri_early', '_Tri_late'))) |>
  dplyr::left_join(fleet.converter) |> 
  dplyr::mutate(seas = 7) |>
  dplyr::select(year, seas, index = fleet, obs = est, se_log = se)

prerecruit <- read.csv(here('data/canary_prerecruit_indices.csv')) |>
  dplyr::filter(!(YEAR %in% c(2010, 2012, 2022))) |> # could also include these years...
  dplyr::mutate(fleet_no_num = paste0(region, '_prerec')) |>
  dplyr::left_join(fleet.converter) |> 
  dplyr::mutate(seas = 7) |>
  dplyr::select(year = YEAR, seas, index = fleet, obs = est, se_log = se)

mod$dat$CPUE <- dplyr::bind_rows(wcgbts.cpue, tri.cpue, prerecruit)

# Triennial selectivity and Q should probably be mirrored!!!


# Update combo survey comps -----------------------------------------------------

length.min <- min(mod$dat$lbin_vector)
length.max <- max(mod$dat$lbin_vector)
age.min <- min(mod$dat$agebin_vector)
age.max <- max(mod$dat$agebin_vector)

caal <- marginal.ages <- marginal.lengths <- list()
for(ii in 1:4) {
  area <- c('CA', 'OR', 'WA', 'coastwide')[ii]
  fleet_num <- fleet.converter$fleet[grep(x = fleet.converter$fleet_no_num, 
                                          pattern = paste0(area, "_NWFSC"))]
  caal[[area]] <- purrr::map(list(`F` = 'Female', M = 'Male'), function(.x) {
    read.csv(here(glue::glue('data/{area}_wcgbts_comps/Survey_CAAL_{sex}_Bins_{lmin}_{lmax}_{amin}_{amax}.csv',
                             area = area,
                             sex = .x,
                             lmin = length.min,
                             lmax = length.max,
                             amin = age.min,
                             amax = age.max))) |>
      dplyr::mutate(Fleet = fleet_num) |> 
      `names<-`(names(mod$dat$agecomp)) 
  })
  
  marginal.ages[[area]] <- read.csv(here(glue::glue('data/{area}_wcgbts_comps/Survey_Sex3_Bins_{amin}_{amax}_AgeComps.csv',
                                                    area = area,
                                                    amin = age.min,
                                                    amax = age.max))) |>
    dplyr::mutate(fleet = -1 * fleet_num,
                  agelow = -1,
                  agehigh = -1) |>
    `names<-`(names(mod$dat$agecomp))
  
  marginal.lengths[[area]] <- read.csv(here(glue::glue('data/{area}_wcgbts_comps/Survey_Sex3_Bins_{lmin}_{lmax}_LengthComps.csv',
                                                       area = area,
                                                       lmin = length.min,
                                                       lmax = length.max))) |>
    dplyr::mutate(fleet = fleet_num) |>
    `names<-`(names(mod$dat$lencomp))
  
}

caal.dfr <- caal |>
  purrr::list_flatten() |>
  purrr::list_rbind() |> 
  dplyr::mutate(Yr = ifelse(FltSvy == 28, -1 * Yr, Yr)) |> # exclude coastwide survey from likelihood
  # caal table is in absolute length, model is in length index.
  # Updating caal to be in length index
  dplyr::mutate(dplyr::across(Lbin_lo:Lbin_hi, ~ match(.x, mod$dat$lbin_vector)))

marginal.ages.dfr <- marginal.ages |>
  purrr::list_rbind() 
# Marginal ages already have negative fleet number

marginal.lengths.dfr <- marginal.lengths |>
  purrr::list_rbind() |>
  dplyr::mutate(Yr = ifelse(FltSvy == 28, -1 * Yr, Yr)) # exclude coastwide survey from likelihood

mod$dat$agecomp <- mod$dat$agecomp |> 
  dplyr::filter(!(FltSvy %in% unique(caal.dfr$FltSvy)),
                !(FltSvy %in% unique(marginal.ages.dfr$FltSvy))) |>
  dplyr::bind_rows(caal.dfr, marginal.ages.dfr)

mod$dat$lencomp <- mod$dat$lencomp |> 
  dplyr::filter(!(FltSvy %in% unique(marginal.lengths.dfr$FltSvy))) |>
  dplyr::bind_rows(marginal.lengths.dfr)

# Update triennial survey comps -----------------------------------------------------

caal <- marginal.ages <- marginal.lengths <- list()

for(ii in 1:4) {
  area <- c('CA', 'OR', 'WA', 'coastwide')[ii]
  fleet_num <- fleet.converter$fleet[grep(x = fleet.converter$fleet_no_num, 
                                          pattern = paste0(area, "_Tri"))]
  caal[[area]] <- purrr::map(list(`F` = 'Female', M = 'Male'), function(.x) {
    read.csv(here(glue::glue('data/{area}_tri_comps/Survey_CAAL_{sex}_Bins_{lmin}_{lmax}_{amin}_{amax}.csv',
                             area = area,
                             sex = .x,
                             lmin = length.min,
                             lmax = length.max,
                             amin = age.min,
                             amax = age.max))) |>
      dplyr::mutate(Fleet = ifelse(year <= 1992, fleet_num[1], fleet_num[2])) |>
      `names<-`(names(mod$dat$agecomp)) 
  })
  
  marginal.ages[[area]] <- read.csv(here(glue::glue('data/{area}_tri_comps/Survey_Sex3_Bins_{amin}_{amax}_AgeComps.csv',
                                                    area = area,
                                                    amin = age.min,
                                                    amax = age.max))) |>
    dplyr::mutate(fleet = -1 * ifelse(year <= 1992, fleet_num[1], fleet_num[2]),
                  agelow = -1,
                  agehigh = -1) |>
    `names<-`(names(mod$dat$agecomp))
  
  marginal.lengths[[area]] <- read.csv(here(glue::glue('data/{area}_tri_comps/Survey_Sex3_Bins_{lmin}_{lmax}_LengthComps.csv',
                                                       area = area,
                                                       lmin = length.min,
                                                       lmax = length.max))) |>
    dplyr::mutate(fleet = ifelse(year <= 1992, fleet_num[1], fleet_num[2])) |>
    `names<-`(names(mod$dat$lencomp))
  
}

caal.dfr <- caal |>
  purrr::list_flatten() |>
  purrr::list_rbind() |> 
  dplyr::mutate(Yr = ifelse(FltSvy %in% c(29,30), -1 * Yr, Yr)) |> # exclude coastwide survey from likelihood
  # caal table is in absolute length, model is in length index.
  # Updating caal to be in length index
  dplyr::mutate(dplyr::across(Lbin_lo:Lbin_hi, ~ match(.x, mod$dat$lbin_vector)))

marginal.ages.dfr <- marginal.ages |>
  purrr::list_rbind() 
# Marginal ages already have negative fleet number

marginal.lengths.dfr <- marginal.lengths |>
  purrr::list_rbind() |>
  dplyr::mutate(Yr = ifelse(FltSvy %in% c(29,30), -1 * Yr, Yr)) # exclude coastwide survey from likelihood

mod$dat$agecomp <- mod$dat$agecomp |> 
  dplyr::filter(!(FltSvy %in% unique(caal.dfr$FltSvy)),
                !(FltSvy %in% unique(marginal.ages.dfr$FltSvy))) |>
  dplyr::bind_rows(caal.dfr, marginal.ages.dfr)

mod$dat$lencomp <- mod$dat$lencomp |> 
  dplyr::filter(!(FltSvy %in% unique(marginal.lengths.dfr$FltSvy))) |>
  dplyr::bind_rows(marginal.lengths.dfr)
# Note: consider switching triennial to marginal ages.

# Update fishery comps ----------------------------------------------------

read.fishery.comps <- function(filename, exclude) {
  
}

pacfin.ages <- purrr::map(list('CA', 'OR', 'WA'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_PacFIN_Acomps_{amin}_{amax}_formatted.csv',
                           area = .x,
                           amin = age.min,
                           amax = age.max))) |>
    dplyr::select(-state, -Ntows, -Nsamps) |>
    dplyr::mutate(fleet = sapply(fleet, function(.fleet)
      fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_{fleet}',
                                                                       area = .x,
                                                                       fleet = .fleet)])) |> 
    `names<-`(names(mod$dat$agecomp))
}) |> 
  purrr::list_rbind() 

pacfin.lengths <- purrr::map(list('CA', 'OR', 'WA'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_PacFIN_Lcomps_{lmin}_{lmax}_formatted.csv',
                           area = .x,
                           lmin = length.min,
                           lmax = length.max))) |>
    dplyr::select(-state, -Ntows, -Nsamps) |>
    dplyr::mutate(fleet = sapply(fleet, function(.fleet)
      fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_{fleet}',
                                                                       area = .x, 
                                                                       fleet = .fleet)])) |>
    `names<-`(names(mod$dat$lencomp))
}) |>
  purrr::list_rbind()

rec.ages <- purrr::map(list('OR', 'WA'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_rec_not_expanded_Acomp{amin}_{amax}_formatted.csv',
                           area = .x,
                           amin = age.min,
                           amax = age.max))) |>
    dplyr::select(-Nsamp) |>
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_REC',
                                                                                           area = .x)],
                  ageErr = dplyr::case_when(grepl("OR",fleet.converter$fleet_no_num[fleet]) ~ 1, #non-expanded has different names than expanded so ageErr here
                                            grepl("WA",fleet.converter$fleet_no_num[fleet]) ~ 2)) |> 
    `names<-`(names(mod$dat$agecomp))
}) |>
  purrr::list_rbind()

rec.lengths <- purrr::map(list('CA', 'OR', 'WA'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_rec_not_expanded_Lcomp{lmin}_{lmax}_formatted.csv',
                           area = .x,
                           lmin = length.min,
                           lmax = length.max))) |>
    dplyr::select(-Nsamp) |>
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_REC',
                                                                                           area = .x)]) |>
    `names<-`(names(mod$dat$lencomp))
}) |>
  purrr::list_rbind()

ashop.ages <- purrr::map(list('OR', 'WA'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_ashop_not_expanded_Acomp{amin}_{amax}_formatted.csv',
                           area = .x,
                           amin = age.min,
                           amax = age.max))) |>
    dplyr::select(-Nsamp) |>
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_ASHOP',
                                                                                           area = .x)],
                  ageErr = 1) |> #non-expanded has different names than expanded so ageErr here
    `names<-`(names(mod$dat$agecomp))
}) |>
  purrr::list_rbind()

ashop.lengths <- purrr::map(list('OR', 'WA'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_ashop_not_expanded_Lcomp{lmin}_{lmax}_formatted.csv',
                           area = .x,
                           lmin = length.min,
                           lmax = length.max))) |>
    dplyr::select(-Nsamp) |>
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_ASHOP',
                                                                                           area = .x)]) |>
    `names<-`(names(mod$dat$lencomp))
}) |>
  purrr::list_rbind()


mod$dat$agecomp <- mod$dat$agecomp |> 
  dplyr::filter(!(FltSvy %in% unique(pacfin.ages$FltSvy)),
                !(FltSvy %in% unique(rec.ages$FltSvy)),
                !(FltSvy %in% unique(ashop.ages$FltSvy))) |>
  dplyr::bind_rows(pacfin.ages, rec.ages, ashop.ages)

mod$dat$lencomp <- mod$dat$lencomp |> 
  dplyr::filter(!(FltSvy %in% unique(pacfin.lengths$FltSvy)),
                !(FltSvy %in% unique(rec.lengths$FltSvy)),
                !(FltSvy %in% unique(ashop.lengths$FltSvy))) |>
  dplyr::bind_rows(pacfin.lengths, rec.lengths, ashop.lengths)

#Exclude CA ASHOP length and age comps
mod$dat$lencomp <- mod$dat$lencomp[mod$dat$lencomp$FltSvy!=10,]
mod$dat$agecomp <- mod$dat$agecomp[mod$dat$agecomp$FltSvy!=10,]

#Remove var_adj values for CA rec (age) and CA ashop (age and length)
mod$ctl$Variance_adjustment_list <- mod$ctl$Variance_adjustment_list[
  -c(which(mod$ctl$Variance_adjustment_list$Fleet == 7 & mod$ctl$Variance_adjustment_list$Data_type == 5),
     which(mod$ctl$Variance_adjustment_list$Fleet == 10)),]

##----
#Output files and run
##

SS_write(mod,
         dir = here('models/Bridging coastwide/3_1_1_update_data'),
         overwrite = TRUE)

# r4ss::run(dir = here('models/Bridging coastwide/3_1_1_update_data'), 
#           exe = here('models/ss_win.exe'), 
#           extras = '-nohess', 
#           # show_in_console = TRUE, 
#           skipfinished = FALSE)

pp <- SS_output(here('models','Bridging coastwide/3_1_1_update_data'))
SS_plots(pp, plot = c(1:26))


####------------------------------------------------####
### 3_1_2_catch Individually add data one by one ----
####------------------------------------------------####

new_name <- 'Bridging coastwide/3_1_2_catch'

##
#Copy inputs
##

# I suggest not touching converted, or transition. That was just for updating SS3
# version, and plus just enough changes so that it actually ran. It was not 100% reproducible.
copy_SS_inputs(dir.old = here('models/converted'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models', new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)


##
#Make Changes
##

mod$start$detailed_age_structure <- 1 #all output

# Extend year specific inputs to 2022 ------------------------------------------------

mod$dat$endyr <- 2022
mod$ctl$Block_Design[[1]][2] <- 2022
mod$ctl$Block_Design[[2]][4] <- 2022
mod$ctl$MainRdevYrLast <- 2022
mod$ctl$last_yr_fullbias_adj <- 2020
mod$ctl$first_recent_yr_nobias_adj <- 2022
mod$ctl$MG_parms[c('RecrDist_Area_2','RecrDist_Area_3'),'dev_maxyr'] <- 2022


# Extend catch time series ------------------------------------------------

catches <- read.csv(here('data/canary_total_removals.csv')) 
updated.catch.df <- catches |>
  dplyr::select(-rec.W.N) |>
  tidyr::pivot_longer(cols = -Year, names_to = 'fleet', values_to = 'catch') |>
  tidyr::separate(col = fleet, into = c('gear', 'state'), sep = '\\.') |> 
  # warning is ok, cuts off units in WA rec catch column name
  dplyr::mutate(gear = stringr::str_to_upper(gear),
                state = dplyr::case_when(state == 'W' ~ 'WA',
                                         state == 'O' ~ 'OR',
                                         state == 'C' ~ 'CA'),
                fleet_no_num = paste(state, gear, sep = '_')) |>
  dplyr::left_join(fleet.converter) |>
  dplyr::mutate(seas = 1, 
                catch_se = 0.05) |>
  dplyr::select(year = Year, seas, fleet, catch, catch_se) |>
  #rbind(c(-999, 1, 1, 0, 0.05)) |>
  dplyr::arrange(fleet, year) |>
  as.data.frame()

mod$dat$catch <- updated.catch.df

# Change survey fleets to non-catch fleets
survey.ind <- grep(mod$dat$fleetinfo$fleetname, pattern = 'Tri|NWFSC')
mod$dat$fleetinfo$type[survey.ind] <- 3

# Change fishing mortality to year-round, gets rid of ss3 warnings
mod$dat$fleetinfo$surveytiming[mod$dat$fleetinfo$type==1] <- -1


##
#Output files and run
##

SS_write(mod,
         dir = here('models', new_name),
         overwrite = TRUE)

# r4ss::run(dir = here('models', new_name), 
#           exe = here('models/ss_win.exe'), 
#           extras = '-nohess', 
#           # show_in_console = TRUE, 
#           skipfinished = FALSE)

####------------------------------------------------####
### 3_1_3_survey Individually add data one by one ----
####------------------------------------------------####

new_name <- 'Bridging coastwide/3_1_3_survey'

##
#Copy inputs
##

# I suggest not touching converted, or transition. That was just for updating SS3
# version, and plus just enough changes so that it actually ran. It was not 100% reproducible.
copy_SS_inputs(dir.old = here('models/converted'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models', new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)


##
#Make Changes
##

mod$start$detailed_age_structure <- 1 #all output

# Extend year specific inputs to 2022 ------------------------------------------------

mod$dat$endyr <- 2022
mod$ctl$Block_Design[[1]][2] <- 2022
mod$ctl$Block_Design[[2]][4] <- 2022
mod$ctl$MainRdevYrLast <- 2022
mod$ctl$last_yr_fullbias_adj <- 2020
mod$ctl$first_recent_yr_nobias_adj <- 2022
mod$ctl$MG_parms[c('RecrDist_Area_2','RecrDist_Area_3'),'dev_maxyr'] <- 2022

# Update survey indices ----------------------------------------------------------

wcgbts.cpue <- read.csv(file.path(wd,'Assessments/Assessment Data/2023 Assessment Cycle/canary rockfish/wcgbts/delta_lognormal/index/est_by_area.csv')) |>
  dplyr::mutate(fleet_no_num = paste0(area, '_NWFSC')) |>
  dplyr::left_join(fleet.converter) |> 
  dplyr::mutate(seas = 7) |>
  dplyr::select(year, seas, index = fleet, obs = est, se_log = se)

tri.cpue <- read.csv(file.path(wd,'Assessments/Assessment Data/2023 Assessment Cycle/canary rockfish/triennial/delta_lognormal_mix/index/est_by_area.csv')) |>
  dplyr::mutate(fleet_no_num = paste0(area, ifelse(year <= 1992, '_Tri_early', '_Tri_late'))) |>
  dplyr::left_join(fleet.converter) |> 
  dplyr::mutate(seas = 7) |>
  dplyr::select(year, seas, index = fleet, obs = est, se_log = se)

prerecruit <- read.csv(here('data/canary_prerecruit_indices.csv')) |>
  dplyr::filter(!(YEAR %in% c(2010, 2012, 2022))) |> # could also include these years...
  dplyr::mutate(fleet_no_num = paste0(region, '_prerec')) |>
  dplyr::left_join(fleet.converter) |> 
  dplyr::mutate(seas = 7) |>
  dplyr::select(year = YEAR, seas, index = fleet, obs = est, se_log = se)

mod$dat$CPUE <- dplyr::bind_rows(wcgbts.cpue, tri.cpue, prerecruit)

# Triennial selectivity and Q should probably be mirrored!!!


##
#Output files and run
##

SS_write(mod,
         dir = here('models', new_name),
         overwrite = TRUE)

# r4ss::run(dir = here('models',new_name), 
#           exe = here('models/ss_win.exe'), 
#           extras = '-nohess', 
#           # show_in_console = TRUE, 
#           skipfinished = FALSE)


####------------------------------------------------####
### 3_1_4_surveyCompsNWFSC Individually add data one by one ----
####------------------------------------------------####

new_name <- 'Bridging coastwide/3_1_4_surveyCompsNWFSC'

##
#Copy inputs
##

# I suggest not touching converted, or transition. That was just for updating SS3
# version, and plus just enough changes so that it actually ran. It was not 100% reproducible.
copy_SS_inputs(dir.old = here('models/converted'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models', new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)


##
#Make Changes
##

mod$start$detailed_age_structure <- 1 #all output

# Extend year specific inputs to 2022 ------------------------------------------------

mod$dat$endyr <- 2022
mod$ctl$Block_Design[[1]][2] <- 2022
mod$ctl$Block_Design[[2]][4] <- 2022
mod$ctl$MainRdevYrLast <- 2022
mod$ctl$last_yr_fullbias_adj <- 2020
mod$ctl$first_recent_yr_nobias_adj <- 2022
mod$ctl$MG_parms[c('RecrDist_Area_2','RecrDist_Area_3'),'dev_maxyr'] <- 2022

# Update combo survey comps -----------------------------------------------------

length.min <- min(mod$dat$lbin_vector)
length.max <- max(mod$dat$lbin_vector)
age.min <- min(mod$dat$agebin_vector)
age.max <- max(mod$dat$agebin_vector)

caal <- marginal.ages <- marginal.lengths <- list()
for(ii in 1:4) {
  area <- c('CA', 'OR', 'WA', 'coastwide')[ii]
  fleet_num <- fleet.converter$fleet[grep(x = fleet.converter$fleet_no_num, 
                                          pattern = paste0(area, "_NWFSC"))]
  caal[[area]] <- purrr::map(list(`F` = 'Female', M = 'Male'), function(.x) {
    read.csv(here(glue::glue('data/{area}_wcgbts_comps/Survey_CAAL_{sex}_Bins_{lmin}_{lmax}_{amin}_{amax}.csv',
                             area = area,
                             sex = .x,
                             lmin = length.min,
                             lmax = length.max,
                             amin = age.min,
                             amax = age.max))) |>
      dplyr::mutate(Fleet = fleet_num) |> 
      `names<-`(names(mod$dat$agecomp)) 
  })
  
  marginal.ages[[area]] <- read.csv(here(glue::glue('data/{area}_wcgbts_comps/Survey_Sex3_Bins_{amin}_{amax}_AgeComps.csv',
                                                    area = area,
                                                    amin = age.min,
                                                    amax = age.max))) |>
    dplyr::mutate(fleet = -1 * fleet_num,
                  agelow = -1,
                  agehigh = -1) |>
    `names<-`(names(mod$dat$agecomp))
  
  marginal.lengths[[area]] <- read.csv(here(glue::glue('data/{area}_wcgbts_comps/Survey_Sex3_Bins_{lmin}_{lmax}_LengthComps.csv',
                                                       area = area,
                                                       lmin = length.min,
                                                       lmax = length.max))) |>
    dplyr::mutate(fleet = fleet_num) |>
    `names<-`(names(mod$dat$lencomp))
  
}

caal.dfr <- caal |>
  purrr::list_flatten() |>
  purrr::list_rbind() |> 
  dplyr::mutate(Yr = ifelse(FltSvy == 28, -1 * Yr, Yr)) |> # exclude coastwide survey from likelihood
  # caal table is in absolute length, model is in length index.
  # Updating caal to be in length index
  dplyr::mutate(dplyr::across(Lbin_lo:Lbin_hi, ~ match(.x, mod$dat$lbin_vector)))

marginal.ages.dfr <- marginal.ages |>
  purrr::list_rbind() 
# Marginal ages already have negative fleet number

marginal.lengths.dfr <- marginal.lengths |>
  purrr::list_rbind() |>
  dplyr::mutate(Yr = ifelse(FltSvy == 28, -1 * Yr, Yr)) # exclude coastwide survey from likelihood

mod$dat$agecomp <- mod$dat$agecomp |> 
  dplyr::filter(!(FltSvy %in% unique(caal.dfr$FltSvy)),
                !(FltSvy %in% unique(marginal.ages.dfr$FltSvy))) |>
  dplyr::bind_rows(caal.dfr, marginal.ages.dfr)

mod$dat$lencomp <- mod$dat$lencomp |> 
  dplyr::filter(!(FltSvy %in% unique(marginal.lengths.dfr$FltSvy))) |>
  dplyr::bind_rows(marginal.lengths.dfr)

##
#Output files and run
##

SS_write(mod,
         dir = here('models', new_name),
         overwrite = TRUE)

# r4ss::run(dir = here('models', new_name), 
#           exe = here('models/ss_win.exe'), 
#           extras = '-nohess', 
#           # show_in_console = TRUE, 
#           skipfinished = FALSE)


####------------------------------------------------####
### 3_1_5_surveyCompsTri Individually add data one by one ----
####------------------------------------------------####

new_name <- 'Bridging coastwide/3_1_5_surveyCompsTri'

##
#Copy inputs
##

# I suggest not touching converted, or transition. That was just for updating SS3
# version, and plus just enough changes so that it actually ran. It was not 100% reproducible.
copy_SS_inputs(dir.old = here('models/converted'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models', new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)


##
#Make Changes
##

mod$start$detailed_age_structure <- 1 #all output

# Extend year specific inputs to 2022 ------------------------------------------------

mod$dat$endyr <- 2022
mod$ctl$Block_Design[[1]][2] <- 2022
mod$ctl$Block_Design[[2]][4] <- 2022
mod$ctl$MainRdevYrLast <- 2022
mod$ctl$last_yr_fullbias_adj <- 2020
mod$ctl$first_recent_yr_nobias_adj <- 2022
mod$ctl$MG_parms[c('RecrDist_Area_2','RecrDist_Area_3'),'dev_maxyr'] <- 2022

# Update triennial survey comps -----------------------------------------------------

caal <- marginal.ages <- marginal.lengths <- list()

for(ii in 1:4) {
  area <- c('CA', 'OR', 'WA', 'coastwide')[ii]
  fleet_num <- fleet.converter$fleet[grep(x = fleet.converter$fleet_no_num, 
                                          pattern = paste0(area, "_Tri"))]
  caal[[area]] <- purrr::map(list(`F` = 'Female', M = 'Male'), function(.x) {
    read.csv(here(glue::glue('data/{area}_tri_comps/Survey_CAAL_{sex}_Bins_{lmin}_{lmax}_{amin}_{amax}.csv',
                             area = area,
                             sex = .x,
                             lmin = length.min,
                             lmax = length.max,
                             amin = age.min,
                             amax = age.max))) |>
      dplyr::mutate(Fleet = ifelse(year <= 1992, fleet_num[1], fleet_num[2])) |>
      `names<-`(names(mod$dat$agecomp)) 
  })
  
  marginal.ages[[area]] <- read.csv(here(glue::glue('data/{area}_tri_comps/Survey_Sex3_Bins_{amin}_{amax}_AgeComps.csv',
                                                    area = area,
                                                    amin = age.min,
                                                    amax = age.max))) |>
    dplyr::mutate(fleet = -1 * ifelse(year <= 1992, fleet_num[1], fleet_num[2]),
                  agelow = -1,
                  agehigh = -1) |>
    `names<-`(names(mod$dat$agecomp))
  
  marginal.lengths[[area]] <- read.csv(here(glue::glue('data/{area}_tri_comps/Survey_Sex3_Bins_{lmin}_{lmax}_LengthComps.csv',
                                                       area = area,
                                                       lmin = length.min,
                                                       lmax = length.max))) |>
    dplyr::mutate(fleet = ifelse(year <= 1992, fleet_num[1], fleet_num[2])) |>
    `names<-`(names(mod$dat$lencomp))
  
}

caal.dfr <- caal |>
  purrr::list_flatten() |>
  purrr::list_rbind() |> 
  dplyr::mutate(Yr = ifelse(FltSvy %in% c(29,30), -1 * Yr, Yr)) |> # exclude coastwide survey from likelihood
  # caal table is in absolute length, model is in length index.
  # Updating caal to be in length index
  dplyr::mutate(dplyr::across(Lbin_lo:Lbin_hi, ~ match(.x, mod$dat$lbin_vector)))

marginal.ages.dfr <- marginal.ages |>
  purrr::list_rbind() 
# Marginal ages already have negative fleet number

marginal.lengths.dfr <- marginal.lengths |>
  purrr::list_rbind() |>
  dplyr::mutate(Yr = ifelse(FltSvy %in% c(29,30), -1 * Yr, Yr)) # exclude coastwide survey from likelihood

mod$dat$agecomp <- mod$dat$agecomp |> 
  dplyr::filter(!(FltSvy %in% unique(caal.dfr$FltSvy)),
                !(FltSvy %in% unique(marginal.ages.dfr$FltSvy))) |>
  dplyr::bind_rows(caal.dfr, marginal.ages.dfr)

mod$dat$lencomp <- mod$dat$lencomp |> 
  dplyr::filter(!(FltSvy %in% unique(marginal.lengths.dfr$FltSvy))) |>
  dplyr::bind_rows(marginal.lengths.dfr)
# Note: consider switching triennial to marginal ages.


##
#Output files and run
##

SS_write(mod,
         dir = here('models', new_name),
         overwrite = TRUE)

# r4ss::run(dir = here('models', new_name), 
#           exe = here('models/ss_win.exe'), 
#           extras = '-nohess', 
#           # show_in_console = TRUE, 
#           skipfinished = FALSE)


####------------------------------------------------####
### 3_1_6_fisheryComps Individually add data one by one ----
####------------------------------------------------####

new_name <- 'Bridging coastwide/3_1_6_fisheryComps'

##
#Copy inputs
##

# I suggest not touching converted, or transition. That was just for updating SS3
# version, and plus just enough changes so that it actually ran. It was not 100% reproducible.
copy_SS_inputs(dir.old = here('models/converted'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models', new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)


##
#Make Changes
##

mod$start$detailed_age_structure <- 1 #all output

# Extend year specific inputs to 2022 ------------------------------------------------

mod$dat$endyr <- 2022
mod$ctl$Block_Design[[1]][2] <- 2022
mod$ctl$Block_Design[[2]][4] <- 2022
mod$ctl$MainRdevYrLast <- 2022
mod$ctl$last_yr_fullbias_adj <- 2020
mod$ctl$first_recent_yr_nobias_adj <- 2022
mod$ctl$MG_parms[c('RecrDist_Area_2','RecrDist_Area_3'),'dev_maxyr'] <- 2022

# Update fishery comps ----------------------------------------------------

read.fishery.comps <- function(filename, exclude) {
  
}

pacfin.ages <- purrr::map(list('CA', 'OR', 'WA'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_PacFIN_Acomps_{amin}_{amax}_formatted.csv',
                           area = .x,
                           amin = age.min,
                           amax = age.max))) |>
    dplyr::select(-state, -Ntows, -Nsamps) |>
    dplyr::mutate(fleet = sapply(fleet, function(.fleet)
      fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_{fleet}',
                                                                       area = .x,
                                                                       fleet = .fleet)])) |> 
    `names<-`(names(mod$dat$agecomp))
}) |> 
  purrr::list_rbind() 

pacfin.lengths <- purrr::map(list('CA', 'OR', 'WA'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_PacFIN_Lcomps_{lmin}_{lmax}_formatted.csv',
                           area = .x,
                           lmin = length.min,
                           lmax = length.max))) |>
    dplyr::select(-state, -Ntows, -Nsamps) |>
    dplyr::mutate(fleet = sapply(fleet, function(.fleet)
      fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_{fleet}',
                                                                       area = .x, 
                                                                       fleet = .fleet)])) |>
    `names<-`(names(mod$dat$lencomp))
}) |>
  purrr::list_rbind()

rec.ages <- purrr::map(list('OR', 'WA'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_rec_not_expanded_Acomp{amin}_{amax}_formatted.csv',
                           area = .x,
                           amin = age.min,
                           amax = age.max))) |>
    dplyr::select(-Nsamp) |>
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_REC',
                                                                                           area = .x)],
                  ageErr = dplyr::case_when(grepl("OR",fleet.converter$fleet_no_num[fleet]) ~ 1, #non-expanded has different names than expanded so ageErr here
                                            grepl("WA",fleet.converter$fleet_no_num[fleet]) ~ 2)) |> 
    `names<-`(names(mod$dat$agecomp))
}) |>
  purrr::list_rbind()

rec.lengths <- purrr::map(list('CA', 'OR', 'WA'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_rec_not_expanded_Lcomp{lmin}_{lmax}_formatted.csv',
                           area = .x,
                           lmin = length.min,
                           lmax = length.max))) |>
    dplyr::select(-Nsamp) |>
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_REC',
                                                                                           area = .x)]) |>
    `names<-`(names(mod$dat$lencomp))
}) |>
  purrr::list_rbind()

ashop.ages <- purrr::map(list('OR', 'WA'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_ashop_not_expanded_Acomp{amin}_{amax}_formatted.csv',
                           area = .x,
                           amin = age.min,
                           amax = age.max))) |>
    dplyr::select(-Nsamp) |>
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_ASHOP',
                                                                                           area = .x)],
                  ageErr = 1) |> #non-expanded has different names than expanded so ageErr here
    `names<-`(names(mod$dat$agecomp))
}) |>
  purrr::list_rbind()

ashop.lengths <- purrr::map(list('OR', 'WA'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_ashop_not_expanded_Lcomp{lmin}_{lmax}_formatted.csv',
                           area = .x,
                           lmin = length.min,
                           lmax = length.max))) |>
    dplyr::select(-Nsamp) |>
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_ASHOP',
                                                                                           area = .x)]) |>
    `names<-`(names(mod$dat$lencomp))
}) |>
  purrr::list_rbind()


mod$dat$agecomp <- mod$dat$agecomp |> 
  dplyr::filter(!(FltSvy %in% unique(pacfin.ages$FltSvy)),
                !(FltSvy %in% unique(rec.ages$FltSvy)),
                !(FltSvy %in% unique(ashop.ages$FltSvy))) |>
  dplyr::bind_rows(pacfin.ages, rec.ages, ashop.ages)

mod$dat$lencomp <- mod$dat$lencomp |> 
  dplyr::filter(!(FltSvy %in% unique(pacfin.lengths$FltSvy)),
                !(FltSvy %in% unique(rec.lengths$FltSvy)),
                !(FltSvy %in% unique(ashop.lengths$FltSvy))) |>
  dplyr::bind_rows(pacfin.lengths, rec.lengths, ashop.lengths)

#Exclude CA ASHOP length and age comps
mod$dat$lencomp <- mod$dat$lencomp[mod$dat$lencomp$FltSvy!=10,]
mod$dat$agecomp <- mod$dat$agecomp[mod$dat$agecomp$FltSvy!=10,]

#Remove var_adj values for CA rec (age) and CA ashop (age and length)
mod$ctl$Variance_adjustment_list <- mod$ctl$Variance_adjustment_list[
  -c(which(mod$ctl$Variance_adjustment_list$Fleet == 7 & mod$ctl$Variance_adjustment_list$Data_type == 5),
     which(mod$ctl$Variance_adjustment_list$Fleet == 10)),]

##----
#Output files and run
##

SS_write(mod,
         dir = here('models', new_name),
         overwrite = TRUE)

# r4ss::run(dir = here('models', new_name), 
#           exe = here('models/ss_win.exe'), 
#           extras = '-nohess', 
#           # show_in_console = TRUE, 
#           skipfinished = FALSE)


xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('converted', 
                                                 'Bridging coastwide/3_1_1_update_data', 
                                                 'Bridging coastwide/3_1_2_catch',
                                                 'Bridging coastwide/3_1_3_survey',
                                                 'Bridging coastwide/3_1_4_surveyCompsNWFSC',
                                                 'Bridging coastwide/3_1_5_surveyCompsTri',
                                                 'Bridging coastwide/3_1_6_fisheryComps')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015converted', '2023 All data', 
                                     'Catch',
                                     'Survey',
                                     'SurveyCompsNWFSC',
                                     'SurveyCompsTri',
                                     'fisheryComps'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name) )



####------------------------------------------------####
### 3_1_7_fishery Add catches and fishery comps ----
####------------------------------------------------####

new_name <- 'Bridging coastwide/3_1_7_fishery'

##
#Copy inputs
##

# I suggest not touching converted, or transition. That was just for updating SS3
# version, and plus just enough changes so that it actually ran. It was not 100% reproducible.
copy_SS_inputs(dir.old = here('models/converted'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models', new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)


##
#Make Changes
##

mod$start$detailed_age_structure <- 1 #all output

# Extend year specific inputs to 2022 ------------------------------------------------

mod$dat$endyr <- 2022
mod$ctl$Block_Design[[1]][2] <- 2022
mod$ctl$Block_Design[[2]][4] <- 2022
mod$ctl$MainRdevYrLast <- 2022
mod$ctl$last_yr_fullbias_adj <- 2020
mod$ctl$first_recent_yr_nobias_adj <- 2022
mod$ctl$MG_parms[c('RecrDist_Area_2','RecrDist_Area_3'),'dev_maxyr'] <- 2022


# Extend catch time series ------------------------------------------------

catches <- read.csv(here('data/canary_total_removals.csv')) 
updated.catch.df <- catches |>
  dplyr::select(-rec.W.N) |>
  tidyr::pivot_longer(cols = -Year, names_to = 'fleet', values_to = 'catch') |>
  tidyr::separate(col = fleet, into = c('gear', 'state'), sep = '\\.') |> 
  # warning is ok, cuts off units in WA rec catch column name
  dplyr::mutate(gear = stringr::str_to_upper(gear),
                state = dplyr::case_when(state == 'W' ~ 'WA',
                                         state == 'O' ~ 'OR',
                                         state == 'C' ~ 'CA'),
                fleet_no_num = paste(state, gear, sep = '_')) |>
  dplyr::left_join(fleet.converter) |>
  dplyr::mutate(seas = 1, 
                catch_se = 0.05) |>
  dplyr::select(year = Year, seas, fleet, catch, catch_se) |>
  #rbind(c(-999, 1, 1, 0, 0.05)) |>
  dplyr::arrange(fleet, year) |>
  as.data.frame()

mod$dat$catch <- updated.catch.df

# Change survey fleets to non-catch fleets
survey.ind <- grep(mod$dat$fleetinfo$fleetname, pattern = 'Tri|NWFSC')
mod$dat$fleetinfo$type[survey.ind] <- 3

# Change fishing mortality to year-round, gets rid of ss3 warnings
mod$dat$fleetinfo$surveytiming[mod$dat$fleetinfo$type==1] <- -1

# Update fishery comps ----------------------------------------------------

read.fishery.comps <- function(filename, exclude) {
  
}

pacfin.ages <- purrr::map(list('CA', 'OR', 'WA'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_PacFIN_Acomps_{amin}_{amax}_formatted.csv',
                           area = .x,
                           amin = age.min,
                           amax = age.max))) |>
    dplyr::select(-state, -Ntows, -Nsamps) |>
    dplyr::mutate(fleet = sapply(fleet, function(.fleet)
      fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_{fleet}',
                                                                       area = .x,
                                                                       fleet = .fleet)])) |> 
    `names<-`(names(mod$dat$agecomp))
}) |> 
  purrr::list_rbind() 

pacfin.lengths <- purrr::map(list('CA', 'OR', 'WA'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_PacFIN_Lcomps_{lmin}_{lmax}_formatted.csv',
                           area = .x,
                           lmin = length.min,
                           lmax = length.max))) |>
    dplyr::select(-state, -Ntows, -Nsamps) |>
    dplyr::mutate(fleet = sapply(fleet, function(.fleet)
      fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_{fleet}',
                                                                       area = .x, 
                                                                       fleet = .fleet)])) |>
    `names<-`(names(mod$dat$lencomp))
}) |>
  purrr::list_rbind()

rec.ages <- purrr::map(list('OR', 'WA'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_rec_not_expanded_Acomp{amin}_{amax}_formatted.csv',
                           area = .x,
                           amin = age.min,
                           amax = age.max))) |>
    dplyr::select(-Nsamp) |>
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_REC',
                                                                                           area = .x)],
                  ageErr = dplyr::case_when(grepl("OR",fleet.converter$fleet_no_num[fleet]) ~ 1, #non-expanded has different names than expanded so ageErr here
                                            grepl("WA",fleet.converter$fleet_no_num[fleet]) ~ 2)) |> 
    `names<-`(names(mod$dat$agecomp))
}) |>
  purrr::list_rbind()

rec.lengths <- purrr::map(list('CA', 'OR', 'WA'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_rec_not_expanded_Lcomp{lmin}_{lmax}_formatted.csv',
                           area = .x,
                           lmin = length.min,
                           lmax = length.max))) |>
    dplyr::select(-Nsamp) |>
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_REC',
                                                                                           area = .x)]) |>
    `names<-`(names(mod$dat$lencomp))
}) |>
  purrr::list_rbind()

ashop.ages <- purrr::map(list('OR', 'WA'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_ashop_not_expanded_Acomp{amin}_{amax}_formatted.csv',
                           area = .x,
                           amin = age.min,
                           amax = age.max))) |>
    dplyr::select(-Nsamp) |>
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_ASHOP',
                                                                                           area = .x)],
                  ageErr = 1) |> #non-expanded has different names than expanded so ageErr here
    `names<-`(names(mod$dat$agecomp))
}) |>
  purrr::list_rbind()

ashop.lengths <- purrr::map(list('OR', 'WA'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_ashop_not_expanded_Lcomp{lmin}_{lmax}_formatted.csv',
                           area = .x,
                           lmin = length.min,
                           lmax = length.max))) |>
    dplyr::select(-Nsamp) |>
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_ASHOP',
                                                                                           area = .x)]) |>
    `names<-`(names(mod$dat$lencomp))
}) |>
  purrr::list_rbind()


mod$dat$agecomp <- mod$dat$agecomp |> 
  dplyr::filter(!(FltSvy %in% unique(pacfin.ages$FltSvy)),
                !(FltSvy %in% unique(rec.ages$FltSvy)),
                !(FltSvy %in% unique(ashop.ages$FltSvy))) |>
  dplyr::bind_rows(pacfin.ages, rec.ages, ashop.ages)

mod$dat$lencomp <- mod$dat$lencomp |> 
  dplyr::filter(!(FltSvy %in% unique(pacfin.lengths$FltSvy)),
                !(FltSvy %in% unique(rec.lengths$FltSvy)),
                !(FltSvy %in% unique(ashop.lengths$FltSvy))) |>
  dplyr::bind_rows(pacfin.lengths, rec.lengths, ashop.lengths)

#Exclude CA ASHOP length and age comps
mod$dat$lencomp <- mod$dat$lencomp[mod$dat$lencomp$FltSvy!=10,]
mod$dat$agecomp <- mod$dat$agecomp[mod$dat$agecomp$FltSvy!=10,]

#Remove var_adj values for CA rec (age) and CA ashop (age and length)
mod$ctl$Variance_adjustment_list <- mod$ctl$Variance_adjustment_list[
  -c(which(mod$ctl$Variance_adjustment_list$Fleet == 7 & mod$ctl$Variance_adjustment_list$Data_type == 5),
     which(mod$ctl$Variance_adjustment_list$Fleet == 10)),]


##
#Output files and run
##

SS_write(mod,
         dir = here('models', new_name),
         overwrite = TRUE)

# r4ss::run(dir = here('models', new_name), 
#           exe = here('models/ss_win.exe'), 
#           extras = '-nohess', 
#           # show_in_console = TRUE, 
#           skipfinished = FALSE)



####------------------------------------------------####
### 3_1_8_survey Add survey indices and comps ----
####------------------------------------------------####

new_name <- 'Bridging coastwide/3_1_8_survey'

##
#Copy inputs
##

# I suggest not touching converted, or transition. That was just for updating SS3
# version, and plus just enough changes so that it actually ran. It was not 100% reproducible.
copy_SS_inputs(dir.old = here('models/converted'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models', new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)


##
#Make Changes
##

mod$start$detailed_age_structure <- 1 #all output

# Extend year specific inputs to 2022 ------------------------------------------------

mod$dat$endyr <- 2022
mod$ctl$Block_Design[[1]][2] <- 2022
mod$ctl$Block_Design[[2]][4] <- 2022
mod$ctl$MainRdevYrLast <- 2022
mod$ctl$last_yr_fullbias_adj <- 2020
mod$ctl$first_recent_yr_nobias_adj <- 2022
mod$ctl$MG_parms[c('RecrDist_Area_2','RecrDist_Area_3'),'dev_maxyr'] <- 2022


# Update survey indices ----------------------------------------------------------

wcgbts.cpue <- read.csv(file.path(wd,'Assessments/Assessment Data/2023 Assessment Cycle/canary rockfish/wcgbts/delta_lognormal/index/est_by_area.csv')) |>
  dplyr::mutate(fleet_no_num = paste0(area, '_NWFSC')) |>
  dplyr::left_join(fleet.converter) |> 
  dplyr::mutate(seas = 7) |>
  dplyr::select(year, seas, index = fleet, obs = est, se_log = se)

tri.cpue <- read.csv(file.path(wd,'Assessments/Assessment Data/2023 Assessment Cycle/canary rockfish/triennial/delta_lognormal_mix/index/est_by_area.csv')) |>
  dplyr::mutate(fleet_no_num = paste0(area, ifelse(year <= 1992, '_Tri_early', '_Tri_late'))) |>
  dplyr::left_join(fleet.converter) |> 
  dplyr::mutate(seas = 7) |>
  dplyr::select(year, seas, index = fleet, obs = est, se_log = se)

prerecruit <- read.csv(here('data/canary_prerecruit_indices.csv')) |>
  dplyr::filter(!(YEAR %in% c(2010, 2012, 2022))) |> # could also include these years...
  dplyr::mutate(fleet_no_num = paste0(region, '_prerec')) |>
  dplyr::left_join(fleet.converter) |> 
  dplyr::mutate(seas = 7) |>
  dplyr::select(year = YEAR, seas, index = fleet, obs = est, se_log = se)

mod$dat$CPUE <- dplyr::bind_rows(wcgbts.cpue, tri.cpue, prerecruit)

# Triennial selectivity and Q should probably be mirrored!!!

# Update combo survey comps -----------------------------------------------------

length.min <- min(mod$dat$lbin_vector)
length.max <- max(mod$dat$lbin_vector)
age.min <- min(mod$dat$agebin_vector)
age.max <- max(mod$dat$agebin_vector)

caal <- marginal.ages <- marginal.lengths <- list()
for(ii in 1:4) {
  area <- c('CA', 'OR', 'WA', 'coastwide')[ii]
  fleet_num <- fleet.converter$fleet[grep(x = fleet.converter$fleet_no_num, 
                                          pattern = paste0(area, "_NWFSC"))]
  caal[[area]] <- purrr::map(list(`F` = 'Female', M = 'Male'), function(.x) {
    read.csv(here(glue::glue('data/{area}_wcgbts_comps/Survey_CAAL_{sex}_Bins_{lmin}_{lmax}_{amin}_{amax}.csv',
                             area = area,
                             sex = .x,
                             lmin = length.min,
                             lmax = length.max,
                             amin = age.min,
                             amax = age.max))) |>
      dplyr::mutate(Fleet = fleet_num) |> 
      `names<-`(names(mod$dat$agecomp)) 
  })
  
  marginal.ages[[area]] <- read.csv(here(glue::glue('data/{area}_wcgbts_comps/Survey_Sex3_Bins_{amin}_{amax}_AgeComps.csv',
                                                    area = area,
                                                    amin = age.min,
                                                    amax = age.max))) |>
    dplyr::mutate(fleet = -1 * fleet_num,
                  agelow = -1,
                  agehigh = -1) |>
    `names<-`(names(mod$dat$agecomp))
  
  marginal.lengths[[area]] <- read.csv(here(glue::glue('data/{area}_wcgbts_comps/Survey_Sex3_Bins_{lmin}_{lmax}_LengthComps.csv',
                                                       area = area,
                                                       lmin = length.min,
                                                       lmax = length.max))) |>
    dplyr::mutate(fleet = fleet_num) |>
    `names<-`(names(mod$dat$lencomp))
  
}

caal.dfr <- caal |>
  purrr::list_flatten() |>
  purrr::list_rbind() |> 
  dplyr::mutate(Yr = ifelse(FltSvy == 28, -1 * Yr, Yr)) |> # exclude coastwide survey from likelihood
  # caal table is in absolute length, model is in length index.
  # Updating caal to be in length index
  dplyr::mutate(dplyr::across(Lbin_lo:Lbin_hi, ~ match(.x, mod$dat$lbin_vector)))

marginal.ages.dfr <- marginal.ages |>
  purrr::list_rbind() 
# Marginal ages already have negative fleet number

marginal.lengths.dfr <- marginal.lengths |>
  purrr::list_rbind() |>
  dplyr::mutate(Yr = ifelse(FltSvy == 28, -1 * Yr, Yr)) # exclude coastwide survey from likelihood

mod$dat$agecomp <- mod$dat$agecomp |> 
  dplyr::filter(!(FltSvy %in% unique(caal.dfr$FltSvy)),
                !(FltSvy %in% unique(marginal.ages.dfr$FltSvy))) |>
  dplyr::bind_rows(caal.dfr, marginal.ages.dfr)

mod$dat$lencomp <- mod$dat$lencomp |> 
  dplyr::filter(!(FltSvy %in% unique(marginal.lengths.dfr$FltSvy))) |>
  dplyr::bind_rows(marginal.lengths.dfr)

# Update triennial survey comps -----------------------------------------------------

caal <- marginal.ages <- marginal.lengths <- list()

for(ii in 1:4) {
  area <- c('CA', 'OR', 'WA', 'coastwide')[ii]
  fleet_num <- fleet.converter$fleet[grep(x = fleet.converter$fleet_no_num, 
                                          pattern = paste0(area, "_Tri"))]
  caal[[area]] <- purrr::map(list(`F` = 'Female', M = 'Male'), function(.x) {
    read.csv(here(glue::glue('data/{area}_tri_comps/Survey_CAAL_{sex}_Bins_{lmin}_{lmax}_{amin}_{amax}.csv',
                             area = area,
                             sex = .x,
                             lmin = length.min,
                             lmax = length.max,
                             amin = age.min,
                             amax = age.max))) |>
      dplyr::mutate(Fleet = ifelse(year <= 1992, fleet_num[1], fleet_num[2])) |>
      `names<-`(names(mod$dat$agecomp)) 
  })
  
  marginal.ages[[area]] <- read.csv(here(glue::glue('data/{area}_tri_comps/Survey_Sex3_Bins_{amin}_{amax}_AgeComps.csv',
                                                    area = area,
                                                    amin = age.min,
                                                    amax = age.max))) |>
    dplyr::mutate(fleet = -1 * ifelse(year <= 1992, fleet_num[1], fleet_num[2]),
                  agelow = -1,
                  agehigh = -1) |>
    `names<-`(names(mod$dat$agecomp))
  
  marginal.lengths[[area]] <- read.csv(here(glue::glue('data/{area}_tri_comps/Survey_Sex3_Bins_{lmin}_{lmax}_LengthComps.csv',
                                                       area = area,
                                                       lmin = length.min,
                                                       lmax = length.max))) |>
    dplyr::mutate(fleet = ifelse(year <= 1992, fleet_num[1], fleet_num[2])) |>
    `names<-`(names(mod$dat$lencomp))
  
}

caal.dfr <- caal |>
  purrr::list_flatten() |>
  purrr::list_rbind() |> 
  dplyr::mutate(Yr = ifelse(FltSvy %in% c(29,30), -1 * Yr, Yr)) |> # exclude coastwide survey from likelihood
  # caal table is in absolute length, model is in length index.
  # Updating caal to be in length index
  dplyr::mutate(dplyr::across(Lbin_lo:Lbin_hi, ~ match(.x, mod$dat$lbin_vector)))

marginal.ages.dfr <- marginal.ages |>
  purrr::list_rbind() 
# Marginal ages already have negative fleet number

marginal.lengths.dfr <- marginal.lengths |>
  purrr::list_rbind() |>
  dplyr::mutate(Yr = ifelse(FltSvy %in% c(29,30), -1 * Yr, Yr)) # exclude coastwide survey from likelihood

mod$dat$agecomp <- mod$dat$agecomp |> 
  dplyr::filter(!(FltSvy %in% unique(caal.dfr$FltSvy)),
                !(FltSvy %in% unique(marginal.ages.dfr$FltSvy))) |>
  dplyr::bind_rows(caal.dfr, marginal.ages.dfr)

mod$dat$lencomp <- mod$dat$lencomp |> 
  dplyr::filter(!(FltSvy %in% unique(marginal.lengths.dfr$FltSvy))) |>
  dplyr::bind_rows(marginal.lengths.dfr)
# Note: consider switching triennial to marginal ages.

#


##
#Output files and run
##

SS_write(mod,
         dir = here('models', new_name),
         overwrite = TRUE)

# r4ss::run(dir = here('models', new_name), 
#           exe = here('models/ss_win.exe'), 
#           extras = '-nohess', 
#           # show_in_console = TRUE, 
#           skipfinished = FALSE)



####------------------------------------------------####
### 3_1_9_catchANDsurvey Add survey indices and comps as well as fishery catches ----
####------------------------------------------------####

new_name <- 'Bridging coastwide/3_1_9_catchANDsurvey'

##
#Copy inputs
##

# I suggest not touching converted, or transition. That was just for updating SS3
# version, and plus just enough changes so that it actually ran. It was not 100% reproducible.
copy_SS_inputs(dir.old = here('models/converted'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models', new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)


##
#Make Changes
##

mod$start$detailed_age_structure <- 1 #all output

# Extend year specific inputs to 2022 ------------------------------------------------

mod$dat$endyr <- 2022
mod$ctl$Block_Design[[1]][2] <- 2022
mod$ctl$Block_Design[[2]][4] <- 2022
mod$ctl$MainRdevYrLast <- 2022
mod$ctl$last_yr_fullbias_adj <- 2020
mod$ctl$first_recent_yr_nobias_adj <- 2022
mod$ctl$MG_parms[c('RecrDist_Area_2','RecrDist_Area_3'),'dev_maxyr'] <- 2022


# Extend catch time series ------------------------------------------------

catches <- read.csv(here('data/canary_total_removals.csv')) 
updated.catch.df <- catches |>
  dplyr::select(-rec.W.N) |>
  tidyr::pivot_longer(cols = -Year, names_to = 'fleet', values_to = 'catch') |>
  tidyr::separate(col = fleet, into = c('gear', 'state'), sep = '\\.') |> 
  # warning is ok, cuts off units in WA rec catch column name
  dplyr::mutate(gear = stringr::str_to_upper(gear),
                state = dplyr::case_when(state == 'W' ~ 'WA',
                                         state == 'O' ~ 'OR',
                                         state == 'C' ~ 'CA'),
                fleet_no_num = paste(state, gear, sep = '_')) |>
  dplyr::left_join(fleet.converter) |>
  dplyr::mutate(seas = 1, 
                catch_se = 0.05) |>
  dplyr::select(year = Year, seas, fleet, catch, catch_se) |>
  #rbind(c(-999, 1, 1, 0, 0.05)) |>
  dplyr::arrange(fleet, year) |>
  as.data.frame()

mod$dat$catch <- updated.catch.df

# Change survey fleets to non-catch fleets
survey.ind <- grep(mod$dat$fleetinfo$fleetname, pattern = 'Tri|NWFSC')
mod$dat$fleetinfo$type[survey.ind] <- 3

# Change fishing mortality to year-round, gets rid of ss3 warnings
mod$dat$fleetinfo$surveytiming[mod$dat$fleetinfo$type==1] <- -1


# Update survey indices ----------------------------------------------------------

wcgbts.cpue <- read.csv(file.path(wd,'Assessments/Assessment Data/2023 Assessment Cycle/canary rockfish/wcgbts/delta_lognormal/index/est_by_area.csv')) |>
  dplyr::mutate(fleet_no_num = paste0(area, '_NWFSC')) |>
  dplyr::left_join(fleet.converter) |> 
  dplyr::mutate(seas = 7) |>
  dplyr::select(year, seas, index = fleet, obs = est, se_log = se)

tri.cpue <- read.csv(file.path(wd,'Assessments/Assessment Data/2023 Assessment Cycle/canary rockfish/triennial/delta_lognormal_mix/index/est_by_area.csv')) |>
  dplyr::mutate(fleet_no_num = paste0(area, ifelse(year <= 1992, '_Tri_early', '_Tri_late'))) |>
  dplyr::left_join(fleet.converter) |> 
  dplyr::mutate(seas = 7) |>
  dplyr::select(year, seas, index = fleet, obs = est, se_log = se)

prerecruit <- read.csv(here('data/canary_prerecruit_indices.csv')) |>
  dplyr::filter(!(YEAR %in% c(2010, 2012, 2022))) |> # could also include these years...
  dplyr::mutate(fleet_no_num = paste0(region, '_prerec')) |>
  dplyr::left_join(fleet.converter) |> 
  dplyr::mutate(seas = 7) |>
  dplyr::select(year = YEAR, seas, index = fleet, obs = est, se_log = se)

mod$dat$CPUE <- dplyr::bind_rows(wcgbts.cpue, tri.cpue, prerecruit)

# Triennial selectivity and Q should probably be mirrored!!!

# Update combo survey comps -----------------------------------------------------

length.min <- min(mod$dat$lbin_vector)
length.max <- max(mod$dat$lbin_vector)
age.min <- min(mod$dat$agebin_vector)
age.max <- max(mod$dat$agebin_vector)

caal <- marginal.ages <- marginal.lengths <- list()
for(ii in 1:4) {
  area <- c('CA', 'OR', 'WA', 'coastwide')[ii]
  fleet_num <- fleet.converter$fleet[grep(x = fleet.converter$fleet_no_num, 
                                          pattern = paste0(area, "_NWFSC"))]
  caal[[area]] <- purrr::map(list(`F` = 'Female', M = 'Male'), function(.x) {
    read.csv(here(glue::glue('data/{area}_wcgbts_comps/Survey_CAAL_{sex}_Bins_{lmin}_{lmax}_{amin}_{amax}.csv',
                             area = area,
                             sex = .x,
                             lmin = length.min,
                             lmax = length.max,
                             amin = age.min,
                             amax = age.max))) |>
      dplyr::mutate(Fleet = fleet_num) |> 
      `names<-`(names(mod$dat$agecomp)) 
  })
  
  marginal.ages[[area]] <- read.csv(here(glue::glue('data/{area}_wcgbts_comps/Survey_Sex3_Bins_{amin}_{amax}_AgeComps.csv',
                                                    area = area,
                                                    amin = age.min,
                                                    amax = age.max))) |>
    dplyr::mutate(fleet = -1 * fleet_num,
                  agelow = -1,
                  agehigh = -1) |>
    `names<-`(names(mod$dat$agecomp))
  
  marginal.lengths[[area]] <- read.csv(here(glue::glue('data/{area}_wcgbts_comps/Survey_Sex3_Bins_{lmin}_{lmax}_LengthComps.csv',
                                                       area = area,
                                                       lmin = length.min,
                                                       lmax = length.max))) |>
    dplyr::mutate(fleet = fleet_num) |>
    `names<-`(names(mod$dat$lencomp))
  
}

caal.dfr <- caal |>
  purrr::list_flatten() |>
  purrr::list_rbind() |> 
  dplyr::mutate(Yr = ifelse(FltSvy == 28, -1 * Yr, Yr)) |> # exclude coastwide survey from likelihood
  # caal table is in absolute length, model is in length index.
  # Updating caal to be in length index
  dplyr::mutate(dplyr::across(Lbin_lo:Lbin_hi, ~ match(.x, mod$dat$lbin_vector)))

marginal.ages.dfr <- marginal.ages |>
  purrr::list_rbind() 
# Marginal ages already have negative fleet number

marginal.lengths.dfr <- marginal.lengths |>
  purrr::list_rbind() |>
  dplyr::mutate(Yr = ifelse(FltSvy == 28, -1 * Yr, Yr)) # exclude coastwide survey from likelihood

mod$dat$agecomp <- mod$dat$agecomp |> 
  dplyr::filter(!(FltSvy %in% unique(caal.dfr$FltSvy)),
                !(FltSvy %in% unique(marginal.ages.dfr$FltSvy))) |>
  dplyr::bind_rows(caal.dfr, marginal.ages.dfr)

mod$dat$lencomp <- mod$dat$lencomp |> 
  dplyr::filter(!(FltSvy %in% unique(marginal.lengths.dfr$FltSvy))) |>
  dplyr::bind_rows(marginal.lengths.dfr)

# Update triennial survey comps -----------------------------------------------------

caal <- marginal.ages <- marginal.lengths <- list()

for(ii in 1:4) {
  area <- c('CA', 'OR', 'WA', 'coastwide')[ii]
  fleet_num <- fleet.converter$fleet[grep(x = fleet.converter$fleet_no_num, 
                                          pattern = paste0(area, "_Tri"))]
  caal[[area]] <- purrr::map(list(`F` = 'Female', M = 'Male'), function(.x) {
    read.csv(here(glue::glue('data/{area}_tri_comps/Survey_CAAL_{sex}_Bins_{lmin}_{lmax}_{amin}_{amax}.csv',
                             area = area,
                             sex = .x,
                             lmin = length.min,
                             lmax = length.max,
                             amin = age.min,
                             amax = age.max))) |>
      dplyr::mutate(Fleet = ifelse(year <= 1992, fleet_num[1], fleet_num[2])) |>
      `names<-`(names(mod$dat$agecomp)) 
  })
  
  marginal.ages[[area]] <- read.csv(here(glue::glue('data/{area}_tri_comps/Survey_Sex3_Bins_{amin}_{amax}_AgeComps.csv',
                                                    area = area,
                                                    amin = age.min,
                                                    amax = age.max))) |>
    dplyr::mutate(fleet = -1 * ifelse(year <= 1992, fleet_num[1], fleet_num[2]),
                  agelow = -1,
                  agehigh = -1) |>
    `names<-`(names(mod$dat$agecomp))
  
  marginal.lengths[[area]] <- read.csv(here(glue::glue('data/{area}_tri_comps/Survey_Sex3_Bins_{lmin}_{lmax}_LengthComps.csv',
                                                       area = area,
                                                       lmin = length.min,
                                                       lmax = length.max))) |>
    dplyr::mutate(fleet = ifelse(year <= 1992, fleet_num[1], fleet_num[2])) |>
    `names<-`(names(mod$dat$lencomp))
  
}

caal.dfr <- caal |>
  purrr::list_flatten() |>
  purrr::list_rbind() |> 
  dplyr::mutate(Yr = ifelse(FltSvy %in% c(29,30), -1 * Yr, Yr)) |> # exclude coastwide survey from likelihood
  # caal table is in absolute length, model is in length index.
  # Updating caal to be in length index
  dplyr::mutate(dplyr::across(Lbin_lo:Lbin_hi, ~ match(.x, mod$dat$lbin_vector)))

marginal.ages.dfr <- marginal.ages |>
  purrr::list_rbind() 
# Marginal ages already have negative fleet number

marginal.lengths.dfr <- marginal.lengths |>
  purrr::list_rbind() |>
  dplyr::mutate(Yr = ifelse(FltSvy %in% c(29,30), -1 * Yr, Yr)) # exclude coastwide survey from likelihood

mod$dat$agecomp <- mod$dat$agecomp |> 
  dplyr::filter(!(FltSvy %in% unique(caal.dfr$FltSvy)),
                !(FltSvy %in% unique(marginal.ages.dfr$FltSvy))) |>
  dplyr::bind_rows(caal.dfr, marginal.ages.dfr)

mod$dat$lencomp <- mod$dat$lencomp |> 
  dplyr::filter(!(FltSvy %in% unique(marginal.lengths.dfr$FltSvy))) |>
  dplyr::bind_rows(marginal.lengths.dfr)
# Note: consider switching triennial to marginal ages.

#


##----
#Output files and run
##

SS_write(mod,
         dir = here('models', new_name),
         overwrite = TRUE)

# r4ss::run(dir = here('models', new_name), 
#           exe = here('models/ss_win.exe'), 
#           extras = '-nohess', 
#           # show_in_console = TRUE, 
#           skipfinished = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('converted', 
                                                 'Bridging coastwide/3_1_1_update_data', 
                                                 'Bridging coastwide/3_1_2_catch',
                                                 'Bridging coastwide/3_1_3_survey',
                                                 'Bridging coastwide/3_1_4_surveyCompsNWFSC',
                                                 'Bridging coastwide/3_1_5_surveyCompsTri',
                                                 'Bridging coastwide/3_1_6_fisheryComps',
                                                 'Bridging coastwide/3_1_7_fishery',
                                                 'Bridging coastwide/3_1_8_survey',
                                                 'Bridging coastwide/3_1_9_catchANDsurvey')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015converted', '2023 All data', 
                                     'Catch',
                                     'Survey Indices',
                                     'Survey CompsNWFSC',
                                     'Survey CompsTri',
                                     'fishery Comps',
                                     'fishery Catch and Comps',
                                     'Survey Indices and Comps',
                                     'fishery Catch, Survey Indices and Comps'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name) )


####------------------------------------------------####
### 3_1_10_lambda1 Set lambdas to 1 for setting up tunning ----
####------------------------------------------------####

new_name <- 'Bridging coastwide/3_1_10_lambda1'

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/Bridging coastwide/3_1_1_update_data'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

#Set lambdas to 1 for all but the coastwide comps (rec age comps 
#were previously zero because did not have them in the model)
mod$ctl$lambdas[!grepl("_coastwide",rownames(mod$ctl$lambdas)), "value"] <- 1

#Set lambdas to 0 for CA ashop length and age and CA_rec because dont have them in the model
mod$ctl$lambdas[grepl("CA_ASHOP",rownames(mod$ctl$lambdas)), "value"] <- 0
mod$ctl$lambdas[grepl("age_7_CA_REC",rownames(mod$ctl$lambdas)), "value"] <- 0


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

# r4ss::run(dir = here('models',new_name), 
#           exe = here('models/ss_win.exe'), 
#           extras = '-nohess', 
#           # show_in_console = TRUE, 
#           skipfinished = FALSE)


####------------------------------------------------####
### 3_1_11_tuned Tune the model with data added ----
####------------------------------------------------####

new_name <- 'Bridging coastwide/3_1_11_tuned'
copied_model <- 'Bridging coastwide/3_1_10_lambda1'

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models', copied_model),
               dir.new = here('models',new_name),
               overwrite = TRUE)
file.copy(from = file.path(here('models', copied_model),"Report.sso"),
          to = file.path(here('models',new_name),"Report.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models', copied_model),"CompReport.sso"),
          to = file.path(here('models',new_name),"CompReport.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models', copied_model),"warning.sso"),
          to = file.path(here('models',new_name),"warning.sso"), overwrite = TRUE)

##
#Make Changes
##

yy <- SS_output(here('models', new_name))
dw <- tune_comps(replist = yy, dir = here('models', new_name),
                 option = c("Francis"), niters_tuning = 4, #need 4 to have reasonalbe values
                 exe = here('models/ss_win.exe'), extras = "-nohess",
                 allow_up_tuning = TRUE,
                 write = TRUE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26))

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('converted', 
                                                 'Bridging coastwide/3_1_1_update_data',
                                                 'Bridging coastwide/3_1_10_lambda1',
                                                 'Bridging coastwide/3_1_11_tuned')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015converted', 
                                     '2023 All data',
                                     'lambda1',
                                     '2023 All data tuned'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name) )


####------------------------------------------------####
### 3_2_1_update_bio All bio but with only the prior changed for M----
####------------------------------------------------####

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/Bridging coastwide/3_1_1_update_data'), 
               dir.new = here('models/Bridging coastwide/3_2_1_update_bio_Mval'),
               overwrite = TRUE)

mod <- SS_read(here('models/Bridging coastwide/3_2_1_update_bio_Mval'))

##
#Make Changes
##

# Update M as a single offset value ------------------------------------------------
#mod$ctl$natM_type <- 0
#mod$ctl$parameter_offset_approach <- 2 #because not having breakpoints
#Remove second M breakpoint parameters
#mod$ctl$MG_parms <- mod$ctl$MG_parms[-grep("NatM_p_2",rownames(mod$ctl$MG_parms)),]

max.age <- 84
mod$ctl$MG_parms['NatM_p_1_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD')] <- c(
  0.02, 0.2,
  round(5.4/max.age, 4), 
  round(log(5.4/max.age), 2), 
  0.31
)

# Update maturity ------------------------------------------------
a50_fxn <- 10.87
slope_fxn <- -0.688
mod$ctl$maturity_option <- 2 #age logistic
mod$ctl$MG_parms['Mat50%_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD')] <- 
  c(9, 12, a50_fxn, a50_fxn, 0.055)

# Update steepness ------------------------------------------------
#per best practices: https://www.pcouncil.org/documents/2023/03/accepted-practices-and-guidelines-for-groundfish-stock-assessments.pdf/
mod$ctl$SR_parms['SR_BH_steep', c('INIT', 'PRIOR', 'PR_SD', 'PR_type')] <- 
  c(0.72, 0.72, 0.16, 2)

# Update fecundity ------------------------------------------------
mod$ctl$fecundity_option <- 2 #non-linear in length
mod$ctl$MG_parms['Eggs_alpha_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type')] <- c(
  1E-10,0.1,
  7.218E-08, log(7.218E-08), 
  0.135, 3) #set prior sd for a as exp(~2) where 2 is about half the CI bound for A and use lognormal because alpha = exp(A)
mod$ctl$MG_parms['Eggs_beta_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type')] <- c(
  2, 6, 
  4.043, 4.043, 
  0.3, 6) #set prior sd around half the CI bound for b (~0.6) and keep normal 

# Update WL parameters ------------------------------------------------
wlcoef <- utils::read.csv(here("data", "W_L_pars.csv"), header = TRUE)
#Females
mod$ctl$MG_parms['Wtlen_1_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type')] <- c(
  0, 0.1,
  signif(wlcoef[wlcoef$Sex=="F","A"],3), 
  signif(wlcoef[wlcoef$Sex=="F","A"],3),
  50, 6) #keep same prior sd and distribution
mod$ctl$MG_parms['Wtlen_2_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type')] <- c(
  2, 4,
  round(wlcoef[wlcoef$Sex=="F","B"],3), 
  round(wlcoef[wlcoef$Sex=="F","B"],3),
  50, 6) #keep same prior sd and distribution
#Males
mod$ctl$MG_parms['Wtlen_1_Mal_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type')] <- c(
  0, 0.1,
  signif(wlcoef[wlcoef$Sex=="M","A"],3), 
  signif(wlcoef[wlcoef$Sex=="M","A"],3),
  50, 6) #keep same prior sd and distribution
mod$ctl$MG_parms['Wtlen_2_Mal_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type')] <- c(
  2, 4,
  round(wlcoef[wlcoef$Sex=="M","B"],3), 
  round(wlcoef[wlcoef$Sex=="M","B"],3),
  50, 6)


##
#Output files and run
##

SS_write(mod,
         dir = here('models/Bridging coastwide/3_2_1_update_bio_Mval'),
         overwrite = TRUE)

# r4ss::run(dir = here('models/Bridging coastwide/3_2_1_update_bio_Mval'), 
#           exe = here('models/ss_win.exe'), 
#           extras = '-nohess', 
#           # show_in_console = TRUE, 
#           skipfinished = FALSE)

####------------------------------------------------####
### 3_2_1_update_bio_Mconstant include all bio changes with Mconstant ----
####------------------------------------------------####

new_name <- "Bridging coastwide/3_2_1_update_bio_Mconstant"

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/Bridging coastwide/3_2_1_update_bio_Mval'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

# Update M and growth parameters (not as offsets) ------------------------------------------------
mod$ctl$natM_type <- 0
mod$ctl$parameter_offset_approach <- 1 #Use direct assignment with matching of M to F for L at Amin
#Remove second M breakpoint parameters
mod$ctl$MG_parms <- mod$ctl$MG_parms[-grep("NatM_p_2",rownames(mod$ctl$MG_parms)),]

#Direct estimate female M and fix male M
max.age <- 84
mod$ctl$MG_parms['NatM_p_1_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')] <- c(
  0.02, 0.2,
  round(5.4/max.age, 4), 
  round(log(5.4/max.age), 2), 
  0.31, 2 #estimate female M
)
mod$ctl$MG_parms['NatM_p_1_Mal_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')] <- c(
  0.02, 0.2,
  round(5.4/max.age, 4), 
  round(log(5.4/max.age), 2), 
  0.31, -50 #estimate male M
)

#Reset CV female old because it was an offset
mod$ctl$MG_parms['CV_old_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')] <- c(
  0.01, 0.21,
  round(mod$ctl$MG_parms['CV_young_Fem_GP_1','INIT']*exp(mod$ctl$MG_parms['CV_old_Fem_GP_1','INIT']),4), 
  round(mod$ctl$MG_parms['CV_young_Fem_GP_1','INIT']*exp(mod$ctl$MG_parms['CV_old_Fem_GP_1','INIT']),4),
  50, 2 #estimate male M
)

#Set L at Amin for male to be same as female
#Use init = 0 and negative phase
mod$ctl$MG_parms['L_at_Amin_Mal_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')] <- c(
  0, 15,
  0, 0,
  50, -50 #estimate male M
)

#Direct estimate L at Amax, K, and CVs for male with the same inits as females
mod$ctl$MG_parms['L_at_Amax_Mal_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')] <- 
  mod$ctl$MG_parms['L_at_Amax_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')]
mod$ctl$MG_parms['VonBert_K_Mal_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')] <- 
  mod$ctl$MG_parms['VonBert_K_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')]
mod$ctl$MG_parms['CV_young_Mal_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')] <- 
  mod$ctl$MG_parms['CV_young_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')]
mod$ctl$MG_parms['CV_old_Mal_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')] <- 
  mod$ctl$MG_parms['CV_old_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')]


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

# r4ss::run(dir = here('models',new_name), 
#           exe = here('models/ss_win.exe'), 
#           extras = '-nohess', 
#           # show_in_console = TRUE, 
#           skipfinished = FALSE)


####------------------------------------------------####
### 3_2_2_Mconstant update bio M individually ----
####------------------------------------------------####

new_name <- "Bridging coastwide/3_2_2_Mconstant"

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/Bridging coastwide/3_1_1_update_data'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

# Update M and growth parameters (not as offsets) ------------------------------------------------
mod$ctl$natM_type <- 0
mod$ctl$parameter_offset_approach <- 1 #Use direct assignment with matching of M to F for L at Amin
#Remove second M breakpoint parameters
mod$ctl$MG_parms <- mod$ctl$MG_parms[-grep("NatM_p_2",rownames(mod$ctl$MG_parms)),]

#Direct estimate male and female F
max.age <- 84
mod$ctl$MG_parms['NatM_p_1_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')] <- c(
  0.02, 0.2,
  round(5.4/max.age, 4), 
  round(log(5.4/max.age), 2), 
  0.31, 2 #estimate female M
)
mod$ctl$MG_parms['NatM_p_1_Mal_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')] <- c(
  0.02, 0.2,
  round(5.4/max.age, 4), 
  round(log(5.4/max.age), 2), 
  0.31, 2 #estimate male M
)

#Reset CV female old because it was an offset
mod$ctl$MG_parms['CV_old_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')] <- c(
  0.01, 0.21,
  round(mod$ctl$MG_parms['CV_young_Fem_GP_1','INIT']*exp(mod$ctl$MG_parms['CV_old_Fem_GP_1','INIT']),4), 
  round(mod$ctl$MG_parms['CV_young_Fem_GP_1','INIT']*exp(mod$ctl$MG_parms['CV_old_Fem_GP_1','INIT']),4),
  50, 2 #estimate male M
)

#Set L at Amin for male to be same as female
#Use init = 0 and negative phase
mod$ctl$MG_parms['L_at_Amin_Mal_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')] <- c(
  0, 15,
  0, 0,
  50, -50 #estimate male M
)

#Direct estimate L at Amax, K, and CVs for male with the same inits as females
mod$ctl$MG_parms['L_at_Amax_Mal_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')] <- 
  mod$ctl$MG_parms['L_at_Amax_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')]
mod$ctl$MG_parms['VonBert_K_Mal_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')] <- 
  mod$ctl$MG_parms['VonBert_K_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')]
mod$ctl$MG_parms['CV_young_Mal_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')] <- 
  mod$ctl$MG_parms['CV_young_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')]
mod$ctl$MG_parms['CV_old_Mal_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')] <- 
  mod$ctl$MG_parms['CV_old_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')]


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

# r4ss::run(dir = here('models',new_name), 
#           exe = here('models/ss_win.exe'), 
#           extras = '-nohess', 
#           # show_in_console = TRUE, 
#           skipfinished = FALSE)



####------------------------------------------------####
### 3_2_2_M_justValue update bio M individually ----
####------------------------------------------------####

new_name <- "Bridging coastwide/3_2_2_M_justValue"

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/Bridging coastwide/3_1_1_update_data'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

# Update M as a single offset value ------------------------------------------------
#mod$ctl$natM_type <- 0
#mod$ctl$parameter_offset_approach <- 2 #because not having breakpoints
#Remove second M breakpoint parameters
#mod$ctl$MG_parms <- mod$ctl$MG_parms[-grep("NatM_p_2",rownames(mod$ctl$MG_parms)),]

max.age <- 84
mod$ctl$MG_parms['NatM_p_1_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD')] <- c(
  0.02, 0.2,
  round(5.4/max.age, 4), 
  round(log(5.4/max.age), 2), 
  0.31
)

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

# r4ss::run(dir = here('models',new_name), 
#           exe = here('models/ss_win.exe'), 
#           extras = '-nohess', 
#           # show_in_console = TRUE, 
#           skipfinished = FALSE)



####------------------------------------------------####
### 3_2_3_maturity update bio maturity individually ----
####------------------------------------------------####

new_name <- "Bridging coastwide/3_2_3_maturity"

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/Bridging coastwide/3_1_1_update_data'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make Changes
##

# Update maturity ------------------------------------------------
a50_fxn <- 10.87
slope_fxn <- -0.688
mod$ctl$maturity_option <- 2 #age logistic
mod$ctl$MG_parms['Mat50%_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD')] <- 
  c(9, 12, a50_fxn, a50_fxn, 0.055)

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

# r4ss::run(dir = here('models',new_name), 
#           exe = here('models/ss_win.exe'), 
#           extras = '-nohess', 
#           # show_in_console = TRUE, 
#           skipfinished = FALSE)



####------------------------------------------------####
### 3_2_4_steepness update bio steepness individually ----
####------------------------------------------------####

new_name <- "Bridging coastwide/3_2_4_steepness"

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/Bridging coastwide/3_1_1_update_data'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make Changes
##

# Update steepness ------------------------------------------------
#per best practices: https://www.pcouncil.org/documents/2023/03/accepted-practices-and-guidelines-for-groundfish-stock-assessments.pdf/
mod$ctl$SR_parms['SR_BH_steep', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type')] <- 
  c(0.21, 0.99, 0.72, 0.72, 0.16, 2)


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

# r4ss::run(dir = here('models',new_name), 
#           exe = here('models/ss_win.exe'), 
#           extras = '-nohess', 
#           # show_in_console = TRUE, 
#           skipfinished = FALSE)


####------------------------------------------------####
### 3_2_5_fecund update bio fecundity individually ----
####------------------------------------------------####

new_name <- "Bridging coastwide/3_2_5_fecund"

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/Bridging coastwide/3_1_1_update_data'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make Changes
##

# Update fecundity ------------------------------------------------
mod$ctl$fecundity_option <- 2 #non-linear in length
mod$ctl$MG_parms['Eggs_alpha_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type')] <- c(
  1E-10,0.1,
  7.218E-08, log(7.218E-08), 
  0.135, 3) #set prior sd for a as exp(~2) where 2 is about half the CI bound for A and use lognormal because alpha = exp(A)
mod$ctl$MG_parms['Eggs_beta_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type')] <- c(
  2, 6, 
  4.043, 4.043, 
  0.3, 6) #set prior sd around half the CI bound for b (~0.6) and keep normal 

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

# r4ss::run(dir = here('models',new_name), 
#           exe = here('models/ss_win.exe'), 
#           extras = '-nohess', 
#           # show_in_console = TRUE, 
#           skipfinished = FALSE)



####------------------------------------------------####
### 3_2_6_WL update bio WL individually ----
####------------------------------------------------####

new_name <- "Bridging coastwide/3_2_6_WL"

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/Bridging coastwide/3_1_1_update_data'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make Changes
##

# Update WL parameters ------------------------------------------------
wlcoef <- utils::read.csv(here("data", "W_L_pars.csv"), header = TRUE)
#Females
mod$ctl$MG_parms['Wtlen_1_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type')] <- c(
  0, 0.1,
  signif(wlcoef[wlcoef$Sex=="F","A"],3), 
  signif(wlcoef[wlcoef$Sex=="F","A"],3),
  50, 6) #keep same prior sd and distribution
mod$ctl$MG_parms['Wtlen_2_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type')] <- c(
  2, 4,
  round(wlcoef[wlcoef$Sex=="F","B"],3), 
  round(wlcoef[wlcoef$Sex=="F","B"],3),
  50, 6) #keep same prior sd and distribution
#Males
mod$ctl$MG_parms['Wtlen_1_Mal_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type')] <- c(
  0, 0.1,
  signif(wlcoef[wlcoef$Sex=="M","A"],3), 
  signif(wlcoef[wlcoef$Sex=="M","A"],3),
  50, 6) #keep same prior sd and distribution
mod$ctl$MG_parms['Wtlen_2_Mal_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type')] <- c(
  2, 4,
  round(wlcoef[wlcoef$Sex=="M","B"],3), 
  round(wlcoef[wlcoef$Sex=="M","B"],3),
  50, 6)

##----
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

# r4ss::run(dir = here('models',new_name), 
#           exe = here('models/ss_win.exe'), 
#           extras = '-nohess', 
#           # show_in_console = TRUE, 
#           skipfinished = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('converted', 
                                                 'Bridging coastwide/3_1_1_update_data', 
                                                 'Bridging coastwide/3_2_1_update_bio_Mconstant',
                                                 'Bridging coastwide/3_2_1_update_bio_Mval',
                                                 'Bridging coastwide/3_2_2_Mconstant',
                                                 'Bridging coastwide/3_2_2_M_justValue',
                                                 'Bridging coastwide/3_2_3_maturity',
                                                 'Bridging coastwide/3_2_4_steepness',
                                                 'Bridging coastwide/3_2_5_fecund',
                                                 'Bridging coastwide/3_2_6_WL')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015converted', '2023 All data', 
                                     'All bio M as constant',
                                     'All bio M as breakpoint',
                                     'M as constant',
                                     'M as breakpoint',
                                     'Maturity',
                                     'Steepness',
                                     'Fecundity',
                                     'WL'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name) )


####------------------------------------------------####
### 3_2_7_update_bio_phases Adjust phases for GP parms ----
####------------------------------------------------####

new_name <- "Bridging coastwide/3_2_7_update_bio_Mval_phases"

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/Bridging coastwide/3_2_1_update_bio_Mval'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

# Set phases for M = 2, growth = 3, CV = 4. Previously mostly all at 2 ----
mod$ctl$MG_parms[c('NatM_p_2_Fem_GP_1',
                   'L_at_Amin_Fem_GP_1',
                   'L_at_Amax_Fem_GP_1',
                   'VonBert_K_Fem_GP_1',
                   'CV_young_Fem_GP_1',
                   'CV_old_Fem_GP_1',
                   'L_at_Amax_Mal_GP_1',
                   'VonBert_K_Mal_GP_1',
                   'CV_young_Mal_GP_1',
                   'CV_old_Mal_GP_1'),'PHASE'] <- c(2,3,3,3,4,4,3,3,4,4)

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

# r4ss::run(dir = here('models',new_name), 
#           exe = here('models/ss_win.exe'), 
#           extras = '-nohess', 
#           # show_in_console = TRUE, 
#           skipfinished = FALSE)


####------------------------------------------------####
### 3_2_7_update_bio_phases Adjust phases for GP parms but on Mconstant model ----
####------------------------------------------------####

new_name <- "Bridging coastwide/3_2_7_update_bio_Mconstant_phases"

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/Bridging coastwide/3_2_1_update_bio_Mconstant'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

# Set phases for M = 2, growth = 3, CV = 4. Previously mostly all at 2 ----
mod$ctl$MG_parms[c('L_at_Amin_Fem_GP_1',
                   'L_at_Amax_Fem_GP_1',
                   'VonBert_K_Fem_GP_1',
                   'CV_young_Fem_GP_1',
                   'CV_old_Fem_GP_1',
                   'L_at_Amax_Mal_GP_1',
                   'VonBert_K_Mal_GP_1',
                   'CV_young_Mal_GP_1',
                   'CV_old_Mal_GP_1'),'PHASE'] <- c(3,3,3,4,4,3,3,4,4)

##----
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

# r4ss::run(dir = here('models',new_name), 
#           exe = here('models/ss_win.exe'), 
#           extras = '-nohess', 
#           # show_in_console = TRUE, 
#           skipfinished = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('converted', 
                                                 'Bridging coastwide/3_1_1_update_data', 
                                                 'Bridging coastwide/3_2_1_update_bio_Mconstant',
                                                 'Bridging coastwide/3_2_1_update_bio_Mval',
                                                 'Bridging coastwide/3_2_7_update_bio_Mconstant_phases',
                                                 'Bridging coastwide/3_2_7_update_bio_Mval_phases')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015converted', '2023 All data', 
                                     'All bio M as constant',
                                     'All bio M as breakpoint',
                                     'All bio M as constant phases',
                                     'All bio M as breakpoint phases'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name) )


####------------------------------------------------####
### 3_2_8_lambda1 Set lambdas to 1 for setting up tunning for constant M model ----
####------------------------------------------------####

new_name <- 'Bridging coastwide/3_2_8_lambda1'

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/Bridging coastwide/3_2_7_update_bio_Mconstant_phases'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

#Set lambdas to 1 for all but the coastwide comps (rec age comps 
#were previously zero because did not have them in the model)
mod$ctl$lambdas[!grepl("_coastwide",rownames(mod$ctl$lambdas)), "value"] <- 1

#Set lambdas to 0 for CA ashop length and age and CA_rec because dont have them in the model
mod$ctl$lambdas[grepl("CA_ASHOP",rownames(mod$ctl$lambdas)), "value"] <- 0
mod$ctl$lambdas[grepl("age_7_CA_REC",rownames(mod$ctl$lambdas)), "value"] <- 0


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

# r4ss::run(dir = here('models',new_name), 
#           exe = here('models/ss_win.exe'), 
#           extras = '-nohess', 
#           # show_in_console = TRUE, 
#           skipfinished = FALSE)


####------------------------------------------------####
### 3_2_9_tuned Tune the model with data and bio added ----
####------------------------------------------------####

new_name <- 'Bridging coastwide/3_2_9_tuned'
copied_model <- 'Bridging coastwide/3_2_8_lambda1'

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models', copied_model),
               dir.new = here('models',new_name),
               overwrite = TRUE)
file.copy(from = file.path(here('models', copied_model),"Report.sso"),
          to = file.path(here('models',new_name),"Report.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models', copied_model),"CompReport.sso"),
          to = file.path(here('models',new_name),"CompReport.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models', copied_model),"warning.sso"),
          to = file.path(here('models',new_name),"warning.sso"), overwrite = TRUE)

##
#Make Changes
##

yy <- SS_output(here('models', new_name))
dw <- tune_comps(replist = yy, dir = here('models', new_name),
                 option = c("Francis"), niters_tuning = 3,
                 exe = here('models/ss_win.exe'), extras = "-nohess",
                 allow_up_tuning = TRUE,
                 write = TRUE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26))

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('converted', 
                                                 'Bridging coastwide/3_1_1_update_data', 
                                                 'Bridging coastwide/3_1_11_tuned',
                                                 'Bridging coastwide/3_2_7_update_bio_Mconstant_phases',
                                                 'Bridging coastwide/3_2_9_tuned')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015converted', 
                                     '2023 All data',
                                     '2023 All data tuned',
                                     '2023 All data and bio (M as constant)',
                                     '2023 All data and bio tuned'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name) )





##########################################################################################
# 3_3_1 and move to coastwide model -------------------------------------------------
##########################################################################################

new_name <- "Bridging coastwide/3_3_1_coastwide"

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/Bridging coastwide/3_2_7_update_bio_Mconstant_phases'), 
               dir.new = here('models', new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)

######## CHANGE NUMBER OF AREAS ----
mod$ctl$N_areas <- mod$dat$N_areas <- 1
mod$ctl$recr_dist_read <- 1
mod$ctl$recr_dist_pattern <- mod$ctl$recr_dist_pattern[1,]
mod$ctl$MG_parms <- mod$ctl$MG_parms |>
  dplyr::slice(-grep('RecrDist_Area_2', rownames(mod$ctl$MG_parms)),
               -grep('RecrDist_Area_3', rownames(mod$ctl$MG_parms)))

mod$dat$fleetinfo$area <- 1
mod$dat$areas <- rep(1, mod$dat$Nfleets)
mod$dat$fleetinfo1['areas',] <- 1

#Change recruitment distribution method to 4 (none) and change params in MG_parm
mod$ctl$recr_dist_method <- 4
mod$ctl$MG_parms <- mod$ctl$MG_parms[!grepl("RecrDist",rownames(mod$ctl$MG_parms)),]


######## SWITCH TO COASTWIDE SURVEYS ----
state.surveys <- stringr::str_which(fleet.converter$fleet_no_num,
                                    '(?<!coastwide_)(NWFSC|Tri|prerec)')
# returns index for fleet names with NWFSC, Tri, or prerec NOT preceded by coastwide_
coastwide.surveys <- stringr::str_which(fleet.converter$fleet_no_num, 'coastwide')

# Add coastwide surveys back into likelihood
mod$ctl$lambdas <- mod$ctl$lambdas |>
  dplyr::filter(!(fleet %in% fleet.converter$fleet[coastwide.surveys]))

mod$ctl$N_lambdas <- nrow(mod$ctl$lambdas)

# Negative out year of state survey data
# Switch year of coastwide survey comp data to positive
# CPUE
mod$dat$CPUE$year[mod$dat$CPUE$index %in% state.surveys] <- -1 * 
  mod$dat$CPUE$year[mod$dat$CPUE$index %in% state.surveys]
# age comp
mod$dat$agecomp$Yr[mod$dat$agecomp$FltSvy %in% c(state.surveys, coastwide.surveys)] <- -1 *
  mod$dat$agecomp$Yr[mod$dat$agecomp$FltSvy %in% c(state.surveys, coastwide.surveys)]
# length comp
mod$dat$lencomp$Yr[mod$dat$lencomp$FltSvy %in% c(state.surveys, coastwide.surveys)] <- -1 *
  mod$dat$lencomp$Yr[mod$dat$lencomp$FltSvy %in% c(state.surveys, coastwide.surveys)]

######## CATCHABILITY SETTINGS ----
# Get rid of catchability for state surveys
# And add extra_se to coastwide prerec
mod$ctl$Q_options <- mod$ctl$Q_options |>
  dplyr::filter(!(fleet %in% fleet.converter$fleet[state.surveys]))
mod$ctl$Q_options[grep('prerec', rownames(mod$ctl$Q_options)),'extra_se'] <- 1

extra.se.row <- mod$ctl$Q_parms[grep('extraSD', rownames(mod$ctl$Q_parms))[1],]
rownames(extra.se.row) <- stringr::str_replace(rownames(extra.se.row), 'CA', 'coastwide') |>
  stringr::str_replace_all('[:digit:]+',
                           as.character(fleet.converter$fleet[fleet.converter$fleet_no_num == 'coastwide_prerec']))
mod$ctl$Q_parms <- mod$ctl$Q_parms |>
  dplyr::filter(grepl('coastwide', rownames(mod$ctl$Q_parms))) |>
  dplyr::bind_rows(extra.se.row)

######## CHANGE SELECTIVITY FOR COASTWIDE MODEL ----

# Un-mirror TWL, NTWL, REC selectivities
mod$ctl$size_selex_types$Pattern[grep('TWL|REC', fleet.converter$fleetname)] <- 24
mod$ctl$size_selex_types$Special[grep('TWL|REC', fleet.converter$fleetname)] <- 0

# Except WA NTWL which is very small fleet, it mirrors TWL (more similar to WA TWL than OR NTWL)
mod$ctl$size_selex_types$Pattern[fleet.converter$fleet_no_num=='WA_NTWL'] <- 15
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='WA_NTWL'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='WA_TWL']

# Foreign fleets mirror respective state TWL fleet
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='OR_FOR'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='OR_TWL']
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='WA_FOR'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='WA_TWL']

# State surveys have no length selectivity (to eliminate parameter lines)
mod$ctl$size_selex_types$Pattern[grep('NWFSC|Tri', fleet.converter$fleetname)] <- 0
mod$ctl$size_selex_types$Special[grep('NWFSC|Tri', fleet.converter$fleetname)] <- 0

# coastwide surveys get their own selectivity, no mirroring
mod$ctl$size_selex_types$Pattern[grep('coastwide_(NWFSC|Tri)', fleet.converter$fleetname)] <- 24

### Now fix up selectivity parameter table
selex_fleets <- rownames(mod$ctl$size_selex_types)[mod$ctl$size_selex_types$Pattern == 24] |>
  as.list()

selex_names <- purrr::map(selex_fleets,
                          ~ glue::glue('SizeSel_P_{par}_{fleet_name}({fleet_no})',
                                       par = 1:6,
                                       fleet_name = .x,
                                       fleet_no = fleet.converter$fleet[fleet.converter$fleetname == .x])) |>
  unlist()

selex_new <- matrix(0, nrow = length(selex_names), 
                    ncol = ncol(mod$ctl$size_selex_parms), 
                    dimnames = list(selex_names, names(mod$ctl$size_selex_parms))) |>
  as.data.frame()

# default lo and hi
selex_new$LO <- -99
selex_new$HI <- 99

# No prior applied, so just need to fill in a number
selex_new$PR_SD <- 99
selex_new$PRIOR <- 99

# Fix three parameters of double normal
selex_new$INIT[grep('P_2', rownames(selex_new))] <- -15
selex_new$INIT[grep('P_5', rownames(selex_new))] <- -15 #set to -15 to have smallest fish with 0 selectivity
selex_new$INIT[grep('P_6', rownames(selex_new))] <- -999
selex_new$PHASE[grep('P_2', rownames(selex_new))] <- -99
selex_new$PHASE[grep('P_5', rownames(selex_new))] <- -99
selex_new$PHASE[grep('P_6', rownames(selex_new))] <- -99

# calculate initial values for p1, p3, p4 for each fleet
# based on recommendations in assessment handbook
selex_modes <- mod$dat$lencomp |>
  dplyr::arrange(FltSvy) |>
  dplyr::group_by(FltSvy) |>
  dplyr::summarise(dplyr::across(f12:m66, ~ sum(Nsamp*.x)/sum(Nsamp))) |> 
  tidyr::pivot_longer(cols = -FltSvy, names_to = 'len_bin', values_to = 'dens') |>
  tidyr::separate(col = len_bin, into = c('sex', 'length'), sep = 1) |>
  dplyr::group_by(FltSvy, sex) |> 
  dplyr::summarise(mode = length[which.max(dens)]) |>
  dplyr::summarise(mode = mean(as.numeric(mode))) |>
  dplyr::mutate(asc.slope = log(8*(mode - 12)),
                desc.slope = log(8*(66-mode)))

#Add in CA ASHOP here so this runs (previously it was removed but here its used as the first mirror fleet). 
#Use the same values as OR ASHOP, where INIT is updated below
selex_modes <- rbind(selex_modes, c("FltSvy" = 10, selex_modes[selex_modes$FltSvy==11,-1]))


# P_1
p1.ind <- grep('P_1', rownames(selex_new))
selex_new$LO[p1.ind] <- 13.001
selex_new$HI[p1.ind] <- 65
selex_new$PHASE[p1.ind] <- 4
selex_new$INIT[p1.ind] <- purrr::map(selex_fleets, 
                                     ~ selex_modes$mode[selex_modes$FltSvy == 
                                                          fleet.converter$fleet[fleet.converter$fleetname == .x]]) |>
  unlist()
# Hard coding this in, do not use CA as basis for mode of ASHOP selectivity
selex_new['SizeSel_P_1_10_CA_ASHOP(10)', 'INIT'] <- 48

### P_3
p3.ind <- grep('P_3', rownames(selex_new))
selex_new$PHASE[p3.ind] <- 5
selex_new$LO[p3.ind] <- 0
selex_new$HI[p3.ind] <- 9
selex_new$INIT[p3.ind] <- purrr::map(selex_fleets, 
                                     ~ selex_modes$asc.slope[selex_modes$FltSvy == 
                                                               fleet.converter$fleet[fleet.converter$fleetname == 
                                                                                       .x]]) |>
  unlist()

### P_4
p4.ind <- grep('P_4', rownames(selex_new))
selex_new$PHASE[p4.ind] <- 5
selex_new$LO[p4.ind] <- 0
selex_new$HI[p4.ind] <- 9
selex_new$INIT[p4.ind] <- purrr::map(selex_fleets, 
                                     ~ selex_modes$desc.slope[selex_modes$FltSvy == 
                                                                fleet.converter$fleet[fleet.converter$fleetname == 
                                                                                        .x]]) |>
  unlist()

# just copying blocks from Jim for now
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block', 'Block_Fxn')] <- 2
selex_new[grepl('_NTWL', rownames(selex_new)) & selex_new$PHASE > 0, 'Block'] <- 1
selex_new[grepl('_NTWL', rownames(selex_new)) & selex_new$PHASE > 0, 'Block_Fxn'] <- 2

mod$ctl$size_selex_parms <- selex_new

### Time varying selectivity table
selex_tv_pars <- dplyr::filter(selex_new, Block > 0) |>
  dplyr::select(LO, HI, INIT, PRIOR, PR_SD, PR_type, PHASE, Block) |>
  tidyr::uncount(Block, .id = 'id', .remove = FALSE)

rownames(selex_tv_pars) <- rownames(selex_tv_pars) |>
  stringr::str_remove('\\.\\.\\.[:digit:]+') |>
  stringr::str_c('_BLK', selex_tv_pars$Block, 'repl_', mapply("[",mod$ctl$Block_Design[selex_tv_pars$Block], selex_tv_pars$id * 2 - 1))

mod$ctl$size_selex_parms_tv <- selex_tv_pars |>
  dplyr::select(-Block, -id)


##----
#Output files and run
##

SS_write(mod,
         dir = here('models', new_name),
         overwrite = TRUE)

# r4ss::run(dir = here('models',new_name), 
#           exe = here('models/ss_win.exe'), 
#           # extras = '-nohess', 
#           # show_in_console = TRUE, 
#           skipfinished = FALSE)

out <- r4ss::SS_output(here('models',new_name))
r4ss::SS_plots(replist = out)



####------------------------------------------------####
### 3_3_2_lambda1 Set lambdas to 1 for coastwide model ----
####------------------------------------------------####

new_name <- 'Bridging coastwide/3_3_2_lambda1'

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/Bridging coastwide/3_3_1_coastwide'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

#Set lambdas to 1 for all but the coastwide comps (rec age comps 
#were previously zero because did not have them in the model)
mod$ctl$lambdas[!grepl("_coastwide",rownames(mod$ctl$lambdas)), "value"] <- 1

#Set lambdas to 0 for CA ashop length and age and CA_rec because dont have them in the model
mod$ctl$lambdas[grepl("CA_ASHOP",rownames(mod$ctl$lambdas)), "value"] <- 0
mod$ctl$lambdas[grepl("age_7_CA_REC",rownames(mod$ctl$lambdas)), "value"] <- 0


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

# r4ss::run(dir = here('models',new_name), 
#           exe = here('models/ss_win.exe'), 
#           extras = '-nohess', 
#           # show_in_console = TRUE, 
#           skipfinished = FALSE)



####------------------------------------------------####
### 3_3_3_coastwide_tuned Tune the model with data and bio added ----
####------------------------------------------------####

new_name <- 'Bridging coastwide/3_3_3_coastwide_tuned'
copied_model <- 'Bridging coastwide/3_3_2_lambda1'

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models', copied_model),
               dir.new = here('models',new_name),
               overwrite = TRUE)
file.copy(from = file.path(here('models', copied_model),"Report.sso"),
          to = file.path(here('models',new_name),"Report.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models', copied_model),"CompReport.sso"),
          to = file.path(here('models',new_name),"CompReport.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models', copied_model),"warning.sso"),
          to = file.path(here('models',new_name),"warning.sso"), overwrite = TRUE)

##
#Make Changes
##

mod <- SS_read(here('models',new_name))

yy <- SS_output(here('models', new_name))
dw <- tune_comps(replist = yy, dir = here('models', new_name),
                 option = c("Francis"), niters_tuning = 3,
                 exe = here('models/ss_win.exe'), extras = "-nohess",
                 allow_up_tuning = TRUE,
                 write = TRUE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26))

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('converted', 
                                                 'Bridging coastwide/3_1_1_update_data', 
                                                 'Bridging coastwide/3_1_11_tuned',
                                                 'Bridging coastwide/3_2_7_update_bio_Mconstant_phases',
                                                 'Bridging coastwide/3_2_9_tuned',
                                                 'Bridging coastwide/3_3_1_coastwide',
                                                 'Bridging coastwide/3_3_3_coastwide_tuned')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015converted', 
                                     '2023 All data - spatial',
                                     '2023 All data tuned - spatial',
                                     '2023 All data and bio (M as constant) - spatial',
                                     '2023 All data and bio tuned - spatial',
                                     '2023 Coastwide',
                                     '2023 Coastwide tuned'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name) )

