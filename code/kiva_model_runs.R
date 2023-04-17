# code to update ss3 files and run them. various exploratory runs.

library(r4ss)
library(here)

r4ss::run(dir = here('models/2015base'), exe = 'ss3.exe', #extras = '-nohess', 
          show_in_console = FALSE, skipfinished = FALSE)

copy_SS_inputs(dir.old = here('models/2015base'), 
               dir.new = here('models/transition'))

mod <- SS_read(here('models/converted'))

fleet.converter <- mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)

# eliminate age comp rows with input sample sizes of zero (From Triennial)
mod$dat$agecomp <- mod$dat$agecomp[mod$dat$agecomp[,'Nsamp'] > 0,]

# prerecruit survey needs to be redefined for 3.30
mod$dat$fleetinfo$units[grep('prerec', mod$dat$fleetinfo$fleetname)] <- 32

r4ss::SS_writedat(mod$dat, outfile = here('models/converted/data.ss'), 
                  overwrite = TRUE)

# prerecruit survey needs to be redefined for 3.30
mod$ctl$size_selex_types$Pattern <- sapply(mod$ctl$size_selex_types$Pattern, 
                                                 function(x) ifelse(x == 32, 0, x))

# per warnings file "simpler and takes 1 parm for each settlement"
mod$ctl$recr_dist_method <- 3
# This messes up the ctl file, but I can't figure out what is wrong.

r4ss::SS_write(mod, 
               dir = here('models/converted_rec_dist3'), 
               overwrite = TRUE)

r4ss::run(dir = here('models/converted_rec_dist3'), 
          exe = here('models/converted/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = TRUE, 
          skipfinished = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('2015base', 'converted')))

SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015', 'update SS3 version'))

SS_output(dir = here('models/converted')) |>
  SS_plots()

# Remove research catches -------------------------------------------------

r4ss::copy_SS_inputs(dir.old = here('models/converted'),
                     dir.new = here('models/no_research_catch'), 
                     overwrite = TRUE)

mod <- r4ss::SS_read(dir = here('models/no_research_catch'))
survey.ind <- grep(mod$dat$fleetinfo$fleetname, pattern = 'Tri|NWFSC')
mod$dat$catch <- dplyr::filter(mod$dat$catch, 
                                           !(fleet %in% survey.ind)) 
mod$dat$fleetinfo$type[survey.ind] <- 3

# Change fishing mortality to year-round, gets rid of ss3 warnings
mod$dat$fleetinfo$surveytiming[mod$dat$fleetinfo$type==1] <- -1

r4ss::SS_write(mod, 
               dir = here('models/no_research_catch'), 
               overwrite = TRUE)
r4ss::run(dir = here('models/no_research_catch'), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE, 
          skipfinished = FALSE)
beepr::beep()

SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                subdir = c('2015base', 'converted', 'no_research_catch'))) |>
  SSsummarize() |>
  SSplotComparisons(legendlabels = c('2015', 'update SS3 version', 'no research catch'))
# Differences are generally not discernible.


# Update natural mortality ------------------------------------------------
r4ss::copy_SS_inputs(dir.old = here('models/no_research_catch'),
                     dir.new = here('models/updateM'), 
                     copy_exe = TRUE)
mod <- r4ss::SS_read(dir = here('models/updateM'))

mod$ctl$M_ageBreakPoints <- c(20,21) # or something
# I *think* it does still need two breakpoints. Otherwise it will only estimate one M per sex

max.age <- 84
mod$ctl$MG_parms['NatM_p_1_Fem_GP_1', c('INIT', 'PRIOR', 'PR_SD')] <- c(
  round(5.4/max.age, 4), 
  round(log(5.4/max.age), 2), 
  0.31
)
# I think we should use one M for young females and all males.

SS_write(mod, 
         dir = here('models/updateM'), 
         overwrite = TRUE)

r4ss::run(dir = here('models/updateM'), 
          exe = 'ss_win.exe', 
          extras = '-nohess', 
          show_in_console = FALSE, 
          skipfinished = FALSE)

SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                subdir = c('2015base', 'no_research_catch', 'updateM'))) |>
  SSsummarize() |>
  SSplotComparisons(legendlabels = c('2015', 'no research catch', 'update M'))
# Improvement in status. 

