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
                     dir.new = here('models/update_commerical_comps'), overwrite = TRUE)
mod <- r4ss::SS_read(dir = here('models/update_commerical_comps'))


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
         dir = here('models/update_commerical_comps'), 
         overwrite = TRUE)

r4ss::run(dir = here('models/update_commerical_comps'), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)
beepr::beep()

out <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                       subdir = c('no_research_catch',  'update_catch', 
                                                  'update_wcgbts_comps','update_commerical_comps'))) |>
  SSsummarize()

SSplotComparisons(out, legendlabels = c('no research catch', 'update catch', 
                                        'update wcgbts', 'catch comps'),
                  subplots = c(9,3,1))

SStableComparisons(out, modelnames = c('no research catch', 'update catch', 
                                       'update wcgbts', 'update wcgbts comps'))

SS_output(dir = here('models/update_commerical_comps')) |>
  SS_plots()


# coastwide model ---------------------------------------------------------

r4ss::copy_SS_inputs(dir.old = here('models/update_commerical_comps'),
                     dir.new = here('models/coastwide'), overwrite = TRUE)
mod <- r4ss::SS_read(dir = here('models/coastwide'))

mod$ctl$N_areas <- mod$dat$N_areas <- 1
mod$ctl$recr_dist_read <- 1
mod$ctl$recr_dist_pattern <- mod$ctl$recr_dist_pattern[1,]
mod$ctl$MG_parms <- mod$ctl$MG_parms |>
  dplyr::slice(-grep('RecrDist_Area_2', rownames(mod$ctl$MG_parms)),
               -grep('RecrDist_Area_3', rownames(mod$ctl$MG_parms)))

mod$dat$fleetinfo$area <- 1
mod$dat$areas <- rep(1, mod$dat$Nfleets)
mod$dat$fleetinfo1['areas',] <- 1

state.surveys <- stringr::str_which(fleet.converter$fleet_no_num,
                                    '(?<!coastwide_)(NWFSC|Tri|prerec)')
# returns index for fleet names with NWFSC, Tri, or prerec NOT preceded by coastwide_
coastwide.surveys <- stringr::str_which(fleet.converter$fleet_no_num, 'coastwide')

# Set lambda = 0 for cpue, length, age comps for state surveys (use coastwide instead)
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

mod$ctl$lambdas <- mod$ctl$lambdas |>
  dplyr::filter(!(fleet %in% fleet.converter$fleet[coastwide.surveys])) |>
  dplyr::bind_rows(new.lambdas)

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
  dplyr::filter(!(FltSvy %in% fleet.converter$fleet[state.surveys])) |>
  dplyr::bind_rows(caal.dfr, caal.tri)

SS_write(mod, dir = here('models/coastwide'), overwrite = TRUE)
r4ss::run(dir = here('models/coastwide'), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE,
          skipfinished = FALSE)
beepr::beep()

# Need to deal with selectivity now. Probably:
# 1. free up selectivity by area
# 2. Fix a third double normal parameter. (I think standard is to fix three?)

# No triennial
# Triennial combined
# Estimate state by state or CA selectivity
# Only include commercial data from fisheries (no rec or non-trawl)
# Fix growth, remove CAAL
# Coastwide, no spatial
# Update M prior
# Update M ramp

# Expand survey data comps