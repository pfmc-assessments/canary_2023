##########################################################################################
#
# Model runs for 2023 Canary rockfish 
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
### 0_1_1_update_data ----
####------------------------------------------------####

##
#Copy inputs
##

# I suggest not touching converted, or transition. That was just for updating SS3
# version, and plus just enough changes so that it actually ran. It was not 100% reproducible.
copy_SS_inputs(dir.old = here('models/converted'), 
               dir.new = here('models/0_1_1_update_data'),
               overwrite = TRUE)

mod <- SS_read(here('models/0_1_1_update_data'))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)


##
#Make Changes
##

mod$start$detailed_age_structure <- 1 #all output

# Extend catch time series ------------------------------------------------

mod$dat$endyr <- 2022

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
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_REC', ##THIS IS INCORRECT. IT SHOULD BE {area}_ASHOP
                                                                                           area = .x)],
                  ageErr = 1) |> #non-expanded has different names than expanded so ageErr here
    `names<-`(names(mod$dat$agecomp))
}) |>
  purrr::list_rbind()

ashop.lengths <- purrr::map(list('OR', 'WA'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_rec_not_expanded_Lcomp{lmin}_{lmax}_formatted.csv', ##THIS IS INCORRECT. THE FILE NAME SHOULD HAVE ASHOP
                           area = .x,
                           lmin = length.min,
                           lmax = length.max))) |>
    dplyr::select(-Nsamp) |>
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_REC', ##THIS IS INCORRECT. IT SHOULD BE {area}_ASHOP
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



##
#Output files and run
##

SS_write(mod,
         dir = here('models/0_1_1_update_data'),
         overwrite = TRUE)

r4ss::run(dir = here('models/0_1_1_update_data'), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)


##
#Comparison plots
##

pp <- SS_output(here('models/0_1_1_update_data'),covar=FALSE)
SS_plots(pp)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('2015base', 'converted', '0_1_1_update_data')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015', 'converted', '2023 data update'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models/0_1_1_update_data'))


####------------------------------------------------####
### 0_1_2_catch Individually add data one by one ----
####------------------------------------------------####

new_name <- '0_1_2_catch'

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

# Extend catch time series ------------------------------------------------

mod$dat$endyr <- 2022

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

r4ss::run(dir = here('models/0_1_1_update_data'), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

####------------------------------------------------####
### 0_1_3_survey Individually add data one by one ----
####------------------------------------------------####

new_name <- '0_1_3_survey'
#new_name <- '0_1_3_survey_2022' #if uncomment the change to the start year below


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
#mod$dat$endyr <- 2022
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

r4ss::run(dir = here('models/0_1_1_update_data'), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)


####------------------------------------------------####
### 0_1_4_surveyCompsNWFSC Individually add data one by one ----
####------------------------------------------------####

new_name <- '0_1_4_surveyCompsNWFSC'
#new_name <- '0_1_4_surveyCompsNWFSC_2022' #if uncomment the change to the start year below

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
#mod$dat$endyr <- 2022
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

r4ss::run(dir = here('models/0_1_1_update_data'), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)


####------------------------------------------------####
### 0_1_5_surveyCompsTri Individually add data one by one ----
####------------------------------------------------####

new_name <- '0_1_5_surveyCompsTri'
#new_name <- '0_1_5_surveyCompsTri_2022' #if uncomment the change to the start year below

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
#mod$dat$endyr <- 2022
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

r4ss::run(dir = here('models/0_1_1_update_data'), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)


####------------------------------------------------####
### 0_1_6_fisheryComps Individually add data one by one ----
####------------------------------------------------####

new_name <- '0_1_6_fisheryComps'
#new_name <- '0_1_6_fisheryComps_2022' #if uncomment the change to the start year below

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
#mod$dat$endyr <- 2022
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
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_REC', ##THIS IS INCORRECT. IT SHOULD BE {area}_ASHOP
                                                                                           area = .x)],
                  ageErr = 1) |> #non-expanded has different names than expanded so ageErr here
    `names<-`(names(mod$dat$agecomp))
}) |>
  purrr::list_rbind()

ashop.lengths <- purrr::map(list('OR', 'WA'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_rec_not_expanded_Lcomp{lmin}_{lmax}_formatted.csv', ##THIS IS INCORRECT. THE FILE NAME SHOULD HAVE ASHOP
                           area = .x,
                           lmin = length.min,
                           lmax = length.max))) |>
    dplyr::select(-Nsamp) |>
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_REC', ##THIS IS INCORRECT. IT SHOULD BE {area}_ASHOP
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




##
#Output files and run
##

SS_write(mod,
         dir = here('models', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/0_1_1_update_data'), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)


xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('converted', 
                                                 '0_1_1_update_data', 
                                                 '0_1_2_catch',
                                                 '0_1_3_survey',
                                                 '0_1_4_surveyCompsNWFSC',
                                                 '0_1_5_surveyCompsTri',
                                                 '0_1_6_fisheryComps')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015converted', '2023 All data', 
                                     'Catch',
                                     'Survey',
                                     'SurveyCompsNWFSC',
                                     'SurveyCompsTri',
                                     'fisheryComps'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name) )


####------------------------------------------------####
### 0_1_7_fishery Add catches and fishery comps ----
####------------------------------------------------####

#Adding data one by one doesn't recreate the dip in estimated abundance starting in the 50s
#I believe adding comps to the recent years since 2014 results in changed selectivity
#in recent years which given the current block structure match historical years.
#Looking at the selectivity values for CA TWL and NTWL (all other com fleets mirror to those)
#seelctivity has shifted leftward. Also recruitment starting in 1933 declines. Collectively
#this is what is contributing but Im not sure what is driving that shift.

new_name <- '0_1_7_fishery'

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

# Extend catch time series ------------------------------------------------

mod$dat$endyr <- 2022

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
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_REC', ##THIS IS INCORRECT. IT SHOULD BE {area}_ASHOP
                                                                                           area = .x)],
                  ageErr = 1) |> #non-expanded has different names than expanded so ageErr here
    `names<-`(names(mod$dat$agecomp))
}) |>
  purrr::list_rbind()

ashop.lengths <- purrr::map(list('OR', 'WA'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_rec_not_expanded_Lcomp{lmin}_{lmax}_formatted.csv', ##THIS IS INCORRECT. THE FILE NAME SHOULD HAVE ASHOP
                           area = .x,
                           lmin = length.min,
                           lmax = length.max))) |>
    dplyr::select(-Nsamp) |>
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_REC', ##THIS IS INCORRECT. IT SHOULD BE {area}_ASHOP
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




##
#Output files and run
##

SS_write(mod,
         dir = here('models', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/0_1_1_update_data'), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)


xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('converted', 
                                                 '0_1_1_update_data', 
                                                 '0_1_2_catch',
                                                 '0_1_3_survey',
                                                 '0_1_4_surveyCompsNWFSC',
                                                 '0_1_5_surveyCompsTri',
                                                 '0_1_6_fisheryComps',
                                                 '0_1_7_fishery')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015converted', '2023 All data', 
                                     'Catch',
                                     'Survey',
                                     'SurveyCompsNWFSC',
                                     'SurveyCompsTri',
                                     'fisheryComps',
                                     "fisheryCompsCatch"),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name) )


####------------------------------------------------####
### 0_1_8_survey Add survey indices and comps ----
####------------------------------------------------####

#This run lowers the population a bit, and seems to be based on lower recruitment
#during period the population declines. Also lowers trawl selectivity slightly


new_name <- '0_1_8_survey'
#new_name <- '0_1_8_survey_2022' #if uncomment the change to the start year below

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
#mod$dat$endyr <- 2022
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

r4ss::run(dir = here('models', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)


xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('converted', 
                                                 '0_1_1_update_data', 
                                                 '0_1_2_catch',
                                                 '0_1_3_survey',
                                                 '0_1_4_surveyCompsNWFSC',
                                                 '0_1_5_surveyCompsTri',
                                                 '0_1_6_fisheryComps',
                                                 '0_1_7_fishery',
                                                 '0_1_8_survey')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015converted', '2023 All data', 
                                     'Catch',
                                     'Survey',
                                     'SurveyCompsNWFSC',
                                     'SurveyCompsTri',
                                     'fisheryComps',
                                     "fisheryCompsCatch",
                                     'surveyCompsIndex'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name) )

#For runs with extending time seires to 2022
xx2022 <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('converted', 
                                                 '0_1_1_update_data', 
                                                 '0_1_2_catch',
                                                 '0_1_3_survey',
                                                 '0_1_3_survey_2022',
                                                 '0_1_4_surveyCompsNWFSC',
                                                 '0_1_4_surveyCompsNWFSC_2022',
                                                 '0_1_5_surveyCompsTri',
                                                 '0_1_5_surveyCompsTri_2022',
                                                 '0_1_6_fisheryComps',
                                                 '0_1_6_fisheryComps_2022',
                                                 '0_1_7_fishery',
                                                 '0_1_8_survey',
                                                 '0_1_8_survey_2022')))
SSsummarize(xx2022) |>
  SSplotComparisons(legendlabels = c('2015converted', '2023 All data', 
                                     'Catch',
                                     'Survey',
                                     'Survey 2022',
                                     'SurveyCompsNWFSC',
                                     'SurveyCompsNWFSC 2022',
                                     'SurveyCompsTri',
                                     'SurveyCompsTri 2022',
                                     'fisheryComps',
                                     'fisheryComps 2022',
                                     "fisheryCompsCatch",
                                     'surveyCompsIndex',
                                     'surveyCompsIndex 2022'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name) )



####------------------------------------------------####
### 0_1_9_catchANDsurvey Add survey indices and comps as well as catches ----
####------------------------------------------------####

new_name <- '0_1_9_catchANDsurvey'

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

# Extend catch time series ------------------------------------------------

mod$dat$endyr <- 2022

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


##
#Output files and run
##

SS_write(mod,
         dir = here('models', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)


xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('converted', 
                                                 '0_1_1_update_data', 
                                                 '0_1_2_catch',
                                                 '0_1_3_survey',
                                                 '0_1_4_surveyCompsNWFSC',
                                                 '0_1_5_surveyCompsTri',
                                                 '0_1_6_fisheryComps',
                                                 '0_1_7_fishery',
                                                 '0_1_8_survey',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015converted', '2023 All data', 
                                     'Catch',
                                     'Survey',
                                     'SurveyCompsNWFSC',
                                     'SurveyCompsTri',
                                     'fisheryComps',
                                     'fisheryCompsCatch',
                                     'surveyCompsIndex',
                                     'CatchSurveys'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name) )


####------------------------------------------------####
### 0_1_10_extendBlocks Update fishery data AND extend blocks out to end year ----
####------------------------------------------------####

#This shows that the population declines much less when selectivity in 2015-2022 isn't
#set to mirror the < 2000 block. Selectivity for CA TWL and NTWL (which otehr fleets mirror)
#moves right

#Note however that the gradients on this are really bad so not sure whether can trust this.
#Try extending blocks with all data

new_name <- '0_1_10_extendBlocks_fishery'

##
#Copy inputs
##

# I suggest not touching converted, or transition. That was just for updating SS3
# version, and plus just enough changes so that it actually ran. It was not 100% reproducible.
copy_SS_inputs(dir.old = here('models/0_1_7_fishery'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models', new_name))


##
#Make Changes
##

mod$ctl$Block_Design[[1]][2] <- 2022
mod$ctl$Block_Design[[2]][4] <- 2022


##
#Output files and run
##

SS_write(mod,
         dir = here('models', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)


##
#Comparison plots
##

pp <- SS_output(here('models', new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('converted', 
                                                 '0_1_1_update_data',
                                                 '0_1_7_fishery',
                                                 '0_1_8_survey',
                                                 '0_1_9_catchANDsurvey',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015converted', '2023 All data', 
                                     'fisheryCompsCatch',
                                     'surveyCompsIndex',
                                     'Catch and Surveys',
                                     'fishery and extend Blocks'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name) )


####------------------------------------------------####
### 0_1_10_extendBlocks Extend blocks out to end year with all data updated ----
####------------------------------------------------####

#Extending with all data in ends up in similar place as 0_1_1. The decline does not appear to be due
#to not extending the blocks nor adding in fishing data.
#This drops NTWL selectivity but raises the dome portion of TWL

new_name <- '0_1_10_extendBlocks_all'

##
#Copy inputs
##

# I suggest not touching converted, or transition. That was just for updating SS3
# version, and plus just enough changes so that it actually ran. It was not 100% reproducible.
copy_SS_inputs(dir.old = here('models/0_1_1_update_data'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models', new_name))


##
#Make Changes
##

mod$ctl$Block_Design[[1]][2] <- 2022
mod$ctl$Block_Design[[2]][4] <- 2022


##
#Output files and run
##

SS_write(mod,
         dir = here('models', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)


##
#Comparison plots
##

pp <- SS_output(here('models', new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('converted', 
                                                 '0_1_1_update_data',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015converted', '2023 All data', 
                                     'Extend Blocks'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name) )



####------------------------------------------------####
### 0_1_11_fixCaHistCatch ---- Found an error in CA historical catches
####------------------------------------------------####

#Bug has negligable effect on model output

new_name = "0_1_11_fixCaHistCatch"

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

# Extend catch time series ------------------------------------------------

mod$dat$endyr <- 2022

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
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_REC', ##THIS IS INCORRECT. IT SHOULD BE {area}_ASHOP
                                                                                           area = .x)],
                  ageErr = 1) |> #non-expanded has different names than expanded so ageErr here
    `names<-`(names(mod$dat$agecomp))
}) |>
  purrr::list_rbind()

ashop.lengths <- purrr::map(list('OR', 'WA'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_rec_not_expanded_Lcomp{lmin}_{lmax}_formatted.csv', ##THIS IS INCORRECT. THE FILE NAME SHOULD HAVE ASHOP
                           area = .x,
                           lmin = length.min,
                           lmax = length.max))) |>
    dplyr::select(-Nsamp) |>
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_REC', ##THIS IS INCORRECT. IT SHOULD BE {area}_ASHOP
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



##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)


##
#Comparison plots
##

pp <- SS_output(here('models', new_name),covar=FALSE)
SS_plots(pp)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('converted', 
                                                 '0_1_1_update_data',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('converted', 
                                     '2023 data update',
                                     'fix CA hist catch'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models', new_name))



####------------------------------------------------####
### 0_2_1_update_bio All bio but with only the prior changed for M----
####------------------------------------------------####

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/0_1_1_update_data'), 
               dir.new = here('models/0_2_1_update_bio_Mval'),
               overwrite = TRUE)

mod <- SS_read(here('models/0_2_1_update_bio_Mval'))

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
         dir = here('models/0_2_1_update_bio_Mval'),
         overwrite = TRUE)

r4ss::run(dir = here('models/0_2_1_update_bio_Mval'), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models/0_2_1_update_bio'),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('2015base', 
                                                 '0_1_1_update_data', 
                                                 '0_2_1_update_bio_Mval',
                                                 '0_2_2_Mconstant',
                                                 '0_2_2_M_justValue',
                                                 '0_2_3_maturity',
                                                 '0_2_4_steepness',
                                                 '0_2_5_fecund',
                                                 '0_2_6_WL')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015', '2023 data update', '2023 data bio', 
                                     'mortality', 'mortality-value', 'maturity', 'steepness','fecundity', 'WL'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models/0_2_1_update_bio_Mval') )


####------------------------------------------------####
### 0_2_2_Mconstant update bio M individually ----
####------------------------------------------------####

new_name <- "0_2_2_Mconstant"

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/0_1_1_update_data'), 
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

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])


####------------------------------------------------####
### 0_2_2_M_justValue update bio M individually ----
####------------------------------------------------####

new_name <- "0_2_2_M_justValue"

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/0_1_1_update_data'), 
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

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])



####------------------------------------------------####
### 0_2_3_maturity update bio maturity individually ----
####------------------------------------------------####

new_name <- "0_2_3_maturity"

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/0_1_1_update_data'), 
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

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])


####------------------------------------------------####
### 0_2_4_steepness update bio steepness individually ----
####------------------------------------------------####

new_name <- "0_2_4_steepness"

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/0_1_1_update_data'), 
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

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])


####------------------------------------------------####
### 0_2_5_fecund update bio fecundity individually ----
####------------------------------------------------####

new_name <- "0_2_5_fecund"

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/0_1_1_update_data'), 
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

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])


####------------------------------------------------####
### 0_2_6_WL update bio WL individually ----
####------------------------------------------------####

new_name <- "0_2_6_WL"

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/0_1_1_update_data'), 
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

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])



####------------------------------------------------####
### 0_2_7_update_bio_Mconstant include all bio changes ----
####------------------------------------------------####

new_name <- "0_2_7_update_bio_Mconstant"

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/0_2_1_update_bio_Mval'), 
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

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('2015base', 
                                                 '0_1_1_update_data', 
                                                 '0_2_1_update_bio_Mval',
                                                 '0_2_2_Mconstant',
                                                 '0_2_2_M_justValue',
                                                 '0_2_3_maturity',
                                                 '0_2_4_steepness',
                                                 '0_2_5_fecund',
                                                 '0_2_6_WL',
                                                 '0_2_7_update_bio_Mconstant')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015', '2023 data update', '2023 data bio-Mval', 
                                     'mortality-cons', 'mortality-val', 'maturity', 'steepness','fecundity', 'WL',
                                     '2023 data bio-Mcons'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


#This produces funky results. R0 wants to go higher and higher (see 0_2_7_upR0bound - which is not automated)
#RecDist also become poorly estimated
#Adjusting phases (0_2_7_adjustPhases - which is not automated) does make some difference but still funky. 
#I later automate that in 0_2_8
#If fix male M (dfone in 0_2_10) result is much improved


####------------------------------------------------####
### 0_2_8_update_bio_phases Adjust phases for GP parms ----
####------------------------------------------------####

new_name <- "0_2_8_update_bio_Mval_phases"

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/0_2_1_update_bio_Mval'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

# Set phases for M = 2, growth = 3, CV = 4. Previously mostly all at 2
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

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('2015base', 
                                                 '0_1_1_update_data', 
                                                 '0_2_1_update_bio_Mval',
                                                 '0_2_8_update_bio_Mval_phases')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015', '2023 data update', '2023 data bio-Mval', 
                                     '2023 data bio-phase'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 0_2_9_newBreakpoints Adjust breakpoints for M based on occurrence in trawl ----
####------------------------------------------------####

new_name <- "0_2_9_breakpoints"

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/0_2_8_update_bio_Mval_phases'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

# Set breakpoints to ages 20 and 21, when female sex ratio declines
mod$ctl$M_ageBreakPoints[[1]] <- 20
mod$ctl$M_ageBreakPoints[[2]] <- 21


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('2015base', '0_2_8_update_bio_Mval_phases',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015', '2023 data bio-Mvalphase',
                                     'BreakPoints'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 0_2_10_maleMfix Fix male mortality in constant M model ----
####------------------------------------------------####

new_name <- "0_2_10_maleMfix"

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/0_2_7_update_bio_Mconstant'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

# Fix male M at the prior, estimate female m
mod$ctl$MG_parms['NatM_p_1_Mal_GP_1', 'PHASE'] <- -50


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('2015base', 
                                                 '0_1_1_update_data', 
                                                 '0_2_1_update_bio_Mval',
                                                 '0_2_7_update_bio_Mconstant',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015', '2023 data update', '2023 data bio-Mval', 
                                     '2023 data bio-Mcons', '2023 data bio-Mcons maleFix'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 0_2_11_femMprior Set female logevity to 55 for M prior ----
####------------------------------------------------####

#Basically identical to when prior is same with males

new_name <- "0_2_11_femMprior"

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/0_2_10_maleMfix'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

# Base female longevity on 99.99% quantile of commercial ages. Rec and survey ages are lower
max.age <- 55
mod$ctl$MG_parms['NatM_p_1_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')] <- c(
  0.02, 0.2,
  round(5.4/max.age, 4), 
  round(log(5.4/max.age), 2), 
  0.31, 2 #estimate female M
)


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_2_10_maleMfix',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('maleFixM', "change fem M prior"),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))



####------------------------------------------------####
### 0_2_12_phases Update phases from fix male mortality ----
####------------------------------------------------####

#Basically identical

new_name <- "0_2_12_maleMfixPhases"

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/0_2_10_maleMfix'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

# Set phases for M = 2, growth = 3, CV = 4. Previously mostly all at 2
mod$ctl$MG_parms[c('L_at_Amin_Fem_GP_1',
                   'L_at_Amax_Fem_GP_1',
                   'VonBert_K_Fem_GP_1',
                   'CV_young_Fem_GP_1',
                   'CV_old_Fem_GP_1',
                   'L_at_Amax_Mal_GP_1',
                   'VonBert_K_Mal_GP_1',
                   'CV_young_Mal_GP_1',
                   'CV_old_Mal_GP_1'),'PHASE'] <- c(3,3,3,4,4,3,3,4,4)

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_2_1_update_bio_Mval',
                                                 '0_2_8_update_bio_Mval_phases',
                                                 '0_2_10_maleMfix',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Mval', 'MvalPhase',
                                     'MaleFix', 'MaleFixPhase'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))





##########################################################################################
# 0_3_1 and 0_5_1 Move to coastwide model -------------------------------------------------
##########################################################################################

# new_name <- "0_3_1_coastwide" #copied from 0_2_1_update_bio_Mval
new_name <- "0_5_1_coastwide_better_blocks"

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/0_4_3_selexExtend'), 
               dir.new = here('models', new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

######## CHANGE NUMBER OF AREAS
mod$ctl$N_areas <- mod$dat$N_areas <- 1
mod$ctl$recr_dist_read <- 1
mod$ctl$recr_dist_pattern <- mod$ctl$recr_dist_pattern[1,]
mod$ctl$MG_parms <- mod$ctl$MG_parms |>
  dplyr::slice(-grep('RecrDist_Area_2', rownames(mod$ctl$MG_parms)),
               -grep('RecrDist_Area_3', rownames(mod$ctl$MG_parms)))

mod$dat$fleetinfo$area <- 1
mod$dat$areas <- rep(1, mod$dat$Nfleets)
mod$dat$fleetinfo1['areas',] <- 1

######## SWITCH TO COASTWIDE SURVEYS
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

######## CATCHABILITY SETTINGS
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

######## CHANGE SELECTIVITY FOR COASTWIDE MODEL

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
selex_new$INIT[grep('P_5', rownames(selex_new))] <- -999
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
  stringr::str_c('_BLK', selex_tv_pars$Block, 'repl_', 10*selex_tv_pars$id + 1990)

mod$ctl$size_selex_parms_tv <- selex_tv_pars |>
  dplyr::select(-Block, -id)


##
#Output files and run
##

SS_write(mod,
         dir = here('models', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          # extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)
beepr::beep()

out <- r4ss::SS_output(here('models',new_name))
r4ss::SS_plots(replist = out)
beepr::beep()

####------------------------------------------------####
### 0_3_2_spatialHessian Do hessian for model 0_2_1_update_bio_Mval ----
####------------------------------------------------####

new_name <- "0_3_2_spatialHessian"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_2_1_update_bio_Mval'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          #extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])


####------------------------------------------------####
### 0_3_3_bestSpatialHessian Do hessian for best updated spatial model ----
####------------------------------------------------####

new_name <- "0_3_3_bestSpatialHessian"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_2_12_maleMfixphases'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          #extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('2015base',
                                                 'converted',
                                                 '0_1_1_update_data', 
                                                 '0_2_1_update_bio_Mval',
                                                 '0_2_2_M_justValue',
                                                 '0_2_3_maturity',
                                                 '0_2_4_steepness',
                                                 '0_2_5_fecund',
                                                 '0_2_6_WL',
                                                 '0_2_10_maleMfix',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015', '2015 new SS', '2023 add data', '2023 add bio (Mprior)', 
                                     'only Mprior', 'only mat', 'only steep', 'only fec', 'only WL',
                                     '2023 add bio (fix male M)', 'hessian'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models', new_name) )



##########################################################################################
#               Explorations with up-to-date current version to decide base
##########################################################################################


####------------------------------------------------####
### 0_4_1_ssInputs Based on best spatial model up to this point ----
####------------------------------------------------####

#Basically identical

new_name <- "0_4_1_ssInputs"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_3_3_bestSpatialHessian'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))



##
#Make Changes
##

#Make changes to starter ------------------------------------------------
mod$start$N_bootstraps <- 1 #generate ss_new datafile
mod$start$SPR_basis <- 4 #This may not be needed (1 is ok) but use raw (1-SPR). 

#Make changes to forecast ------------------------------------------------
mod$fore$MSY <- 2 #calculate actual MSY
mod$fore$Bmark_years <- c(-999,0, 0,0, 0,0, -999,0, -999,0) #start year and end year for all but selectivity (because of blocks) and relF
mod$fore$Nforecastyrs <- 12
mod$fore$Fcast_years <- c(0,0, -3,0, -999,0) #last year for selex, last three years for relF, full time series for average recruitment (though using fcast_rec_option = 0 ignores this)
mod$fore$ControlRuleMethod <- 3
mod$fore$Flimitfraction <- -1 #Set year and pstar buffers
mod$fore$Flimitfraction_m <- data.frame("Year" = 2023:2034, 
                                        "Fraction" = get_buffer(c(2023:2034), sigma = 0.5, pstar = 0.45)[,2])
mod$fore$FirstYear_for_caps_and_allocations <- 2025
mod$fore$InputBasis <- 2
mod$fore$ForeCatch <- data.frame("Year" = rep(2023:2024, each = mod$dat$Nfleet),
                                 "Seas" = 1,
                                 "Fleet" = rep(1:mod$dat$Nfleet, 2),
                                 "Catch or F" = 0)

#Make changes to data ------------------------------------------------
mod$dat$N_areas <- 3 #already three but setting up so explicit later
mod$dat$catch$catch_se <- 0.05
mod$dat$len_info$minsamplesize <- 0.01 #Manual says CAAL could have sample size < 1 so setting lower
mod$dat$age_info$minsamplesize <- 0.01 #Manual says CAAL could have sample size < 1 so setting lower

#Make changes to control ------------------------------------------------
mod$ctl$recr_dist_method <- 2 #WOULD NEED TO CHANGE TO 4 IF GO WITH NONSPATIAL MODEL, AND CHECK WHETHER THE RECR PARAMETERS ARE NULLIFIED - THEY ARE NOT AUTOMATICALLY REMOVED
if(mod$ctl$recr_dist_method==4){ #Comment out RecrDist parameters
  recLine <- grep("RecrDist",rownames(mod$ctl$MG_parms))
  mod$ctl$MG_parms$LO[recLine] <- paste("#",mod$ctl$MG_parms$LO[recLine])
}
#mod$ctl$recr_dist_pattern[1:4] <- c(1,1,1,0) #TO DO: DISCUSS CHANGE OF SETTLEMENT TO SPRING-SUMMER? 
mod$ctl$Growth_Age_for_L2 <- 999 #set equivalent to Linf
mod$ctl$First_Mature_Age <- 2 #Keep at 2. IGNORED when maturity option is 3 but Id like to set it to whatever it is in case we change maturity option
mod$ctl$MG_parms[c('RecrDist_Area_2','RecrDist_Area_3'),'dev_maxyr'] <- 2022 #update to current end year
mod$ctl$Use_steep_init_equi <- 1 #include in init eq. equations
mod$ctl$Fcast_recr_phase <- mod$ctl$recdev_phase+1
mod$ctl$F_Method <- 3 #TO DO: RECOMMENDED APPROACH IS 4 but IM NOT SURE WHAT DIFFERENCE IS. Looks like its useful if the model has issues (fleet specific F phases). THIS SLOWS DOWN RUNTIME A BIT
mod$ctl$maxF <- 4
mod$ctl$F_iter <-  5



##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_3_3_bestSpatialHessian',new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2023 model', 'SS3 inputs'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name) )


####------------------------------------------------####
### 0_4_1_1_MGdevPH ----
####------------------------------------------------####

#Not reproducing here but I copied model 0_4_1_ssInputs and then set all 
#dev_PH = 0.5 values to 0 in the MG parm section to confirm that this indeed 
#has no effect on the model

new_name <- '0_4_1_1_MGdevPH'

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_4_1_ssInputs',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('SS3 inputs',
                                     'set dev_PH to 0'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name) )



####------------------------------------------------####
### 0_4_2_selexSetup Update selectivity setup and stop mirroring all fleets ----
####------------------------------------------------####

new_name <- "0_4_2_selexSetup"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_4_1_ssInputs'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)



##
#Make Changes
##

### Unmirror fleets ----
# Un-mirror TWL, NTWL, REC selectivities
mod$ctl$size_selex_types$Pattern[grep('TWL|REC', fleet.converter$fleetname)] <- 24
mod$ctl$size_selex_types$Special[grep('TWL|REC', fleet.converter$fleetname)] <- 0

# Except WA NTWL which is very small fleet, it mirrors TWL (more similar to WA TWL than OR NTWL)
mod$ctl$size_selex_types$Pattern[fleet.converter$fleet_no_num=='WA_NTWL'] <- 15
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='WA_NTWL'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='WA_TWL']

# Foreign fleets mirror respective state TWL fleet
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='OR_FOR'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='OR_TWL']
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='WA_FOR'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='WA_TWL']

# NMFS surveys by state mirror one another as well as the coastwide so keep as is


### Now fix up selectivity parameter table ----

#First for double normal selextivities
selex_fleets <- rownames(mod$ctl$size_selex_types)[mod$ctl$size_selex_types$Pattern == 24] |>
  as.list()

#Get names of all six parms for double normal
selex_names <- purrr::map(selex_fleets,
                          ~ glue::glue('SizeSel_P_{par}_{fleet_name}({fleet_no})',
                                       par = 1:6,
                                       fleet_name = .x,
                                       fleet_no = fleet.converter$fleet[fleet.converter$fleetname == .x])) |>
  unlist()

#Set up new selectivity table
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

# Fix three parameters of double normal initially
selex_new$INIT[grep('P_2', rownames(selex_new))] <- -15
selex_new$INIT[grep('P_5', rownames(selex_new))] <- -999
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
  dplyr::mutate(asc.slope = log(8*(mode - min(mod$dat$lbin_vector))),
                desc.slope = log(8*(max(mod$dat$lbin_vector)-mode)))

# P_1
p1.ind <- grep('P_1', rownames(selex_new))
selex_new$LO[p1.ind] <- 13.001
selex_new$HI[p1.ind] <- 65
selex_new$PHASE[p1.ind] <- 4
selex_new$INIT[p1.ind] <- purrr::map(selex_fleets, 
                                     ~ selex_modes$mode[selex_modes$FltSvy == 
                                                          fleet.converter$fleet[fleet.converter$fleetname == .x]]) |>
  unlist()
# Hard coding this in, used mode of ASHOP selectivity based on mode of all ASHOP fleets (~48) not just CA
selex_new['SizeSel_P_1_10_CA_ASHOP(10)', 'INIT'] <- 48

# P_3
p3.ind <- grep('P_3', rownames(selex_new))
selex_new$PHASE[p3.ind] <- 5
selex_new$LO[p3.ind] <- 0 #This can become negative, but effect is small compared to when 0
selex_new$HI[p3.ind] <- 9
selex_new$INIT[p3.ind] <- purrr::map(selex_fleets, 
                                     ~ selex_modes$asc.slope[selex_modes$FltSvy == 
                                                               fleet.converter$fleet[fleet.converter$fleetname == 
                                                                                       .x]]) |>
  unlist()

# P_4
p4.ind <- grep('P_4', rownames(selex_new))
selex_new$PHASE[p4.ind] <- 5
selex_new$LO[p4.ind] <- 0 #This can become negative, but effect is small compared to when 0
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

### Time varying selectivity table ----
selex_tv_pars <- dplyr::filter(selex_new, Block > 0) |>
  dplyr::select(LO, HI, INIT, PRIOR, PR_SD, PR_type, PHASE, Block) |>
  tidyr::uncount(Block, .id = 'id', .remove = FALSE)

rownames(selex_tv_pars) <- rownames(selex_tv_pars) |>
  stringr::str_remove('\\.\\.\\.[:digit:]+') |>
  stringr::str_c('_BLK', selex_tv_pars$Block, 'repl_', 10*selex_tv_pars$id + 1990)

mod$ctl$size_selex_parms_tv <- selex_tv_pars |>
  dplyr::select(-Block, -id)


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_4_1_ssInputs',new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('SS3 inputs', 'selex set up'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 0_4_3_selexExtend Something wrong when unmirroring and making new blocks so try first extending blocks ---- 
####------------------------------------------------####

new_name <- "0_4_3_selexExtend"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_4_1_ssInputs'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))



##
#Make Changes
##

### Extend previous blocks ----
mod$ctl$Block_Design[[1]][2] <- 2022
mod$ctl$Block_Design[[2]][4] <- 2022


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_4_1_ssInputs',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('SS3 inputs', 'extend blocks'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))



####------------------------------------------------####
### 0_4_4_newBlocks Set up new blocks while still mirroring fleets ---- 
####------------------------------------------------####

#Note that for this I have the block parameters are additive (Blk_Fxn = 1). 
#I correct this in later runs to be replaced parameters (Blk_Fxn = 2) but Im 
#leaving this as is here

new_name <- "0_4_4_newBlocks"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_4_3_selexExtend'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))



##
#Make Changes
##

### Update blocks ----

mod$ctl$N_Block_Designs <- 4
mod$ctl$blocks_per_pattern <- c(2,2,1,1)
names(mod$ctl$blocks_per_pattern) <- paste0("blocks_per_pattern_",1:4)

#Still mirroring so blocks need to be consistent across states
mod$ctl$Block_Design <- list(c(2001, 2010, 2011, 2022), #TWL fleets
                             c(2003, 2016, 2017, 2022), #NTWL (mix between CA and OR/WA)
                             c(2001, 2022), #Rec (simple to start)
                             c(1891, 1891))

selex_new <- mod$ctl$size_selex_parms
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 1
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2

selex_new[grepl('_NTWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block', 'Block_Fxn')] <- 2