# update m prior only -----------------------------------------------------

r4ss::copy_SS_inputs(dir.old = here('models/no_research_catch'),
                     dir.new = here('models/updateM_prior'), 
                     copy_exe = TRUE)
mod <- r4ss::SS_read(dir = here('models/updateM_prior'))

max.age <- 84
mod$ctl$MG_parms['NatM_p_1_Fem_GP_1', c('INIT', 'PRIOR', 'PR_SD')] <- c(
  round(5.4/max.age, 4), 
  round(log(5.4/max.age), 2), 
  0.31
)
# I think we should use one M for young females and all males.

SS_write(mod, 
         dir = here('models/updateM_prior'), 
         overwrite = TRUE)

r4ss::run(dir = here('models/updateM_prior'), 
          exe = 'ss_win.exe', 
          extras = '-nohess', 
          show_in_console = FALSE, 
          skipfinished = FALSE)

SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                subdir = c('2015base', 'no_research_catch',  'updateM_prior', 'updateM'))) |>
  SSsummarize() |>
  SSplotComparisons(legendlabels = c('2015', 'no research catch', 'update M prior', 'update M ramp'))
# Updating M prior changes status up a LOT. Updating ramp made status worse, but still better than 2015.
# This makes sense, changing ramp essentially decreases natural mortality of teenage fish.

# I think updating the ramp in particular might improve wcgbts fits slightly if you squint?


# Add catch data ----------------------------------------------------------

r4ss::copy_SS_inputs(dir.old = here('models/no_research_catch'),
                     dir.new = here('models/update_catch'),
                     overwrite = TRUE)
mod <- r4ss::SS_read(dir = here('models/update_catch'))

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
                catch_se = 0.01) |>
  dplyr::select(year = Year, seas, fleet, catch, catch_se) |>
  rbind(c(-999, 1, 1, 0, 0.01)) |>
  dplyr::arrange(fleet, year) |>
  as.data.frame()

mod$dat$catch <- updated.catch.df

SS_write(mod, 
         dir = here('models/update_catch'), 
         overwrite = TRUE)

r4ss::run(dir = here('models/update_catch'), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE, 
          skipfinished = FALSE)
beepr::beep()

SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                subdir = c('2015base','no_research_catch', 'update_catch'))) |>
  SSsummarize() |>
  SSplotComparisons(legendlabels = c('2015', 'no research catch', 'extend catch'),
                    subplots = c(9,3,1))


# extend wcgbts ------------------------------------------------------------

r4ss::copy_SS_inputs(dir.old = here('models/update_catch'),
                     dir.new = here('models/update_wcgbts'), overwrite = TRUE)
mod <- r4ss::SS_read(dir = here('models/update_wcgbts'))

wcgbts.cpue <- read.csv(here('data/wcgbts_index.csv')) |>
  dplyr::mutate(area = ifelse(area == 'coastwide',
                              area,
                              stringr::str_to_upper(area)),
                fleet_no_num = paste0(area, '_NWFSC')) |>
  dplyr::left_join(fleet.converter) |> 
  dplyr::mutate(seas = 7) |>
  dplyr::select(year = Year, seas, index = fleet, obs = est, se_log = se)

mod$dat$CPUE <- mod$dat$CPUE |>
  dplyr::filter(!(index %in% wcgbts.cpue$index)) |>
  dplyr::bind_rows(wcgbts.cpue) |>
  dplyr::arrange(index, year) 

SS_write(mod,
         dir = here('models/update_wcgbts'), 
         overwrite = TRUE)

r4ss::run(dir = here('models/update_wcgbts'), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)
beepr::beep()

SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                subdir = c('no_research_catch', 'update_catch', 'update_wcgbts'))) |>
  SSsummarize() |>
  SSplotComparisons(legendlabels = c('no research catch', 'extend catch', 'extend wcgbts'),
                    subplots = c(9,3,1))

# Update wcgbts comps -----------------------------------------------------
r4ss::copy_SS_inputs(dir.old = here('models/update_wcgbts'),
                     dir.new = here('models/update_wcgbts_comps'), overwrite = TRUE)
