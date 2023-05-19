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

#Add file managing section here 
#I will try to get 'here' to work but if I cant I will go with what I had
if(Sys.getenv("USERNAME") == "Brian.Langseth") {
 wd = "L:/"
}
if(Sys.getenv("USERNAME") == "Kiva.Oken") {
  wd = "Q:/"
}



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

#----
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
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_REC',
                                                                                           area = .x)],
                  ageErr = 1) |> #non-expanded has different names than expanded so ageErr here
    `names<-`(names(mod$dat$agecomp))
}) |>
  purrr::list_rbind()

ashop.lengths <- purrr::map(list('OR', 'WA'), function(.x) {
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

#----


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

#----
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


#----


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

#----
mod$start$detailed_age_structure <- 1 #all output
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



#----


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

#----
mod$start$detailed_age_structure <- 1 #all output
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


#----


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

#----
mod$start$detailed_age_structure <- 1 #all output
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


#----


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

#----
mod$start$detailed_age_structure <- 1 #all output
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
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_REC',
                                                                                           area = .x)],
                  ageErr = 1) |> #non-expanded has different names than expanded so ageErr here
    `names<-`(names(mod$dat$agecomp))
}) |>
  purrr::list_rbind()

ashop.lengths <- purrr::map(list('OR', 'WA'), function(.x) {
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


#----


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

#----
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
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_REC',
                                                                                           area = .x)],
                  ageErr = 1) |> #non-expanded has different names than expanded so ageErr here
    `names<-`(names(mod$dat$agecomp))
}) |>
  purrr::list_rbind()

ashop.lengths <- purrr::map(list('OR', 'WA'), function(.x) {
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


#----


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

new_name <- '0_1_8_survey'

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

#----
mod$start$detailed_age_structure <- 1 #all output

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
#----


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

#----
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
#----


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
#----
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

#----

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
#----
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

#----

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
#----
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
#----

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
#----
# Update maturity ------------------------------------------------
a50_fxn <- 10.87
slope_fxn <- -0.688
mod$ctl$maturity_option <- 2 #age logistic
mod$ctl$MG_parms['Mat50%_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD')] <- 
  c(9, 12, a50_fxn, a50_fxn, 0.055)
#----

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
#----
# Update steepness ------------------------------------------------
#per best practices: https://www.pcouncil.org/documents/2023/03/accepted-practices-and-guidelines-for-groundfish-stock-assessments.pdf/
mod$ctl$SR_parms['SR_BH_steep', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type')] <- 
  c(0.21, 0.99, 0.72, 0.72, 0.16, 2)
#----

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
#----
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
#----

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
#----
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
#----

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
#----
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

#----

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
#----
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
#----

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
#----
# Set breakpoints to ages 20 and 21, when female sex ratio declines
mod$ctl$M_ageBreakPoints[[1]] <- 20
mod$ctl$M_ageBreakPoints[[2]] <- 21

#----

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
#----
# Fix male M at the prior, estimate female m
mod$ctl$MG_parms['NatM_p_1_Mal_GP_1', 'PHASE'] <- -50

#----

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
#----
# Base female longevity on 99.99% quantile of commercial ages. Rec and survey ages are lower
max.age <- 55
mod$ctl$MG_parms['NatM_p_1_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PHASE')] <- c(
  0.02, 0.2,
  round(5.4/max.age, 4), 
  round(log(5.4/max.age), 2), 
  0.31, 2 #estimate female M
)

#----

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
#----
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
#----

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
# 0_3_1 Move to coastwide model -------------------------------------------------
##########################################################################################

new_name <- "0_3_1_coastwide"

##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/0_2_1_update_bio_Mval'), 
               dir.new = here('models',new_name),
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

#----

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

out <- r4ss::SS_output(here('models',new_name))
r4ss::SS_plots(replist = out)


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
  SSplotComparisons(legendlabels = c('2015', '2015 new SS', '2023 data update', '2023 bio update', 
                                     'Mval', 'maturity', 'steepness', 'fecundity', 'WL',
                                     'Mcons-maleFix', 'hessian'),
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
#----
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

#----


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
#----
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
#----


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
### 0_4_3_selexBlocks Update selectivity blocks to new years ---- 
####------------------------------------------------####

new_name <- "0_4_3_selexBlocks"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_4_2_selexSetup'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))



##
#Make Changes
##
#----
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

selex_new <- mod$ctl$size_selex_parms
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 1
selex_new[grepl('_TWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2

selex_new[grepl('CA_NTWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block', 'Block_Fxn')] <- 2
selex_new[grepl('OR_NTWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 4
selex_new[grepl('OR_NTWL', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 2
#WA NTWL is set to mirror WA TWL. It mirrors better with OR NTWL so could change that

selex_new[grepl('CA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 3
selex_new[grepl('CA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block_Fxn')] <- 1
selex_new[grepl('OR_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 4
selex_new[grepl('OR_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block', 'Block_Fxn')] <- 2
selex_new[grepl('WA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 5
selex_new[grepl('WA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block', 'Block_Fxn')] <- 2

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
#----


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
                                                 '0_4_2_selexSetup',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('SS3 inputs', 'selex set up', 'selex blocks'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))



####------------------------------------------------####
### 0_4_4_selexFree ---- Free up selectivity by state
####------------------------------------------------####

new_name <- "0_4_4_selexFree"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/0_4_3_selexBlocks'), 
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))



##
#Make Changes
##
#----

#----


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
                                                 '0_4_2_selexSetup',
                                                 '0_4_3_selexBlocks',
                                                 new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('SS3 inputs', 'selex set up', 'selex blocks', 'selex no mirror'),
                    subplots = c(1,3), print = TRUE, plotdir = here('models',new_name))




##########################################################################################

#Sensitivities on base can probably go into separate script called sensitivities
##########################################################################################