selex_new[grepl('_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 3
selex_new[grepl('_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 1

mod$ctl$size_selex_parms <- selex_new

### Time varying selectivity table ----
#Need to set id based on Block_Fxn not Block
selex_tv_pars <- dplyr::filter(selex_new, Block > 0) |>
  dplyr::select(LO, HI, INIT, PRIOR, PR_SD, PR_type, PHASE, Block, Block_Fxn) |>
  tidyr::uncount(Block_Fxn, .id = 'id', .remove = FALSE)

rownames(selex_tv_pars) <- rownames(selex_tv_pars) |>
  stringr::str_remove('\\.\\.\\.[:digit:]+') |>
  stringr::str_c('_BLK', selex_tv_pars$Block_Fxn, 'repl_', mapply("[",mod$ctl$Block_Design[selex_tv_pars$Block], selex_tv_pars$id*2))

mod$ctl$size_selex_parms_tv <- selex_tv_pars |>
  dplyr::select(-Block, -Block_Fxn, -id)


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_4_1_ssInputs',
                                                 '0_4_3_selexExtend',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('SS3 inputs', '+ selex Extend', '+ new blocks'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 0_4_5_Setup Update selectivity setup but keep mirroring and same blocks. Extend block ----
####------------------------------------------------####

new_name <- "0_4_5_Setup"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_4_3_selexExtend'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)



##
#Make Changes
##

### Fix up selectivity parameter table ----

#First for double normal selextivities
selex_fleets <- rownames(mod$ctl$size_selex_types)[mod$ctl$size_selex_types$Pattern == 24] |>
  as.list()

#Get names of all six parms for double normal
selex_names <- purrr::map(selex_fleets,
                          ~ glue::glue('SizeSel_P_{par}_{fleet_name}({fleet_no})',
                                       par = 1:6,
                                       fleet_name = .x,
                                       fleet_no = fleet.converter$fleet[fleet.converter$fleetname == .x])) |>
  unlist()

#Set up new selectivity table
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

# Fix three parameters of double normal initially
selex_new$INIT[grep('P_2', rownames(selex_new))] <- -15
selex_new$INIT[grep('P_5', rownames(selex_new))] <- -999
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
  dplyr::mutate(asc.slope = log(8*(mode - min(mod$dat$lbin_vector))),
                desc.slope = log(8*(max(mod$dat$lbin_vector)-mode)))

# P_1
p1.ind <- grep('P_1', rownames(selex_new))
selex_new$LO[p1.ind] <- 13.001
selex_new$HI[p1.ind] <- 65
selex_new$PHASE[p1.ind] <- 4
selex_new$INIT[p1.ind] <- purrr::map(selex_fleets, 
                                     ~ selex_modes$mode[selex_modes$FltSvy == 
                                                          fleet.converter$fleet[fleet.converter$fleetname == .x]]) |>
  unlist()
# Hard coding this in, used mode of ASHOP selectivity based on mode of all ASHOP fleets (~48) not just CA
selex_new['SizeSel_P_1_10_CA_ASHOP(10)', 'INIT'] <- 48

# P_3
p3.ind <- grep('P_3', rownames(selex_new))
selex_new$PHASE[p3.ind] <- 5
selex_new$LO[p3.ind] <- 0 #This can become negative, but effect is small compared to when 0
selex_new$HI[p3.ind] <- 9
selex_new$INIT[p3.ind] <- purrr::map(selex_fleets, 
                                     ~ selex_modes$asc.slope[selex_modes$FltSvy == 
                                                               fleet.converter$fleet[fleet.converter$fleetname == 
                                                                                       .x]]) |>
  unlist()

# P_4
p4.ind <- grep('P_4', rownames(selex_new))
selex_new$PHASE[p4.ind] <- 5
selex_new$LO[p4.ind] <- 0 #This can become negative, but effect is small compared to when 0
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

### Time varying selectivity table ----
selex_tv_pars <- dplyr::filter(selex_new, Block > 0) |>
  dplyr::select(LO, HI, INIT, PRIOR, PR_SD, PR_type, PHASE, Block) |>
  tidyr::uncount(Block, .id = 'id', .remove = FALSE)

rownames(selex_tv_pars) <- rownames(selex_tv_pars) |>
  stringr::str_remove('\\.\\.\\.[:digit:]+') |>
  stringr::str_c('_BLK', selex_tv_pars$Block, 'repl_', mapply("[",mod$ctl$Block_Design[selex_tv_pars$Block], selex_tv_pars$id * 2 - 1))

mod$ctl$size_selex_parms_tv <- selex_tv_pars |>
  dplyr::select(-Block, -id)


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_4_1_ssInputs',
                                                 '0_4_3_selexExtend',
                                                 '0_4_4_newBlocks',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('SS3 inputs', 
                                     '+ selex Extend', 
                                     'selex Extend + new blocks',
                                     'selex Extend + new Setup'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 0_4_6_unMirror Try new selex setup with same extended blocks but now unmirror the fleets ----
####------------------------------------------------####

new_name <- "0_4_6_unMirror"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_4_3_selexExtend'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)



##
#Make Changes
##

### Unmirror fleets ----
# Un-mirror TWL, NTWL, REC selectivities
mod$ctl$size_selex_types$Pattern[grep('TWL|REC', fleet.converter$fleetname)] <- 24
mod$ctl$size_selex_types$Special[grep('TWL|REC', fleet.converter$fleetname)] <- 0

# Except WA NTWL which is very small fleet, it mirrors TWL (more similar to WA TWL than OR NTWL)
mod$ctl$size_selex_types$Pattern[fleet.converter$fleet_no_num=='WA_NTWL'] <- 15
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='WA_NTWL'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='WA_TWL']

# Foreign fleets mirror respective state TWL fleet
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='OR_FOR'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='OR_TWL']
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='WA_FOR'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='WA_TWL']

# NMFS surveys by state mirror one another as well as the coastwide so keep as is


### Fix up selectivity parameter table ----

#First for double normal selextivities
selex_fleets <- rownames(mod$ctl$size_selex_types)[mod$ctl$size_selex_types$Pattern == 24] |>
  as.list()

#Get names of all six parms for double normal
selex_names <- purrr::map(selex_fleets,
                          ~ glue::glue('SizeSel_P_{par}_{fleet_name}({fleet_no})',
                                       par = 1:6,
                                       fleet_name = .x,
                                       fleet_no = fleet.converter$fleet[fleet.converter$fleetname == .x])) |>
  unlist()

#Set up new selectivity table
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

# Fix three parameters of double normal initially
selex_new$INIT[grep('P_2', rownames(selex_new))] <- -15
selex_new$INIT[grep('P_5', rownames(selex_new))] <- -999
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
  dplyr::mutate(asc.slope = log(8*(mode - min(mod$dat$lbin_vector))),
                desc.slope = log(8*(max(mod$dat$lbin_vector)-mode)))

# P_1
p1.ind <- grep('P_1', rownames(selex_new))
selex_new$LO[p1.ind] <- 13.001
selex_new$HI[p1.ind] <- 65
selex_new$PHASE[p1.ind] <- 4
selex_new$INIT[p1.ind] <- purrr::map(selex_fleets, 
                                     ~ selex_modes$mode[selex_modes$FltSvy == 
                                                          fleet.converter$fleet[fleet.converter$fleetname == .x]]) |>
  unlist()
# Hard coding this in, used mode of ASHOP selectivity based on mode of all ASHOP fleets (~48) not just CA
selex_new['SizeSel_P_1_10_CA_ASHOP(10)', 'INIT'] <- 48

# P_3
p3.ind <- grep('P_3', rownames(selex_new))
selex_new$PHASE[p3.ind] <- 5
selex_new$LO[p3.ind] <- 0 #This can become negative, but effect is small compared to when 0
selex_new$HI[p3.ind] <- 9
selex_new$INIT[p3.ind] <- purrr::map(selex_fleets, 
                                     ~ selex_modes$asc.slope[selex_modes$FltSvy == 
                                                               fleet.converter$fleet[fleet.converter$fleetname == 
                                                                                       .x]]) |>
  unlist()

# P_4
p4.ind <- grep('P_4', rownames(selex_new))
selex_new$PHASE[p4.ind] <- 5
selex_new$LO[p4.ind] <- 0 #This can become negative, but effect is small compared to when 0
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

### Time varying selectivity table ----
selex_tv_pars <- dplyr::filter(selex_new, Block > 0) |>
  dplyr::select(LO, HI, INIT, PRIOR, PR_SD, PR_type, PHASE, Block) |>
  tidyr::uncount(Block, .id = 'id', .remove = FALSE)

rownames(selex_tv_pars) <- rownames(selex_tv_pars) |>
  stringr::str_remove('\\.\\.\\.[:digit:]+') |>
  stringr::str_c('_BLK', selex_tv_pars$Block, 'repl_', mapply("[",mod$ctl$Block_Design[selex_tv_pars$Block], selex_tv_pars$id * 2 - 1))

mod$ctl$size_selex_parms_tv <- selex_tv_pars |>
  dplyr::select(-Block, -id)


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_4_1_ssInputs',
                                                 '0_4_3_selexExtend',
                                                 '0_4_4_newBlocks',
                                                 '0_4_5_Setup',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('SS3 inputs', 
                                     '+ selex Extend', 
                                     '+ selex Extend + new blocks',
                                     '+ selex Extend + new Setup',
                                     '+ selex Extend + new Setup + unmirror'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 0_4_7_selexFullUpdate Full change of selex. New selex setup, unmirroring, complete and full blocking ----
####------------------------------------------------####

new_name <- "0_4_7_selexFullUpdate"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_4_1_ssInputs'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)



##
#Make Changes
##

### Unmirror fleets ----
# Un-mirror TWL, NTWL, REC selectivities
mod$ctl$size_selex_types$Pattern[grep('TWL|REC', fleet.converter$fleetname)] <- 24
mod$ctl$size_selex_types$Special[grep('TWL|REC', fleet.converter$fleetname)] <- 0

# Except WA NTWL which is very small fleet, it mirrors TWL (more similar to WA TWL than OR NTWL)
mod$ctl$size_selex_types$Pattern[fleet.converter$fleet_no_num=='WA_NTWL'] <- 15
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='WA_NTWL'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='WA_TWL']

# Foreign fleets mirror respective state TWL fleet
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='OR_FOR'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='OR_TWL']
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='WA_FOR'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='WA_TWL']

# NMFS surveys by state mirror one another as well as the coastwide so keep as is

### Update blocks ----
mod$ctl$N_Block_Designs <- 6
mod$ctl$blocks_per_pattern <- c(2,2,1,2,2,1)
names(mod$ctl$blocks_per_pattern) <- paste0("blocks_per_pattern_",1:6)

#Now that no longer mirrored can have distinct blocks
#Note: This is probably too many
mod$ctl$Block_Design <- list(c(2001, 2010, 2011, 2022), #TWL fleets
                             c(2003, 2020, 2021, 2022), #CA ntwl
                             c(2001, 2022), #CA rec
                             c(2004, 2014, 2015, 2022), #OR and WA NTWL, OR rec
                             c(2006, 2020, 2021, 2022), #WA rec
                             c(1891, 1891))

### Fix up selectivity parameter table ----

#First for double normal selextivities
selex_fleets <- rownames(mod$ctl$size_selex_types)[mod$ctl$size_selex_types$Pattern == 24] |>
  as.list()

#Get names of all six parms for double normal
selex_names <- purrr::map(selex_fleets,
                          ~ glue::glue('SizeSel_P_{par}_{fleet_name}({fleet_no})',
                                       par = 1:6,
                                       fleet_name = .x,
                                       fleet_no = fleet.converter$fleet[fleet.converter$fleetname == .x])) |>
  unlist()

#Set up new selectivity table
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

# Fix three parameters of double normal initially
selex_new$INIT[grep('P_2', rownames(selex_new))] <- -15
selex_new$INIT[grep('P_5', rownames(selex_new))] <- -999
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
  dplyr::mutate(asc.slope = log(8*(mode - min(mod$dat$lbin_vector))),
                desc.slope = log(8*(max(mod$dat$lbin_vector)-mode)))

# P_1
p1.ind <- grep('P_1', rownames(selex_new))
selex_new$LO[p1.ind] <- 13.001
selex_new$HI[p1.ind] <- 65
selex_new$PHASE[p1.ind] <- 4
selex_new$INIT[p1.ind] <- purrr::map(selex_fleets, 
                                     ~ selex_modes$mode[selex_modes$FltSvy == 
                                                          fleet.converter$fleet[fleet.converter$fleetname == .x]]) |>
  unlist()
# Hard coding this in, used mode of ASHOP selectivity based on mode of all ASHOP fleets (~48) not just CA
selex_new['SizeSel_P_1_10_CA_ASHOP(10)', 'INIT'] <- 48

# P_3
p3.ind <- grep('P_3', rownames(selex_new))
selex_new$PHASE[p3.ind] <- 5
selex_new$LO[p3.ind] <- 0 #This can become negative, but effect is small compared to when 0
selex_new$HI[p3.ind] <- 9
selex_new$INIT[p3.ind] <- purrr::map(selex_fleets, 
                                     ~ selex_modes$asc.slope[selex_modes$FltSvy == 
                                                               fleet.converter$fleet[fleet.converter$fleetname == 
                                                                                       .x]]) |>
  unlist()

# P_4
p4.ind <- grep('P_4', rownames(selex_new))
selex_new$PHASE[p4.ind] <- 5
selex_new$LO[p4.ind] <- 0 #This can become negative, but effect is small compared to when 0
selex_new$HI[p4.ind] <- 9
selex_new$INIT[p4.ind] <- purrr::map(selex_fleets, 
                                     ~ selex_modes$desc.slope[selex_modes$FltSvy == 
                                                                fleet.converter$fleet[fleet.converter$fleetname == 
                                                                                        .x]]) |>
  unlist()

# Use new block set up
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 1
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2

selex_new[grepl('CA_NTWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block', 'Block_Fxn')] <- 2
selex_new[grepl('OR_NTWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 4
selex_new[grepl('OR_NTWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2
#WA NTWL is set to mirror WA TWL. It mirrors better with OR NTWL so could change that

selex_new[grepl('CA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 3
selex_new[grepl('CA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2
selex_new[grepl('OR_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 4
selex_new[grepl('OR_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2
selex_new[grepl('WA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 5
selex_new[grepl('WA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2

mod$ctl$size_selex_parms <- selex_new

### Time varying selectivity table ----
selex_tv_pars <- dplyr::filter(selex_new, Block > 0) |>
  dplyr::select(LO, HI, INIT, PRIOR, PR_SD, PR_type, PHASE, Block) |>
  tidyr::uncount(mod$ctl$blocks_per_pattern[Block], .id = 'id', .remove = FALSE)

rownames(selex_tv_pars) <- rownames(selex_tv_pars) |>
  stringr::str_remove('\\.\\.\\.[:digit:]+') |>
  stringr::str_c('_BLK', selex_tv_pars$Block, 'repl_', mapply("[",mod$ctl$Block_Design[selex_tv_pars$Block], selex_tv_pars$id * 2 - 1))

mod$ctl$size_selex_parms_tv <- selex_tv_pars |>
  dplyr::select(-Block, -id)


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_4_1_ssInputs',
                                                 '0_4_3_selexExtend',
                                                 '0_4_4_newBlocks',
                                                 '0_4_5_Setup',
                                                 '0_4_6_unMirror',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('SS3 inputs', 
                                     '+ selex Extend', 
                                     '+ selex Extend + new blocks',
                                     '+ selex Extend + new Setup',
                                     '+ selex Extend + unmirror',
                                     '+ new Setup + full new blocks + unmirror'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 0_4_8_selexPartUpdate New selex setup and add new blocks, but keep mirroring ----
####------------------------------------------------####

new_name <- "0_4_8_selexPartUpdate"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_4_3_selexExtend'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)



##
#Make Changes
##

### Update blocks ----

mod$ctl$N_Block_Designs <- 4
mod$ctl$blocks_per_pattern <- c(2,2,1,1)
names(mod$ctl$blocks_per_pattern) <- paste0("blocks_per_pattern_",1:4)

#Still mirroring so blocks need to be consistent across states
mod$ctl$Block_Design <- list(c(2001, 2010, 2011, 2022), #TWL fleets
                             c(2003, 2016, 2017, 2022), #NTWL (mix between CA and OR/WA)
                             c(2001, 2022), #Rec (simple to start)
                             c(1891, 1891))


### Fix up selectivity parameter table ----

#First for double normal selextivities
selex_fleets <- rownames(mod$ctl$size_selex_types)[mod$ctl$size_selex_types$Pattern == 24] |>
  as.list()

#Get names of all six parms for double normal
selex_names <- purrr::map(selex_fleets,
                          ~ glue::glue('SizeSel_P_{par}_{fleet_name}({fleet_no})',
                                       par = 1:6,
                                       fleet_name = .x,
                                       fleet_no = fleet.converter$fleet[fleet.converter$fleetname == .x])) |>
  unlist()

#Set up new selectivity table
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

# Fix three parameters of double normal initially
selex_new$INIT[grep('P_2', rownames(selex_new))] <- -15
selex_new$INIT[grep('P_5', rownames(selex_new))] <- -999
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
  dplyr::mutate(asc.slope = log(8*(mode - min(mod$dat$lbin_vector))),
                desc.slope = log(8*(max(mod$dat$lbin_vector)-mode)))

# P_1
p1.ind <- grep('P_1', rownames(selex_new))
selex_new$LO[p1.ind] <- 13.001
selex_new$HI[p1.ind] <- 65
selex_new$PHASE[p1.ind] <- 4
selex_new$INIT[p1.ind] <- purrr::map(selex_fleets, 
                                     ~ selex_modes$mode[selex_modes$FltSvy == 
                                                          fleet.converter$fleet[fleet.converter$fleetname == .x]]) |>
  unlist()
# Hard coding this in, used mode of ASHOP selectivity based on mode of all ASHOP fleets (~48) not just CA
selex_new['SizeSel_P_1_10_CA_ASHOP(10)', 'INIT'] <- 48

# P_3
p3.ind <- grep('P_3', rownames(selex_new))
selex_new$PHASE[p3.ind] <- 5
selex_new$LO[p3.ind] <- 0 #This can become negative, but effect is small compared to when 0
selex_new$HI[p3.ind] <- 9
selex_new$INIT[p3.ind] <- purrr::map(selex_fleets, 
                                     ~ selex_modes$asc.slope[selex_modes$FltSvy == 
                                                               fleet.converter$fleet[fleet.converter$fleetname == 
                                                                                       .x]]) |>
  unlist()

# P_4
p4.ind <- grep('P_4', rownames(selex_new))
selex_new$PHASE[p4.ind] <- 5
selex_new$LO[p4.ind] <- 0 #This can become negative, but effect is small compared to when 0
selex_new$HI[p4.ind] <- 9
selex_new$INIT[p4.ind] <- purrr::map(selex_fleets, 
                                     ~ selex_modes$desc.slope[selex_modes$FltSvy == 
                                                                fleet.converter$fleet[fleet.converter$fleetname == 
                                                                                        .x]]) |>
  unlist()

# Use new block set up
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 1
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2

selex_new[grepl('_NTWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block', 'Block_Fxn')] <- 2

selex_new[grepl('_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 3
selex_new[grepl('_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2

mod$ctl$size_selex_parms <- selex_new


### Time varying selectivity table ----
selex_tv_pars <- dplyr::filter(selex_new, Block > 0) |>
  dplyr::select(LO, HI, INIT, PRIOR, PR_SD, PR_type, PHASE, Block) |>
  tidyr::uncount(mod$ctl$blocks_per_pattern[Block], .id = 'id', .remove = FALSE)

rownames(selex_tv_pars) <- rownames(selex_tv_pars) |>
  stringr::str_remove('\\.\\.\\.[:digit:]+') |>
  stringr::str_c('_BLK', selex_tv_pars$Block, 'repl_', mapply("[",mod$ctl$Block_Design[selex_tv_pars$Block], selex_tv_pars$id * 2 - 1))

mod$ctl$size_selex_parms_tv <- selex_tv_pars |>
  dplyr::select(-Block, -id)


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_4_1_ssInputs',
                                                 '0_4_3_selexExtend',
                                                 '0_4_4_newBlocks',
                                                 '0_4_5_Setup',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('SS3 inputs', 
                                     '+ selex Extend', 
                                     '+ selex Extend + new blocks',
                                     '+ selex Extend + new Setup',
                                     '+ selex Extend + new blocks + new Setup'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 0_4_9_unMirror2015 To see if unmirroring really is intractable, check what doing that does to 2015 model ----
####------------------------------------------------####

#2015 model can handle unmirroring. Not sure why current 2023 version cant. Try whether its because
#of new selex setup

new_name <- "0_4_9_unMirror2015"

##
#Copy inputs
##

#this model is the same as converted but has detailed_age_structure in the starter set to 1
copy_SS_inputs(dir.old = here('models/converted_detailed'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)



##
#Make Changes
##

### Unmirror fleets ----
# Un-mirror TWL, NTWL, REC selectivities
mod$ctl$size_selex_types$Pattern[grep('TWL|REC', fleet.converter$fleetname)] <- 24
mod$ctl$size_selex_types$Special[grep('TWL|REC', fleet.converter$fleetname)] <- 0

# Except WA NTWL which is very small fleet, it mirrors TWL (more similar to WA TWL than OR NTWL)
mod$ctl$size_selex_types$Pattern[fleet.converter$fleet_no_num=='WA_NTWL'] <- 15
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='WA_NTWL'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='WA_TWL']

# Foreign fleets mirror respective state TWL fleet
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='OR_FOR'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='OR_TWL']
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='WA_FOR'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='WA_TWL']

# NMFS surveys by state mirror one another as well as the coastwide so keep as is

### Update selectivity parameter table matching Jim's parameters setup ----

#First for double normal selextivities
selex_fleets <- rownames(mod$ctl$size_selex_types)[mod$ctl$size_selex_types$Pattern == 24] |>
  as.list()

#Get names of all six parms for double normal
selex_names <- purrr::map(selex_fleets,
                          ~ glue::glue('SizeSel_P_{par}_{fleet_name}({fleet_no})',
                                       par = 1:6,
                                       fleet_name = .x,
                                       fleet_no = fleet.converter$fleet[fleet.converter$fleetname == .x])) |>
  unlist()

#Extend CA TWL and CA REC lines to all three states.
#Extend CA NTWL to two other states, because mirroring WA NTWL to WA TWL
#Thus initial values among states are the same as when they are mirrored
selex_new <- mod$ctl$size_selex_parms

selex_new <- rbind(selex_new[grep('_TWL', rownames(selex_new)),], 
                   selex_new[grep('_TWL', rownames(selex_new)),],
                   selex_new) #extend TWL to three states
selex_new <- rbind(selex_new[1:(min(grep('_NTWL', rownames(selex_new)))-1),], 
                   selex_new[grep('_NTWL', rownames(selex_new)),], #extend NTWL to two states
                   selex_new[min(grep('_NTWL', rownames(selex_new))):nrow(selex_new),]) #extend trawls
selex_new <- rbind(selex_new[1:(min(grep('_REC', rownames(selex_new)))-1),], 
                   selex_new[grep('_REC', rownames(selex_new)),],
                   selex_new[grep('_REC', rownames(selex_new)),],
                   selex_new[min(grep('_REC', rownames(selex_new))):nrow(selex_new),]) #extend REC to three states
rownames(selex_new) <- selex_names


mod$ctl$size_selex_parms <- selex_new

### Update time varying selectivity table ----
selex_tv_pars <- dplyr::filter(selex_new, Block > 0) |>
  dplyr::select(LO, HI, INIT, PRIOR, PR_SD, PR_type, PHASE, Block) |>
  tidyr::uncount(mod$ctl$blocks_per_pattern[Block], .id = 'id', .remove = FALSE)

rownames(selex_tv_pars) <- rownames(selex_tv_pars) |>
  stringr::str_remove('\\.\\.\\.[:digit:]+') |>
  stringr::str_c('_BLK', selex_tv_pars$Block, 'repl_', mapply("[",mod$ctl$Block_Design[selex_tv_pars$Block], selex_tv_pars$id * 2 - 1))

mod$ctl$size_selex_parms_tv <- selex_tv_pars |>
  dplyr::select(-Block, -id)


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_4_1_ssInputs',
                                                 '0_4_6_unMirror',
                                                 'converted',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('SS3 inputs', 
                                     'extend Blocks + new Setup + unmirror',
                                     '2015 converted',
                                     '+ unmirror'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 0_4_10_unMirrorOldSetup Check if the new setup (3parm selex) is contributing to poor stability when unmirroring ----
####------------------------------------------------####

#Does new selex setup contribute to unstable results seen in 0_4_6? Yes it does!!

new_name <- "0_4_10_unMirrorOldSetup"

##
#Copy inputs
##

#this model is the same as converted but has detailed_age_structure in the starter set to 1
copy_SS_inputs(dir.old = here('models/0_4_3_selexExtend'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)



##
#Make Changes
##

### Extend previous blocks ----
mod$ctl$Block_Design[[1]][2] <- 2022
mod$ctl$Block_Design[[2]][4] <- 2022

### Unmirror fleets ----
# Un-mirror TWL, NTWL, REC selectivities
mod$ctl$size_selex_types$Pattern[grep('TWL|REC', fleet.converter$fleetname)] <- 24
mod$ctl$size_selex_types$Special[grep('TWL|REC', fleet.converter$fleetname)] <- 0

# Except WA NTWL which is very small fleet, it mirrors TWL (more similar to WA TWL than OR NTWL)
mod$ctl$size_selex_types$Pattern[fleet.converter$fleet_no_num=='WA_NTWL'] <- 15
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='WA_NTWL'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='WA_TWL']

# Foreign fleets mirror respective state TWL fleet
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='OR_FOR'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='OR_TWL']
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='WA_FOR'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='WA_TWL']

# NMFS surveys by state mirror one another as well as the coastwide so keep as is

### Update selectivity parameter table matching Jim's parameters setup ----

#First for double normal selextivities
selex_fleets <- rownames(mod$ctl$size_selex_types)[mod$ctl$size_selex_types$Pattern == 24] |>
  as.list()

#Get names of all six parms for double normal
selex_names <- purrr::map(selex_fleets,
                          ~ glue::glue('SizeSel_P_{par}_{fleet_name}({fleet_no})',
                                       par = 1:6,
                                       fleet_name = .x,
                                       fleet_no = fleet.converter$fleet[fleet.converter$fleetname == .x])) |>
  unlist()

#Extend CA TWL and CA REC lines to all three states.
#Extend CA NTWL to two other states, because mirroring WA NTWL to WA TWL
#Thus initial values among states are the same as when they are mirrored
selex_new <- mod$ctl$size_selex_parms

selex_new <- rbind(selex_new[grep('_TWL', rownames(selex_new)),], 
                   selex_new[grep('_TWL', rownames(selex_new)),],
                   selex_new) #extend TWL to three states
selex_new <- rbind(selex_new[1:(min(grep('_NTWL', rownames(selex_new)))-1),], 
                   selex_new[grep('_NTWL', rownames(selex_new)),], #extend NTWL to two states
                   selex_new[min(grep('_NTWL', rownames(selex_new))):nrow(selex_new),]) #extend trawls
selex_new <- rbind(selex_new[1:(min(grep('_REC', rownames(selex_new)))-1),], 
                   selex_new[grep('_REC', rownames(selex_new)),],
                   selex_new[grep('_REC', rownames(selex_new)),],
                   selex_new[min(grep('_REC', rownames(selex_new))):nrow(selex_new),]) #extend REC to three states
rownames(selex_new) <- selex_names


mod$ctl$size_selex_parms <- selex_new

### Update time varying selectivity table ----
selex_tv_pars <- dplyr::filter(selex_new, Block > 0) |>
  dplyr::select(LO, HI, INIT, PRIOR, PR_SD, PR_type, PHASE, Block) |>
  tidyr::uncount(mod$ctl$blocks_per_pattern[Block], .id = 'id', .remove = FALSE)

rownames(selex_tv_pars) <- rownames(selex_tv_pars) |>
  stringr::str_remove('\\.\\.\\.[:digit:]+') |>
  stringr::str_c('_BLK', selex_tv_pars$Block, 'repl_', mapply("[",mod$ctl$Block_Design[selex_tv_pars$Block], selex_tv_pars$id * 2 - 1))

mod$ctl$size_selex_parms_tv <- selex_tv_pars |>
  dplyr::select(-Block, -id)


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_4_1_ssInputs',
                                                 '0_4_3_selexExtend',
                                                 '0_4_5_Setup',
                                                 '0_4_6_unMirror',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('SS3 inputs', 
                                     '+ extend Blocks',
                                     '+ extend Blocks + newSetup',
                                     '+ extend Blocks + newSetup + unmirror',
                                     '+ extend Blocks + oldSetup + unmirror'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 0_4_11_unMirrorPreSSinput Check if the new SS inputs contribute to poor stability when unmirroring ----
####------------------------------------------------####

#Does new SSinput setup contribute to unstable results seen in 0_4_6? Not the case, but it does affect scale

new_name <- "0_4_11_unmirrorPreSSinput"

##
#Copy inputs
##

#this model is the same as converted but has detailed_age_structure in the starter set to 1
copy_SS_inputs(dir.old = here('models/0_3_3_bestSpatialHessian'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)



##
#Make Changes
##

### Extend previous blocks ----
mod$ctl$Block_Design[[1]][2] <- 2022
mod$ctl$Block_Design[[2]][4] <- 2022

### Unmirror fleets ----
# Un-mirror TWL, NTWL, REC selectivities
mod$ctl$size_selex_types$Pattern[grep('TWL|REC', fleet.converter$fleetname)] <- 24
mod$ctl$size_selex_types$Special[grep('TWL|REC', fleet.converter$fleetname)] <- 0

# Except WA NTWL which is very small fleet, it mirrors TWL (more similar to WA TWL than OR NTWL)
mod$ctl$size_selex_types$Pattern[fleet.converter$fleet_no_num=='WA_NTWL'] <- 15
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='WA_NTWL'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='WA_TWL']

# Foreign fleets mirror respective state TWL fleet
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='OR_FOR'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='OR_TWL']
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='WA_FOR'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='WA_TWL']

# NMFS surveys by state mirror one another as well as the coastwide so keep as is

### Update selectivity parameter table matching Jim's parameters setup ----

#First for double normal selextivities
selex_fleets <- rownames(mod$ctl$size_selex_types)[mod$ctl$size_selex_types$Pattern == 24] |>
  as.list()

#Get names of all six parms for double normal
selex_names <- purrr::map(selex_fleets,
                          ~ glue::glue('SizeSel_P_{par}_{fleet_name}({fleet_no})',
                                       par = 1:6,
                                       fleet_name = .x,
                                       fleet_no = fleet.converter$fleet[fleet.converter$fleetname == .x])) |>
  unlist()

#Extend CA TWL and CA REC lines to all three states.
#Extend CA NTWL to two other states, because mirroring WA NTWL to WA TWL
#Thus initial values among states are the same as when they are mirrored
selex_new <- mod$ctl$size_selex_parms

selex_new <- rbind(selex_new[grep('_TWL', rownames(selex_new)),], 
                   selex_new[grep('_TWL', rownames(selex_new)),],
                   selex_new) #extend TWL to three states
selex_new <- rbind(selex_new[1:(min(grep('_NTWL', rownames(selex_new)))-1),], 
                   selex_new[grep('_NTWL', rownames(selex_new)),], #extend NTWL to two states
                   selex_new[min(grep('_NTWL', rownames(selex_new))):nrow(selex_new),]) #extend trawls
selex_new <- rbind(selex_new[1:(min(grep('_REC', rownames(selex_new)))-1),], 
                   selex_new[grep('_REC', rownames(selex_new)),],
                   selex_new[grep('_REC', rownames(selex_new)),],
                   selex_new[min(grep('_REC', rownames(selex_new))):nrow(selex_new),]) #extend REC to three states
rownames(selex_new) <- selex_names


mod$ctl$size_selex_parms <- selex_new

### Update time varying selectivity table ----
selex_tv_pars <- dplyr::filter(selex_new, Block > 0) |>
  dplyr::select(LO, HI, INIT, PRIOR, PR_SD, PR_type, PHASE, Block) |>
  tidyr::uncount(mod$ctl$blocks_per_pattern[Block], .id = 'id', .remove = FALSE)

rownames(selex_tv_pars) <- rownames(selex_tv_pars) |>
  stringr::str_remove('\\.\\.\\.[:digit:]+') |>
  stringr::str_c('_BLK', selex_tv_pars$Block, 'repl_', mapply("[",mod$ctl$Block_Design[selex_tv_pars$Block], selex_tv_pars$id * 2 - 1))

mod$ctl$size_selex_parms_tv <- selex_tv_pars |>
  dplyr::select(-Block, -id)


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_3_3_bestSpatialHessian',
                                                 new_name,
                                                 '0_4_1_ssInputs',
                                                 '0_4_10_unmirrorOldSetup')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('pre-SS3 inputs',
                                     '+ extend Blocks + oldSetup + unmirror',
                                     'SS3 inputs',
                                     '+ extend Blocks + oldSetup + unmirror'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 0_4_12_selexFullUpdate_OldSetup This repeats 0_4_7 (new blocks, unmirror, new setup) but with old setup of parameters ----
####------------------------------------------------####

new_name <- "0_4_12_selexFullUpdate_OldSetup"

##
#Copy inputs
##

#this model is the same as converted but has detailed_age_structure in the starter set to 1
copy_SS_inputs(dir.old = here('models/0_4_1_ssInputs'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)


##
#Make Changes
##

### Unmirror fleets ----
# Un-mirror TWL, NTWL, REC selectivities
mod$ctl$size_selex_types$Pattern[grep('TWL|REC', fleet.converter$fleetname)] <- 24
mod$ctl$size_selex_types$Special[grep('TWL|REC', fleet.converter$fleetname)] <- 0

# Except WA NTWL which is very small fleet, it mirrors TWL (more similar to WA TWL than OR NTWL)
mod$ctl$size_selex_types$Pattern[fleet.converter$fleet_no_num=='WA_NTWL'] <- 15
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='WA_NTWL'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='WA_TWL']

# Foreign fleets mirror respective state TWL fleet
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='OR_FOR'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='OR_TWL']
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='WA_FOR'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='WA_TWL']

# NMFS surveys by state mirror one another as well as the coastwide so keep as is

### Update blocks ----
mod$ctl$N_Block_Designs <- 6
mod$ctl$blocks_per_pattern <- c(2,2,1,2,2,1)
names(mod$ctl$blocks_per_pattern) <- paste0("blocks_per_pattern_",1:6)

#Now that no longer mirrored can have distinct blocks
#Note: This is probably too many
mod$ctl$Block_Design <- list(c(2001, 2010, 2011, 2022), #TWL fleets
                             c(2003, 2020, 2021, 2022), #CA ntwl
                             c(2001, 2022), #CA rec
                             c(2004, 2014, 2015, 2022), #OR and WA NTWL, OR rec
                             c(2006, 2020, 2021, 2022), #WA rec
                             c(1891, 1891))

### Update selectivity parameter table matching Jim's parameters setup ----

#First for double normal selextivities
selex_fleets <- rownames(mod$ctl$size_selex_types)[mod$ctl$size_selex_types$Pattern == 24] |>
  as.list()

#Get names of all six parms for double normal
selex_names <- purrr::map(selex_fleets,
                          ~ glue::glue('SizeSel_P_{par}_{fleet_name}({fleet_no})',
                                       par = 1:6,
                                       fleet_name = .x,
                                       fleet_no = fleet.converter$fleet[fleet.converter$fleetname == .x])) |>
  unlist()

#Extend CA TWL and CA REC lines to all three states.
#Extend CA NTWL to two other states, because mirroring WA NTWL to WA TWL
#Thus initial values among states are the same as when they are mirrored
selex_new <- mod$ctl$size_selex_parms

selex_new <- rbind(selex_new[grep('_TWL', rownames(selex_new)),], 
                   selex_new[grep('_TWL', rownames(selex_new)),],
                   selex_new) #extend TWL to three states
selex_new <- rbind(selex_new[1:(min(grep('_NTWL', rownames(selex_new)))-1),], 
                   selex_new[grep('_NTWL', rownames(selex_new)),], #extend NTWL to two states
                   selex_new[min(grep('_NTWL', rownames(selex_new))):nrow(selex_new),]) #extend trawls
selex_new <- rbind(selex_new[1:(min(grep('_REC', rownames(selex_new)))-1),], 
                   selex_new[grep('_REC', rownames(selex_new)),],
                   selex_new[grep('_REC', rownames(selex_new)),],
                   selex_new[min(grep('_REC', rownames(selex_new))):nrow(selex_new),]) #extend REC to three states
rownames(selex_new) <- selex_names

# # calculate initial values for p1, p3, p4 for each fleet
# # based on recommendations in assessment handbook
# selex_modes <- mod$dat$lencomp |>
#   dplyr::arrange(FltSvy) |>
#   dplyr::group_by(FltSvy) |>
#   dplyr::summarise(dplyr::across(f12:m66, ~ sum(Nsamp*.x)/sum(Nsamp))) |> 
#   tidyr::pivot_longer(cols = -FltSvy, names_to = 'len_bin', values_to = 'dens') |>
#   tidyr::separate(col = len_bin, into = c('sex', 'length'), sep = 1) |>
#   dplyr::group_by(FltSvy, sex) |> 
#   dplyr::summarise(mode = length[which.max(dens)]) |>
#   dplyr::summarise(mode = mean(as.numeric(mode))) |>
#   dplyr::mutate(asc.slope = log(8*(mode - min(mod$dat$lbin_vector))),
#                 desc.slope = log(8*(max(mod$dat$lbin_vector)-mode)))



# Use new block set up
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 1
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2

selex_new[grepl('CA_NTWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block', 'Block_Fxn')] <- 2
selex_new[grepl('OR_NTWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 4
selex_new[grepl('OR_NTWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2
#WA NTWL is set to mirror WA TWL. It mirrors better with OR NTWL so could change that

selex_new[grepl('CA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 3
selex_new[grepl('CA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2
selex_new[grepl('OR_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 4
selex_new[grepl('OR_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2
selex_new[grepl('WA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 5
selex_new[grepl('WA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2

mod$ctl$size_selex_parms <- selex_new

### Time varying selectivity table ----
selex_tv_pars <- dplyr::filter(selex_new, Block > 0) |>
  dplyr::select(LO, HI, INIT, PRIOR, PR_SD, PR_type, PHASE, Block) |>
  tidyr::uncount(mod$ctl$blocks_per_pattern[Block], .id = 'id', .remove = FALSE)

rownames(selex_tv_pars) <- rownames(selex_tv_pars) |>
  stringr::str_remove('\\.\\.\\.[:digit:]+') |>
  stringr::str_c('_BLK', selex_tv_pars$Block, 'repl_', mapply("[",mod$ctl$Block_Design[selex_tv_pars$Block], selex_tv_pars$id * 2 - 1))

mod$ctl$size_selex_parms_tv <- selex_tv_pars |>
  dplyr::select(-Block, -id)


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_4_1_ssInputs',
                                                 '0_4_6_unMirror',
                                                 '0_4_7_selexFullUpdate',
                                                 '0_4_8_selexPartUpdate',
                                                 '0_4_10_unMirrorOldSetup',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('SS3 inputs',
                                     '+ extend Blocks + newSetup + unmirror',
                                     '+ full Blocks + newSetup + unmirror',
                                     '+ part Blocks + newSetup',
                                     '+ extend Blocks + oldSetup + unmirror',
                                     '+ full Blocks + oldSetup + unmirror'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 0_4_13_newInit This repeats 0_4_12 but uses new inits for p1, p3, and p4 ----
####------------------------------------------------####

new_name <- "0_4_13_newInit"

##
#Copy inputs
##

#this model is the same as converted but has detailed_age_structure in the starter set to 1
copy_SS_inputs(dir.old = here('models/0_4_1_ssInputs'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)


##
#Make Changes
##

### Unmirror fleets ----
# Un-mirror TWL, NTWL, REC selectivities
mod$ctl$size_selex_types$Pattern[grep('TWL|REC', fleet.converter$fleetname)] <- 24
mod$ctl$size_selex_types$Special[grep('TWL|REC', fleet.converter$fleetname)] <- 0

# Except WA NTWL which is very small fleet, it mirrors TWL (more similar to WA TWL than OR NTWL)
mod$ctl$size_selex_types$Pattern[fleet.converter$fleet_no_num=='WA_NTWL'] <- 15
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='WA_NTWL'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='WA_TWL']

# Foreign fleets mirror respective state TWL fleet
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='OR_FOR'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='OR_TWL']
mod$ctl$size_selex_types$Special[fleet.converter$fleet_no_num=='WA_FOR'] <- fleet.converter$fleet[fleet.converter$fleet_no_num=='WA_TWL']

# NMFS surveys by state mirror one another as well as the coastwide so keep as is

### Update blocks ----
mod$ctl$N_Block_Designs <- 6
mod$ctl$blocks_per_pattern <- c(2,2,1,2,2,1)
names(mod$ctl$blocks_per_pattern) <- paste0("blocks_per_pattern_",1:6)

#Now that no longer mirrored can have distinct blocks
#Note: This is probably too many
mod$ctl$Block_Design <- list(c(2001, 2010, 2011, 2022), #TWL fleets
                             c(2003, 2020, 2021, 2022), #CA ntwl
                             c(2001, 2022), #CA rec
                             c(2004, 2014, 2015, 2022), #OR and WA NTWL, OR rec
                             c(2006, 2020, 2021, 2022), #WA rec
                             c(1891, 1891))

### Update selectivity parameter table matching Jim's parameters setup but with updated inits ----

#First for double normal selextivities
selex_fleets <- rownames(mod$ctl$size_selex_types)[mod$ctl$size_selex_types$Pattern == 24] |>
  as.list()

#Get names of all six parms for double normal
selex_names <- purrr::map(selex_fleets,
                          ~ glue::glue('SizeSel_P_{par}_{fleet_name}({fleet_no})',
                                       par = 1:6,
                                       fleet_name = .x,
                                       fleet_no = fleet.converter$fleet[fleet.converter$fleetname == .x])) |>
  unlist()

#Extend CA TWL and CA REC lines to all three states.
#Extend CA NTWL to two other states, because mirroring WA NTWL to WA TWL
#Thus initial values among states are the same as when they are mirrored
selex_new <- mod$ctl$size_selex_parms

selex_new <- rbind(selex_new[grep('_TWL', rownames(selex_new)),], 
                   selex_new[grep('_TWL', rownames(selex_new)),],
                   selex_new) #extend TWL to three states
selex_new <- rbind(selex_new[1:(min(grep('_NTWL', rownames(selex_new)))-1),], 
                   selex_new[grep('_NTWL', rownames(selex_new)),], #extend NTWL to two states
                   selex_new[min(grep('_NTWL', rownames(selex_new))):nrow(selex_new),]) #extend trawls
selex_new <- rbind(selex_new[1:(min(grep('_REC', rownames(selex_new)))-1),], 
                   selex_new[grep('_REC', rownames(selex_new)),],
                   selex_new[grep('_REC', rownames(selex_new)),],
                   selex_new[min(grep('_REC', rownames(selex_new))):nrow(selex_new),]) #extend REC to three states
rownames(selex_new) <- selex_names

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
  dplyr::mutate(asc.slope = log(8*(mode - min(mod$dat$lbin_vector))),
                desc.slope = log(8*(max(mod$dat$lbin_vector)-mode)))

# P_1
p1.ind <- grep('P_1', rownames(selex_new))
selex_new$LO[p1.ind] <- 13.001
selex_new$HI[p1.ind] <- 65
selex_new$PHASE[p1.ind] <- 4
selex_new$INIT[p1.ind] <- purrr::map(selex_fleets, 
                                     ~ selex_modes$mode[selex_modes$FltSvy == 
                                                          fleet.converter$fleet[fleet.converter$fleetname == .x]]) |>
  unlist()
# Hard coding this in, used mode of ASHOP selectivity based on mode of all ASHOP fleets (~48) not just CA
selex_new['SizeSel_P_1_10_CA_ASHOP(10)', 'INIT'] <- 48

# P_3
p3.ind <- grep('P_3', rownames(selex_new))
selex_new$PHASE[p3.ind] <- 5
selex_new$LO[p3.ind] <- 0 #This can become negative, but effect is small compared to when 0
selex_new$HI[p3.ind] <- 9
selex_new$INIT[p3.ind] <- purrr::map(selex_fleets, 
                                     ~ selex_modes$asc.slope[selex_modes$FltSvy == 
                                                               fleet.converter$fleet[fleet.converter$fleetname == 
                                                                                       .x]]) |>
  unlist()

# P_4
p4.ind <- grep('P_4', rownames(selex_new))
selex_new$PHASE[p4.ind] <- 5
selex_new$LO[p4.ind] <- 0 #This can become negative, but effect is small compared to when 0
selex_new$HI[p4.ind] <- 9
selex_new$INIT[p4.ind] <- purrr::map(selex_fleets, 
                                     ~ selex_modes$desc.slope[selex_modes$FltSvy == 
                                                                fleet.converter$fleet[fleet.converter$fleetname == 
                                                                                        .x]]) |>
  unlist()


# Use new block set up
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 1
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2

selex_new[grepl('CA_NTWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block', 'Block_Fxn')] <- 2
selex_new[grepl('OR_NTWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 4
selex_new[grepl('OR_NTWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2
#WA NTWL is set to mirror WA TWL. It mirrors better with OR NTWL so could change that

selex_new[grepl('CA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 3
selex_new[grepl('CA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2
selex_new[grepl('OR_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 4
selex_new[grepl('OR_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2
selex_new[grepl('WA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 5
selex_new[grepl('WA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2

mod$ctl$size_selex_parms <- selex_new


### Time varying selectivity table ----
selex_tv_pars <- dplyr::filter(selex_new, Block > 0) |>
  dplyr::select(LO, HI, INIT, PRIOR, PR_SD, PR_type, PHASE, Block) |>
  tidyr::uncount(mod$ctl$blocks_per_pattern[Block], .id = 'id', .remove = FALSE)

rownames(selex_tv_pars) <- rownames(selex_tv_pars) |>
  stringr::str_remove('\\.\\.\\.[:digit:]+') |>
  stringr::str_c('_BLK', selex_tv_pars$Block, 'repl_', mapply("[",mod$ctl$Block_Design[selex_tv_pars$Block], selex_tv_pars$id * 2 - 1))

mod$ctl$size_selex_parms_tv <- selex_tv_pars |>
  dplyr::select(-Block, -id)


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26)[-c(13:14,16:17)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_4_12_selexFullUpdate_OldSetup',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('full Blocks + oldSetup + unmirror',
                                     'full Blocks + oldSetup + unmirror + newInits'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 0_5_2_coastwide_selex_and_comps  ----
####------------------------------------------------####

new_name <- "0_5_2_coastwide_selex_comps_lambdas"

##
#Copy inputs
##

#this model is the same as converted but has detailed_age_structure in the starter set to 1
copy_SS_inputs(dir.old = here('models/0_5_1_coastwide_better_blocks'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)

# Change P5 from -999 to -15 so selectivity at small sizes is zero
mod$ctl$size_selex_parms$INIT[grepl('P_5', rownames(mod$ctl$size_selex_parms))] <- -15

# Get rid of CA ASHOP age and length comps. 
# They are all in 2000s and have been added to OR
# Ages:
ca.ashop.comps.ind <- which(mod$dat$agecomp$FltSvy == 
                              fleet.converter$fleet[fleet.converter$fleet_no_num == 
                                                      'CA_ASHOP']
)
mod$dat$agecomp$Yr[ca.ashop.comps.ind] <- -1 * mod$dat$agecomp$Yr[ca.ashop.comps.ind]

# Lengths:
ca.ashop.comps.ind <- which(mod$dat$lencomp$FltSvy == 
                              fleet.converter$fleet[fleet.converter$fleet_no_num == 
                                                      'CA_ASHOP']
)
mod$dat$lencomp$Yr[ca.ashop.comps.ind] <- -1 * mod$dat$lencomp$Yr[ca.ashop.comps.ind]

# Get rid of variance factor for CA fleets with no comp data.
ca.rec.ind <- which(mod$ctl$Variance_adjustment_list$Fleet == 
                      fleet.converter$fleet[fleet.converter$fleet_no_num == 'CA_REC'] & 
                      mod$ctl$Variance_adjustment_list$Data_type == 5) 
# likelihood component 5 = age comps
ca.ashop.ind <- which(mod$ctl$Variance_adjustment_list$Fleet == 
                      fleet.converter$fleet[fleet.converter$fleet_no_num == 'CA_ASHOP'] 
) 
mod$ctl$Variance_adjustment_list <- mod$ctl$Variance_adjustment_list[-c(ca.rec.ind,
                                                                        ca.ashop.ind),]

# Zero out lambdas that are effectively doing data weighting
mod$ctl$lambdas <- NULL
mod$ctl$N_lambdas <- 0

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)
beepr::beep()

####------------------------------------------------####
### 0_5_3 tune comps using Francis weights  ----
####------------------------------------------------####


new_name <- "0_5_3_tuned"

##
#Copy inputs
##

R.utils::copyDirectory(from = here('models/0_5_2_coastwide_selex_comps_lambdas'),
                       to = here('models', new_name), 
                       overwrite = TRUE)

mod.out <- SS_output(here('models', new_name))
xx <- r4ss::tune_comps(replist = mod.out, 
                       option = 'Francis', 
                       dir = here('models', new_name), 
                       exe = here('models/ss_win.exe'), 
                       niters_tuning = 3, 
                       extras = '-nohess')
beepr::beep()

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          # extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)
beepr::beep()


pp <- SS_output(here('models',new_name))
SS_plots(pp)
beepr::beep()

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_3_1_coastwide',
                                                 '0_5_1_coastwide_better_blocks',
                                                 '0_5_2_coastwide_selex_comps_lambdas',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Original coastwide',
                                     'Coastwide, blocks extended',
                                     'Coastwide, various fixes',
                                     'Coastwide, tuned comps'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 0_5_4 updated untuned model with full new blocks  ----
####------------------------------------------------####


new_name <- "0_5_4_fullBlocks"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_5_2_coastwide_selex_comps_lambdas'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make Changes
##

## Update blocks
mod$ctl$N_Block_Designs <- 6
mod$ctl$blocks_per_pattern <- c(2,2,1,2,2,1)
names(mod$ctl$blocks_per_pattern) <- paste0("blocks_per_pattern_",1:6)

mod$ctl$Block_Design <- list(c(2001, 2010, 2011, 2022), #TWL fleets
                             c(2003, 2020, 2021, 2022), #CA ntwl
                             c(2001, 2022), #CA rec
                             c(2004, 2014, 2015, 2022), #OR and WA NTWL, OR rec
                             c(2006, 2020, 2021, 2022), #WA rec
                             c(1891, 1891))

selex_new <- mod$ctl$size_selex_parms

# Use new block set up
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 1
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2

selex_new[grepl('CA_NTWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block', 'Block_Fxn')] <- 2
selex_new[grepl('OR_NTWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 4
selex_new[grepl('OR_NTWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2
#WA NTWL is set to mirror WA TWL. It mirrors better with OR NTWL so could change that

selex_new[grepl('CA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 3
selex_new[grepl('CA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2
selex_new[grepl('OR_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 4
selex_new[grepl('OR_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2
selex_new[grepl('WA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 5
selex_new[grepl('WA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2

mod$ctl$size_selex_parms <- selex_new


### Time varying selectivity table ----
selex_tv_pars <- dplyr::filter(selex_new, Block > 0) |>
  dplyr::select(LO, HI, INIT, PRIOR, PR_SD, PR_type, PHASE, Block) |>
  tidyr::uncount(mod$ctl$blocks_per_pattern[Block], .id = 'id', .remove = FALSE)

rownames(selex_tv_pars) <- rownames(selex_tv_pars) |>
  stringr::str_remove('\\.\\.\\.[:digit:]+') |>
  stringr::str_c('_BLK', selex_tv_pars$Block, 'repl_', mapply("[",mod$ctl$Block_Design[selex_tv_pars$Block], selex_tv_pars$id * 2 - 1))

mod$ctl$size_selex_parms_tv <- selex_tv_pars |>
  dplyr::select(-Block, -id)

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)


pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26))

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('coastwide',
                                                 '0_3_1_coastwide',
                                                 '0_5_1_coastwide_better_blocks',
                                                 '0_5_2_coastwide_selex_comps_lambdas',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Original coastwide',
                                     'Coastwide with new data and bio (for M just val)',
                                     'Coastwide, blocks extended',
                                     'Coastwide, various fixes',
                                     'Coastwide, various fixes and full blocks'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))

####------------------------------------------------####
### 0_5_5 full new blocked with Francis weighting  ----
####------------------------------------------------####

new_name <- "0_5_5_fullBlocks_tuned"

##
#Copy inputs
##

R.utils::copyDirectory(from = here('models/0_5_4_fullBlocks'),
                       to = here('models', new_name), 
                       overwrite = TRUE)

mod.out <- SS_output(here('models', new_name))
xx <- r4ss::tune_comps(replist = mod.out, 
                       option = 'Francis', 
                       dir = here('models', new_name), 
                       exe = here('models/ss_win.exe'), 
                       niters_tuning = 3, 
                       extras = '-nohess')
beepr::beep()

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          # extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)
beepr::beep()


pp <- SS_output(here('models',new_name))
SS_plots(pp)
beepr::beep()

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_3_1_coastwide',
                                                 '0_5_1_coastwide_better_blocks',
                                                 '0_5_2_coastwide_selex_comps_lambdas',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Original coastwide',
                                     'Coastwide, blocks extended',
                                     'Coastwide, various fixes',
                                     'Coastwide, tuned comps'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))



####------------------------------------------------####
### 0_5_6_survLogistic Try fixing survey selectivity at logistic  ----
####------------------------------------------------####

new_name <- "0_5_6_survLogistic"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_5_3_tuned'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make Changes
##

#Set parameter 4 to a large number (15) and dont estimate
mod$ctl$size_selex_parms[intersect(
  grep("_coastwide",rownames(mod$ctl$size_selex_parms)),
  grep("P_4",rownames(mod$ctl$size_selex_parms))),c("HI")] <- 20
mod$ctl$size_selex_parms[intersect(
  grep("_coastwide",rownames(mod$ctl$size_selex_parms)),
  grep("P_4",rownames(mod$ctl$size_selex_parms))),c("INIT")] <- 15
mod$ctl$size_selex_parms[intersect(
  grep("_coastwide",rownames(mod$ctl$size_selex_parms)),
  grep("P_4",rownames(mod$ctl$size_selex_parms))),c("PHASE")] <- -99


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)


pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:19)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('coastwide',
                                                 '0_3_1_coastwide',
                                                 '0_5_1_coastwide_better_blocks',
                                                 '0_5_2_coastwide_selex_comps_lambdas',
                                                 '0_5_3_tuned_toGetReport',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Original coastwide',
                                     'Coastwide with new data and bio (for M just val)',
                                     'Coastwide, blocks extended',
                                     'Coastwide, various fixes',
                                     'tuned',
                                     'survey logistic selex'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))



####------------------------------------------------####
### 0_5_7 simplified new blocks  ----
####------------------------------------------------####

new_name <- "0_5_7_mediumBlocks"

copy_SS_inputs(dir.old = here('models/0_5_3_tuned'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make Changes
##

## Update blocks
mod$ctl$N_Block_Designs <- 4
mod$ctl$blocks_per_pattern <- c(2,2,1,1)
names(mod$ctl$blocks_per_pattern) <- paste0("blocks_per_pattern_",1:4)

mod$ctl$Block_Design <- list(c(2001, 2010, 2011, 2022), #TWL fleets
                             c(2003, 2016, 2017, 2022), #NTWL (mix between CA and OR/WA)
                             c(2001, 2022), #Rec (simple to start)
                             c(1891, 1891))

selex_new <- mod$ctl$size_selex_parms
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 1
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2

selex_new[grepl('_NTWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block', 'Block_Fxn')] <- 2

selex_new[grepl('_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 3
selex_new[grepl('_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 1 ##NOTE THAT THIS SHOULD BE 2 (replace not additive). Corrected in 0_5_8

mod$ctl$size_selex_parms <- selex_new

### Time varying selectivity table ----
#Need to set id based on Block_Fxn not Block
selex_tv_pars <- dplyr::filter(selex_new, Block > 0) |>
  dplyr::select(LO, HI, INIT, PRIOR, PR_SD, PR_type, PHASE, Block, Block_Fxn) |>
  tidyr::uncount(Block_Fxn, .id = 'id', .remove = FALSE)

rownames(selex_tv_pars) <- rownames(selex_tv_pars) |>
  stringr::str_remove('\\.\\.\\.[:digit:]+') |>
  stringr::str_c('_BLK', selex_tv_pars$Block_Fxn, 'repl_', mapply("[",mod$ctl$Block_Design[selex_tv_pars$Block], selex_tv_pars$id*2))

mod$ctl$size_selex_parms_tv <- selex_tv_pars |>
  dplyr::select(-Block, -Block_Fxn, -id)

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

# this model is garbage. Try tuning???

xx <- r4ss::tune_comps(replist = mod.out, 
                       option = 'Francis', 
                       dir = here('models', new_name), 
                       exe = here('models/ss_win.exe'), 
                       niters_tuning = 3, 
                       extras = '-nohess')
# Actually worked. Get plots

pp <- SS_output(here('models',new_name))
SS_plots(pp)


####------------------------------------------------####
### 0_5_7_1 simplified new blocks corrected so that recreational selex is replace not additive ----
####------------------------------------------------####

new_name <- "0_5_7_1_mediumBlocks_corrected"

copy_SS_inputs(dir.old = here('models/0_5_3_tuned'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make Changes
##

## Update blocks
mod$ctl$N_Block_Designs <- 4
mod$ctl$blocks_per_pattern <- c(2,2,1,1)
names(mod$ctl$blocks_per_pattern) <- paste0("blocks_per_pattern_",1:4)

mod$ctl$Block_Design <- list(c(2001, 2010, 2011, 2022), #TWL fleets
                             c(2003, 2016, 2017, 2022), #NTWL (mix between CA and OR/WA)
                             c(2001, 2022), #Rec (simple to start)
                             c(1891, 1891))

selex_new <- mod$ctl$size_selex_parms
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 1
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2

selex_new[grepl('_NTWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block', 'Block_Fxn')] <- 2

selex_new[grepl('_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 3
selex_new[grepl('_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2

mod$ctl$size_selex_parms <- selex_new

### Time varying selectivity table ----
selex_tv_pars <- dplyr::filter(selex_new, Block > 0) |>
  dplyr::select(LO, HI, INIT, PRIOR, PR_SD, PR_type, PHASE, Block) |>
  tidyr::uncount(mod$ctl$blocks_per_pattern[Block], .id = 'id', .remove = FALSE)

rownames(selex_tv_pars) <- rownames(selex_tv_pars) |>
  stringr::str_remove('\\.\\.\\.[:digit:]+') |>
  stringr::str_c('_BLK', selex_tv_pars$Block, 'repl_', mapply("[",mod$ctl$Block_Design[selex_tv_pars$Block], selex_tv_pars$id * 2 - 1))

mod$ctl$size_selex_parms_tv <- selex_tv_pars |>
  dplyr::select(-Block, -id)

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

#Try tunning
mod.out <- SS_output(here('models',new_name))

xx <- r4ss::tune_comps(replist = mod.out, 
                       option = 'Francis', 
                       dir = here('models', new_name), 
                       exe = here('models/ss_win.exe'), 
                       niters_tuning = 3, 
                       extras = '-nohess')

pp <- SS_output(here('models',new_name))
SS_plots(pp)

plot_sel_comm(pp)
plot_sel_noncomm(pp, spatial = FALSE)

#This model has a terrible gradient
#How is the selectivity function for CA NTWL possible? 
#Upweighted CA_TWL ages, and WA NTWL ages and lengths


####------------------------------------------------####
### 0_5_8 use breakpoint for female M  ----
####------------------------------------------------####

new_name <- "0_5_8_breakpoint_M"

copy_SS_inputs(dir.old = here('models/0_5_6_survLogistic'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

mod$ctl$natM_type <- 1
mod$ctl$N_natM <- 2
mod$ctl$M_ageBreakPoints <- c(20,21) # or something
# I *think* it does still need two breakpoints. Otherwise it will only estimate one M per sex

male.ind <- which(rownames(mod$ctl$MG_parms) == 'NatM_p_1_Mal_GP_1')
mod$ctl$MG_parms <- mod$ctl$MG_parms[c(1,1,2:male.ind, male.ind:nrow(mod$ctl$MG_parms)),] 
rownames(mod$ctl$MG_parms) <- stringr::str_replace(rownames(mod$ctl$MG_parms), 
                                                   pattern = '1.1', 
                                                   replacement = '2')
mod$ctl$MG_parms[1,] <- mod$ctl$MG_parms['NatM_p_1_Mal_GP_1',]
mod$ctl$MG_parms[2, 1:7] <- c(0, 0.9, 0.1, 99, 99, 0, 3)

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:19)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_5_1_coastwide_better_blocks',
                                                 '0_5_2_coastwide_selex_comps_lambdas',
                                                 '0_5_3_tuned_toGetReport',
                                                 '0_5_6_survLogistic',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Coastwide, blocks extended',
                                     'Coastwide, various fixes',
                                     'tuned',
                                     'survey logistic selex',
                                     'breakpoint female M'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))

####------------------------------------------------####
### 0_5_9 mirror non-trawl fleet  ----
####------------------------------------------------####

new_name <- "0_5_9_mirror_ntwl"

copy_SS_inputs(dir.old = here('models/0_5_8_breakpoint_M'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)

mod$ctl$size_selex_types[fleet.converter$fleetname[fleet.converter$fleet_no_num == 'OR_NTWL'],
                         c('Pattern', 'Special')] <- c(15,
                                                       fleet.converter$fleet[fleet.converter$fleet_no_num ==
                                                                               'CA_NTWL'])

mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[-grep('OR_NTWL', rownames(mod$ctl$size_selex_parms)),]
mod$ctl$size_selex_parms_tv <- mod$ctl$size_selex_parms_tv[-grep('OR_NTWL', rownames(mod$ctl$size_selex_parms_tv)),]

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:19)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_5_1_coastwide_better_blocks',
                                                 '0_5_3_tuned_toGetReport',
                                                 '0_5_6_survLogistic',
                                                 '0_5_8_breakpoint_M',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Coastwide, blocks extended',
                                     'Coastwide, various fixes tuned',
                                     'survey logistic selex',
                                     'breakpoint female M',
                                     'mirror OR NTWL to CA'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))

tune_comps(pp, option = 'Francis', dir = here('models', new_name), 
           niters_tuning = 0, exe = here('models/ss_win.exe'))



####------------------------------------------------####
### Setup models 0_6_0 with: -----
### 1. Removing CA ASHOP length and age comps (which are holdovers from early models)
### 2. Removing the var_adj value for ages for CA_REC (fleet 7, type 5) because there are not CA rec ages in this model or in the last model
### 3. Remove the var_adj values for ages and lengths for CA ASHOP
### 4. Setting the new selex setup to have init for param 5 as -15 (instead of -999) because we expect selectivity at the youngest sizes to be 0
####------------------------------------------------####

#047 now behaves but 048 now does not. 
#Appears to be due to parm5 adjustment for 048 since its not due to removing CA ASHOP.

new_name <- c("0_6_0_1_update047", "0_6_0_2_update048", "0_6_0_3_update0413")
old_name <- c("0_4_7_selexFullUpdate", "0_4_8_selexPartUpdate", "0_4_13_newInit")

for(i in 1:length(new_name)){
  
  ##
  #Copy inputs
  ##
  
  copy_SS_inputs(dir.old = here('models',old_name[i]),
                 dir.new = here('models',new_name[i]),
                 overwrite = TRUE)
  
  mod <- SS_read(here('models',new_name[i]))
  
  
  ##
  #Make Changes
  ##
  
  #Exclude CA ASHOP length and age comps
  mod$dat$lencomp <- mod$dat$lencomp[mod$dat$lencomp$FltSvy!=10,]
  mod$dat$agecomp <- mod$dat$agecomp[mod$dat$agecomp$FltSvy!=10,]
  
  #Remove var_adj values for CA rec (age) and CA ashop (age and length)
  mod$ctl$Variance_adjustment_list <- mod$ctl$Variance_adjustment_list[
    -c(which(mod$ctl$Variance_adjustment_list$Fleet == 7 & mod$ctl$Variance_adjustment_list$Data_type == 5),
       which(mod$ctl$Variance_adjustment_list$Fleet == 10)),]
  
  #Set initial value of the 5th parameters for selectivity to be -15 instead of -999
  mod$ctl$size_selex_parms[grep("_P_5",rownames(mod$ctl$size_selex_parms)), "INIT"] <- -15
  
  
  ##
  #Output files and run
  ##
  
  SS_write(mod,
           dir = here('models',new_name[i]),
           overwrite = TRUE)
  
  r4ss::run(dir = here('models',new_name[i]),
            exe = here('models/ss_win.exe'),
            extras = '-nohess',
            # show_in_console = TRUE,
            skipfinished = FALSE)
  
  
  ##
  #Comparison plots
  ##
  
  xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                        subdir = c(old_name[i],
                                                   new_name[i])))
  SSsummarize(xx) |>
    SSplotComparisons(legendlabels = c(old_name[i], 
                                       'Clean up before data weighting'),
                      subplots = c(1,3), print = TRUE, plotdir = here('models',new_name[i]))
  
}



####------------------------------------------------####
### 0_6_1_0_lambda1_047 Take the 0_6_0_X revised model of 0_4_7 (new blocks without mirroring, new selex setup) and turn lambdas to 1 ----
####------------------------------------------------####

new_name <- "0_6_1_0_lambda1_047"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_6_0_1_update047'), 
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

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_6_0_1_update047',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('selexFullUpdate with 0_6_0 changes', 
                                     'lambdas = 1'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 0_6_1_1_francisAll_047 Copy model 0_6_1_0 and then iterate 2 to get Francis weights ----
####------------------------------------------------####

new_name <- "0_6_1_1_francisAll_047"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_6_1_0_lambda1_047'),
               dir.new = here('models',new_name),
               overwrite = TRUE)
file.copy(from = file.path(here('models/0_6_1_0_lambda1_047'),"Report.sso"),
          to = file.path(here('models',new_name),"Report.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/0_6_1_0_lambda1_047'),"CompReport.sso"),
          to = file.path(here('models',new_name),"CompReport.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/0_6_1_0_lambda1_047'),"warning.sso"),
          to = file.path(here('models',new_name),"warning.sso"), overwrite = TRUE)


##
#Make Changes
##

yy <- SS_output(here('models', new_name))
dw <- tune_comps(replist = yy, dir = here('models', new_name),
                 option = c("Francis"), niters_tuning = 2,
                 exe = here('models/ss_win.exe'), extras = "-nohess",
                 allow_up_tuning = TRUE,
                 write = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26))

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_6_0_1_update047',
                                                 '0_6_1_0_lambda1_047',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('selexFullUpdate with 0_6_0 changes',
                                     'selexFullUpdate with lambda = 1',
                                     'after 2 new Francis runs'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))



####------------------------------------------------####
### 0_6_2_0_lambda1_048 Take the 0_6_0_X revised model of 0_4_8 (new blocks with mirroring, new selex setup) and turn lambdas to 1 ----
####------------------------------------------------####

new_name <- "0_6_2_0_lambda1_048"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_6_0_2_update048'), 
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

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_4_8_selexPartUpdate',
                                                 '0_6_0_2_update048',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('selexPartUpdate',
                                     'selexPartUpdate with 0_6_0 changes',
                                     'lambdas = 1'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 0_6_2_1_francisAll_048 Copy model 0_6_2_0 and then iterate 2 to get Francis weights ----
####------------------------------------------------####

new_name <- "0_6_2_1_francisAll_048"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_6_2_0_lambda1_048'),
               dir.new = here('models',new_name),
               overwrite = TRUE)
file.copy(from = file.path(here('models/0_6_2_0_lambda1_048'),"Report.sso"),
          to = file.path(here('models',new_name),"Report.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/0_6_2_0_lambda1_048'),"CompReport.sso"),
          to = file.path(here('models',new_name),"CompReport.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/0_6_2_0_lambda1_048'),"warning.sso"),
          to = file.path(here('models',new_name),"warning.sso"), overwrite = TRUE)


##
#Make Changes
##

yy <- SS_output(here('models', new_name))
dw <- tune_comps(replist = yy, dir = here('models', new_name),
                 option = c("Francis"), niters_tuning = 2,
                 exe = here('models/ss_win.exe'), extras = "-nohess",
                 allow_up_tuning = TRUE,
                 write = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26))

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_6_0_2_update048',
                                                 '0_6_2_0_lambda1_048',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('selexPartUpdate with 0_6_0 changes',
                                     'selexPartUpdate with lambda = 1',
                                     'after 2 new Francis runs'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))



####------------------------------------------------####
### 0_6_3_0_lambda1_0413 Take the 0_6_0_X revised model of 0_4_13 (new blocks without mirroring, old selex setup but with new inits) and turn lambdas to 1 ----
####------------------------------------------------####

new_name <- "0_6_3_0_lambda1_0413"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_6_0_3_update0413'), 
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

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_4_13_newInit',
                                                 '0_6_0_3_update0413',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('newInit',
                                     'newInit with 0_6_0 changes',
                                     'lambdas = 1'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 0_6_3_1_francisAll_0413 Copy model 0_6_3_0 and then iterate 2 to get Francis weights ----
####------------------------------------------------####

new_name <- "0_6_3_1_francisAll_0413"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_6_3_0_lambda1_0413'),
               dir.new = here('models',new_name),
               overwrite = TRUE)
file.copy(from = file.path(here('models/0_6_3_0_lambda1_0413'),"Report.sso"),
          to = file.path(here('models',new_name),"Report.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/0_6_3_0_lambda1_0413'),"CompReport.sso"),
          to = file.path(here('models',new_name),"CompReport.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/0_6_3_0_lambda1_0413'),"warning.sso"),
          to = file.path(here('models',new_name),"warning.sso"), overwrite = TRUE)


##
#Make Changes
##

yy <- SS_output(here('models', new_name))
dw <- tune_comps(replist = yy, dir = here('models', new_name),
                 option = c("Francis"), niters_tuning = 2,
                 exe = here('models/ss_win.exe'), extras = "-nohess",
                 allow_up_tuning = TRUE,
                 write = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26))

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_6_0_3_update0413',
                                                 '0_6_3_0_lambda1_0413',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('OldSetup newInit with 0_6_0 changes',
                                     'OldSetup newInit with lambda = 1',
                                     'after 2 new Francis runs'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))



####------------------------------------------------####
### 0_6_4_reweight_047 Add one more iteration to Francis weighting of model 0_6_1_1_francisAll_047 ----
####------------------------------------------------####

#Despite model previous weighting of 047 suggested stability, weighting a third time
#suggests the model is not biologically realistic. Female M is less than male M. 

new_name <- "0_6_4_reweight_047"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_6_1_1_francisAll_047'),
               dir.new = here('models',new_name),
               overwrite = TRUE)
file.copy(from = file.path(here('models/0_6_1_1_francisAll_047'),"Report.sso"),
          to = file.path(here('models',new_name),"Report.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/0_6_1_1_francisAll_047'),"CompReport.sso"),
          to = file.path(here('models',new_name),"CompReport.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/0_6_1_1_francisAll_047'),"warning.sso"),
          to = file.path(here('models',new_name),"warning.sso"), overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make Changes
##

yy <- SS_output(here('models', new_name))
dw <- tune_comps(replist = yy, dir = here('models', new_name),
                 option = c("Francis"), niters_tuning = 0,
                 exe = here('models/ss_win.exe'), extras = "-nohess",
                 allow_up_tuning = TRUE,
                 write = TRUE)

plot(dw$Francis_mult)
colnames(dw)[1] = "Data_type"
new_var_adj <- dplyr::left_join(mod$ctl$Variance_adjustment_list, dw,
                                by = dplyr::join_by(Data_type, Fleet))
mod$ctl$Variance_adjustment_list$Value <-  new_var_adj$New_Var_adj
  
##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name),covar=FALSE)
SS_plots(pp, plot = c(1:26))

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_6_0_1_update047',
                                                 '0_6_1_0_lambda1_047',
                                                 '0_6_1_1_francisAll_047',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('selexFullUpdate with 0_6_0 changes',
                                     'selexFullUpdate with lambda = 1',
                                     'after 2 new Francis runs',
                                     'after 1 adtl. Francis run'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 0_6_5_survLogistic Try fixing survey selectivity at logistic  ----
####------------------------------------------------####

new_name <- "0_6_5_survLogistic"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_6_4_reweight_047'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make Changes
##

#Set parameter 4 to a large number (15) and dont estimate
mod$ctl$size_selex_parms[intersect(
  grep("_NWFSC|_Tri",rownames(mod$ctl$size_selex_parms)),
  grep("P_4",rownames(mod$ctl$size_selex_parms))),c("HI")] <- 20
mod$ctl$size_selex_parms[intersect(
  grep("_NWFSC|_Tri",rownames(mod$ctl$size_selex_parms)),
  grep("P_4",rownames(mod$ctl$size_selex_parms))),c("INIT")] <- 15
mod$ctl$size_selex_parms[intersect(
  grep("_NWFSC|_Tri",rownames(mod$ctl$size_selex_parms)),
  grep("P_4",rownames(mod$ctl$size_selex_parms))),c("PHASE")] <- -99


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)


pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:19)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_6_0_1_update047',
                                                 '0_6_1_0_lambda1_047',
                                                 '0_6_1_1_francisAll_047',
                                                 '0_6_4_reweight_047',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('selexFullUpdate with 0_6_0 changes',
                                     'selexFullUpdate with lambda = 1',
                                     'after 2 new Francis runs',
                                     'after 1 adtl. Francis run',
                                     'survey logistic selex'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))



##########################################################################################

#Revisiting earlier models and reweighting to see if earlier versions are stable
##########################################################################################

####------------------------------------------------####
### 1_1_0_lambda1_2015 Take the 2015 base model, set lambdas to 1 ----
####------------------------------------------------####

new_name <- "1_1_0_lambda1_2015"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/converted'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

mod$start$detailed_age_structure <- 1 #all output

#Set lambdas to 1 for all but the coastwide comps (rec age comps were previously 
#zero but these aren't in the model so can set them to 1 to avoid issues later)
mod$ctl$lambdas[!grepl("_coastwide",rownames(mod$ctl$lambdas)), "value"] <- 1


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('2015base',
                                                 'converted',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015base',
                                     'converted2015', 
                                     'lambdas = 1'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 1_1_1_reweight_2015 Take the 2015 base model with lambdas set to 1 and reweight ----
####------------------------------------------------####

new_name <- "1_1_1_reweight_2015"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/1_1_0_lambda1_2015'),
               dir.new = here('models',new_name),
               overwrite = TRUE)
file.copy(from = file.path(here('models/1_1_0_lambda1_2015'),"Report.sso"),
          to = file.path(here('models',new_name),"Report.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/1_1_0_lambda1_2015'),"CompReport.sso"),
          to = file.path(here('models',new_name),"CompReport.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/1_1_0_lambda1_2015'),"warning.sso"),
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

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('2015base',
                                                 'converted',
                                                 '1_0_0_lambda1_2015',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015base',
                                     'converted2015', 
                                     'lambdas = 1',
                                     'Francis reweight'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))

plot_sel_comm(yy)
plot_sel_noncomm(yy)


####------------------------------------------------####
### 1_2_0_data_lambda1 Take the 2015 base model with new data added and set lambdas to 1 ----
####------------------------------------------------####

new_name <- "1_2_0_lambda1_data"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_1_1_update_data'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make Changes
##

#Set lambdas to 1 for all but the coastwide comps (rec age comps were previously 
#zero but these aren't in the model so can set them to 1 to avoid issues later)
mod$ctl$lambdas[!grepl("_coastwide",rownames(mod$ctl$lambdas)), "value"] <- 1


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)


####------------------------------------------------####
### 1_2_1_reweight_data Take the 2015 base model with new data added and lambdas set to 1 and reweight ----
####------------------------------------------------####

new_name <- "1_2_1_reweight_data"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/1_2_0_lambda1_data'),
               dir.new = here('models',new_name),
               overwrite = TRUE)
file.copy(from = file.path(here('models/1_2_0_lambda1_data'),"Report.sso"),
          to = file.path(here('models',new_name),"Report.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/1_2_0_lambda1_data'),"CompReport.sso"),
          to = file.path(here('models',new_name),"CompReport.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/1_2_0_lambda1_data'),"warning.sso"),
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

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('2015base',
                                                 'converted',
                                                 '1_1_1_reweight_2015',
                                                 '1_2_0_lambda1_data',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015base',
                                     'converted2015',
                                     'Francis reweight',
                                     'Data lambda = 1',
                                     'Francis reweight data'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))

plot_sel_comm(yy)
plot_sel_noncomm(yy)


####------------------------------------------------####
### 1_2_2_reweight_data_extend Forgot to extend selectivity blocks. Do so with 2015 base model with new data added and lambdas set to 1 and reweight ----
####------------------------------------------------####

new_name <- "1_2_2_reweight_data_extend"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/1_2_0_lambda1_data'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make Changes
##

mod$ctl$Block_Design[[1]][2] <- 2022
mod$ctl$Block_Design[[2]][4] <- 2022


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

#Reweight

yy <- SS_output(here('models', new_name))
dw <- tune_comps(replist = yy, dir = here('models', new_name),
                 option = c("Francis"), niters_tuning = 3,
                 exe = here('models/ss_win.exe'), extras = "-nohess",
                 allow_up_tuning = TRUE,
                 write = TRUE)

##
#Comparison plots
##

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('2015base',
                                                 'converted',
                                                 '1_2_1_reweight_data',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015base',
                                     'converted2015',
                                     'Francis reweight data',
                                     'Francis reweight data extend'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 1_3_0_bioMval_lambda1 Take the 2015 base model with new data added and new bio (just M value) and set lambdas to 1 ----
####------------------------------------------------####

new_name <- "1_3_0_lambda1_bioMval"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_2_1_update_bio_Mval'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make Changes
##

#Set lambdas to 1 for all but the coastwide comps (rec age comps were previously 
#zero but these aren't in the model so can set them to 1 to avoid issues later)
mod$ctl$lambdas[!grepl("_coastwide",rownames(mod$ctl$lambdas)), "value"] <- 1


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)


####------------------------------------------------####
### 1_3_1_reweight_bioMval Take the 2015 base model with new data and bio added (just M value) and lambdas set to 1 and reweight ----
####------------------------------------------------####

new_name <- "1_3_1_reweight_bioMval"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/1_3_0_lambda1_bioMval'),
               dir.new = here('models',new_name),
               overwrite = TRUE)
file.copy(from = file.path(here('models/1_3_0_lambda1_bioMval'),"Report.sso"),
          to = file.path(here('models',new_name),"Report.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/1_3_0_lambda1_bioMval'),"CompReport.sso"),
          to = file.path(here('models',new_name),"CompReport.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/1_3_0_lambda1_bioMval'),"warning.sso"),
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

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('2015base',
                                                 'converted',
                                                 '1_1_1_reweight_2015',
                                                 '1_2_1_reweight_data',
                                                 '1_3_0_lambda1_bioMval',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015base',
                                     'converted2015',
                                     'Francis reweight',
                                     'Francis reweight data',
                                     'BioMval lambda = 1',
                                     'Francis reweight bioMval'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))

plot_sel_comm(yy)
plot_sel_noncomm(yy)


####------------------------------------------------####
### 1_3_2_reweight_bioMval_extend Forgot to extend selectivity blocks. Do so with 2015 base model with new data and bio added (just Mvalue) and lambdas set to 1 and reweight ----
####------------------------------------------------####

new_name <- "1_3_2_reweight_bioMval_extend"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/1_3_0_lambda1_bioMval'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make Changes
##

mod$ctl$Block_Design[[1]][2] <- 2022
mod$ctl$Block_Design[[2]][4] <- 2022


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

#Reweight

yy <- SS_output(here('models', new_name))
dw <- tune_comps(replist = yy, dir = here('models', new_name),
                 option = c("Francis"), niters_tuning = 3,
                 exe = here('models/ss_win.exe'), extras = "-nohess",
                 allow_up_tuning = TRUE,
                 write = TRUE)

##
#Comparison plots
##

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('2015base',
                                                 'converted',
                                                 '1_3_1_reweight_bioMval',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015base',
                                     'converted2015',
                                     'Francis reweight bioMval',
                                     'Francis reweight bioMval extend'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 1_4_0_bio_lambda1 Take the 2015 base model with new data added and all new bio and set lambdas to 1 ----
####------------------------------------------------####

new_name <- "1_4_0_lambda1_bio"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_2_12_maleMfixPhases'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make Changes
##

#Set lambdas to 1 for all but the coastwide comps (rec age comps were previously 
#zero but these aren't in the model so can set them to 1 to avoid issues later)
mod$ctl$lambdas[!grepl("_coastwide",rownames(mod$ctl$lambdas)), "value"] <- 1


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)


####------------------------------------------------####
### 1_4_1_reweight_bio Take the 2015 base model with new data and bio added and lambdas set to 1 and reweight ----
####------------------------------------------------####

new_name <- "1_4_1_reweight_bio"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/1_4_0_lambda1_bio'),
               dir.new = here('models',new_name),
               overwrite = TRUE)
file.copy(from = file.path(here('models/1_4_0_lambda1_bio'),"Report.sso"),
          to = file.path(here('models',new_name),"Report.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/1_4_0_lambda1_bio'),"CompReport.sso"),
          to = file.path(here('models',new_name),"CompReport.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/1_4_0_lambda1_bio'),"warning.sso"),
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

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('2015base',
                                                 'converted',
                                                 '1_1_1_reweight_2015',
                                                 '1_2_1_reweight_data',
                                                 '1_3_1_reweight_bioMval',
                                                 '1_4_0_lambda1_bio',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015base',
                                     'converted2015',
                                     'Francis reweight',
                                     'Francis reweight data',
                                     'Francis reweight bioMval',
                                     'Bio lambda = 1',
                                     'Francis reweight bio'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))

plot_sel_comm(yy)
plot_sel_noncomm(yy)


####------------------------------------------------####
### 1_4_2_reweight_bio_extend Forgot to extend selectivity blocks. Do so with 2015 base model with new data and bio added and lambdas set to 1 and reweight ----
####------------------------------------------------####

new_name <- "1_4_2_reweight_bio_extend"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/1_4_0_lambda1_bio'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make Changes
##

mod$ctl$Block_Design[[1]][2] <- 2022
mod$ctl$Block_Design[[2]][4] <- 2022


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

#Reweight

yy <- SS_output(here('models', new_name))
dw <- tune_comps(replist = yy, dir = here('models', new_name),
                 option = c("Francis"), niters_tuning = 3,
                 exe = here('models/ss_win.exe'), extras = "-nohess",
                 allow_up_tuning = TRUE,
                 write = TRUE)

##
#Comparison plots
##

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('2015base',
                                                 'converted',
                                                 '1_4_1_reweight_bio',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015base',
                                     'converted2015',
                                     'Francis reweight bio',
                                     'Francis reweight bio extend'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


##########################################################################################

#Working towards a base model for the coastwide model
##########################################################################################


####------------------------------------------------####
### 2_0_0 minor fixes to various inputs from model 0_5_6 and corrections to data  ----
####------------------------------------------------####

new_name <- "2_0_0_coastwide_minor_fixes"
#new_name <- "2_0_0_coastwide_minor_fixes_not_data" #this is the same, but does not include the updated rec and ashop data lines, nor historical CA comm catches

copy_SS_inputs(dir.old = here('models/0_5_6_survLogistic'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make Changes
##

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)

# Update ASHOP comps, previous versions were not updated (were added to rec for ages and taken and then doubled rec for lengths) so update rec too ------------------------------------------------
length.min <- min(mod$dat$lbin_vector)
length.max <- max(mod$dat$lbin_vector)
age.min <- min(mod$dat$agebin_vector)
age.max <- max(mod$dat$agebin_vector)

read.fishery.comps <- function(filename, exclude) {
  
}

#Keep just rec (since ASHOP were added to them)
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

#These now correctly replace ASHOP fleets
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
  dplyr::filter(!(FltSvy %in% unique(rec.ages$FltSvy)),
                !(FltSvy %in% unique(ashop.ages$FltSvy))) |>
  dplyr::bind_rows(rec.ages, ashop.ages)

mod$dat$lencomp <- mod$dat$lencomp |> 
  dplyr::filter(!(FltSvy %in% unique(rec.lengths$FltSvy)),
                !(FltSvy %in% unique(ashop.lengths$FltSvy))) |>
  dplyr::bind_rows(rec.lengths, ashop.lengths)

# Update CA catches, previous versions did not update recent values ------------------------------------------------
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

# Replace unused but weird values in MGparms (devPH, cohort growth min/max) ------------------------------------------------
mod$ctl$MG_parms$dev_PH <- 0
mod$ctl$MG_parms['CohortGrowDev', c('dev_minyr', 'dev_maxyr')] <- 0

# Remove final block, which does not appear to be used anywhere ------------------------------------------------
mod$ctl$Block_Design <- mod$ctl$Block_Design[-3]
mod$ctl$N_Block_Designs <- 2
mod$ctl$blocks_per_pattern <- c(1,2)
names(mod$ctl$blocks_per_pattern) <- paste0("blocks_per_pattern_",1:2)

# Adjust recdev start (early devs) and last year (main devs) and bias adj (update to recent years) ------------------------------------------------
mod$ctl$recdev_early_start <- mod$dat$styr
mod$ctl$last_yr_fullbias_adj <- 2020
mod$ctl$first_recent_yr_nobias_adj <- 2022
mod$ctl$MainRdevYrLast <- 2022

#Change recruitment distribution method to 4 (none) and change params in MG_parm ------------------------------------------------
mod$ctl$recr_dist_method <- 4
mod$ctl$MG_parms <- mod$ctl$MG_parms[!grepl("RecrDist",rownames(mod$ctl$MG_parms)),]

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:19)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_5_1_coastwide_better_blocks',
                                                 '0_5_3_tuned_toGetReport',
                                                 '0_5_6_survLogistic',
                                                 '0_5_8_breakpoint_M',
                                                 '0_5_9_mirror_ntwl',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Coastwide, blocks extended',
                                     'Coastwide, various fixes tuned',
                                     'survey logistic selex',
                                     'breakpoint female M',
                                     'mirror OR NTWL to CA',
                                     'survey logistic + fixes to data and SSinputs'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))

plot_sel_comm(pp)
plot_sel_noncomm(pp, spatial = FALSE)

####------------------------------------------------####
### 2_0_1_remove_sex0 Remove spiky parts of combined sex fish for length and age comps ----
####------------------------------------------------####

#thought is that these could contribute to poor weights when reweighting
#Changes aren't as great as I thought though I still think removing sparse comps is a good idea
#Initial weighting for OR rec is really high

new_name <- "2_0_1_remove_sex0"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/2_0_0_coastwide_minor_fixes'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make Changes
##

#Remove sex = 0 fish for all AGE comps (Most have small absolute sample size or small relative to sexed samples)
#NTWL (WA, OR); ASHOP (WA), Rec (OR, WA), and TWL (CA, OR, WA). Of these WA TWL has most samples so could be kept.  
table(mod$dat$agecomp$FltSvy, mod$dat$agecomp$Gender, mod$dat$agecomp$Yr <0)
mod$dat$agecomp$Yr[mod$dat$agecomp$Gender == 0] <- -1 * 
  mod$dat$agecomp$Yr[mod$dat$agecomp$Gender == 0]

#Remove sex = 0 fish for some LENGTH comps that have few samples (absolute or relative to sexed samples)
#NTWL (WA, OR); ASHOP (WA, OR), and TWL (OR). WA rec has sparse data but sex=0 is similarly sparse as sex=3 so keep   
table(mod$dat$lencomp$FltSvy, mod$dat$lencomp$Gender, mod$dat$lencomp$Yr <0)
mod$dat$lencomp$Yr[mod$dat$lencomp$Gender == 0 & mod$dat$lencomp$FltSvy %in% c(2,5,6,11,12)] <- -1 * 
  mod$dat$lencomp$Yr[mod$dat$lencomp$Gender == 0 & mod$dat$lencomp$FltSvy %in% c(2,5,6,11,12)]


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_5_6_survLogistic',
                                                 '2_0_0_coastwide_minor_fixes',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('survey logistic selex',
                                     'survey logistic + fixes to data and SSinputs',
                                     'remove sparse sex=0 comp samples'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


plot_sel_comm(pp)
plot_sel_noncomm(pp, spatial = FALSE)

####------------------------------------------------####
### 2_0_2_tuned Reweight model 2_0_1 due to updating data ----
####------------------------------------------------####

new_name <- "2_0_2_tuned"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/2_0_1_remove_sex0'),
               dir.new = here('models',new_name),
               overwrite = TRUE)
file.copy(from = file.path(here('models/2_0_1_remove_sex0'),"Report.sso"),
          to = file.path(here('models',new_name),"Report.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/2_0_1_remove_sex0'),"CompReport.sso"),
          to = file.path(here('models',new_name),"CompReport.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/2_0_1_remove_sex0'),"warning.sso"),
          to = file.path(here('models',new_name),"warning.sso"), overwrite = TRUE)

##
#Make Changes
##

yy <- SS_output(here('models', new_name))
dw <- tune_comps(replist = yy, dir = here('models', new_name),
                 option = c("Francis"), niters_tuning = 4,
                 exe = here('models/ss_win.exe'), extras = "-nohess",
                 allow_up_tuning = TRUE,
                 write = TRUE)

##
#Comparison plots
##

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_5_6_survLogistic',
                                                 '2_0_0_coastwide_minor_fixes',
                                                 '2_0_1_remove_sex0',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('survey logistic selex',
                                     'survey logistic + fixes to data and SSinputs',
                                     'remove sparse sex=0 comp samples',
                                     'Francis reweight'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))

dev.off()
plot_sel_comm(pp)
plot_sel_noncomm(pp, spatial = FALSE)

####------------------------------------------------####
### 2_1_1_noSurveyLogistic Remove logistic assumption for surveys ----
####------------------------------------------------####

new_name <- "2_1_1_noSurveyLogistic"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/2_0_2_tuned'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))
nonlog <- SS_read(here('models','0_5_3_tuned'))


##
#Make Changes
##

#Reset parameter 4 to allow domed (turn on phase and reset init)
mod$ctl$size_selex_parms[intersect(
  grep("_NWFSC|_Tri",rownames(mod$ctl$size_selex_parms)),
  grep("P_4",rownames(mod$ctl$size_selex_parms))),"HI"] <- nonlog$ctl$size_selex_parms[intersect(
    grep("_NWFSC|_Tri",rownames(nonlog$ctl$size_selex_parms)),
    grep("P_4",rownames(nonlog$ctl$size_selex_parms))),"HI"]
mod$ctl$size_selex_parms[intersect(
  grep("_NWFSC|_Tri",rownames(mod$ctl$size_selex_parms)),
  grep("P_4",rownames(mod$ctl$size_selex_parms))),c("INIT")] <- nonlog$ctl$size_selex_parms[intersect(
    grep("_NWFSC|_Tri",rownames(nonlog$ctl$size_selex_parms)),
    grep("P_4",rownames(nonlog$ctl$size_selex_parms))),"INIT"]
mod$ctl$size_selex_parms[intersect(
  grep("_NWFSC|_Tri",rownames(mod$ctl$size_selex_parms)),
  grep("P_4",rownames(mod$ctl$size_selex_parms))),c("PHASE")] <- 5


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:19)])

dev.off()
plot_sel_comm(pp)
plot_sel_noncomm(pp, spatial = FALSE)


####------------------------------------------------####
### 2_1_1_ORtwlLogistic Remove logistic assumption for surveys and add to Oregon trawl for early period ----
####------------------------------------------------####

new_name <- "2_1_2_ORTWL_Logistic"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/2_1_1_noSurveyLogistic'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

#Reset parameter 4 to force logistic for the early period. No need to change timevarying parms. 
mod$ctl$size_selex_parms[intersect(
  grep("_OR_TWL",rownames(mod$ctl$size_selex_parms)),
  grep("P_4",rownames(mod$ctl$size_selex_parms))),"HI"] <- 20
mod$ctl$size_selex_parms[intersect(
  grep("_OR_TWL",rownames(mod$ctl$size_selex_parms)),
  grep("P_4",rownames(mod$ctl$size_selex_parms))),c("INIT")] <- 15
mod$ctl$size_selex_parms[intersect(
  grep("_OR_TWL",rownames(mod$ctl$size_selex_parms)),
  grep("P_4",rownames(mod$ctl$size_selex_parms))),c("PHASE")] <- -99


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:19)])

dev.off()
plot_sel_comm(pp)
plot_sel_noncomm(pp, spatial = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('2_0_2_tuned',
                                                 '2_1_1_noSurveyLogistic',
                                                 '2_1_2_ORTWL_Logistic',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('tuned',
                                     'survey domed',
                                     'survey domed and OR early TWL logistic'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 2_1_3_param6 Turn on parameter 6 estimation for selectivity ----
####------------------------------------------------####

new_name <- "2_1_3_param6"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/2_0_2_tuned'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

mod$ctl$size_selex_parms[grep("P_6",rownames(mod$ctl$size_selex_parms)),"LO"] <- -10
mod$ctl$size_selex_parms[grep("P_6",rownames(mod$ctl$size_selex_parms)),"HI"] <- 10
mod$ctl$size_selex_parms[grep("P_6",rownames(mod$ctl$size_selex_parms)),"INIT"] <- 0
mod$ctl$size_selex_parms[grep("P_6",rownames(mod$ctl$size_selex_parms)),"PHASE"] <- 5

mod$ctl$size_selex_parms[grep("P_6",rownames(mod$ctl$size_selex_parms)),"Block_Fxn"] <- 2
mod$ctl$size_selex_parms[grep("P_6",rownames(mod$ctl$size_selex_parms)),"Block"] <-
  mod$ctl$size_selex_parms[grep("P_1",rownames(mod$ctl$size_selex_parms)),"Block"]


### Time varying selectivity table
selex_tv_pars <- dplyr::filter(mod$ctl$size_selex_parms, Block > 0) |>
  dplyr::select(LO, HI, INIT, PRIOR, PR_SD, PR_type, PHASE, Block) |>
  tidyr::uncount(Block, .id = 'id', .remove = FALSE)

rownames(selex_tv_pars) <- rownames(selex_tv_pars) |>
  stringr::str_remove('\\.\\.\\.[:digit:]+') |>
  stringr::str_c('_BLK', selex_tv_pars$Block, 'repl_', mapply("[",mod$ctl$Block_Design[selex_tv_pars$Block], selex_tv_pars$id * 2 - 1))

mod$ctl$size_selex_parms_tv <- selex_tv_pars |>
  dplyr::select(-Block, -id)



##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:19)])

dev.off()
plot_sel_comm(pp)
plot_sel_noncomm(pp, spatial = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('2_0_2_tuned',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('tuned',
                                     'turn on selex param6'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 3_0_0_Maturity slope Slope for the maturity function was not updated. Do so ----
####------------------------------------------------####

new_name <- "3_0_0_MaturitySlope"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/2_0_2_tuned'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##


slope_fxn <- -0.688
mod$ctl$MG_parms['Mat_slope_Fem_GP_1', c('INIT', 'PRIOR')] <- c(slope_fxn, slope_fxn)


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

dev.off()
plot_sel_comm(pp)
plot_sel_noncomm(pp, spatial = FALSE)


####------------------------------------------------####
### 3_0_1_tuned Tune the model with updated maturity slope ----
####------------------------------------------------####

new_name <- "3_0_1_tuned"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_0_0_MaturitySlope'),
               dir.new = here('models',new_name),
               overwrite = TRUE)
file.copy(from = file.path(here('models/3_0_0_MaturitySlope'),"Report.sso"),
          to = file.path(here('models',new_name),"Report.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/3_0_0_MaturitySlope'),"CompReport.sso"),
          to = file.path(here('models',new_name),"CompReport.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/3_0_0_MaturitySlope'),"warning.sso"),
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

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('2_0_2_tuned',
                                                 '3_0_0_MaturitySlope',
                                                 '3_0_1_tuned')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Model 202',
                                     'Update maturity slope',
                                     'Francis reweight'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))

dev.off()
plot_sel_comm(pp)
plot_sel_noncomm(pp, spatial = FALSE)


####------------------------------------------------####
### 3_1_1_noFloat Turn off float q for triennial. Instead estimate. ----
####------------------------------------------------####

#Just setting float = 0, fixes q at the init. Need to turn on positive phase 

new_name <- "3_1_1_noFloat"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_0_1_tuned'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

#Turn off float q for triennial surveys. Need this off to mirror
mod$ctl$Q_options[c('29_coastwide_Tri_early','30_coastwide_Tri_late'), "float"] <- 0

#Turn on phase
mod$ctl$Q_parms[c('LnQ_base_29_coastwide_Tri_early(29)',
                  'LnQ_base_30_coastwide_Tri_late(30)'), "PHASE"] <- 2


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))


####------------------------------------------------####
### 3_1_2_triennial Mirror q and selectivity for the early and late triennial surveys ----
####------------------------------------------------####

new_name <- "3_1_2_triennial"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_0_1_tuned'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

#Remove float for triennials and mirror q
mod$ctl$Q_options[c('29_coastwide_Tri_early','30_coastwide_Tri_late'), "float"] <- 0

mod$ctl$Q_options["30_coastwide_Tri_late", c("link", "link_info")] <- c(2, 29)
mod$ctl$Q_parms["LnQ_base_30_coastwide_Tri_late(30)", "INIT"] <- 0 #This gets ignored so is not needed but using 0 to indicate a change

mod$ctl$Q_parms[c('LnQ_base_29_coastwide_Tri_early(29)',
                  'LnQ_base_30_coastwide_Tri_late(30)'), "PHASE"] <- 2

#Mirror selectivity of late triennial to early
mod$ctl$size_selex_types["30_coastwide_Tri_late",c("Pattern","Special")] <- c(15, 29)
mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[-grep(
  "_Tri_late",rownames(mod$ctl$size_selex_parms)),]


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

dev.off()
plot_sel_comm(pp)
plot_sel_noncomm(pp, spatial = FALSE)


####------------------------------------------------####
### 3_1_3_triennial_q Mirror q only. Selectivity in 3_1_2 for triennial is wrong----
####------------------------------------------------####

new_name <- "3_1_3_triennial_q"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_0_1_tuned'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

#Remove float for triennials and mirror
mod$ctl$Q_options[c('29_coastwide_Tri_early','30_coastwide_Tri_late'), "float"] <- 0

mod$ctl$Q_options["30_coastwide_Tri_late", c("link", "link_info")] <- c(2, 29)
mod$ctl$Q_parms["LnQ_base_30_coastwide_Tri_late(30)", "INIT"] <- 0 #This gets ignored so is not needed but using 0 to indicate a change

#Turn on phase
mod$ctl$Q_parms[c('LnQ_base_29_coastwide_Tri_early(29)',
                  'LnQ_base_30_coastwide_Tri_late(30)'), "PHASE"] <- 2


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))


dev.off()
plot_sel_comm(pp)
plot_sel_noncomm(pp, spatial = FALSE)


####------------------------------------------------####
### 3_1_4_triennial_selex Mirror selectivity only. Selectivity in 3_1_2 for triennial is wrong  ----
####------------------------------------------------####

new_name <- "3_1_4_triennial_mirrorSelex"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_0_1_tuned'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

#Mirror selectivity of late triennial to early
mod$ctl$size_selex_types["30_coastwide_Tri_late",c("Pattern","Special")] <- c(15, 29)
mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[-grep(
  "_Tri_late",rownames(mod$ctl$size_selex_parms)),]


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('3_0_1_tuned',
                                                 '3_1_1_noFloat',
                                                 '3_1_2_triennial',
                                                 '3_1_3_triennial_q',
                                                 '3_1_4_triennial_mirrorSelex')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Model 301',
                                     'No float triennial',
                                     'Mirror triennial selex and q',
                                     'Mirror triennial q only',
                                     'Mirror triennial selex only'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))

dev.off()
plot_sel_comm(pp)
plot_sel_noncomm(pp, spatial = FALSE)

####------------------------------------------------####
### 3_1_5_update_tri_index Update triennial index to lognormal error instead of mixture (not stable)  ----
####------------------------------------------------####

new_name <- "3_1_5_update_tri_index"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_1_2_triennial'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)

##
#Make Changes
##

tri.cpue <- read.csv(file.path(wd,'Assessments/Assessment Data/2023 Assessment Cycle/canary rockfish/triennial/delta_lognormal/index/est_by_area.csv')) |>
  dplyr::mutate(fleet_no_num = paste0(area, ifelse(year <= 1992, '_Tri_early', '_Tri_late'))) |>
  dplyr::left_join(fleet.converter) |> 
  dplyr::mutate(seas = 7) |>
  dplyr::select(year, seas, index = fleet, obs = est, se_log = se) |>
  dplyr::mutate(year = ifelse(index %in% fleet.converter$fleet[grep('coastwide', fleet.converter$fleetname)],
                              year, -year))

mod$dat$CPUE <- dplyr::filter(mod$dat$CPUE, 
                              !(index %in% fleet.converter$fleet[grep('Tri', fleet.converter$fleetname)])) |>
  dplyr::bind_rows(tri.cpue)


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)
beepr::beep()

# pp <- SS_output(here('models',new_name))
# SS_plots(pp, plot = c(1:26))

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('3_1_2_triennial',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Mirror triennial selex and q',
                                     'Update triennial to lognormal'),
                    subplots = c(1,3,9,11), print = TRUE, plotdir = here('models',new_name))

dev.off()

xx$replist2$cpue |> View()

# Triennial Q is 0.28



####------------------------------------------------####
### 3_1_6_survey_domed Relax the assumption of forcing the surveys to be logistic  ----
####------------------------------------------------####

new_name <- "3_1_6_survey_domed"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_1_5_update_tri_index'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)

##
#Make Changes
##

# Relax logistic selectivity assumption for coastwide surveys. Reset param 4 to inits
selex_modes <- mod$dat$lencomp |>
  dplyr::arrange(FltSvy) |>
  dplyr::group_by(FltSvy) |>
  dplyr::summarise(dplyr::across(f12:m66, ~ sum(Nsamp*.x)/sum(Nsamp))) |>
  tidyr::pivot_longer(cols = -FltSvy, names_to = 'len_bin', values_to = 'dens') |>
  tidyr::separate(col = len_bin, into = c('sex', 'length'), sep = 1) |>
  dplyr::group_by(FltSvy, sex) |>
  dplyr::summarise(mode = length[which.max(dens)]) |>
  dplyr::summarise(mode = mean(as.numeric(mode))) |>
  dplyr::mutate(asc.slope = log(8*(mode - min(mod$dat$lbin_vector))),
                desc.slope = log(8*(max(mod$dat$lbin_vector)-mode))) |>
  filter(FltSvy %in% c(28,29))


mod$ctl$size_selex_parms[intersect(
  grep("_coastwide",rownames(mod$ctl$size_selex_parms)),
  grep("P_4",rownames(mod$ctl$size_selex_parms))),c("HI")] <- 9
mod$ctl$size_selex_parms[intersect(
  grep("_coastwide",rownames(mod$ctl$size_selex_parms)),
  grep("P_4",rownames(mod$ctl$size_selex_parms))),c("PHASE")] <- 5
mod$ctl$size_selex_parms[intersect(
  grep("_coastwide",rownames(mod$ctl$size_selex_parms)),
  grep("P_4",rownames(mod$ctl$size_selex_parms))),c("INIT")] <- selex_modes$desc.slope

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('3_1_2_triennial',
                                                 '3_1_5_update_tri_index',
                                                 '3_1_6_survey_domed')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Mirror triennial selex and q',
                                     'Update triennial index',
                                     'Allow domed shaped for surveys'),
                    subplots = c(1,3,9,11), print = TRUE, plotdir = here('models',new_name))

dev.off()
plot_sel_comm(pp)
plot_sel_noncomm(pp, spatial = FALSE)


####------------------------------------------------####
### 4_0_1_sigmaR_bias Explore fix to pattern in early recdevs. Need hessian for this. Tune sigmaR  ----
####------------------------------------------------####

new_name <- "4_0_1_sigmaR_bias"

##
#Copy inputs and run with hessian
##

copy_SS_inputs(dir.old = here('models/3_1_6_survey_domed'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          #extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

#Save report file used in initial run so have it after rec adjustments are done
file.copy(from = file.path(here('models/4_0_1_sigmaR'),"Report.sso"),
          to = file.path(here('models/4_0_1_sigmaR'),"Report_preadj.sso"), overwrite = TRUE)

mod <- SS_read(here('models',new_name))

pp <- SS_output(here('models',new_name))

##
#Make Changes
##

#Update sigmaR with tuned value? Suggests 0.5 is good so keep it
pp$sigma_R_info
mod$ctl$SR_parms["SR_sigmaR","INIT"] <- pp$sigma_R_info[pp$sigma_R_info$period == "Main",
                                                        "alternative_sigma_R"]


#Update bias adjust? Not really, just maybe 2017
pp$breakpoints_for_bias_adjustment_ramp
biasadj <- SS_fitbiasramp(pp, verbose = TRUE)

#Update bias adjustments
mod$ctl$last_yr_fullbias_adj <- 2017


##
#Output files and run with hessian
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          #extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:19)])



####------------------------------------------------####
### 4_0_2_setSigmaR Not much changes from the previous assessment are needed, but these done fix issue. Trying fixing sigmaR to see effect  ----
####------------------------------------------------####

new_name <- "4_0_2_setSigmaR"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_1_6_survey_domed'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

mod$ctl$SR_parms['SR_sigmaR',"INIT"] <- 0.9


##
#Output files and run run with hessian
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)


####------------------------------------------------####
### 4_0_3_offEarlyDevs See how turning off early devs affects model  ----
####------------------------------------------------####

new_name <- "4_0_3_offEarlyDevs"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_1_6_survey_domed'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

mod$ctl$recdev_early_start <- 0 #turn off


##
#Output files and run run with hessian
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:19)])


####------------------------------------------------####
### 4_0_4_notSumTo1 Allow rec devs not to sum to 1  ----
####------------------------------------------------####

new_name <- "4_0_4_notSumTo1"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_1_6_survey_domed'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

mod$ctl$do_recdev <- 2 


##
#Output files and run run with hessian
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:19)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('3_1_6_survey_domed',
                                                 '4_0_1_sigmaR_bias',
                                                 '4_0_2_setSigmaR',
                                                 '4_0_3_offEarlyDevs',
                                                 '4_0_4_notSumTo1')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Domed survey selectivity',
                                     'Update sigmaR and bias correction',
                                     'Fix sigmaR at 0.9',
                                     'Turn off early devs',
                                     'Relax recdev sum to 1'),
                    subplots = c(1,3,9,11), print = TRUE, plotdir = here('models',new_name))

#The model wants to increase recdevs in recent years. Preferrentially fitting age and length comps. 
#Less depletion when recdevs dont need to sum to one. 
pp_new <- SS_output(here('models','4_0_4_notSumTo1'))
pp_old <- SS_output(here('models','3_1_6_survey_domed'))
like_compare <- cbind(pp_new$likelihoods_used, "prev_val" = pp_prev$likelihoods_used$values)
like_compare$diff = round(like_compare$values - like_compare$prev_val,5) #improving age comps then length, poorer survey index
pp_new$likelihoods_by_fleet[pp_new$likelihoods_by_fleet$Label %in% c("Length_like","Age_like"), -1] - 
  pp_prev$likelihoods_by_fleet[pp_prev$likelihoods_by_fleet$Label %in% c("Length_like","Age_like"), -1]


####------------------------------------------------####
### 4_0_5_fixSteep0.9 Fix steepness to allow model to increase recdevs easier  ----
####------------------------------------------------####

new_name <- "4_0_5_fixSteep0.9"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_1_6_survey_domed'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

mod$ctl$SR_parms["SR_BH_steep","INIT"] <- 0.9


##
#Output files and run run with hessian
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:19)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('3_1_6_survey_domed',
                                                 '4_0_1_sigmaR_bias',
                                                 '4_0_2_setSigmaR',
                                                 '4_0_3_offEarlyDevs',
                                                 '4_0_4_notSumTo1',
                                                 '4_0_5_fixSteep0.9')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Domed survey selectivity',
                                     'Update sigmaR and bias correction',
                                     'Fix sigmaR at 0.9',
                                     'Turn off early devs',
                                     'Relax recdev sum to 1',
                                     'Fix steepness at 0.9'),
                    subplots = c(1,3,9,11), print = TRUE, plotdir = here('models',new_name))

####------------------------------------------------####
### 4_0_6_maleM Estiamte male M as well as female  ----
####------------------------------------------------####

new_name <- "4_0_6_maleM"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_1_6_survey_domed'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

mod$ctl$MG_parms["NatM_p_1_Mal_GP_1", "PHASE"] <- 2


##
#Output files and run run with hessian
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:19)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('3_1_6_survey_domed',
                                                 '4_0_1_sigmaR_bias',
                                                 '4_0_2_setSigmaR',
                                                 '4_0_3_offEarlyDevs',
                                                 '4_0_4_notSumTo1',
                                                 '4_0_5_fixSteep0.9',
                                                 '4_0_6_maleM')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Domed survey selectivity',
                                     'Update sigmaR and bias correction',
                                     'Fix sigmaR at 0.9',
                                     'Turn off early devs',
                                     'Relax recdev sum to 1',
                                     'Fix steepness at 0.9',
                                     'Estimate male M'),
                    subplots = c(1,3,9,11), print = TRUE, plotdir = here('models',new_name))

####------------------------------------------------####
### 4_0_7_estM Fix male M to match female M  ----
####------------------------------------------------####

new_name <- "4_0_7_estM"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_1_6_survey_domed'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

mod$ctl$MG_parms["NatM_p_1_Mal_GP_1", c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type', 'PHASE')] <-
  c(-3, 3, 0, 0, 50, 6, -50)


##
#Output files and run run with hessian
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:19)])


####------------------------------------------------####
### 4_0_8_estH Estimate steepness  ----
####------------------------------------------------####

new_name <- "4_0_8_estH"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_1_6_survey_domed'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

mod$ctl$SR_parms["SR_BH_steep", "PHASE"] <- 2


##
#Output files and run run with hessian
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:19)])

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('3_1_6_survey_domed',
                                                 '4_0_7_estM',
                                                 '4_0_8_estH')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Estimate M together',
                                     'Estimate H'),
                    subplots = c(1,3,9,11), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 4_1_1_blocks Revisiting additional blocks  ----
####------------------------------------------------####

new_name <- "4_1_1_blocks"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_1_6_survey_domed'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

### Update blocks ----
mod$ctl$N_Block_Designs <- 5
mod$ctl$blocks_per_pattern <- c(2,2,2,2,2)
names(mod$ctl$blocks_per_pattern) <- paste0("blocks_per_pattern_",1:mod$ctl$N_Block_Designs)

#Update blocks. Blocking for NTWL is tricky. Right now have WA NTWL to WA TWL mirrored but could unmirror
#Keeping 2000 block instead of 2001 since the data seems to suggest change there (also same as last assessment)
mod$ctl$Block_Design <- list(c(2000, 2010, 2011, 2022), #TWL fleets
                             c(2000, 2019, 2020, 2022), #CA/OR ntwl
                             c(2004, 2016, 2017, 2022), #CA rec
                             c(2004, 2014, 2015, 2022), #OR rec
                             c(2006, 2020, 2021, 2022)) #WA rec

### Update selectivity parameter table matching Jim's parameters setup ----

selex_new <- mod$ctl$size_selex_parms

# Use new block set up
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 1
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2

selex_new[grepl('CA_NTWL|OR_NTWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block', 'Block_Fxn')] <- 2
#WA NTWL is set to mirror WA TWL due to better aggregate match. 

selex_new[grepl('CA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 3
selex_new[grepl('CA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2
selex_new[grepl('OR_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 4
selex_new[grepl('OR_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2
selex_new[grepl('WA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 5
selex_new[grepl('WA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2

mod$ctl$size_selex_parms <- selex_new

### Time varying selectivity table ----
selex_tv_pars <- dplyr::filter(selex_new, Block > 0) |>
  dplyr::select(LO, HI, INIT, PRIOR, PR_SD, PR_type, PHASE, Block) |>
  tidyr::uncount(mod$ctl$blocks_per_pattern[Block], .id = 'id', .remove = FALSE)

rownames(selex_tv_pars) <- rownames(selex_tv_pars) |>
  stringr::str_remove('\\.\\.\\.[:digit:]+') |>
  stringr::str_c('_BLK', selex_tv_pars$Block, 'repl_', mapply("[",mod$ctl$Block_Design[selex_tv_pars$Block], selex_tv_pars$id * 2 - 1))

mod$ctl$size_selex_parms_tv <- selex_tv_pars |>
  dplyr::select(-Block, -id)

##
#Output files and run run with hessian
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

dev.off()
plot_sel_comm(pp)
plot_sel_noncomm(pp, spatial = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('3_1_6_survey_domed',
                                                 '4_1_1_blocks')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Domed survey selectivity',
                                     'Update blocks'),
                    subplots = c(1,3,9,11), print = TRUE, plotdir = here('models',new_name))

#Compare likelihoods. Blocking improves likelihood as well as AIC
pp_new <- SS_output(here('models','4_1_1_blocks'))
pp_prev <- SS_output(here('models','3_1_6_survey_domed'))
cbind(pp_new$likelihoods_used, "prev_val" = pp_prev$likelihoods_used$values)
AIC_new <- 2 * pp_new$N_estimated_parameters + (2 * as.numeric(pp_new$likelihoods_used["TOTAL", "values"]))
AIC_prev <- 2 * pp_prev$N_estimated_parameters + (2 * as.numeric(pp_prev$likelihoods_used["TOTAL", "values"]))


####------------------------------------------------####
### 4_2_1_noRec Explore effect of removing rec to see if bimodality really matters  ----
####------------------------------------------------####

new_name <- "4_2_1_norec"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_1_6_survey_domed'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))
par <- SS_output(here('models/3_1_6_survey_domed'))

##
#Make Changes
##

#Set lambdas to rec length and age to 0
mod$ctl$N_lambdas <- 5
mod$ctl$lambdas <- data.frame("like_comp" = c(rep(4,3), rep(5,2)), #no CA rec ages
                              "fleet" = c(7,8,9,8,9),
                              "phase" = 1,
                              "value" = 0, #turn off
                              "size_freq_method" = 1)

#Fix rec selex at existing selex values from previous model
mod$ctl$size_selex_parms[grep('_REC', rownames(mod$ctl$size_selex_parms)), "INIT"] <- 
  par$parameters[grep('_REC', rownames(par$parameters)),'Value']
mod$ctl$size_selex_parms[grep('_REC', rownames(mod$ctl$size_selex_parms)), "PHASE"] <- -99


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

dev.off()
plot_sel_comm(pp)
plot_sel_noncomm(pp, spatial = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('3_1_6_survey_domed',
                                                 '4_2_1_norec')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Domed survey selectivity',
                                     'Exclude rec comps'),
                    subplots = c(1,3,9,11), print = TRUE, plotdir = here('models',new_name))

####------------------------------------------------####
### 4_3_1_M_ramp use female M parameterization from previous assessments  ----
####------------------------------------------------####

new_name <- "4_3_1_M_ramp"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_1_6_survey_domed'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

mod$ctl$natM_type <- 1
mod$ctl$N_natM <- 2
mod$ctl$M_ageBreakPoints <- c(6, 14)

M.ind <- grep('NatM', rownames(mod$ctl$MG_parms))

mod$ctl$MG_parms <- mod$ctl$MG_parms[c(rep(M.ind[1], 2), (M.ind[1]+1):(M.ind[2]-1),
                                       rep(M.ind[2], 2), (M.ind[2]+1):(nrow(mod$ctl$MG_parms))),]
M.ind <- grep('1.1', rownames(mod$ctl$MG_parms))
rownames(mod$ctl$MG_parms)[M.ind] <- stringr::str_replace(rownames(mod$ctl$MG_parms)[M.ind], 
                                                          pattern = 'p_1', 
                                                          replacement = 'p_2') |>
  stringr::str_remove(pattern = '\\.1')

mod$ctl$MG_parms['NatM_p_1_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type', 'PHASE')] <-
  mod$ctl$MG_parms['NatM_p_1_Mal_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type', 'PHASE')]

mod$ctl$MG_parms['NatM_p_2_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type', 'PHASE')] <-
  c(0, 0.9, 0.5, 99, 99, 0, 3)

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

dev.off()
plot_sel_comm(pp)
plot_sel_noncomm(pp, spatial = FALSE)

r4ss::tune_comps(replist = pp, 
                 option = 'Francis', 
                 dir = here('models', new_name), 
                 exe = here('models/ss_win.exe'), 
                 niters_tuning = 0)

####------------------------------------------------####
### 4_3_1_M_ramp_update Update female M to be direct estimation (and correct prior)  ----
####------------------------------------------------####

new_name <- "4_3_1_M_ramp_update"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_1_6_survey_domed'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

mod$ctl$natM_type <- 1
mod$ctl$N_natM <- 2
mod$ctl$M_ageBreakPoints <- c(6, 14)

M.ind <- grep('NatM', rownames(mod$ctl$MG_parms))

mod$ctl$MG_parms <- mod$ctl$MG_parms[c(rep(M.ind[1], 2), (M.ind[1]+1):(M.ind[2]-1),
                                       rep(M.ind[2], 2), (M.ind[2]+1):(nrow(mod$ctl$MG_parms))),]
M.ind <- grep('1.1', rownames(mod$ctl$MG_parms))
rownames(mod$ctl$MG_parms)[M.ind] <- stringr::str_replace(rownames(mod$ctl$MG_parms)[M.ind], 
                                                          pattern = 'p_1', 
                                                          replacement = 'p_2') |>
  stringr::str_remove(pattern = '\\.1')

mod$ctl$MG_parms['NatM_p_2_Fem_GP_1',] <- mod$ctl$MG_parms['NatM_p_1_Fem_GP_1',]
mod$ctl$MG_parms[c('NatM_p_1_Fem_GP_1'), 'PHASE'] <- -50
mod$ctl$MG_parms[c('NatM_p_1_Mal_GP_1', 'NatM_p_2_Mal_GP_1'), 'PR_type'] <- 3

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

dev.off()
plot_sel_comm(pp)
plot_sel_noncomm(pp, spatial = FALSE)

####------------------------------------------------####
### 4_3_1_M_ramp_update Update female M with offset approach 3  ----
####------------------------------------------------####

new_name <- "4_3_1_M_ramp_offset"


##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_1_6_survey_domed'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

mod$ctl$parameter_offset_approach <- 3

mod$ctl$natM_type <- 1
mod$ctl$N_natM <- 2
mod$ctl$M_ageBreakPoints <- c(6, 14)

M.ind <- grep('NatM', rownames(mod$ctl$MG_parms))

mod$ctl$MG_parms <- mod$ctl$MG_parms[c(rep(M.ind[1], 2), (M.ind[1]+1):(M.ind[2]-1),
                                       rep(M.ind[2], 2), (M.ind[2]+1):(nrow(mod$ctl$MG_parms))),]
M.ind <- grep('1.1', rownames(mod$ctl$MG_parms))
rownames(mod$ctl$MG_parms)[M.ind] <- stringr::str_replace(rownames(mod$ctl$MG_parms)[M.ind], 
                                                          pattern = 'p_1', 
                                                          replacement = 'p_2') |>
  stringr::str_remove(pattern = '\\.1')

mod$ctl$MG_parms[c('NatM_p_1_Fem_GP_1'), 'PHASE'] <- -50
mod$ctl$MG_parms[c('NatM_p_1_Mal_GP_1', 'NatM_p_2_Mal_GP_1'), 
                 c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type', 'PHASE')] <- 
  rep(c(-3, 3, 0, 0, 50, 6, -50), each = 2)

mod$ctl$MG_parms['NatM_p_2_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type', 'PHASE')] <-
  c(0, 0.9, 0.5, 0.5, 50, 0, 2)

#Because offset approach is 3 need to update male L at amin and offset male Linf, and offset K and CV

mod$ctl$MG_parms['L_at_Amin_Mal_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type', 'PHASE')] <-
  c(-3, 3, 0, 0, 50, 6, -50)
mod$ctl$MG_parms['L_at_Amax_Mal_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type', 'PHASE')] <-
  c(-3, 3, 0, 0, 50, 0, 3)

mod$ctl$MG_parms['CV_old_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type', 'PHASE')] <-
  c(-3, 3, 0, 0, 50, 0, 4)
mod$ctl$MG_parms['CV_young_Mal_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type', 'PHASE')] <-
  c(-3, 3, 0, 0, 50, 0, 4)
mod$ctl$MG_parms['CV_old_Mal_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type', 'PHASE')] <-
  c(-3, 3, 0, 0, 50, 0, 4)

mod$ctl$MG_parms['VonBert_K_Mal_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type', 'PHASE')] <-
  c(-3, 3, 0, 0, 50, 0, 3)



##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)


####------------------------------------------------####
### 4_3_2_M_breakpoint use female M breakpoint where sex ratio declines  ----
####------------------------------------------------####

new_name <- "4_3_2_M_breakpoint"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_3_1_M_ramp'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

mod$ctl$M_ageBreakPoints <- c(20,21)

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

dev.off()
plot_sel_comm(pp)
plot_sel_noncomm(pp, spatial = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('3_1_6_survey_domed',
                                                 '4_3_1_M_ramp',
                                                 '4_3_2_M_breakpoint')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Constant M',
                                     'M ramp (historical)',
                                     'M breakpoint'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))

r4ss::tune_comps(replist = pp, 
                 option = 'Francis', 
                 dir = here('models', new_name), 
                 exe = here('models/ss_win.exe'), 
                 niters_tuning = 0)

####------------------------------------------------####
### 4_3_2_M_breakpoint_update Update female M to be direct estimation (and correct prior)  ----
####------------------------------------------------####

new_name <- "4_3_2_M_breakpoint_update"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_3_1_M_ramp_update'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

mod$ctl$M_ageBreakPoints <- c(20,21)

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

dev.off()
plot_sel_comm(pp)
plot_sel_noncomm(pp, spatial = FALSE)


####------------------------------------------------####
### 4_3_2_M_breakpoint_update Update female M to be direct estimation (and correct prior)  ----
####------------------------------------------------####

new_name <- "4_3_2_M_breakpoint_offset"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_3_1_M_ramp_offset'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

mod$ctl$M_ageBreakPoints <- c(20,21)

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)


xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('4_3_1_M_ramp',
                                                 '4_3_1_M_ramp_update',
                                                 '4_3_1_M_ramp_offset',
                                                 '4_3_2_M_breakpoint',
                                                 '4_3_2_M_breakpoint_update',
                                                 '4_3_2_M_breakpoint_offset')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('M ramp (historical)',
                                     'M ramp update',
                                     'M ramp true offset',
                                     'M breakpoint',
                                     'M breakpoint update',
                                     'M breakpoint true offset'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


pp_con <- SS_output(here('models','3_1_6_survey_domed'))
pp_ramp <- SS_output(here('models','4_3_1_M_ramp_update'))
pp_break <- SS_output(here('models','4_3_2_M_breakpoint_update'))
like_compare <- cbind(pp_ramp$likelihoods_used, "bp" = pp_break$likelihoods_used$values, "con" = pp_con$likelihoods_used$values)
like_compare$diff_ramp_break = round(like_compare$values - like_compare$bp,5) #improving age comps then length, poorer survey index
like_compare$diff_cons_ramp = round(like_compare$con - like_compare$values,5) #improving age comps then length, poorer survey index
pp_ramp$likelihoods_by_fleet[pp_ramp$likelihoods_by_fleet$Label %in% c("Length_like","Age_like"), -1] - 
  pp_break$likelihoods_by_fleet[pp_break$likelihoods_by_fleet$Label %in% c("Length_like","Age_like"), -1]
#Comps are better fit with breakpoint assumption. Likelihoods across the board are improved.


####------------------------------------------------####
### 4_4_0_negLOp3p4 I notice parm 3 and 4 are only positive, test allowing the LO to be negative ----
####------------------------------------------------####

new_name <- "4_4_1_negLOp3p4"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_1_6_survey_domed'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

mod$ctl$size_selex_parms[grep("_P_3|_P_4", rownames(mod$ctl$size_selex_parms)),"LO"] <- -9


##
#Output files and run
##


SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('3_1_6_survey_domed',
                                                 '4_4_1_negLOp3p4')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('LO is 0',
                                     'LO is -9'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))

#These are the same. Can proceed accordingly



####------------------------------------------------####
### 4_4_1_sexSelex1 Set up sex specific selectivity for parm 1  ----
####------------------------------------------------####

new_name <- "4_4_1_sexSelex_1_AllFleets"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_1_6_survey_domed'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

#Pick fleets want to have an offset for. Here we are doing all
maleFleets <- rownames(mod$ctl$size_selex_types[mod$ctl$size_selex_types$Pattern == 24, ]) 
#Male offset from female (using option 4 (female offset from male) makes no difference)
mod$ctl$size_selex_types[maleFleets, "Male"] <- 3

for(i in maleFleets){
  ifelse(i != tail(maleFleets,1),
         mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[c(1:max(grep(i,rownames(mod$ctl$size_selex_parms))),
                                                       grep(i,rownames(mod$ctl$size_selex_parms))[c(1,3,4,6,2)], #only output 5 parameters. Use P_2 for the fifth parameter name
                                                       (max(grep(i, rownames(mod$ctl$size_selex_parms)))+1):
                                                         length(rownames(mod$ctl$size_selex_parms))),],
         mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[c(1:max(grep(i,rownames(mod$ctl$size_selex_parms))),
                                                         grep(i,rownames(mod$ctl$size_selex_parms))[c(1,3,4,6,2)]),]) #only output 5 parameters. Use P_2 for the fifth parameter name
}
#male parm 1 added to female parm 1. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_1", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-25, 25, 0, 0, 50, 0, 4, 0, 0), each = length(maleFleets))

#male parm 2 added to female parm 3. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_3", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-9, 9, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 3 added to female parm 4. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_4", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-9, 9, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 4 added to female parm 6. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_6", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-99, 99, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 5 is a scalar to apical selectivity AND descending limb (rescales the whole thing). Use 1 for no change
#search for P_2 for this because I arbitrarily copied the parm2 line for the 5th male parameter
mod$ctl$size_selex_parms[intersect(grep("_P_2", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(0, 2, 1, 1, 50, 0, -99, 0, 0), each = length(maleFleets))


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:18)])

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)


####------------------------------------------------####
### 4_4_1_sexSelex3 Set up sex specific selectivity for parm 3  ----
####------------------------------------------------####

new_name <- "4_4_2_sexSelex_3_AllFleets"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_1_6_survey_domed'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

#Pick fleets want to have an offset for. Here we are doing all
maleFleets <- rownames(mod$ctl$size_selex_types[mod$ctl$size_selex_types$Pattern == 24, ]) 
#Male offset from female (using option 4 (female offset from male) makes no difference)
mod$ctl$size_selex_types[maleFleets, "Male"] <- 3

for(i in maleFleets){
  ifelse(i != tail(maleFleets,1),
         mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[c(1:max(grep(i,rownames(mod$ctl$size_selex_parms))),
                                                                grep(i,rownames(mod$ctl$size_selex_parms))[c(1,3,4,6,2)], #only output 5 parameters. Use P_2 for the fifth parameter name
                                                                (max(grep(i, rownames(mod$ctl$size_selex_parms)))+1):
                                                                  length(rownames(mod$ctl$size_selex_parms))),],
         mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[c(1:max(grep(i,rownames(mod$ctl$size_selex_parms))),
                                                                grep(i,rownames(mod$ctl$size_selex_parms))[c(1,3,4,6,2)]),]) #only output 5 parameters. Use P_2 for the fifth parameter name
}
#male parm 1 added to female parm 1. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_1", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-25, 25, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 2 added to female parm 3. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_3", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-9, 9, 0, 0, 50, 0, 5, 0, 0), each = length(maleFleets))

#male parm 3 added to female parm 4. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_4", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-9, 9, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 4 added to female parm 6. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_6", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-99, 99, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 5 is a scalar to apical selectivity AND descending limb (rescales the whole thing). Use 1 for no change
#search for P_2 for this because I arbitrarily copied the parm2 line for the 5th male parameter
mod$ctl$size_selex_parms[intersect(grep("_P_2", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(0, 2, 1, 1, 50, 0, -99, 0, 0), each = length(maleFleets))


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:18)])

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

####------------------------------------------------####
### 4_4_3_sexSelex4 Set up sex specific selectivity for parm 4  ----
####------------------------------------------------####

new_name <- "4_4_3_sexSelex_4_AllFleets"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_1_6_survey_domed'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

#Pick fleets want to have an offset for. Here we are doing all
maleFleets <- rownames(mod$ctl$size_selex_types[mod$ctl$size_selex_types$Pattern == 24, ]) 
#Male offset from female (using option 4 (female offset from male) makes no difference)
mod$ctl$size_selex_types[maleFleets, "Male"] <- 3

for(i in maleFleets){
  ifelse(i != tail(maleFleets,1),
         mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[c(1:max(grep(i,rownames(mod$ctl$size_selex_parms))),
                                                                grep(i,rownames(mod$ctl$size_selex_parms))[c(1,3,4,6,2)], #only output 5 parameters. Use P_2 for the fifth parameter name
                                                                (max(grep(i, rownames(mod$ctl$size_selex_parms)))+1):
                                                                  length(rownames(mod$ctl$size_selex_parms))),],
         mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[c(1:max(grep(i,rownames(mod$ctl$size_selex_parms))),
                                                                grep(i,rownames(mod$ctl$size_selex_parms))[c(1,3,4,6,2)]),]) #only output 5 parameters. Use P_2 for the fifth parameter name
}
#male parm 1 added to female parm 1. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_1", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-25, 25, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 2 added to female parm 3. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_3", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-9, 9, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 3 added to female parm 4. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_4", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-9, 9, 0, 0, 50, 0, 5, 0, 0), each = length(maleFleets))

#male parm 4 added to female parm 6. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_6", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-99, 99, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 5 is a scalar to apical selectivity AND descending limb (rescales the whole thing). Use 1 for no change
#search for P_2 for this because I arbitrarily copied the parm2 line for the 5th male parameter
mod$ctl$size_selex_parms[intersect(grep("_P_2", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(0, 2, 1, 1, 50, 0, -99, 0, 0), each = length(maleFleets))


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:18)])

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('3_1_6_survey_domed',
                                                 '4_3_1_M_ramp',
                                                 '4_3_2_M_breakpoint',
                                                 '4_4_3_sexSelex_4_AllFleets')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Constant M',
                                     'M ramp (historical)',
                                     'M breakpoint',
                                     'Sex dependent selex descending'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 4_4_4_sexSelex6 Set up sex specific selectivity for parm 6  ----
####------------------------------------------------####

new_name <- "4_4_4_sexSelex_6_AllFleets"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_1_6_survey_domed'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

#Pick fleets want to have an offset for. Here we are doing all
maleFleets <- rownames(mod$ctl$size_selex_types[mod$ctl$size_selex_types$Pattern == 24, ]) 
#Male offset from female (using option 4 (female offset from male) makes no difference)
mod$ctl$size_selex_types[maleFleets, "Male"] <- 3

for(i in maleFleets){
  ifelse(i != tail(maleFleets,1),
         mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[c(1:max(grep(i,rownames(mod$ctl$size_selex_parms))),
                                                                grep(i,rownames(mod$ctl$size_selex_parms))[c(1,3,4,6,2)], #only output 5 parameters. Use P_2 for the fifth parameter name
                                                                (max(grep(i, rownames(mod$ctl$size_selex_parms)))+1):
                                                                  length(rownames(mod$ctl$size_selex_parms))),],
         mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[c(1:max(grep(i,rownames(mod$ctl$size_selex_parms))),
                                                                grep(i,rownames(mod$ctl$size_selex_parms))[c(1,3,4,6,2)]),]) #only output 5 parameters. Use P_2 for the fifth parameter name
}
#male parm 1 added to female parm 1. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_1", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-25, 25, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 2 added to female parm 3. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_3", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-9, 9, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 3 added to female parm 4. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_4", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-9, 9, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 4 added to female parm 6. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_6", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-99, 99, 0, 0, 50, 0, 5, 0, 0), each = length(maleFleets))

#male parm 5 is a scalar to apical selectivity AND descending limb (rescales the whole thing). Use 1 for no change
#search for P_2 for this because I arbitrarily copied the parm2 line for the 5th male parameter
mod$ctl$size_selex_parms[intersect(grep("_P_2", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(0, 2, 1, 1, 50, 0, -99, 0, 0), each = length(maleFleets))


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:18)])

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

####------------------------------------------------####
### 4_4_5_sexSelexApical Set up sex specific selectivity for scaling  ----
####------------------------------------------------####

new_name <- "4_4_5_sexSelex_Apical_AllFleets"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_1_6_survey_domed'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

#Pick fleets want to have an offset for. Here we are doing all
maleFleets <- rownames(mod$ctl$size_selex_types[mod$ctl$size_selex_types$Pattern == 24, ]) 
#Use female offset from male (using option 3 makes a difference)
mod$ctl$size_selex_types[maleFleets, "Male"] <- 4

for(i in maleFleets){
  ifelse(i != tail(maleFleets,1),
         mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[c(1:max(grep(i,rownames(mod$ctl$size_selex_parms))),
                                                                grep(i,rownames(mod$ctl$size_selex_parms))[c(1,3,4,6,2)], #only output 5 parameters. Use P_2 for the fifth parameter name
                                                                (max(grep(i, rownames(mod$ctl$size_selex_parms)))+1):
                                                                  length(rownames(mod$ctl$size_selex_parms))),],
         mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[c(1:max(grep(i,rownames(mod$ctl$size_selex_parms))),
                                                                grep(i,rownames(mod$ctl$size_selex_parms))[c(1,3,4,6,2)]),]) #only output 5 parameters. Use P_2 for the fifth parameter name
}
#male parm 1 added to female parm 1. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_1", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-25, 25, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 2 added to female parm 3. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_3", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-9, 9, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 3 added to female parm 4. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_4", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-9, 9, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 4 added to female parm 6. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_6", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-99, 99, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 5 is a scalar to apical selectivity AND descending limb (rescales the whole thing). Use 1 for no change
#search for P_2 for this because I arbitrarily copied the parm2 line for the 5th male parameter
mod$ctl$size_selex_parms[intersect(grep("_P_2", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(0, 2, 1, 1, 50, 0, 5, 0, 0), each = length(maleFleets))


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:18)])

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)


####------------------------------------------------####
### 4_4_6_sexSelexAll Set up sex specific selectivity for all male parameters  ----
####------------------------------------------------####

new_name <- "4_4_6_sexSelex_All_AllFleets"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_1_6_survey_domed'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

#Pick fleets want to have an offset for. Here we are doing all
maleFleets <- rownames(mod$ctl$size_selex_types[mod$ctl$size_selex_types$Pattern == 24, ]) 
#Female offset from male (using option 3 doesn't make a difference but for apical this makes more sense)
mod$ctl$size_selex_types[maleFleets, "Male"] <- 4

for(i in maleFleets){
  ifelse(i != tail(maleFleets,1),
         mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[c(1:max(grep(i,rownames(mod$ctl$size_selex_parms))),
                                                                grep(i,rownames(mod$ctl$size_selex_parms))[c(1,3,4,6,2)], #only output 5 parameters. Use P_2 for the fifth parameter name
                                                                (max(grep(i, rownames(mod$ctl$size_selex_parms)))+1):
                                                                  length(rownames(mod$ctl$size_selex_parms))),],
         mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[c(1:max(grep(i,rownames(mod$ctl$size_selex_parms))),
                                                                grep(i,rownames(mod$ctl$size_selex_parms))[c(1,3,4,6,2)]),]) #only output 5 parameters. Use P_2 for the fifth parameter name
}
#male parm 1 added to female parm 1. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_1", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-25, 25, 0, 0, 50, 0, 4, 0, 0), each = length(maleFleets))

#male parm 2 added to female parm 3. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_3", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-9, 9, 0, 0, 50, 0, 5, 0, 0), each = length(maleFleets))

#male parm 3 added to female parm 4. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_4", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-9, 9, 0, 0, 50, 0, 5, 0, 0), each = length(maleFleets))

#male parm 4 added to female parm 6. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_6", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-99, 99, 0, 0, 50, 0, 5, 0, 0), each = length(maleFleets))

#male parm 5 is a scalar to apical selectivity AND descending limb (rescales the whole thing). Use 1 for no change
#search for P_2 for this because I arbitrarily copied the parm2 line for the 5th male parameter
mod$ctl$size_selex_parms[intersect(grep("_P_2", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(0, 2, 1, 1, 50, 0, 5, 0, 0), each = length(maleFleets))


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:18)])

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)


xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('3_1_6_survey_domed',
                                                 '4_4_1_sexSelex_1_AllFleets',
                                                 '4_4_2_sexSelex_3_AllFleets',
                                                 '4_4_3_sexSelex_4_AllFleets',
                                                 '4_4_4_sexSelex_6_AllFleets',
                                                 '4_4_5_sexSelex_Apical_AllFleets',
                                                 '4_4_5_sexSelex_Apical_AllFleets_3',
                                                 '4_4_6_sexSelex_All_AllFleets',
                                                 '4_4_6_sexSelex_All_AllFleets_3')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c("model 3_1_6",
                                     'Selex parm 1 sex specific',
                                     'Selex parm 3 sex specific',
                                     'Selex parm 4 sex specific',
                                     'Selex parm 6 sex specific',
                                     'Apical selex sex specific Mal offset',
                                     'Apical selex sex specific Fem offset',
                                     'All selex parm sex specific Mal offset',
                                     'All selex parm sex specific Fem offset'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


pp_0 <- SS_output(here('models','3_1_6_survey_domed'))
pp_1 <- SS_output(here('models','4_4_1_sexSelex_1_AllFleets'))
pp_4 <- SS_output(here('models','4_4_3_sexSelex_4_AllFleets'))
pp_all <- SS_output(here('models','4_4_6_sexSelex_All_AllFleets_3'))

like_compare <- cbind(pp_0$likelihoods_used, "one" = pp_1$likelihoods_used$values, "four" = pp_4$likelihoods_used$values, "all" = pp_4$likelihoods_used$values)
like_compare$diff_from0 = round(like_compare$values - like_compare[c("one","four","all")]) #improving age comps then length, poorer survey index
pp_0$likelihoods_by_fleet[pp_0$likelihoods_by_fleet$Label %in% c("Length_like","Age_like"), -1] - 
  pp_4$likelihoods_by_fleet[pp_4$likelihoods_by_fleet$Label %in% c("Length_like","Age_like"), -1]
#Comps are better fit parm 4 as sex dependent. Length and age comps are much improved


####------------------------------------------------####
### 4_5_1_blocks_Mramp Revisiting additional blocks for M ramp ----
####------------------------------------------------####

new_name <- "4_5_1_blocks_Mramp"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_3_1_M_ramp_update'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

### Update blocks ----
mod$ctl$N_Block_Designs <- 5
mod$ctl$blocks_per_pattern <- c(2,2,2,2,2)
names(mod$ctl$blocks_per_pattern) <- paste0("blocks_per_pattern_",1:mod$ctl$N_Block_Designs)

#Update blocks. Blocking for NTWL is tricky. Right now have WA NTWL to WA TWL mirrored but could unmirror
#Keeping 2000 block instead of 2001 since the data seems to suggest change there (also same as last assessment)
mod$ctl$Block_Design <- list(c(2000, 2010, 2011, 2022), #TWL fleets
                             c(2000, 2019, 2020, 2022), #CA/OR ntwl
                             c(2004, 2016, 2017, 2022), #CA rec
                             c(2004, 2014, 2015, 2022), #OR rec
                             c(2006, 2020, 2021, 2022)) #WA rec

### Update selectivity parameter table matching Jim's parameters setup ----

selex_new <- mod$ctl$size_selex_parms

# Use new block set up
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 1
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2

selex_new[grepl('CA_NTWL|OR_NTWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block', 'Block_Fxn')] <- 2
#WA NTWL is set to mirror WA TWL due to better aggregate match. 

selex_new[grepl('CA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 3
selex_new[grepl('CA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2
selex_new[grepl('OR_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 4
selex_new[grepl('OR_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2
selex_new[grepl('WA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 5
selex_new[grepl('WA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2

mod$ctl$size_selex_parms <- selex_new

### Time varying selectivity table ----
selex_tv_pars <- dplyr::filter(selex_new, Block > 0) |>
  dplyr::select(LO, HI, INIT, PRIOR, PR_SD, PR_type, PHASE, Block) |>
  tidyr::uncount(mod$ctl$blocks_per_pattern[Block], .id = 'id', .remove = FALSE)

rownames(selex_tv_pars) <- rownames(selex_tv_pars) |>
  stringr::str_remove('\\.\\.\\.[:digit:]+') |>
  stringr::str_c('_BLK', selex_tv_pars$Block, 'repl_', mapply("[",mod$ctl$Block_Design[selex_tv_pars$Block], selex_tv_pars$id * 2 - 1))

mod$ctl$size_selex_parms_tv <- selex_tv_pars |>
  dplyr::select(-Block, -id)

##
#Output files and run run with hessian
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

dev.off()
plot_sel_comm(pp)
plot_sel_noncomm(pp, spatial = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('4_3_1_M_ramp_update',
                                                 '4_6_1_blocks_Mramp')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('M_ramp',
                                     'Update blocks'),
                    subplots = c(1,3,9,11), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 4_5_2_blocks_selex4 Revisiting additional blocks for sex specific selectivity ----
####------------------------------------------------####

new_name <- "4_5_2_blocks_selex4"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_4_3_sexSelex_4_AllFleets'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make Changes
##

### Update blocks ----
mod$ctl$N_Block_Designs <- 5
mod$ctl$blocks_per_pattern <- c(2,2,2,2,2)
names(mod$ctl$blocks_per_pattern) <- paste0("blocks_per_pattern_",1:mod$ctl$N_Block_Designs)

#Update blocks. Blocking for NTWL is tricky. Right now have WA NTWL to WA TWL mirrored but could unmirror
#Keeping 2000 block instead of 2001 since the data seems to suggest change there (also same as last assessment)
mod$ctl$Block_Design <- list(c(2000, 2010, 2011, 2022), #TWL fleets
                             c(2000, 2019, 2020, 2022), #CA/OR ntwl
                             c(2004, 2016, 2017, 2022), #CA rec
                             c(2004, 2014, 2015, 2022), #OR rec
                             c(2006, 2020, 2021, 2022)) #WA rec

### Update selectivity parameter table matching Jim's parameters setup ----

selex_new <- mod$ctl$size_selex_parms

# Use new block set up
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 1
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2

selex_new[grepl('CA_NTWL|OR_NTWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block', 'Block_Fxn')] <- 2
#WA NTWL is set to mirror WA TWL due to better aggregate match. 

selex_new[grepl('CA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 3
selex_new[grepl('CA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2
selex_new[grepl('OR_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 4
selex_new[grepl('OR_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2
selex_new[grepl('WA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 5
selex_new[grepl('WA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2

mod$ctl$size_selex_parms <- selex_new

### Time varying selectivity table ----
selex_tv_pars <- dplyr::filter(selex_new, Block > 0) |>
  dplyr::select(LO, HI, INIT, PRIOR, PR_SD, PR_type, PHASE, Block) |>
  tidyr::uncount(mod$ctl$blocks_per_pattern[Block], .id = 'id', .remove = FALSE)

rownames(selex_tv_pars) <- rownames(selex_tv_pars) |>
  stringr::str_remove('\\.\\.\\.[:digit:]+') |>
  stringr::str_c('_BLK', selex_tv_pars$Block, 'repl_', mapply("[",mod$ctl$Block_Design[selex_tv_pars$Block], selex_tv_pars$id * 2 - 1))

mod$ctl$size_selex_parms_tv <- selex_tv_pars |>
  dplyr::select(-Block, -id)

##
#Output files and run run with hessian
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('4_4_3_sexSelex_4_AllFleets',
                                                 '4_5_2_blocks_selex4')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Selex 4',
                                     'Update blocks'),
                    subplots = c(1,3,9,11), print = TRUE, plotdir = here('models',new_name))


pp_noblock <- SS_output(here('models','4_4_3_sexSelex_4_AllFleets'))
pp_block <- SS_output(here('models','4_5_2_blocks_selex4'))

like_compare <- cbind(pp_noblock$likelihoods_used, "block" = pp_block$likelihoods_used$values)
like_compare$diff = round(like_compare$values - like_compare$block) #improving age comps then length, poorer survey index
pp_noblock$likelihoods_by_fleet[pp_noblock$likelihoods_by_fleet$Label %in% c("Length_like","Age_like"), -1] - 
  pp_block$likelihoods_by_fleet[pp_block$likelihoods_by_fleet$Label %in% c("Length_like","Age_like"), -1]
#Comps are better fit parm 4 as sex dependent. Length and age comps are much improved
#Improvement is mostly with the rec fleets. Trawl and survey are generally poorer fitting

xx <- r4ss::tune_comps(replist = pp_block, 
                       option = 'Francis', 
                       dir = here('models', new_name), 
                       exe = here('models/ss_win.exe'), 
                       niters_tuning = 0, 
                       extras = '-nohess',
                       allow_up_tuning = TRUE)

################

#Repeat the process from models 4_4_X but with copying model 4_3_1_M_ramp_update. Only use male = 3
################

####------------------------------------------------####
### 4_6_1_sexSelex1 Set up sex specific selectivity for parm 1  ----
####------------------------------------------------####

new_name <- "4_6_1_MrampsexSelex_1_AllFleets"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_3_1_M_ramp_update'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

#Pick fleets want to have an offset for. Here we are doing all
maleFleets <- rownames(mod$ctl$size_selex_types[mod$ctl$size_selex_types$Pattern == 24, ]) 
#Male offset from female (using option 4 (female offset from male) makes no difference)
mod$ctl$size_selex_types[maleFleets, "Male"] <- 3

for(i in maleFleets){
  ifelse(i != tail(maleFleets,1),
         mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[c(1:max(grep(i,rownames(mod$ctl$size_selex_parms))),
                                                                grep(i,rownames(mod$ctl$size_selex_parms))[c(1,3,4,6,2)], #only output 5 parameters. Use P_2 for the fifth parameter name
                                                                (max(grep(i, rownames(mod$ctl$size_selex_parms)))+1):
                                                                  length(rownames(mod$ctl$size_selex_parms))),],
         mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[c(1:max(grep(i,rownames(mod$ctl$size_selex_parms))),
                                                                grep(i,rownames(mod$ctl$size_selex_parms))[c(1,3,4,6,2)]),]) #only output 5 parameters. Use P_2 for the fifth parameter name
}
#male parm 1 added to female parm 1. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_1", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-25, 25, 0, 0, 50, 0, 4, 0, 0), each = length(maleFleets))

#male parm 2 added to female parm 3. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_3", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-9, 9, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 3 added to female parm 4. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_4", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-9, 9, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 4 added to female parm 6. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_6", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-99, 99, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 5 is a scalar to apical selectivity AND descending limb (rescales the whole thing). Use 1 for no change
#search for P_2 for this because I arbitrarily copied the parm2 line for the 5th male parameter
mod$ctl$size_selex_parms[intersect(grep("_P_2", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(0, 2, 1, 1, 50, 0, -99, 0, 0), each = length(maleFleets))


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)


####------------------------------------------------####
### 4_6_2_sexSelex3 Set up sex specific selectivity for parm 3  ----
####------------------------------------------------####

new_name <- "4_6_2_MrampsexSelex_3_AllFleets"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_3_1_M_ramp_update'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

#Pick fleets want to have an offset for. Here we are doing all
maleFleets <- rownames(mod$ctl$size_selex_types[mod$ctl$size_selex_types$Pattern == 24, ]) 
#Male offset from female (using option 4 (female offset from male) makes no difference)
mod$ctl$size_selex_types[maleFleets, "Male"] <- 3

for(i in maleFleets){
  ifelse(i != tail(maleFleets,1),
         mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[c(1:max(grep(i,rownames(mod$ctl$size_selex_parms))),
                                                                grep(i,rownames(mod$ctl$size_selex_parms))[c(1,3,4,6,2)], #only output 5 parameters. Use P_2 for the fifth parameter name
                                                                (max(grep(i, rownames(mod$ctl$size_selex_parms)))+1):
                                                                  length(rownames(mod$ctl$size_selex_parms))),],
         mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[c(1:max(grep(i,rownames(mod$ctl$size_selex_parms))),
                                                                grep(i,rownames(mod$ctl$size_selex_parms))[c(1,3,4,6,2)]),]) #only output 5 parameters. Use P_2 for the fifth parameter name
}
#male parm 1 added to female parm 1. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_1", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-25, 25, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 2 added to female parm 3. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_3", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-9, 9, 0, 0, 50, 0, 5, 0, 0), each = length(maleFleets))

#male parm 3 added to female parm 4. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_4", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-9, 9, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 4 added to female parm 6. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_6", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-99, 99, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 5 is a scalar to apical selectivity AND descending limb (rescales the whole thing). Use 1 for no change
#search for P_2 for this because I arbitrarily copied the parm2 line for the 5th male parameter
mod$ctl$size_selex_parms[intersect(grep("_P_2", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(0, 2, 1, 1, 50, 0, -99, 0, 0), each = length(maleFleets))


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

####------------------------------------------------####
### 4_6_3_sexSelex4 Set up sex specific selectivity for parm 4  ----
####------------------------------------------------####

new_name <- "4_6_3_MrampsexSelex_4_AllFleets"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_3_1_M_ramp_update'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

#Pick fleets want to have an offset for. Here we are doing all
maleFleets <- rownames(mod$ctl$size_selex_types[mod$ctl$size_selex_types$Pattern == 24, ]) 
#Male offset from female (using option 4 (female offset from male) makes no difference)
mod$ctl$size_selex_types[maleFleets, "Male"] <- 3

for(i in maleFleets){
  ifelse(i != tail(maleFleets,1),
         mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[c(1:max(grep(i,rownames(mod$ctl$size_selex_parms))),
                                                                grep(i,rownames(mod$ctl$size_selex_parms))[c(1,3,4,6,2)], #only output 5 parameters. Use P_2 for the fifth parameter name
                                                                (max(grep(i, rownames(mod$ctl$size_selex_parms)))+1):
                                                                  length(rownames(mod$ctl$size_selex_parms))),],
         mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[c(1:max(grep(i,rownames(mod$ctl$size_selex_parms))),
                                                                grep(i,rownames(mod$ctl$size_selex_parms))[c(1,3,4,6,2)]),]) #only output 5 parameters. Use P_2 for the fifth parameter name
}
#male parm 1 added to female parm 1. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_1", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-25, 25, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 2 added to female parm 3. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_3", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-9, 9, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 3 added to female parm 4. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_4", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-9, 9, 0, 0, 50, 0, 5, 0, 0), each = length(maleFleets))

#male parm 4 added to female parm 6. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_6", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-99, 99, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 5 is a scalar to apical selectivity AND descending limb (rescales the whole thing). Use 1 for no change
#search for P_2 for this because I arbitrarily copied the parm2 line for the 5th male parameter
mod$ctl$size_selex_parms[intersect(grep("_P_2", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(0, 2, 1, 1, 50, 0, -99, 0, 0), each = length(maleFleets))


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)


xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('3_1_6_survey_domed',
                                                 '4_4_3_sexSelex_4_AllFleets',
                                                 '4_3_1_M_ramp_update',
                                                 '4_6_3_MrampsexSelex_4_AllFleets')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c("model 3_1_6",
                                     'Selex parm 4 sex specific',
                                     "model 4_3_1 Mramp",
                                     'Mramp Selex parm 4 sex specific'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))

####------------------------------------------------####
### 4_6_4_sexSelex6 Set up sex specific selectivity for parm 6  ----
####------------------------------------------------####

new_name <- "4_6_4_MrampsexSelex_6_AllFleets"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_3_1_M_ramp_update'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

#Pick fleets want to have an offset for. Here we are doing all
maleFleets <- rownames(mod$ctl$size_selex_types[mod$ctl$size_selex_types$Pattern == 24, ]) 
#Male offset from female (using option 4 (female offset from male) makes no difference)
mod$ctl$size_selex_types[maleFleets, "Male"] <- 3

for(i in maleFleets){
  ifelse(i != tail(maleFleets,1),
         mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[c(1:max(grep(i,rownames(mod$ctl$size_selex_parms))),
                                                                grep(i,rownames(mod$ctl$size_selex_parms))[c(1,3,4,6,2)], #only output 5 parameters. Use P_2 for the fifth parameter name
                                                                (max(grep(i, rownames(mod$ctl$size_selex_parms)))+1):
                                                                  length(rownames(mod$ctl$size_selex_parms))),],
         mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[c(1:max(grep(i,rownames(mod$ctl$size_selex_parms))),
                                                                grep(i,rownames(mod$ctl$size_selex_parms))[c(1,3,4,6,2)]),]) #only output 5 parameters. Use P_2 for the fifth parameter name
}
#male parm 1 added to female parm 1. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_1", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-25, 25, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 2 added to female parm 3. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_3", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-9, 9, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 3 added to female parm 4. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_4", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-9, 9, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 4 added to female parm 6. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_6", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-99, 99, 0, 0, 50, 0, 5, 0, 0), each = length(maleFleets))

#male parm 5 is a scalar to apical selectivity AND descending limb (rescales the whole thing). Use 1 for no change
#search for P_2 for this because I arbitrarily copied the parm2 line for the 5th male parameter
mod$ctl$size_selex_parms[intersect(grep("_P_2", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(0, 2, 1, 1, 50, 0, -99, 0, 0), each = length(maleFleets))


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

####------------------------------------------------####
### 4_6_5_sexSelexApical Set up sex specific selectivity for scaling  ----
####------------------------------------------------####

new_name <- "4_6_5_MrampsexSelex_Apical_AllFleets_3"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_6_1_M_ramp_update'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

#Pick fleets want to have an offset for. Here we are doing all
maleFleets <- rownames(mod$ctl$size_selex_types[mod$ctl$size_selex_types$Pattern == 24, ]) 
#Use female offset from male (using option 3 makes a difference)
mod$ctl$size_selex_types[maleFleets, "Male"] <- 3

for(i in maleFleets){
  ifelse(i != tail(maleFleets,1),
         mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[c(1:max(grep(i,rownames(mod$ctl$size_selex_parms))),
                                                                grep(i,rownames(mod$ctl$size_selex_parms))[c(1,3,4,6,2)], #only output 5 parameters. Use P_2 for the fifth parameter name
                                                                (max(grep(i, rownames(mod$ctl$size_selex_parms)))+1):
                                                                  length(rownames(mod$ctl$size_selex_parms))),],
         mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[c(1:max(grep(i,rownames(mod$ctl$size_selex_parms))),
                                                                grep(i,rownames(mod$ctl$size_selex_parms))[c(1,3,4,6,2)]),]) #only output 5 parameters. Use P_2 for the fifth parameter name
}
#male parm 1 added to female parm 1. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_1", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-25, 25, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 2 added to female parm 3. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_3", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-9, 9, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 3 added to female parm 4. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_4", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-9, 9, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 4 added to female parm 6. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_6", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-99, 99, 0, 0, 50, 0, -99, 0, 0), each = length(maleFleets))

#male parm 5 is a scalar to apical selectivity AND descending limb (rescales the whole thing). Use 1 for no change
#search for P_2 for this because I arbitrarily copied the parm2 line for the 5th male parameter
mod$ctl$size_selex_parms[intersect(grep("_P_2", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(0, 2, 1, 1, 50, 0, 5, 0, 0), each = length(maleFleets))


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)


####------------------------------------------------####
### 4_6_6_sexSelexAll Set up sex specific selectivity for all male parameters  ----
####------------------------------------------------####

new_name <- "4_6_6_MrampsexSelex_All_AllFleets_3"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_3_1_M_ramp_update'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

#Pick fleets want to have an offset for. Here we are doing all
maleFleets <- rownames(mod$ctl$size_selex_types[mod$ctl$size_selex_types$Pattern == 24, ]) 
#Female offset from male (using option 3 doesn't make a difference but for apical this makes more sense)
mod$ctl$size_selex_types[maleFleets, "Male"] <- 3

for(i in maleFleets){
  ifelse(i != tail(maleFleets,1),
         mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[c(1:max(grep(i,rownames(mod$ctl$size_selex_parms))),
                                                                grep(i,rownames(mod$ctl$size_selex_parms))[c(1,3,4,6,2)], #only output 5 parameters. Use P_2 for the fifth parameter name
                                                                (max(grep(i, rownames(mod$ctl$size_selex_parms)))+1):
                                                                  length(rownames(mod$ctl$size_selex_parms))),],
         mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[c(1:max(grep(i,rownames(mod$ctl$size_selex_parms))),
                                                                grep(i,rownames(mod$ctl$size_selex_parms))[c(1,3,4,6,2)]),]) #only output 5 parameters. Use P_2 for the fifth parameter name
}
#male parm 1 added to female parm 1. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_1", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-25, 25, 0, 0, 50, 0, 4, 0, 0), each = length(maleFleets))

#male parm 2 added to female parm 3. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_3", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-9, 9, 0, 0, 50, 0, 5, 0, 0), each = length(maleFleets))

#male parm 3 added to female parm 4. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_4", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-9, 9, 0, 0, 50, 0, 5, 0, 0), each = length(maleFleets))

#male parm 4 added to female parm 6. Use 0 for no change
mod$ctl$size_selex_parms[intersect(grep("_P_6", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(-99, 99, 0, 0, 50, 0, 5, 0, 0), each = length(maleFleets))

#male parm 5 is a scalar to apical selectivity AND descending limb (rescales the whole thing). Use 1 for no change
#search for P_2 for this because I arbitrarily copied the parm2 line for the 5th male parameter
mod$ctl$size_selex_parms[intersect(grep("_P_2", rownames(mod$ctl$size_selex_parms)),
                                   grep(").1", rownames(mod$ctl$size_selex_parms))),
                         c("LO", "HI", "INIT", "PRIOR", "PR_SD", "PR_type", "PHASE", "Block", "Block_Fxn")] <-
  rep(c(0, 2, 1, 1, 50, 0, 5, 0, 0), each = length(maleFleets))


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)


xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('4_3_1_M_ramp_update',
                                                 '4_6_1_MrampsexSelex_1_AllFleets',
                                                 '4_6_2_MrampsexSelex_3_AllFleets',
                                                 '4_6_3_MrampsexSelex_4_AllFleets',
                                                 '4_6_4_MrampsexSelex_6_AllFleets',
                                                 '4_6_5_MrampsexSelex_Apical_AllFleets_3',
                                                 '4_6_6_MrampsexSelex_All_AllFleets_3')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c("model 4_3_1",
                                     'Selex parm 1 sex specific',
                                     'Selex parm 3 sex specific',
                                     'Selex parm 4 sex specific',
                                     'Selex parm 6 sex specific',
                                     'Apical selex sex specific',
                                     'All selex parm sex specific'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


pp_0 <- SS_output(here('models','4_3_1_M_ramp_update'))
pp_1 <- SS_output(here('models','4_6_1_MrampsexSelex_1_AllFleets'))
pp_4 <- SS_output(here('models','4_6_3_MrampsexSelex_4_AllFleets'))
pp_all <- SS_output(here('models','4_6_6_MrampsexSelex_All_AllFleets_3'))

like_compare <- cbind(pp_0$likelihoods_used, "one" = pp_1$likelihoods_used$values, "four" = pp_4$likelihoods_used$values, "all" = pp_4$likelihoods_used$values)
like_compare$diff_from0 = round(like_compare$values - like_compare[c("one","four","all")]) #improving age comps then length, poorer survey index
pp_0$likelihoods_by_fleet[pp_0$likelihoods_by_fleet$Label %in% c("Length_like","Age_like"), -1] - 
  pp_4$likelihoods_by_fleet[pp_4$likelihoods_by_fleet$Label %in% c("Length_like","Age_like"), -1]
#Same thing. Four changes most and is similar to all. With all the combo survey selex is weird. Go with 4. 
#Compared to constant M model with sex-dependent selectivity (4_4_3), the likelihood is higher/poorer. 


####------------------------------------------------####
### 4_7_1_tune452 Tune model 4_5_2  ----
####------------------------------------------------####

new_name <- "4_7_1_tune452"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_5_2_blocks_selex4'),
               dir.new = here('models',new_name),
               overwrite = TRUE)
file.copy(from = file.path(here('models/4_5_2_blocks_selex4'),"Report.sso"),
          to = file.path(here('models',new_name),"Report.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/4_5_2_blocks_selex4'),"CompReport.sso"),
          to = file.path(here('models',new_name),"CompReport.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/4_5_2_blocks_selex4'),"warning.sso"),
          to = file.path(here('models',new_name),"warning.sso"), overwrite = TRUE)

mod.out <- SS_output(here('models', new_name))
xx <- r4ss::tune_comps(replist = mod.out, 
                       option = 'Francis', 
                       dir = here('models', new_name), 
                       exe = here('models/ss_win.exe'), 
                       niters_tuning = 4, 
                       extras = '-nohess',
                       allow_up_tuning = TRUE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('4_4_3_sexSelex_4_AllFleets',
                                                 '4_5_2_blocks_selex4',
                                                 '4_7_1_tune452')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Sex dependent selex descending',
                                     'Updated blocks',
                                     'Retuned'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))

#Changes NTWL and REC weightings mostly, which is as expected.

#Check that var adjust are not more than number of fish.
upwgt <- mod$ctl$Variance_adjustment_list[which(mod$ctl$Variance_adjustment_list$Value>1),]
#mod$dat$lencomp[mod$dat$lencomp$FltSvy %in% c(upwgt[upwgt$Data_type==4,"Fleet"]),]
#mod$dat$agecomp[mod$dat$agecomp$FltSvy %in% c(upwgt[upwgt$Data_type==5,"Fleet"]),]

#For oregon ntwl positive years comps are fine with upweight of 1.7  
#For washington ntwl lengths positive years comps are close with upweight of 3.12 (for one year the 
#number is 3 and Ninput is 1 so that would be higher)
#For washington ntwl ages positive years comps are fine with upweight of 1.3 (for one year of sample size = 1
#is would be above)
#For oregon rec ages upweight of 1.15 is fine
#For california trawl ages, upweight of 2 results is more than Nsamples for two years (where N = 1, upweight = 2; 
#and N = 12, upweight = 14)
#All together I would not say this is a huge issue. 


####------------------------------------------------####
### 4_8_1_mirrorORWA_twl Mirror trawl for oregon and washington  ----
####------------------------------------------------####

new_name <- "4_8_1_mirrorORWA_twl"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_7_1_tune452'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make changes
##

#Mirror WA TWL to OR TWL
mod$ctl$size_selex_types["3_WA_TWL", c("Pattern", "Male", "Special")] <- c(15, 0, 2)

#Remove WA TWL selex parms
mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[-grep("_WA_TWL", rownames(mod$ctl$size_selex_parms)), ]

#Remove WA TWL from time-varying 

mod$ctl$size_selex_parms_tv <- mod$ctl$size_selex_parms_tv[-grep("_WA_TWL", rownames(mod$ctl$size_selex_parms_tv)), ]


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('4_7_1_tune452',
                                                 '4_8_1_mirrorORWA_twl')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Tuned model',
                                     'Mirror OR/WA trawl'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))

pp_0 <- SS_output(here('models','4_7_1_tune452'))
pp_1 <- SS_output(here('models','4_8_1_mirrorORWA_twl'))

like_compare <- cbind(pp_0$likelihoods_used, "mir" = pp_1$likelihoods_used$values)
like_compare$diff_from0 = round(like_compare$values - like_compare[,c("mir")]) #improving age comps then length, poorer survey index
pp_0$likelihoods_by_fleet[pp_0$likelihoods_by_fleet$Label %in% c("Length_like","Age_like"), -1] - 
  pp_1$likelihoods_by_fleet[pp_1$likelihoods_by_fleet$Label %in% c("Length_like","Age_like"), -1]
#Improves length comps for OR TWL but not age comps. Improve WA TWL (because less influence of WA NTWL)
#Overall poorer fit by 60 units for 12 less parameters. 

#Need to first unmirror WA_NTWL with WA_TWL and then run this test. 


####------------------------------------------------####
### 4_8_2_unmirrorWA_ntwl Unmirror WA NTWL from TWL  ----
####------------------------------------------------####

new_name <- "4_8_2_unmirrorWA_ntwl"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_7_1_tune452'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)


##
#Make changes
##

#For whatever reason I could not get this to output, so I did the changes manually

# #Unmirror WA NTWL
# #Currently not setting a block. Likely will fit recent years anyway
# mod$ctl$size_selex_types["6_WA_NTWL", c("Pattern", "Male", "Special")] <- c(24, 4, 0)
# 
# ### Set up selectivity parameter table ----
# 
# #Get names of all six parms for double normal
# selex_names <- purrr::map("6_WA_NTWL",
#                           ~ glue::glue('SizeSel_P_{par}_{fleet_name}({fleet_no})',
#                                        par = 1:6,
#                                        fleet_name = .x,
#                                        fleet_no = fleet.converter$fleet[fleet.converter$fleetname == .x])) |>
#   unlist()
# 
# #Set up new selectivity table
# selex_new <- matrix(0, nrow = length(selex_names), 
#                     ncol = ncol(mod$ctl$size_selex_parms), 
#                     dimnames = list(selex_names, names(mod$ctl$size_selex_parms))) |>
#   as.data.frame()
# 
# # default lo and hi
# selex_new$LO <- -99
# selex_new$HI <- 99
# 
# # No prior applied, so just need to fill in a number
# selex_new$PR_SD <- 99
# selex_new$PRIOR <- 99
# 
# # Fix three parameters of double normal initially
# selex_new$INIT[grep('P_2', rownames(selex_new))] <- -15
# selex_new$INIT[grep('P_5', rownames(selex_new))] <- -999
# selex_new$INIT[grep('P_6', rownames(selex_new))] <- -999
# selex_new$PHASE[grep('P_2', rownames(selex_new))] <- -99
# selex_new$PHASE[grep('P_5', rownames(selex_new))] <- -99
# selex_new$PHASE[grep('P_6', rownames(selex_new))] <- -99
# 
# # calculate initial values for p1, p3, p4 for each fleet
# # based on recommendations in assessment handbook
# selex_modes <- mod$dat$lencomp |>
#   dplyr::arrange(FltSvy) |>
#   dplyr::group_by(FltSvy) |>
#   dplyr::summarise(dplyr::across(f12:m66, ~ sum(Nsamp*.x)/sum(Nsamp))) |> 
#   tidyr::pivot_longer(cols = -FltSvy, names_to = 'len_bin', values_to = 'dens') |>
#   tidyr::separate(col = len_bin, into = c('sex', 'length'), sep = 1) |>
#   dplyr::group_by(FltSvy, sex) |> 
#   dplyr::summarise(mode = length[which.max(dens)]) |>
#   dplyr::summarise(mode = mean(as.numeric(mode))) |>
#   dplyr::mutate(asc.slope = log(8*(mode - min(mod$dat$lbin_vector))),
#                 desc.slope = log(8*(max(mod$dat$lbin_vector)-mode)))
# 
# # P_1
# p1.ind <- grep('P_1', rownames(selex_new))
# selex_new$LO[p1.ind] <- 13.001
# selex_new$HI[p1.ind] <- 65
# selex_new$PHASE[p1.ind] <- 4
# selex_new$INIT[p1.ind] <- selex_modes[selex_modes$FltSvy == 6,"mode"]
# 
# 
# # P_3
# p3.ind <- grep('P_3', rownames(selex_new))
# selex_new$PHASE[p3.ind] <- 5
# selex_new$LO[p3.ind] <- 0 #This can become negative, but effect is small compared to when 0
# selex_new$HI[p3.ind] <- 9
# selex_new$INIT[p3.ind] <- selex_modes[selex_modes$FltSvy == 6,"asc.slope"]
# 
# # P_4
# p4.ind <- grep('P_4', rownames(selex_new))
# selex_new$PHASE[p4.ind] <- 5
# selex_new$LO[p4.ind] <- 0 #This can become negative, but effect is small compared to when 0
# selex_new$HI[p4.ind] <- 9
# selex_new$INIT[p4.ind] <- selex_modes[selex_modes$FltSvy == 6,"desc.slope"]
# 
# #Add in new WA NTWL paramasters along with the female offset for descending limb
# mod$ctl$size_selex_parms <- rbind(mod$ctl$size_selex_parms[1:(min(grep("CA_REC",rownames(mod$ctl$size_selex_parms)))-1),], 
#   selex_new,
#   mod$ctl$size_selex_parms[grep("PFemOff_1_5_OR_NTWL",rownames(mod$ctl$size_selex_parms)):
#                              grep("PFemOff_5_5_OR_NTWL",rownames(mod$ctl$size_selex_parms)),],
#   mod$ctl$size_selex_parms[min(grep("CA_REC",rownames(mod$ctl$size_selex_parms))):length(rownames(mod$ctl$size_selex_parms)),])
# 
# #Set the new offsets to not have a block because copied from OR NTWL which did
# mod$ctl$size_selex_parms[
#   intersect(grep(")1",rownames(mod$ctl$size_selex_parms)),grep("_3",rownames(mod$ctl$size_selex_parms))),
#   c("Block","Block_Fxn")] <- 0


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('4_7_1_tune452',
                                                 '4_8_2_unmirrorWA_ntwl')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Tuned model',
                                     'Unmirror WA nontrawl'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))

xx <- r4ss::tune_comps(replist = pp, 
                       option = 'Francis', 
                       dir = here('models', new_name), 
                       exe = here('models/ss_win.exe'), 
                       niters_tuning = 0,
                       write = TRUE,
                       extras = '-nohess')

pp_0 <- SS_output(here('models','4_7_1_tune452'))
pp_1 <- SS_output(here('models','4_8_2_unmirrorWA_ntwl'))

like_compare <- cbind(pp_0$likelihoods_used, "unmir" = pp_1$likelihoods_used$values)
like_compare$diff_from0 = round(like_compare$values - like_compare[,c("unmir")]) #improving age comps then length, poorer survey index
pp_0$likelihoods_by_fleet[pp_0$likelihoods_by_fleet$Label %in% c("Length_like","Age_like"), -1] - 
  pp_1$likelihoods_by_fleet[pp_1$likelihoods_by_fleet$Label %in% c("Length_like","Age_like"), -1]


####------------------------------------------------####
### 4_8_3_tune482 Tune model 4_8_2 which is unmirroring WA NTWL  ----
####------------------------------------------------####

new_name <- "4_8_3_tune482"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_8_2_unmirrorWA_ntwl'),
               dir.new = here('models',new_name),
               overwrite = TRUE)
file.copy(from = file.path(here('models/4_8_2_unmirrorWA_ntwl'),"Report.sso"),
          to = file.path(here('models',new_name),"Report.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/4_8_2_unmirrorWA_ntwl'),"CompReport.sso"),
          to = file.path(here('models',new_name),"CompReport.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/4_8_2_unmirrorWA_ntwl'),"warning.sso"),
          to = file.path(here('models',new_name),"warning.sso"), overwrite = TRUE)

mod.out <- SS_output(here('models', new_name))
xx <- r4ss::tune_comps(replist = mod.out, 
                       option = 'Francis', 
                       dir = here('models', new_name), 
                       exe = here('models/ss_win.exe'), 
                       niters_tuning = 3, 
                       extras = '-nohess',
                       allow_up_tuning = TRUE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('4_7_1_tune452',
                                                 '4_8_2_unmirrorWA_ntwl',
                                                 '4_8_3_tune482')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Previously tuned: model_471',
                                     'Unmirrored WA NTWL',
                                     'Retuned unmirrored'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))

#Biggest change in francis weight values is downweighting WA NTWL as expected

####------------------------------------------------####
### 4_8_4_mirrorORWA_twl Mirror trawl for oregon and washington  ----
####------------------------------------------------####

new_name <- "4_8_4_mirrorORWA_twl"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_8_3_tune482'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make changes
##

#Mirror WA TWL to OR TWL
mod$ctl$size_selex_types["3_WA_TWL", c("Pattern", "Male", "Special")] <- c(15, 0, 2)

#Remove WA TWL selex parms
mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[-grep("_WA_TWL", rownames(mod$ctl$size_selex_parms)), ]

#Remove WA TWL from time-varying 

mod$ctl$size_selex_parms_tv <- mod$ctl$size_selex_parms_tv[-grep("_WA_TWL", rownames(mod$ctl$size_selex_parms_tv)), ]


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('4_8_3_tune482',
                                                 '4_8_4_mirrorORWA_twl')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Unmirrored WA nontrawl tuned',
                                     'and mirrored OR/WA trawl'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))

pp_0 <- SS_output(here('models','4_8_3_tune482'))
pp_1 <- SS_output(here('models','4_8_4_mirrorORWA_twl'))

like_compare <- cbind(pp_0$likelihoods_used, "mir" = pp_1$likelihoods_used$values)
like_compare$diff_from0 = round(like_compare$values - like_compare[,c("mir")]) #improving age comps then length, poorer survey index
pp_0$likelihoods_by_fleet[pp_0$likelihoods_by_fleet$Label %in% c("Length_like","Age_like"), -1] - 
  pp_1$likelihoods_by_fleet[pp_1$likelihoods_by_fleet$Label %in% c("Length_like","Age_like"), -1]

xx <- r4ss::tune_comps(replist = pp, 
                       option = 'Francis', 
                       dir = here('models', new_name), 
                       exe = here('models/ss_win.exe'), 
                       niters_tuning = 0, 
                       extras = '-nohess',
                       allow_up_tuning = TRUE)

####------------------------------------------------####
### 4_9_1_0agelambda Remove age comps by setting lambdas to 0  ----
####------------------------------------------------####

new_name <- "4_9_1_0agelambda"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_8_4_mirrorORWA_twl'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make changes
##

#Set up lambda dataframe for ages
fleetAge <- unique(mod$dat$agecomp$FltSvy)[unique(mod$dat$agecomp$FltSvy)>0]

mod$ctl$lambdas <- data.frame("like_comp" = 5, 
                              "fleet" = sort(fleetAge),
                              "phase" = 1,
                              "value" = 1,
                              "sizefreq_method" = 1)

rownames(mod$ctl$lambdas) = paste0("ages_",fleet.converter[fleet.converter$fleet %in% fleetAge,"fleetname"])

#Exclude spatial surveys (not used) and coastwide survey (which are CAAL)
mod$ctl$lambdas <- mod$ctl$lambdas[!mod$ctl$lambdas$fleet %in% c(16:24),]
mod$ctl$lambdas <- mod$ctl$lambdas[!mod$ctl$lambdas$fleet %in% c(28:30),]

#Set lambdas
mod$ctl$N_lambdas <- nrow(mod$ctl$lambdas)
mod$ctl$lambdas$value <- 0


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)



####------------------------------------------------####
### 4_9_2_lowlengthlambda Lower length lambdas  ----
####------------------------------------------------####

new_name <- "4_9_2_lowlengthlambda"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_8_4_mirrorORWA_twl'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make changes
##

#Set up lambda dataframe for lengths
fleetLen <- unique(mod$dat$lencomp$FltSvy)[unique(mod$dat$lencomp$FltSvy)>0]

mod$ctl$lambdas <- data.frame("like_comp" = 4, 
                              "fleet" = sort(fleetLen),
                              "phase" = 1,
                              "value" = 1,
                              "sizefreq_method" = 1)

rownames(mod$ctl$lambdas) = paste0("lengths_",fleet.converter[fleet.converter$fleet %in% fleetLen,"fleetname"])

#Exclude spatial surveys (not used) and coastwide surveys
mod$ctl$lambdas <- mod$ctl$lambdas[!mod$ctl$lambdas$fleet %in% c(16:24),]
mod$ctl$lambdas <- mod$ctl$lambdas[!mod$ctl$lambdas$fleet %in% c(28:30),]

#Set lambdas
mod$ctl$N_lambdas <- nrow(mod$ctl$lambdas)
mod$ctl$lambdas$value <- 0.01


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)


####------------------------------------------------####
### 4_9_3_lowlengthlambda_withSurvey Lower length and survey lambdas  ----
####------------------------------------------------####

new_name <- "4_9_3_lowlengthlambda_withSurvey"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_8_4_mirrorORWA_twl'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make changes
##

#Set up lambda dataframe for lengths
fleetLen <- unique(mod$dat$lencomp$FltSvy)[unique(mod$dat$lencomp$FltSvy)>0]

mod$ctl$lambdas <- data.frame("like_comp" = 4, 
                              "fleet" = sort(fleetLen),
                              "phase" = 1,
                              "value" = 1,
                              "sizefreq_method" = 1)

rownames(mod$ctl$lambdas) = paste0("lengths_",fleet.converter[fleet.converter$fleet %in% fleetLen,"fleetname"])

#Exclude ONLY spatial surveys (not used)
mod$ctl$lambdas <- mod$ctl$lambdas[!mod$ctl$lambdas$fleet %in% c(16:24),]

#Set lambdas
mod$ctl$N_lambdas <- nrow(mod$ctl$lambdas)
mod$ctl$lambdas$value <- 0.01


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)


####------------------------------------------------####
### 4_9_4_upweightAge Increase francis age weights by 10fold  ----
####------------------------------------------------####

new_name <- "4_9_4_upweightAge"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_8_4_mirrorORWA_twl'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make changes
##

mod$ctl$Variance_adjustment_list[mod$ctl$Variance_adjustment_list$Data_type==5,"Value"] = 10 *
  mod$ctl$Variance_adjustment_list[mod$ctl$Variance_adjustment_list$Data_type==5,"Value"]

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)


####------------------------------------------------####
### 4_9_5_upweightLen Increase francis length weights by 10fold  ----
####------------------------------------------------####

new_name <- "4_9_5_upweightLen"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_8_4_mirrorORWA_twl'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make changes
##

mod$ctl$Variance_adjustment_list[mod$ctl$Variance_adjustment_list$Data_type==4,"Value"] = 10 *
  mod$ctl$Variance_adjustment_list[mod$ctl$Variance_adjustment_list$Data_type==4,"Value"]

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)




####------------------------------------------------####
### 4_9_6_surveyagelambda1 Set survey age var adj to 1  ----
####------------------------------------------------####

new_name <- "4_9_6_surveyWeightAge1"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_8_4_mirrorORWA_twl'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make changes
##

#Set up lambda dataframe for ages
mod$ctl$Variance_adjustment_list[mod$ctl$Variance_adjustment_list$Data_type==5 & 
                                   mod$ctl$Variance_adjustment_list$Fleet > 26, "Value"] <- 1

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)


####------------------------------------------------####
### 4_9_7_orTWLage1 Set oregon trawl age var adj to 1  ----
####------------------------------------------------####

new_name <- "4_9_7_orTWLage1"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_8_4_mirrorORWA_twl'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make changes
##

#Set up lambda dataframe for ages
mod$ctl$Variance_adjustment_list[mod$ctl$Variance_adjustment_list$Data_type==5 & 
                                   mod$ctl$Variance_adjustment_list$Fleet == 2, "Value"] <- 1

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)


####------------------------------------------------####
### 4_9_8_orTWLlen1 Set oregon trawl length var adj to 1  ----
####------------------------------------------------####

new_name <- "4_9_8_orTWLlen1"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_8_4_mirrorORWA_twl'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make changes
##

#Set up lambda dataframe for ages
mod$ctl$Variance_adjustment_list[mod$ctl$Variance_adjustment_list$Data_type==4 & 
                                   mod$ctl$Variance_adjustment_list$Fleet == 2, "Value"] <- 1

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)


xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('4_8_4_mirrorORWA_twl',
                                                 '4_9_1_0agelambda',
                                                 '4_9_2_lowlengthlambda',
                                                 '4_9_3_lowlengthlambda_withSurvey',
                                                 '4_9_4_upweightAge',
                                                 '4_9_6_surveyWeightAge1',
                                                 '4_9_7_orTWLage1',
                                                 '4_9_5_upweightLen',
                                                 '4_9_8_orTWLlen1')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('model 484',
                                     'fishery age lambda = 0',
                                     'low fishery length lambda',
                                     'low all length lambda',
                                     'all age comp weights x10',
                                     'survey age comp weights = 1',
                                     'OR TWL age comp weight = 1',
                                     'all length comp weights x10',
                                     'OR TWL length comp weight = 1'),
                    print = TRUE, plotdir = here('models',new_name))



# 4_10_1 Update triennial to gamma -------------------------------------------------

new_name <- "4_10_1_gamma_tri"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_8_4_mirrorORWA_twl'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make changes
##
fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)

tri.cpue <- read.csv(file.path(wd,'Assessments/Assessment Data/2023 Assessment Cycle/canary rockfish/triennial/delta_gamma/index/est_by_area.csv')) |>
  dplyr::mutate(fleet_no_num = paste0(area, ifelse(year <= 1992, '_Tri_early', '_Tri_late'))) |>
  dplyr::left_join(fleet.converter) |> 
  dplyr::mutate(seas = 7) |>
  dplyr::select(year, seas, index = fleet, obs = est, se_log = se) |>
  dplyr::mutate(year = ifelse(index %in% fleet.converter$fleet[grep('coastwide', fleet.converter$fleetname)],
                              year, -year))

mod$dat$CPUE <- dplyr::filter(mod$dat$CPUE, 
                              !(index %in% fleet.converter$fleet[grep('Tri', fleet.converter$fleetname)])) |>
  dplyr::bind_rows(tri.cpue)


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)
beepr::beep()

# 4_10_2 Update wcgbts to gamma -------------------------------------------------

new_name <- "4_10_2_gamma_wcgbts"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_10_1_gamma_tri'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make changes
##

wcgbts.cpue <- read.csv(file.path(wd,'Assessments/Assessment Data/2023 Assessment Cycle/canary rockfish/wcgbts/delta_gamma/index/est_by_area.csv')) |>
  dplyr::mutate(fleet_no_num = paste0(area, '_NWFSC')) |>
  dplyr::left_join(fleet.converter) |> 
  dplyr::mutate(seas = 7) |>
  dplyr::select(year, seas, index = fleet, obs = est, se_log = se) |>
  dplyr::mutate(year = ifelse(index %in% fleet.converter$fleet[grep('coastwide', fleet.converter$fleetname)],
                              year, -year))

mod$dat$CPUE <- dplyr::filter(mod$dat$CPUE, 
                              !(index %in% fleet.converter$fleet[grep('NWFSC', fleet.converter$fleetname)])) |>
  dplyr::bind_rows(wcgbts.cpue)


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)
beepr::beep()

# 4_10_3_tri_float_Q Change triennial to float Q -------------------------------------------------

new_name <- "4_10_3_tri_float_Q"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_10_2_gamma_wcgbts'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make changes
##

# Move late tri data to early tri so it is in a single fleet
tri.late.index <- fleet.converter$fleet[fleet.converter$fleet_no_num == 'coastwide_Tri_late']
tri.early.index <- fleet.converter$fleet[fleet.converter$fleet_no_num == 'coastwide_Tri_early']
mod$dat$CPUE <- dplyr::mutate(mod$dat$CPUE,
                              index = ifelse(index == tri.late.index, tri.early.index, index))
mod$dat$agecomp <- dplyr::mutate(mod$dat$agecomp, 
                                 FltSvy = ifelse(FltSvy == tri.late.index, tri.early.index, FltSvy),
                                 FltSvy = ifelse(FltSvy == -tri.late.index, -tri.early.index, FltSvy))
mod$dat$lencomp <- dplyr::mutate(mod$dat$lencomp, 
                                 FltSvy = ifelse(FltSvy == tri.late.index, tri.early.index, FltSvy),
                                 FltSvy = ifelse(FltSvy == -tri.late.index, -tri.early.index, FltSvy))

# Float early tri
mod$ctl$Q_options['29_coastwide_Tri_early','float'] <- 1

# Negative phase for early tri (float)
mod$ctl$Q_parms[grep('Tri_early', rownames(mod$ctl$Q_parms)),'PHASE'] <- -1

# Remove Q setup for late tri (no data)
mod$ctl$Q_parms <- mod$ctl$Q_parms[-grep('Tri_late', rownames(mod$ctl$Q_parms)),]
mod$ctl$Q_options <- mod$ctl$Q_options[-grep('Tri_late', rownames(mod$ctl$Q_options)),]

# Do not need to touch selectivity. It is mirrored.

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)
beepr::beep()

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('4_8_4_mirrorORWA_twl',
                                                 '4_10_1_gamma_tri',
                                                 '4_10_2_gamma_wcgbts',
                                                 '4_10_3_tri_float_Q')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Mirrored OR/WA trawl',
                                     'Tri w/gamma',
                                     'WCGBTS w/gamma',
                                     'Tri float Q'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

# 4_10_4_tri_est_Q estimate triennial Q with data fully combined -------------------------------------------------

new_name <- "4_10_4_tri_est_Q"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_10_3_tri_float_Q'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make changes
##

# Estimate Q, leave everything else unchanged

mod$ctl$Q_options['29_coastwide_Tri_early', 'float'] <- 0
mod$ctl$Q_parms[grep('Tri', rownames(mod$ctl$Q_parms)), 'PHASE'] <- 2

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)
beepr::beep()

# 4_10_5_tri_float_Q_late_weights -------------------------------------------------

new_name <- "4_10_5_float_Q_late_weights"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_10_3_tri_float_Q'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make changes
##

data.weights.new <- mod$ctl$Variance_adjustment_list |>
  dplyr::group_by(Data_type) |>
  dplyr::mutate(tri.late = ifelse(Fleet == tri.late.index, Value, 0), # this is a hack
                  Value = ifelse(Fleet == tri.early.index, max(tri.late), Value)) |>
  dplyr::select(-tri.late) |>
  dplyr::ungroup() |>
  as.data.frame() |>
  `rownames<-`(rownames(mod$ctl$Variance_adjustment_list))

mod$ctl$Variance_adjustment_list <- data.weights.new

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)
beepr::beep()

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('4_8_4_mirrorORWA_twl',
                                                 '4_10_1_gamma_tri',
                                                 '4_10_2_gamma_wcgbts',
                                                 '4_10_3_tri_float_Q',
                                                 '4_10_4_tri_est_Q',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Mirrored OR/WA trawl',
                                     'Tri w/gamma',
                                     'WCGBTS w/gamma',
                                     'Float Q, early Tri wts',
                                     'Est Q, data combined, early Tri wts',
                                     'Float Q, late Tri wts'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

# 4_10_6_tri_separate_late_weights  -------------------------------------------------

new_name <- "4_10_6_tri_separate_late_weights"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_8_4_mirrorORWA_twl'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))


##
#Make changes
##

data.weights.new <- mod$ctl$Variance_adjustment_list |>
  dplyr::group_by(Data_type) |>
  dplyr::mutate(tri.late = ifelse(Fleet == tri.late.index, Value, 0), # this is a hack
                Value = ifelse(Fleet == tri.early.index, max(tri.late), Value)) |>
  dplyr::select(-tri.late) |>
  dplyr::ungroup() |>
  as.data.frame() |>
  `rownames<-`(rownames(mod$ctl$Variance_adjustment_list))

mod$ctl$Variance_adjustment_list <- data.weights.new

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)
beepr::beep()

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('4_8_4_mirrorORWA_twl',
                                                 new_name,
                                                 '4_10_3_tri_float_Q',
                                                 '4_10_4_tri_est_Q',
                                                 '4_10_5_float_Q_late_weights')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Mirrored OR/WA trawl',
                                     'Separate data, late Tri wts',
                                     'Float Q, early Tri wts',
                                     'Est Q, data combined, early Tri wts',
                                     'Float Q, late Tri wts'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))

####------------------------------------------------####
### 5_0_1_base Update catches from CA rec (for 2020 and 2021) and WA 2022 (but not WA pacfin comps). ----
### Remove sex dependent selex for CA rec, update the inits and name for WA NTWL selex  
### I tested these individually in 5_0_0_ models 
####------------------------------------------------####

#WA catches are not yet in PacFIN so just manually adjust here

new_name <- "5_0_1_base"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/4_8_4_mirrorORWA_twl'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)


##
#Make changes
##

# Update catch time series ------------------------------------------------
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

#Manually update the WA 2022 trawl and nontrawl amounts because not in the updated catch time series
mod$dat$catch[mod$dat$catch$fleet == 3 & mod$dat$catch$year == 2022, "catch"] <- 102.4 + 0.01


# Update inits for WA NTWL (previously had copied from OR NTWL) ----------------------------------------------

selex_modes <- mod$dat$lencomp |>
  dplyr::arrange(FltSvy) |>
  dplyr::group_by(FltSvy) |>
  dplyr::summarise(dplyr::across(f12:m66, ~ sum(Nsamp*.x)/sum(Nsamp))) |>
  tidyr::pivot_longer(cols = -FltSvy, names_to = 'len_bin', values_to = 'dens') |>
  tidyr::separate(col = len_bin, into = c('sex', 'length'), sep = 1) |>
  dplyr::group_by(FltSvy, sex) |>
  dplyr::summarise(mode = length[which.max(dens)]) |>
  dplyr::summarise(mode = mean(as.numeric(mode))) |>
  dplyr::mutate(asc.slope = log(8*(mode - min(mod$dat$lbin_vector))),
                desc.slope = log(8*(max(mod$dat$lbin_vector)-mode)))

mod$ctl$size_selex_parms[intersect(grep("6_WA_NTWL",rownames(mod$ctl$size_selex_parms)),
                                   grep("SizeSel_P_1",rownames(mod$ctl$size_selex_parms))),"INIT"] <- 
  selex_modes[selex_modes$FltSvy == 6,"mode"]

mod$ctl$size_selex_parms[intersect(grep("6_WA_NTWL",rownames(mod$ctl$size_selex_parms)),
                                   grep("SizeSel_P_3",rownames(mod$ctl$size_selex_parms))),"INIT"] <- 
  selex_modes[selex_modes$FltSvy == 6,"asc.slope"]

mod$ctl$size_selex_parms[intersect(grep("6_WA_NTWL",rownames(mod$ctl$size_selex_parms)),
                                   grep("SizeSel_P_4",rownames(mod$ctl$size_selex_parms))),"INIT"] <- 
  selex_modes[selex_modes$FltSvy == 6,"desc.slope"]


# Remove sex dependent selex from CA rec -----------------------------------------------
# Removing this altogether gave poor gradient so likely wasnt doing correctly

# mod$ctl$size_selex_types[grep("7_CA_REC",rownames(mod$ctl$size_selex_types)),"Male"] <- 0
# 
# mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[
#   -intersect(grep("SizeSel_PFemOff", rownames(mod$ctl$size_selex_parms)),
#             grep("7_CA_REC", rownames(mod$ctl$size_selex_parms))),]
# 
# mod$ctl$size_selex_parms_tv <- mod$ctl$size_selex_parms_tv[
#   -intersect(grep("SizeSel_PFemOff", rownames(mod$ctl$size_selex_parms_tv)),
#              grep("7_CA_REC", rownames(mod$ctl$size_selex_parms_tv))),]

# Instead, fix male and female selectivity to be the same for CA rec 
mod$ctl$size_selex_parms[grep("SizeSel_PFemOff_3_7_CA_REC", rownames(mod$ctl$size_selex_parms)), "PHASE"] <- -99
mod$ctl$size_selex_parms_tv[grep("SizeSel_PFemOff_3_7_CA_REC", rownames(mod$ctl$size_selex_parms_tv)), "PHASE"] <- -99

##----
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

xx <- r4ss::tune_comps(replist = pp, 
                       option = 'Francis', 
                       dir = here('models', new_name), 
                       exe = here('models/ss_win.exe'), 
                       niters_tuning = 0, 
                       extras = '-nohess', write = TRUE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('4_8_4_mirrorORWA_twl',
                                                 '5_0_0_justCatch',
                                                 '5_0_0_justInits',
                                                 '5_0_0_CArec_fem4_fixed_noTV',
                                                 '5_0_1_base')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('model 484',
                                     'Update catch',
                                     'Update inits',
                                     'fix rec sex dependent at 0 for all',
                                     '5_0_1_all'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))

####------------------------------------------------####
### 5_0_2_base Extend bounds on WA rec paramaeters at their bound to negative values, which are sensible ----
####------------------------------------------------####

new_name <- "5_0_2_base2"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/5_0_1_base'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

#Adjust bound on tv parms. This is model 5_0_2_base
mod$ctl$size_selex_parms_tv[intersect(grep('SizeSel_P_3_9_WA_REC',rownames(mod$ctl$size_selex_parms_tv)),
                                      grep('BLK5repl_2006',rownames(mod$ctl$size_selex_parms_tv))),"LO"] <- -9
mod$ctl$size_selex_parms_tv[intersect(grep('SizeSel_P_4_9_WA_REC',rownames(mod$ctl$size_selex_parms_tv)),
                                      grep('BLK5repl_2021',rownames(mod$ctl$size_selex_parms_tv))),"LO"] <- -9

#Get a lot of warnings that regular parameters are below limits. Thus to adjust bounds on time-varying parameters
#need to change the bound on the original because replace (block_fxn = 2). This is model 5_0_2_base2
mod$ctl$size_selex_parms[grep('SizeSel_P_3_9_WA_REC',rownames(mod$ctl$size_selex_parms)),"LO"] <- -9
mod$ctl$size_selex_parms[grep('SizeSel_P_4_9_WA_REC',rownames(mod$ctl$size_selex_parms)),"LO"] <- -9

####------------------------------------------------####
### 5_0_2_base Extend bounds on WA rec paramaeters at their bound to negative values, which are sensible ----
####------------------------------------------------####

new_name <- "5_0_2_base2"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/5_0_1_base'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

#Adjust bound on tv parms. This is model 5_0_2_base
mod$ctl$size_selex_parms_tv[intersect(grep('SizeSel_P_3_9_WA_REC',rownames(mod$ctl$size_selex_parms_tv)),
                                      grep('BLK5repl_2006',rownames(mod$ctl$size_selex_parms_tv))),"LO"] <- -9
mod$ctl$size_selex_parms_tv[intersect(grep('SizeSel_P_4_9_WA_REC',rownames(mod$ctl$size_selex_parms_tv)),
                                      grep('BLK5repl_2021',rownames(mod$ctl$size_selex_parms_tv))),"LO"] <- -9

#Get a lot of warnings that regular parameters are below limits. Thus to adjust bounds on time-varying parameters
#need to change the bound on the original because replace (block_fxn = 2). This is model 5_0_2_base2
mod$ctl$size_selex_parms[grep('SizeSel_P_3_9_WA_REC',rownames(mod$ctl$size_selex_parms)),"LO"] <- -9
mod$ctl$size_selex_parms[grep('SizeSel_P_4_9_WA_REC',rownames(mod$ctl$size_selex_parms)),"LO"] <- -9


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)


####------------------------------------------------####
### 5_0_3_base Liklihood is worse when extend bounds so fix at 0 ----
####------------------------------------------------####

#WA catches are not yet in PacFIN so just manually adjust here

new_name <- "5_0_3_base"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/5_0_1_base'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

mod$ctl$size_selex_parms_tv[intersect(grep('SizeSel_P_3_9_WA_REC',rownames(mod$ctl$size_selex_parms_tv)),
                                      grep('BLK5repl_2006',rownames(mod$ctl$size_selex_parms_tv))),c("INIT","PHASE")] <- c(0,-99)
mod$ctl$size_selex_parms_tv[intersect(grep('SizeSel_P_4_9_WA_REC',rownames(mod$ctl$size_selex_parms_tv)),
                                      grep('BLK5repl_2021',rownames(mod$ctl$size_selex_parms_tv))),c("INIT","PHASE")] <- c(0,-99)

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)


####------------------------------------------------####
### 5_0_4_OR_Rec_fix2 No sex specific selectivity for OR Rec. It was really struggling. ---- 
####------------------------------------------------####

new_name <- "5_0_4_OR_Rec_fix2"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/5_0_1_base'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

mod$ctl$size_selex_parms[grep("SizeSel_PFemOff_3_8_OR_REC", rownames(mod$ctl$size_selex_parms)), "PHASE"] <- -99
mod$ctl$size_selex_parms_tv[grep("SizeSel_PFemOff_3_8_OR_REC\\(8\\)_BLK4repl_2004", rownames(mod$ctl$size_selex_parms_tv)), "PHASE"] <- -99

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

# pp <- SS_output(here('models',new_name))
# SS_plots(pp)

####------------------------------------------------####
### 5_0_5_OR_Rec_fix1 No sex specific selectivity for OR Rec. It was really struggling.  ----
####------------------------------------------------####

new_name <- "5_0_5_OR_Rec_fix1"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/5_0_1_base'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

mod$ctl$size_selex_parms_tv[grep("SizeSel_PFemOff_3_8_OR_REC\\(8\\)_BLK4repl_2004", rownames(mod$ctl$size_selex_parms_tv)), "PHASE"] <- -99

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('5_0_1_base',
                                                 '5_0_1_base_best_jitter',
                                                 '5_0_2_OR_Rec_fix2',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Base model',
                                     'Best jitter from base',
                                     'Fix blk 1 & 2 OR Rec female offset',
                                     'Fix blk 2 OR Rec female offset'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))

SSsummarize(xx) |>
  SStableComparisons()

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)


####------------------------------------------------####
### 5_1_1_wa_rec_par3_4_lowbound Make a number of corrections. ----
##  Change middle block of OR rec to not have sex dependent selex (copy from 5_0_5_OR_Rec_fix1)
##  Change WA rec params at bounds by allowing parameters 3 and 4 (and timevarying) to have lower bound of -9 
####------------------------------------------------####

new_name <- "5_1_1_wa_rec_par3_4_lowbound"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/5_0_5_OR_Rec_fix1'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

#Change parmaeters 3 and 4 for WA rec selectivity to have lower bound of -9
mod$ctl$size_selex_parms[grep("SizeSel_P_3_9_WA_REC\\(9\\)", rownames(mod$ctl$size_selex_parms)), "LO"] <- -9
mod$ctl$size_selex_parms[grep("SizeSel_P_4_9_WA_REC\\(9\\)", rownames(mod$ctl$size_selex_parms)), "LO"] <- -9

mod$ctl$size_selex_parms_tv[grep("SizeSel_P_3_9_WA_REC\\(9\\)_BLK5", rownames(mod$ctl$size_selex_parms_tv)), "LO"] <- -9
mod$ctl$size_selex_parms_tv[grep("SizeSel_P_4_9_WA_REC\\(9\\)_BLK5", rownames(mod$ctl$size_selex_parms_tv)), "LO"] <- -9


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:19)])

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

####------------------------------------------------####
### 5_1_2_WA_NTWL_descend_lowbound Set lower bound for parm 4 of WA NTWL to -9 ----
####------------------------------------------------####

new_name <- "5_1_2_WA_NTWL_descend_lowbound"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/5_1_1_wa_rec_par3_4_lowbound'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

#Set lower bound for parm 4 of WA NTWL to -9
mod$ctl$size_selex_parms[grep("SizeSel_P_4_6_WA_NTWL\\(6\\)", rownames(mod$ctl$size_selex_parms)), "LO"] <- -9


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)


####------------------------------------------------####
### 5_1_3_no_WA_REC_midblock Gradient on peak in middle block is lowish, mid block doesnt seem to change so remove ----
####------------------------------------------------####

new_name <- "5_1_3_no_WA_REC_midblock"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/5_1_2_WA_NTWL_descend_lowbound'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

mod$ctl$Block_Design[[5]] <- c(2021, 2022)
mod$ctl$blocks_per_pattern[5] <- 1
mod$ctl$size_selex_parms_tv <- mod$ctl$size_selex_parms_tv[
  -grep("WA_REC\\(9\\)_BLK5repl_2006",rownames(mod$ctl$size_selex_parms_tv)),]


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)



####------------------------------------------------####
### 5_2_1_wa_rec_parm_fix Make a number of corrections. ----
##  Change middle block of OR rec to not have sex dependent selex (copy from 5_0_5_OR_Rec_fix1)
##  Change WA rec params at bounds by fixing at values 
####------------------------------------------------####

new_name <- "5_2_1_wa_rec_parm_fix"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/5_0_5_OR_Rec_fix1'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

#Change parameters 3 in 2006 block and 4 in 2021 block for WA rec selectivity to 0
mod$ctl$size_selex_parms_tv[grep("SizeSel_P_3_9_WA_REC\\(9\\)_BLK5repl_2006", rownames(mod$ctl$size_selex_parms_tv)), c("INIT","PHASE")] <- c(0, -99)
mod$ctl$size_selex_parms_tv[grep("SizeSel_P_4_9_WA_REC\\(9\\)_BLK5repl_2021", rownames(mod$ctl$size_selex_parms_tv)), c("INIT","PHASE")] <- c(0, -99)


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)


pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:19)])

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)


####------------------------------------------------####
### 5_3_1_no_WA_rec_midBlock Make a number of corrections ----
##  Change middle block of OR rec to not have sex dependent selex (copy from 5_0_5_OR_Rec_fix1)
##  Change WA rec params at bounds by removing the middle block
####------------------------------------------------####

new_name <- "5_3_1_no_WA_rec_midBlock"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/5_0_5_OR_Rec_fix1'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

mod$ctl$Block_Design[[5]] <- c(2021, 2022)
mod$ctl$blocks_per_pattern[5] <- 1
mod$ctl$size_selex_parms_tv <- mod$ctl$size_selex_parms_tv[
  -grep("WA_REC\\(9\\)_BLK5repl_2006",rownames(mod$ctl$size_selex_parms_tv)),]


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:19)])

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)


####------------------------------------------------####
### 5_4_1_all_parm34_lowerBound Make a number of corrections ----
##  Change middle block of OR rec to not have sex dependent selex (copy from 5_0_5_OR_Rec_fix1)
##  Change WA rec params at bounds by setting lower bound for ALL parameter 3 and 4 to -9
####------------------------------------------------####

new_name <- "5_4_1_all_parm34_lowerBound"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/5_0_5_OR_Rec_fix1'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

#Change parameters 3 and 4 for WA rec selectivity to have lower bound of -9
mod$ctl$size_selex_parms[grep("SizeSel_P_3", rownames(mod$ctl$size_selex_parms)), "LO"] <- -9
mod$ctl$size_selex_parms[grep("SizeSel_P_4", rownames(mod$ctl$size_selex_parms)), "LO"] <- -9

mod$ctl$size_selex_parms_tv[grep("SizeSel_P_3", rownames(mod$ctl$size_selex_parms_tv)), "LO"] <- -9
mod$ctl$size_selex_parms_tv[grep("SizeSel_P_4", rownames(mod$ctl$size_selex_parms_tv)), "LO"] <- -9

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)


####------------------------------------------------####
### 5_4_2_some_parm34_lowerBound Make a number of corrections ----
##  Change middle block of OR rec to not have sex dependent selex (copy from 5_0_5_OR_Rec_fix1)
##  Change WA rec params at bounds by setting lower bound for NTWL and REC parameters 3 and 4 from OR or WA to -9
####------------------------------------------------####

new_name <- "5_4_2_some_parm34_lowerBound"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/5_0_5_OR_Rec_fix1'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

#Change parameters 3 and 4 for WA rec selectivity to have lower bound of -9
mod$ctl$size_selex_parms[intersect(grep("SizeSel_P_3", rownames(mod$ctl$size_selex_parms)),
                                   grep("OR_REC|WA_REC|OR_NTWL|WA_NTWL", rownames(mod$ctl$size_selex_parms))), "LO"] <- -9
mod$ctl$size_selex_parms[intersect(grep("SizeSel_P_4", rownames(mod$ctl$size_selex_parms)),
                                   grep("OR_REC|WA_REC|OR_NTWL|WA_NTWL", rownames(mod$ctl$size_selex_parms))), "LO"] <- -9

mod$ctl$size_selex_parms_tv[intersect(grep("SizeSel_P_3", rownames(mod$ctl$size_selex_parms_tv)),
                                      grep("OR_REC|WA_REC|OR_NTWL|WA_NTWL", rownames(mod$ctl$size_selex_parms_tv))),"LO"] <- -9
mod$ctl$size_selex_parms_tv[intersect(grep("SizeSel_P_4", rownames(mod$ctl$size_selex_parms_tv)),
                                      grep("OR_REC|WA_REC|OR_NTWL|WA_NTWL", rownames(mod$ctl$size_selex_parms_tv))),"LO"] <- -9

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('5_0_1_base',
                                                 '5_0_5_OR_Rec_fix1',
                                                 '5_1_1_wa_rec_par3_4_lowbound',
                                                 '5_1_2_WA_NTWL_descend_lowbound',
                                                 '5_2_1_wa_rec_parm_fix',
                                                 '5_4_1_all_parm34_lowerBound',
                                                 '5_4_2_some_parm34_lowerBound')))

SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Old base model',
                                         'Fix blk 2 OR Rec female offset',
                                         'Set lower bound WA REC parm 3 and 4',
                                         '+ set lower bound WA NTWL 4',
                                         'Set WA REC parm 3 and 4 to 0',
                                         'Set lower bound for ALL fleets parm 3 and 4',
                                         'Set lower bound for WA|OR REC|NTWL fleets parm 3 and 4'),
                        subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 5_5_0_hessian Run hessian ----
####------------------------------------------------####

new_name <- "5_5_0_hessian"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/5_4_2_some_parm34_lowerBound'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          # extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp)
SSplotData(pp, print = TRUE, subplots = c(1,2), plotdir = here('documents/figures'),
           pwidth = 5.5, pheight = 7, ptsize = 8,margins = c(5.1, 2.1, 2.1, 10.1))
file.rename(from = file.path(here('documents/figures'), c("data_plot.png","data_plot2.png")),
            to = file.path(here('documents/figures'), c("data_plot_custom.png","data_plot2_custom.png")))
#To make CAAL plots on fewer plots run this which copied the two CAAL WCGBTS plots to documents/figures
SS_plots(pp, plot = 18, maxrows2 = 4, maxcols2 = 5, printfolder = "custom_plots")
file.rename(from = file.path(here('models', new_name, 'custom_plots'), "comp_condAALfit_residsflt28mkt0_page1.png"),
            to = file.path(here('documents/figures'), "comp_condAALfit_residsflt28mkt0_page1_custom.png"))
file.rename(from = file.path(here('models', new_name, 'custom_plots'), "comp_condAALfit_residsflt28mkt0_page2.png"),
            to = file.path(here('documents/figures'), "comp_condAALfit_residsflt28mkt0_page2_custom.png"))
unlink(here('models', new_name, 'custom_plots'), recursive = TRUE)


r4ss::SSplotComps(pp, subplots = 21, kind = "LEN", fleets = c(5,8,9), datonly = TRUE,
                  print = TRUE, plot = TRUE, plotdir = here('documents/figures'))
file.rename(from = file.path(here('documents/figures'), "comp_lendat__aggregated_across_time.png"),
          to = file.path(here('documents/figures'), "comp_lendat__aggregated_across_time_custom.png"))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

plot_sel_comm_age(pp, sex=1, fact = "Asel2")
plot_sel_comm_age(pp, sex=2, fact = "Asel2")
plot_sel_noncomm_age(pp, sex=1, spatial = FALSE, fact = "Asel2")
plot_sel_noncomm_age(pp, sex=2, spatial = FALSE, fact = "Asel2")

xx=r4ss::tune_comps(replist = pp, 
                    option = 'Francis', 
                    dir = here('models', new_name), 
                    exe = here('models/ss_win.exe'), 
                    niters_tuning = 0, 
                    extras = '-nohess',
                    allow_up_tuning = TRUE)

SSunavailableSpawningOutput(pp, plotdir = here('models',new_name), print = TRUE)


#Improve legend on catch plot - thanks to Ian
png(file.path(here('documents/figures'), "catch2 landings stacked_custom.png"),
    res = 300, 
    units = "in",
    width = 6.5, 
    height = 4.1, # change this to make it taller
    pointsize = 10 # change this to make the text even smaller
    # r4ss default is pointsize = 10
)

fleets_with_catch <- sort(unique(pp$catch$Fleet))
legend_labels <- model$FleetNames[fleets_with_catch]
# colors matching what's done in SSplotCatch()
# (removes first color from vector)
legend_colors <- r4ss::rich.colors.short(length(legend_labels) + 1)[-1]
SSplotCatch(model, showlegend = FALSE, subplots = 2, ymax = 6000, addmax = FALSE)
legend("topleft",
       fill = legend_colors, 
       legend = legend_labels, 
       bty = "n",
       ncol = 1 # number of columns: could change this to 3 if you want
)
dev.off()

#Improve legend on catch plot - thanks to Ian
png(file.path(here('documents/figures'), "catch1 landings_customTWL.png"),
    res = 300, 
    units = "in",
    width = 6.5, 
    height = 4.1, # change this to make it taller
    pointsize = 10 # change this to make the text even smaller
    # r4ss default is pointsize = 10
)

fleets_with_catch <- sort(unique(pp$catch$Fleet))
legend_labels <- pp$FleetNames[fleets_with_catch]
# colors matching what's done in SSplotCatch()
# (removes first color from vector)
legend_colors <- r4ss::rich.colors.short(length(legend_labels) + 1)[-1]
legend_colors <- r4ss::rich.colors.short(3)

SSplotCatch(pp, showlegend = FALSE, subplots = 1, ymax = 6000, addmax = FALSE, fleetcols = c(legend_colors,rep(NA,length(fleets_with_catch)-3)))
legend("topleft",
       fill = c(1,legend_colors), 
       legend = c("Total",legend_labels[1:3]), 
       bty = "n",
       ncol = 1 # number of columns: could change this to 3 if you want
)
dev.off()

# #confirm external growth is within bounds (taken from discussion #21)
# age = c(1:40)
# lmm <- 8.344 + (54.6481000	 - 8.344) * (1-exp(-0.1558210 * (age-1)))
# lfm <- 8.344 + (59.4463000 - 8.344) * (1-exp(-0.1372000	 * (age-1)))
# lmx <- 11.365088 + (51.320627 - 11.365088) * (1-exp(-0.175495  * (age-1)))
# lfx <- 11.382156  + (57.900273	 - 11.382156 ) * (1-exp(-0.142700 * (age-1)))
# 
# SSplotBiology(pp,subplot=1)
# lines(age,lfx,col=1,lty=1,lwd=3)
# lines(age,lmx,col=1,lty=2,lwd=3)



####------------------------------------------------####
### 5_5_1_biasAdj - Overall this doesn't seem to be worthwhile. Minor changes and more params on bounds ----
####------------------------------------------------####

new_name <- "5_5_1_biasAdj"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/5_5_0_hessian'),
               dir.new = here('models',new_name),
               overwrite = TRUE)
file.copy(from = file.path(here('models/5_5_0_hessian'),"Report.sso"),
          to = file.path(here('models',new_name),"Report.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/5_5_0_hessian'),"CompReport.sso"),
          to = file.path(here('models',new_name),"CompReport.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/5_5_0_hessian'),"warning.sso"),
          to = file.path(here('models',new_name),"warning.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models/5_5_0_hessian'),"covar.sso"),
          to = file.path(here('models',new_name),"covar.sso"), overwrite = TRUE)

mod <- SS_read(here('models',new_name))

pp <- SS_output(here('models',new_name), covar = TRUE)


##
#Make changes
##

#Update sigmaR with tuned value? Suggests 0.5 is good so keep it
pp$sigma_R_info[pp$sigma_R_info$period == "Main","alternative_sigma_R"]

#Update bias adjust? Not really, just maybe start, last full bias, and max bias adj
pp$breakpoints_for_bias_adjustment_ramp
biasadj <- SS_fitbiasramp(pp, verbose = TRUE)

mod$ctl$last_early_yr_nobias_adj <- biasadj$newbias$par[1]
mod$ctl$last_yr_fullbias_adj <- biasadj$newbias$par[3]
mod$ctl$max_bias_adj <- biasadj$newbias$par[5]

#Need to fix femoffset for WA Rec in last block because it hits a bound and hessian cant be inverted
mod$ctl$size_selex_parms_tv[
  grep("SizeSel_PFemOff_3_9_WA_REC\\(9\\)_BLK5repl_2021",rownames(mod$ctl$size_selex_parms_tv)), c("INIT","PHASE")] <- c(-9,-99)

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          # extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)


####------------------------------------------------####
### 5_5_2_bestJitter Running with ctl.ss_new as ctl file ----
####------------------------------------------------####

new_name <- "5_5_2_bestJitter_hessian"
old_name <- "5_5_0_profile_best_jitter_hessian"

##
#Copy inputs
##

mod <- SS_read(here('models',old_name), ss_new = TRUE)


##
#Make changes
##

mod$start$init_values_src <- 0


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          # extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)


##
#5_5_2_bestJitter_hessian_Mphase resets the phase of female M back to 2 - I did that manually but noting here
##

# 5_5_3_recruitment -------------------------------------------------------
## Include 2010, 2012, 2022 for prerecruit survey
## Change early rec dev settings
####------------------------------------------------####

new_name <- "5_5_3_recruitment"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/5_5_0_hessian'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)

##
#Make changes
##

prerecruit <- read.csv(here('data/canary_prerecruit_indices.csv')) |>
  dplyr::mutate(fleet_no_num = paste0(region, '_prerec')) |>
  dplyr::left_join(fleet.converter) |> 
  dplyr::mutate(seas = 7,
                YEAR = ifelse(region == 'coastwide', YEAR, -YEAR)) |>
  dplyr::select(year = YEAR, seas, index = fleet, obs = est, se_log = se)

mod$dat$CPUE <- mod$dat$CPUE |>
  dplyr::filter(!(index %in% unique(prerecruit$index))) |>
  dplyr::bind_rows(prerecruit)

mod$ctl$MainRdevYrFirst <- 1955

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          # extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))


# 5_5_4_recdev_only -------------------------------------------------------
## Change early rec dev settings
####------------------------------------------------####

new_name <- "5_5_4_recdev_only"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/5_5_0_hessian'),
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

##
#Make changes
##

mod$ctl$MainRdevYrFirst <- 1955

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          # extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('5_5_0_hessian',
                                                 new_name,
                                                 '5_5_3_recruitment')))

SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Old base model',
                                     'Change main rec dev period',
                                     'Main rec dev + update prerec'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 5_5_6_bestJitter Running with ctl.ss_new as ctl file ----
####------------------------------------------------####

new_name <- "5_5_6_bestJitter"
old_name <- "5_5_5_bestJitter_hessian_best_jitter" #run from copying over the winning jitter profile

##
#Copy inputs
##

mod <- SS_read(here('models',old_name), ss_new = TRUE)


##
#Make changes
##

mod$start$init_values_src <- 0


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          # extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)



####------------------------------------------------####
### 5_6_0_Mphase Change female M phase back to 2 ----
####------------------------------------------------####

new_name <- "5_6_0_Mphase"
old_name <- "5_5_6_bestJitter" #run from copying over the winning jitter profile

##
#Copy inputs
##

mod <- SS_read(here('models',old_name))


##
#Make changes
##

mod$ctl$MG_parms[grep("NatM_p_1_Fem_GP_1", rownames(mod$ctl$MG_parms)),"PHASE"] <- 2

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          # extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('5_5_0_hessian',
                                                 '5_5_2_bestJitter_hessian',
                                                 '5_5_2_bestJitter_hessian_Mphase',
                                                 '5_5_5_bestJitter_hessian_best_jitter',
                                                 '5_6_0_Mphase')))

SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Old base model 500',
                                     'Best jitter of model 500',
                                     'Best jitter of model 500 with M phase 2',
                                     'Best 2nd jittering model',
                                     'Best 2nd jittering model with M phase 2'),
                    subplots = c(1:4, 11, 13:14, 16), print = TRUE, plotdir = here('models',new_name))

#Compared to model 5_5_2_bestJitter_Mphase, 5_6_0 fits rec devs better (less extreme), 
#length comps better but age comps worse, survey comps slightly worse, but has better stability.
#Both have comparable gradients (worse for R0), and when female phase is 1 the gradient is better.
#Weights have changed a bit. 

#For report
xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('5_5_0_hessian',
                                                 '5_5_2_bestJitter_hessian',
                                                 '5_5_5_bestJitter_hessian_best_jitter')))

SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Current base model',
                                     '1st jitter lowest likelihood',
                                     '2nd jitter lowest likelihood'),
                    subplots = c(1:4, 11, 13:14, 16), print = TRUE, plotdir = here('models',new_name,'jitter_compare_for_report'))

file.copy(from = file.path(here('models',new_name,'jitter_compare_for_report'), "compare1_spawnbio.png"),
            to = file.path(here('documents/figures'), "jitter_compare1_spawnbio.png"))


##########################################################################################

#Internal review deadline break

##########################################################################################

####------------------------------------------------####
### 6_0_0_priors - Fix male M prior, remove unused priors ----
####------------------------------------------------####

new_name <- "6_0_0_priors"
old_name <- "5_5_0_hessian"

##
#Copy inputs
##

mod <- SS_read(here('models',old_name))


##
#Make changes
##

mod$ctl$MG_parms[-grep("NatM_p_1", rownames(mod$ctl$MG_parms)),"PR_type"] <- 0 #turn off non-M priors
mod$ctl$MG_parms[grep("NatM_p_1_Mal_GP_1", rownames(mod$ctl$MG_parms)),"PR_type"] <- 3 #lognormal prior

mod$ctl$SR_parms[-grep("SR_BH_steep", rownames(mod$ctl$SR_parms)),"PR_type"] <- 0 #turn off non-M priors


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          # extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('5_5_0_hessian',
                                                 '6_0_0_priors')))

SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Pre star base',
                                     'Fix parm priors'),
                    subplots = c(1, 3), print = TRUE, plotdir = here('models',new_name))



####------------------------------------------------####
### 6_0_1_growthInits - Set external growth params as growth inits ----
####------------------------------------------------####

new_name <- "6_0_1_growthInits"
old_name <- "6_0_0_priors"

##
#Copy inputs
##

mod <- SS_read(here('models',old_name))


##
#Make changes
##

mod$ctl$MG_parms[grep("L_at_|VonBert_K", rownames(mod$ctl$MG_parms)),"INIT"] <- c(11.38, 57.9, 0.1427, 0, 51.32, 0.175)


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          # extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('5_5_0_hessian',
                                                 '6_0_0_priors',
                                                 '6_0_1_growthInits')))

SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Pre star base',
                                     'Fix parm priors',
                                     'Use external growth as inits'),
                    subplots = c(1, 3), print = TRUE, plotdir = here('models',new_name))

#Growth inits do change result but fit is poorer and parms are at bounds.
#Overall growth values are very similar. Differences due to selectivity
round(pp$likelihoods_used,2)
round(pp_base$likelihoods_used,2)


####------------------------------------------------####
### 6_1_0_projections - add GMT projections ----
####------------------------------------------------####

new_name <- "6_1_0_projections"
old_name <- "6_0_0_priors"

##
#Copy inputs
##

mod <- SS_read(here('models',old_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)

##
#Make changes
##

ForeCatch <- readxl::read_excel(here('data-raw/GMT Canary Projected Removals 2023.xlsx'),
                   range = 'A1:L9') |>
  dplyr::rename(Year = '...1') |>
  tidyr::pivot_longer(cols = -Year, names_to = 'fleet_name', values_to = 'catch') |>
  dplyr::mutate(split = stringr::str_split(fleet_name, ' '),
                state = sapply(split, function(.x)
                  .x[which(stringr::str_length(.x) == 2)]),
                fleet = sapply(split, function(.x)
                  .x[which(stringr::str_length(.x) > 2)]),
                fleet_abbrv = dplyr::case_when(fleet == 'At-sea' ~ 'ASHOP',
                                               fleet == 'trawl' ~ 'TWL',
                                               fleet == 'nontrawl' ~ 'NTWL',
                                               fleet == 'recreational' ~ 'REC'),
                fleet_no_num = paste(state, fleet_abbrv, sep = '_'),
                Seas = 1) |>
  dplyr::select(Year, catch, fleet_no_num, Seas) |>
  dplyr::left_join(fleet.converter) |>
  dplyr::select(Year, Seas, Fleet = fleet, `Catch or F` = catch) |>
  dplyr::filter(Year %in% 2023:2024) |>
  as.data.frame()

mod$fore$ForeCatch <- ForeCatch

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('5_5_0_hessian',
                                                 '6_1_0_projections'))) |>
  SSsummarize() |>
  SStableComparisons()