mod <- r4ss::SS_read(dir = here('models/update_wcgbts_comps'))


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
  dplyr::filter(FltSvy != 28, Lbin_lo > 0) |> # This is not a good long-term thing to do!
  # caal table is in absolute length, update.wcgbts is in length index.
  # Updating caal to be in length index
  dplyr::mutate(dplyr::across(Lbin_lo:Lbin_hi, ~ match(.x, mod$dat$lbin_vector)))

marginal.ages.dfr <- marginal.ages |>
  purrr::list_rbind() 
# Since the marginal ages are not in the likelihood and only used for diagnostics,
# I am keeping the coastwide survey in, since base model likely to be coastwide.
  
marginal.lengths.dfr <- marginal.lengths |>
  purrr::list_rbind() |>
  dplyr::filter(FltSvy != 28) # Again, this is excluding the coastwide index
                                           # from the comps
  
mod$dat$agecomp <- mod$dat$agecomp |> 
  dplyr::filter(!(FltSvy %in% unique(caal.dfr$FltSvy)),
                !(FltSvy %in% unique(marginal.ages.dfr$FltSvy))) |>
  dplyr::bind_rows(caal.dfr, marginal.ages.dfr)

mod$dat$lencomp <- mod$dat$lencomp |> 
  dplyr::filter(!(FltSvy %in% unique(marginal.lengths.dfr$FltSvy))) |>
  dplyr::bind_rows(marginal.lengths.dfr)

SS_write(mod,
         dir = here('models/update_wcgbts_comps'), 
         overwrite = TRUE)

r4ss::run(dir = here('models/update_wcgbts_comps'), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)
beepr::beep()

out <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                subdir = c('no_research_catch',  'update_catch', 
                                           'update_wcgbts', 'update_wcgbts_comps'))) |>
  SSsummarize()

SSplotComparisons(out, legendlabels = c('no research catch', 'update catch', 
                                        'update wcgbts', 'update wcgbts comps'),
                  subplots = c(9,3,1))

SStableComparisons(out, modelnames = c('no research catch', 'update catch', 
                                       'update wcgbts', 'update wcgbts comps'))

# have checked, these differences are indeed due to new comps, not
# differences in old comps
r4ss::SS_output(here('models/update_wcgbts_comps')) |>
  r4ss::SS_plots()



# Add fishery comps -------------------------------------------------------

r4ss::copy_SS_inputs(dir.old = here('models/update_wcgbts_comps'),
                     dir.new = here('models/update_commercial_comps'), overwrite = TRUE)
mod <- r4ss::SS_read(dir = here('models/update_commercial_comps'))


length.min <- min(mod$dat$lbin_vector)
length.max <- max(mod$dat$lbin_vector)
age.min <- min(mod$dat$agebin_vector)
age.max <- max(mod$dat$agebin_vector)

