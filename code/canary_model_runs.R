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
### 0_1_1_update_data
####------------------------------------------------####

##
#Copy inputs
##

# Kiva: happy to use a numbering scheme, but if it's not just 1, 2, 3, ..., 
# I don't understand what kind of change increments which number.

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


# Update survey comps -----------------------------------------------------

length.min <- min(mod$dat$lbin_vector)
length.max <- max(mod$dat$lbin_vector)
age.min <- min(mod$dat$agebin_vector)
age.max <- max(mod$dat$agebin_vector)

caal <- marginal.ages <- marginal.lengths <- list()
for(ii in 1:4) {
  area <- c('CA', 'OR', 'WA', 'coastwide')[ii]
  fleet_num <- fleet.converter$fleet[grep(x = fleet.converter$fleet_no_num, 
                                          pattern = paste0(area, '_NWFSC'))]
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

# NAs in lbin low and lbin hi
# These are all with ages in the first age bin so assume for now these are the first length bin
# until can confirm what is going on
mod$dat$agecomp[which(is.na(mod$dat$agecomp$Lbin_hi)),c("Lbin_lo","Lbin_hi")] <- 1

# Not updating triennial comps, those have not changes nor have our methods.
# Note: consider switching triennial to marginal ages.

# TO DO: Update ageing error matrices ----------------------------------------------------

# Update fishery comps ----------------------------------------------------

#TO DO: Need to add correct ageerr values

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
                                                                       fleet = .fleet)]),
      ageerr = 1) |> 
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
                  ageErr = 1) |> #non-expanded has different names than expanded so ageErr here
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
                    subplots = c(2,4), print = TRUE, plotdir = here('models/0_1_1_update_data'))


####------------------------------------------------####
### 0_1_1_update_data_ageErr - NEED TO COMPLETE
####------------------------------------------------####

##
#Copy inputs
##

# I suggest not touching converted, or transition. That was just for updating SS3
# version, and plus just enough changes so that it actually ran. It was not 100% reproducible.
copy_SS_inputs(dir.old = here('models/0_1_1_update_data'), 
               dir.new = here('models/0_1_2_ageErr'),
               overwrite = TRUE)

mod <- SS_read(here('models/0_1_2_ageErr'))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)


##
#Make Changes
##

#----

# TO DO: Update ageing error matrices ----------------------------------------------------

#TO DO: Need to add correct ageerr values

#----


##
#Output files and run
##

SS_write(mod,
         dir = here('models/0_1_2_ageErr'),
         overwrite = TRUE)

r4ss::run(dir = here('models/0_1_2_ageErr'), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)


##
#Comparison plots
##

pp <- SS_output(here('models/0_1_2_ageErr'),covar=FALSE)
SS_plots(pp)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('2015base', 'converted', '0_1_1_update_data', '0_1_2_ageErr')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015', 'converted', '2023 data update', 'add ageErr'),
                    subplots = c(2,4), print = TRUE, plotdir = here('models/0_1_2_ageErr'))


####------------------------------------------------####
### 0_2_1_update_bio
####------------------------------------------------####


##
#Copy inputs
##
copy_SS_inputs(dir.old = here('models/0_1_1_update_data'), 
               dir.new = here('models/0_2_1_update_bio'),
               overwrite = TRUE)

mod <- SS_read(here('models/0_2_1_update_bio'))


##
#Make Changes
##
#----
# Update M as a single offset value ------------------------------------------------
mod$ctl$natM_type <- 0
mod$ctl$parameter_offset_approach <- 2 #because not having breakpoints
#Remove second M breakpoint parameters
mod$ctl$MG_parms <- mod$ctl$MG_parms[-grep("NatM_p_2",rownames(mod$ctl$MG_parms)),]

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
mod$ctl$MG_parms['Eggs_alpha_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type')] <- c(
  0,0.1,
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
         dir = here('models/0_2_1_update_bio'),
         overwrite = TRUE)

r4ss::run(dir = here('models/0_2_1_update_bio'), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)

##
#Comparison plots
##

pp <- SS_output(here('models/0_2_1_update_bio'),covar=FALSE)
SS_plots(pp)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('2015base', '0_1_1_update_data', '0_2_1_update_bio')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015', '2023 data update', '2023 data bio'),
                    subplots = c(2,4), print = TRUE, plotdir = here('models/0_2_1_update_bio') )


####------------------------------------------------####
### 0_2_2_Mconstant update bio M individually
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
# Update M as a single offset value ------------------------------------------------
mod$ctl$natM_type <- 0
mod$ctl$parameter_offset_approach <- 2 #because not having breakpoints
#Remove second M breakpoint parameters
mod$ctl$MG_parms <- mod$ctl$MG_parms[-grep("NatM_p_2",rownames(mod$ctl$MG_parms)),]

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
SS_plots(pp)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_1_1_update_data', '0_2_1_update_bio',new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015', '2023 data update', '2023 data bio', "Mconstant"),
                    subplots = c(2,4))


####------------------------------------------------####
### 0_2_3_maturity update bio maturity individually
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
SS_plots(pp)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_1_1_update_data', '0_2_1_update_bio',new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015', '2023 data update', '2023 data bio', "maturity"),
                    subplots = c(2,4))


####------------------------------------------------####
### 0_2_4_steepness update bio steepness individually
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
SS_plots(pp)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_1_1_update_data', '0_2_1_update_bio',new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015', '2023 data update', '2023 data bio', "steepness"),
                    subplots = c(2,4))


####------------------------------------------------####
### 0_2_5_fecund update bio fecundity individually
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
mod$ctl$MG_parms['Eggs_alpha_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type')] <- c(
  0,0.1,
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
SS_plots(pp)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_1_1_update_data', '0_2_1_update_bio',new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015', '2023 data update', '2023 data bio', "fecundity"),
                    subplots = c(2,4))


####------------------------------------------------####
### 0_2_6_WL update bio WL individually
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
SS_plots(pp)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('0_1_1_update_data', '0_2_1_update_bio',new_name)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015', '2023 data update', '2023 data bio', "weight-length"),
                    subplots = c(2,4))


##########################################################################################
#               Explorations with up-to-date current version to decide base
##########################################################################################


####------------------------------------------------####
### Model name here with numbering (starting with 1_0_0)
####------------------------------------------------####


##
#Copy inputs
##


##
#Make Changes
##
#----

#----


##
#Output files and run
##


##
#Comparison plots
##




##########################################################################################

#Sensitivities on base can probably go into separate script called sensitivities
##########################################################################################