xx$model1 - xx$model2
# Model runs are identical


####------------------------------------------------####
### 7_0_0_fixAges - Correct error in commercial age comp work up (include recent ages now) ----
####------------------------------------------------####

new_name <- "7_0_0_addAges"
old_name <- "6_1_0_projections"

##
#Copy inputs
##

mod <- SS_read(here('models',old_name))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)

##
#Make changes
##

#Update pacfin comps
length.min <- min(mod$dat$lbin_vector)
length.max <- max(mod$dat$lbin_vector)
age.min <- min(mod$dat$agebin_vector)
age.max <- max(mod$dat$agebin_vector)

read.fishery.comps <- function(filename, exclude) {
  
}

#Just need to do so for ages
pacfin.ages <- purrr::map(list('CA', 'OR', 'WA'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_PacFIN_Acomps_{amin}_{amax}_formatted_fixAges.csv',
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

mod$dat$agecomp <- mod$dat$agecomp |> 
  dplyr::filter(!(FltSvy %in% unique(pacfin.ages$FltSvy))) |>
  dplyr::bind_rows(pacfin.ages)

#Make adjustments to remove spiky data (ala model 201)
#Remove sex = 0 fish for all AGE comps (Most have small absolute sample size or small relative to sexed samples)
#NTWL (WA, OR); ASHOP (WA), Rec (OR, WA), and TWL (CA, OR, WA). Of these WA TWL has most samples so could be kept.  
table(mod$dat$agecomp$FltSvy, mod$dat$agecomp$Gender, mod$dat$agecomp$Yr <0)
mod$dat$agecomp$Yr[mod$dat$agecomp$Gender == 0 & mod$dat$agecomp$Yr >0] <- -1 * 
  mod$dat$agecomp$Yr[mod$dat$agecomp$Gender == 0 & mod$dat$agecomp$Yr >0]


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('5_5_0_hessian',
                                                 '7_0_0_addAges')))

SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Pre star base',
                                     'Add omitted commercial ages'),
                    subplot = c(1,3,9,11), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 7_0_1_tune - Retune ---- 
####------------------------------------------------####

new_name <- "7_0_1_tune"
old_name <- "7_0_0_addAges"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models',old_name),
               dir.new = here('models',new_name),
               overwrite = TRUE)
file.copy(from = file.path(here('models',old_name),"Report.sso"),
          to = file.path(here('models',new_name),"Report.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models',old_name),"CompReport.sso"),
          to = file.path(here('models',new_name),"CompReport.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models',old_name),"warning.sso"),
          to = file.path(here('models',new_name),"warning.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models',old_name),"covar.sso"),
          to = file.path(here('models',new_name),"covar.sso"), overwrite = TRUE)

pp <- SS_output(here('models',old_name))

##
#Make changes
##

xx=r4ss::tune_comps(replist = pp, 
                    option = 'Francis', 
                    dir = here('models', new_name), 
                    exe = here('models/ss_win.exe'), 
                    niters_tuning = 1, 
                    extras = '-nohess',
                    allow_up_tuning = TRUE)


pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('5_5_0_hessian',
                                                 '7_0_0_addAges',
                                                 '7_0_1_tune')))

SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Pre star base',
                                     'Add omitted commercial ages',
                                     'Retuned'),
                    subplots = c(1, 3, 9, 11), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 7_0_2_hessian - now run with a hessian ----