ages <- purrr::map(list('CA', 'OR', 'WA'), function(.x) {
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

lengths <- purrr::map(list('CA', 'OR', 'WA'), function(.x) {
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

rec.comps <- purrr::map(list('CA', 'OR', 'WA'), function(.x) {
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
  dplyr::filter(!(FltSvy %in% unique(ages$FltSvy))) |>
  dplyr::bind_rows(ages)

mod$dat$lencomp <- mod$dat$lencomp |> 
  dplyr::filter(!(FltSvy %in% unique(lengths$FltSvy)),
                !(FltSvy %in% unique(rec.comps$FltSvy))) |>
  dplyr::bind_rows(lengths, rec.comps)


SS_write(mod,
         dir = here('models/update_commercial_comps'), 
         overwrite = TRUE)

r4ss::run(dir = here('models/update_commercial_comps'), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)
beepr::beep()

out <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                       subdir = c('no_research_catch',  'update_catch', 
                                                  'update_wcgbts_comps','update_commercial_comps'))) |>
  SSsummarize()

SSplotComparisons(out, legendlabels = c('no research catch', 'update catch', 
                                        'update wcgbts', 'catch comps'),
                  subplots = c(9,3,1))

SStableComparisons(out, modelnames = c('no research catch', 'update catch', 
                                       'update wcgbts', 'update wcgbts comps'))

SS_output(dir = here('models/update_commercial_comps')) |>
  SS_plots()


# coastwide model ---------------------------------------------------------

r4ss::copy_SS_inputs(dir.old = here('models/update_commercial_comps'),
                     dir.new = here('models/coastwide'), overwrite = TRUE)
mod <- r4ss::SS_read(dir = here('models/coastwide'))

# oopsies
mod$ctl$MainRdevYrLast <- 2022
mod$ctl$last_yr_fullbias_adj <- 2020

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

# need to add in CAAL for coastwide surveys
# marginal coastwide lengths are already there
# marginal age comps for wcgbts are there
# need to add marginal age comps for coastwide triennial

caal.dfr <- caal$coastwide |>
  purrr::list_rbind() |> 
  dplyr::filter(Lbin_lo > 0) |> 
  # caal table is in absolute length, update.wcgbts is in length index.
  # Updating caal to be in length index
  dplyr::mutate(dplyr::across(Lbin_lo:Lbin_hi, ~ match(.x, mod$dat$lbin_vector))) 


caal.tri <- purrr::map(list('Female', 'Male'), function(.x) {
  read.csv(here(glue::glue('data/coastwide_tri_comps/Survey_CAAL_{sex}_Bins_{lmin}_{lmax}_{amin}_{amax}.csv',
                           sex = .x, 
                           lmin = length.min, lmax = length.max,
                           amin = age.min, amax = age.max))) |>
    `names<-`(names(mod$dat$agecomp))
}) |>
  purrr::list_rbind() |> 
  dplyr::mutate(FltSvy = ifelse(Yr <= 1992, 
                                fleet.converter$fleet[fleet.converter$fleet_no_num == 'coastwide_Tri_early'],
                                fleet.converter$fleet[fleet.converter$fleet_no_num == 'coastwide_Tri_late']),
                dplyr::across(Lbin_lo:Lbin_hi, ~ match(.x, mod$dat$lbin_vector)))
                           
mod$dat$agecomp <- mod$dat$agecomp |> 
  # using negative year method instead
  # dplyr::filter(!(FltSvy %in% fleet.converter$fleet[state.surveys])) |>
  dplyr::bind_rows(caal.dfr, caal.tri)

# Negative out year of state survey data
# CPUE
mod$dat$CPUE$year[mod$dat$CPUE$index %in% state.surveys] <- -1 * 
  mod$dat$CPUE$year[mod$dat$CPUE$index %in% state.surveys]
# age comp
mod$dat$agecomp$Yr[mod$dat$agecomp$FltSvy %in% state.surveys] <- -1 *
  mod$dat$agecomp$Yr[mod$dat$agecomp$FltSvy %in% state.surveys]
# length comp
mod$dat$lencomp$Yr[mod$dat$lencomp$FltSvy %in% state.surveys] <- -1 *
  mod$dat$lencomp$Yr[mod$dat$lencomp$FltSvy %in% state.surveys]

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
selex_new['SizeSel_P_1_10_CA_AHSOP(10)', 'INIT'] <- 48

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

SS_write(mod,
         dir = here('models/coastwide'), 
         overwrite = TRUE)

r4ss::run(dir = here('models/coastwide'), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = TRUE,
          skipfinished = FALSE)
beepr::beep()

SS_output(dir = here('models/coastwide')) |>
  SS_plots()

# No triennial
# Triennial combined
# Estimate state by state or CA selectivity
# Only include commercial data from fisheries (no rec or non-trawl)
# Fix growth, remove CAAL
# Coastwide, no spatial
# Update M prior
# Update M ramp

# Expand survey data comps

# Set lambda = 0 for cpue, length, age comps for state surveys (use coastwide instead)
# Not using this approach, using negative year and no selectivity instead
# Keeping code for posterity, because I don't have the heart to delete it.
new.lambdas <- purrr::map(list(c('Surv', ''),
                               c('length', '_sizefreq_method_1'),
                               c('age', '')),
                          function(.x){
                            data.frame(like_comp = dplyr::case_when(.x[1] == 'Surv' ~ 1,
                                                                    .x[1] == 'length' ~ 4,
                                                                    .x[1] == 'age' ~ 5),
                                       fleet = fleet.converter$fleet[state.surveys],
                                       phase = 1,
                                       value = 0,
                                       sizefreq_method = 1) |>

                              `rownames<-`(glue::glue('{type}_{fleet}{other}_Phz1',
                                                      type = .x[1],
                                                      fleet = fleet.converter$fleetname[state.surveys],
                                                      other = .x[2]))
                          }) |>
  purrr::list_rbind()