####------------------------------------------------####

new_name <- "7_0_2_hessian"
old_name <- "7_0_1_tune"

##
#Copy inputs
##

mod <- SS_read(here('models',old_name))

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          # extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('5_5_0_hessian',
                                                 '7_0_2_hessian')))

SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Pre star base',
                                     'Recent ages added'),
                    subplot = c(1:4,9,11), print = TRUE, plotdir = here('models',new_name))


#Update sigmaR with tuned value? Suggests 0.5 is good so keep it
pp$sigma_R_info[pp$sigma_R_info$period == "Main","alternative_sigma_R"]

#Update bias adjust? Not really, just maybe start, last full bias, and max bias adj
pp$breakpoints_for_bias_adjustment_ramp
biasadj <- SS_fitbiasramp(pp, verbose = TRUE)


####------------------------------------------------####
### 7_0_3_asympSelex_waRec - the later block for WA rec has high corrrelation among the parameters. Set to asymptotic ----
####------------------------------------------------####

new_name <- "7_0_3_asympSelex_waRec"
old_name <- "7_0_2_hessian"

##
#Copy inputs
##

mod <- SS_read(here('models',old_name))

##
#Make changes
##

mod$ctl$size_selex_parms_tv[grep("SizeSel_P_4_9_WA_REC\\(9\\)_BLK5repl_2021",rownames(mod$ctl$size_selex_parms_tv)),c("INIT","PHASE")] <- c(15,-99)
mod$ctl$size_selex_parms_tv[grep("SizeSel_PFemOff_3_9_WA_REC\\(9\\)_BLK5repl_2021",rownames(mod$ctl$size_selex_parms_tv)),"PHASE"] <- -99

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          # extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)


xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('7_0_2_hessian',
                                                 '7_0_3_asympSelex_waRec')))

SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Add omitted commercial ages',
                                     'Asymptotic selex for last WA Rec block'),
                    subplot = c(1,3,9,11), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 7_0_4_noSexSelex_waRec - the later block for WA rec has high corrrelation among the parameters. Remove sex selectivity ----
####------------------------------------------------####

new_name <- "7_0_4_noSexSelex_waRec"
old_name <- "7_0_2_hessian"

##
#Copy inputs
##

mod <- SS_read(here('models',old_name))

##
#Make changes
##

mod$ctl$size_selex_parms_tv[grep("SizeSel_PFemOff_3_9_WA_REC\\(9\\)_BLK5repl_2021",rownames(mod$ctl$size_selex_parms_tv)),"PHASE"] <- -99

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          # extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('7_0_2_hessian',
                                                 '7_0_3_asympSelex_waRec',
                                                 '7_0_4_noSexSelex_waRec')))

SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Add omitted commercial ages',
                                     'Asymptotic selex for last WA Rec block',
                                     'No sex selex for last WA Rec block'),
                    subplot = c(1,3,9,11), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 7_0_5_noSexSelex_orNTWL ---- 
### When resolving correlation in later block for WA rec, OR NTWL later block then has high corrrelation. 
### Removing sex selectivity for WA rec seemed to resolve it so trying also for OR NTWL
####------------------------------------------------####

new_name <- "7_0_5_noSexSelex_orNTWL"
old_name <- "7_0_4_noSexSelex_waRec"

##
#Copy inputs
##

mod <- SS_read(here('models',old_name))

##
#Make changes
##

mod$ctl$size_selex_parms_tv[grep("SizeSel_PFemOff_3_5_OR_NTWL\\(5\\)_BLK2repl_2020",rownames(mod$ctl$size_selex_parms_tv)),"PHASE"] <- -99

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          # extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('7_0_2_hessian',
                                                 '7_0_3_asympSelex_waRec',
                                                 '7_0_4_noSexSelex_waRec',
                                                 '7_0_5_noSexSelex_orNTWL')))

SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Add omitted commercial ages',
                                     'Asymptotic selex for last WA Rec block',
                                     'No sex selex for last WA Rec block',
                                     'No sex selex for last WA Rec and OR NTWL block'),
                    subplot = c(1,3,9,11), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 7_1_0_hessStep - run hess step in prep for jitter ----
####------------------------------------------------####

#See this link:
#https://nmfs-stock-synthesis.github.io/doc/SS330_User_Manual_release.html#using--hess_step-to-do-additional-newton-steps-using-the-inverse-hessian

#Because running from a model with a hessian use -hess_step -binp ss.bar in SS3 call
  
new_name <- "7_1_0_hess_step"
old_name <- "7_0_2_hessian"

##
#Copy inputs
##

R.utils::copyDirectory(from = here('models', old_name),
                       to = here('models', new_name), 
                       overwrite = TRUE)

##
#Output files and run
##

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          show_in_console = TRUE,
          skipfinished = FALSE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('7_0_2_hessian',
                                                 '7_1_0_hess_step')))

SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Add omitted commercial ages',
                                     'run hess step'),
                    subplot = c(1,3,9,11), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 7_2_0_WArec_comb_late_block - late WA Rec selectivity combined with middle block ----
####------------------------------------------------####

new_name <- "7_2_0_WArec_comb_late_block"
old_name <- "7_0_2_hessian"

##
#Copy inputs
##

mod <- SS_read(here('models',old_name))

##
#Make changes
##

mod$ctl$Block_Design[[5]] <- c(2006, 2022)
mod$ctl$blocks_per_pattern[5] <- 1


mod$ctl$size_selex_parms_tv <- mod$ctl$size_selex_parms_tv[
  !grepl('BLK5repl_2021', rownames(mod$ctl$size_selex_parms_tv)),]

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

tictoc::tic()
r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          show_in_console = FALSE,
          skipfinished = FALSE)
tictoc::toc()

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

xx <- r4ss::tune_comps(replist = pp, 
                       option = 'Francis', 
                       dir = here('models', new_name), 
                       exe = here('models/ss_win.exe'), 
                       niters_tuning = 0, 
                       extras = '-nohess')

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('7_0_2_hessian',
                                                 '7_2_0_WArec_comb_late_block')))

SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Add omitted commercial ages',
                                     'Combine WA rec mid and late blocks'),
                    subplot = c(1,3,9,11), print = TRUE, plotdir = here('models',new_name))


####------------------------------------------------####
### 7_2_1_WArec_comb_all_block - 720 results in correlation with early rec ascendning and peak. Mirror all blocks ----
####------------------------------------------------####

new_name <- "7_2_1_WArec_comb_all_block"
old_name <- "7_2_0_WArec_comb_late_block"

##
#Copy inputs
##

mod <- SS_read(here('models',old_name))

##
#Make changes
##

mod$ctl$N_Block_Designs <- 4
mod$ctl$Block_Design <- mod$ctl$Block_Design[-5]
mod$ctl$blocks_per_pattern <- mod$ctl$blocks_per_pattern[-5]

mod$ctl$size_selex_parms[grepl("WA_REC", rownames(mod$ctl$size_selex_parms)),"Block"] <- 0

mod$ctl$size_selex_parms_tv <- mod$ctl$size_selex_parms_tv[
  !grepl('BLK5repl_2006', rownames(mod$ctl$size_selex_parms_tv)),]

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

tictoc::tic()
r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          show_in_console = FALSE,
          skipfinished = FALSE)
tictoc::toc()

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)


####------------------------------------------------####
### 7_2_2_WArec_reweight - 720 results in correlation with early rec ascendning and peak. Reweight WA rec ----
####------------------------------------------------####

new_name <- "7_2_2_WArec_reweight"
old_name <- "7_2_0_WArec_comb_late_block"

##
#Copy inputs
##

mod <- SS_read(here('models',old_name))

##
#Make changes
##

#Use adjustments in suggested tunings in model 7_2_0 for WA rec length and age
mod$ctl$Variance_adjustment_list[mod$ctl$Variance_adjustment_list$Fleet == 9,"Value"] <- c(0.4546, 0.419027)

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

tictoc::tic()
r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          show_in_console = FALSE,
          skipfinished = FALSE)
tictoc::toc()

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)


####------------------------------------------------####
### 7_2_4_WArec_fix_ascend - 721 results in correlation with early rec ascendning and peak. Fix ascend at estimate ----
####------------------------------------------------####

new_name <- "7_2_4_WArec_fix_ascend"
old_name <- "7_2_0_WArec_comb_late_block"

##
#Copy inputs
##

mod <- SS_read(here('models',old_name))

##
#Make changes
##

pp <- SS_output(here('models',old_name))

#Fix at value of estimate from 7_2_0
mod$ctl$size_selex_parms[grep("P_3_9_WA_REC", rownames(mod$ctl$size_selex_parms)), c("INIT","PHASE")] <- c(
  pp$parameters[pp$parameters$Label=="Size_DblN_ascend_se_9_WA_REC(9)","Value"], -99)


##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

tictoc::tic()
r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          show_in_console = FALSE,
          skipfinished = FALSE)
tictoc::toc()

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)

####------------------------------------------------####
### 7_3_0_WArec_no_late_block - late WA Rec selectivity same as first block ----
####------------------------------------------------####

new_name <- "7_3_0_WArec_no_late_block"
old_name <- "7_0_2_hessian"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models', old_name), 
               dir.new = here('models', new_name), 
               overwrite = TRUE)
mod <- SS_read(here('models',old_name))

##
#Make changes
##

mod$ctl$Block_Design[[5]] <- c(2006, 2020)
mod$ctl$blocks_per_pattern[5] <- 1
mod$ctl$size_selex_parms_tv <- mod$ctl$size_selex_parms_tv[
  -grep('BLK5repl_2021', rownames(mod$ctl$size_selex_parms_tv)),]

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

tictoc::tic()
r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          # extras = '-nohess',
          show_in_console = TRUE,
          skipfinished = FALSE)
tictoc::toc()

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

####------------------------------------------------####
### 7_3_1_ORntwl_no_late_block - late OR NTWL selectivity same as first block ----
####------------------------------------------------####

new_name <- "7_3_1_ORntwl_no_late_block"
old_name <- "7_3_0_WArec_no_late_block"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models', old_name), 
               dir.new = here('models', new_name), 
               overwrite = TRUE)
mod <- SS_read(here('models',old_name))

##
#Make changes
##

mod$ctl$Block_Design[[2]] <- c(2000, 2019)
mod$ctl$blocks_per_pattern[2] <- 1
mod$ctl$size_selex_parms_tv <- mod$ctl$size_selex_parms_tv[
  -grep('BLK2repl_2020', rownames(mod$ctl$size_selex_parms_tv)),]

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

tictoc::tic()
r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          # extras = '-nohess',
          show_in_console = TRUE,
          skipfinished = FALSE)
tictoc::toc()

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26))

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('7_0_2_hessian',
                                                 '7_3_0_WArec_no_late_block',
                                                 new_name)))

xx.sum <- r4ss::SSsummarize(xx)

xx.sum |>
  SSplotComparisons(legendlabels = c('Add omitted commercial ages',
                                     'mirror WA Rec to early',
                                     'mirror OR NTWL to early'),
                    subplot = c(1,3,9,11), print = TRUE, plotdir = here('models',new_name))

xx.sum |> 
  SStableComparisons() |>
  `colnames<-`(c('', 'Full blocking', 'WA Rec mirrored early', 'OR NTWL mirrored early')) |>
  write.csv(here('models', new_name, 'table_comp.csv'), row.names = FALSE)

####------------------------------------------------####
### 7_3_2_tuned - tune 7_3_1 ----
####------------------------------------------------####

new_name <- "7_3_2_tuned"
old_name <- "7_3_1_ORntwl_no_late_block"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models', old_name), 
               dir.new = here('models', new_name), 
               overwrite = TRUE)
file.copy(from = file.path(here('models',old_name),"Report.sso"),
          to = file.path(here('models',new_name),"Report.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models',old_name),"CompReport.sso"),
          to = file.path(here('models',new_name),"CompReport.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models',old_name),"warning.sso"),
          to = file.path(here('models',new_name),"warning.sso"), overwrite = TRUE)
file.copy(from = file.path(here('models',old_name),"covar.sso"),
          to = file.path(here('models',new_name),"covar.sso"), overwrite = TRUE)

pp <- SS_output(here('models',new_name))

##
#Make changes
##

xx=r4ss::tune_comps(replist = pp, 
                    option = 'Francis', 
                    dir = here('models', new_name), 
                    exe = here('models/ss_win.exe'), 
                    niters_tuning = 5, 
                    extras = '-nohess',
                    allow_up_tuning = TRUE)

pp <- SS_output(here('models',new_name))
SS_plots(pp)


####------------------------------------------------####
### 7_3_3_tuned_full_blocks - full blocks using retuned model ----
####------------------------------------------------####

new_name <- "7_3_3_tuned_full_blocks"
old_name <- "7_3_2_tuned"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models', old_name), 
               dir.new = here('models', new_name), 
               overwrite = TRUE)

mod <- SS_read(here('models',old_name))

##
#Make changes
##

old.selex <- SS_read(here('models/7_0_2_hessian'))

mod$ctl$Block_Design[[2]] <- c(2000, 2019, 2020, 2022)
mod$ctl$blocks_per_pattern[2] <- 2
mod$ctl$Block_Design[[5]] <- c(2006, 2020, 2021, 2022)
mod$ctl$blocks_per_pattern[5] <- 2

mod$ctl$size_selex_parms_tv <- old.selex$ctl$size_selex_parms_tv

##
#Output files and run
##

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)


xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('7_0_2_hessian',
                                                 '7_3_0_WArec_no_late_block',
                                                 '7_3_1_ORntwl_no_late_block',
                                                 '7_3_2_tuned',
                                                 '7_3_3_tuned_full_blocks')))

xx.sum <- r4ss::SSsummarize(xx)

xx.sum |>
  SSplotComparisons(legendlabels = c('Add omitted commercial ages',
                                     '+ mirror WA Rec to early',
                                     '+ mirror OR NTWL to early',
                                     '+ retune',
                                     'Full block structure, new weights'),
                    subplot = c(1,3,9,11), print = TRUE, plotdir = here('models',new_name))

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c(new_name,
                                                 '7_3_2_tuned')))

xx.sum <- r4ss::SSsummarize(xx)

xx.sum |> 
  SStableComparisons() |>
  `colnames<-`(c('', 'Full blocking', 'OR NTWL mirrored early')) |>
  write.csv(here('models', new_name, 'table_comp.csv'), row.names = FALSE)
