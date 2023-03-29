# code to update ss3 files and run them. various exploratory runs.

library(r4ss)
library(here)

r4ss::run(dir = here('models/2015base'), exe = 'ss3.exe', #extras = '-nohess', 
          show_in_console = FALSE, skipfinished = FALSE)

copy_SS_inputs(dir.old = here('models/2015base'), 
               dir.new = here('models/transition'))

converted <- SS_read(here('models/converted'))

# eliminate age comp rows with input sample sizes of zero (From Triennial)
converted$dat$agecomp <- converted$dat$agecomp[converted$dat$agecomp[,'Nsamp'] > 0,]

# prerecruit survey needs to be redefined for 3.30
converted$dat$fleetinfo$units[grep('prerec', converted$dat$fleetinfo$fleetname)] <- 32

r4ss::SS_writedat(converted$dat, outfile = here('models/converted/data.ss'), 
                  overwrite = TRUE)

# prerecruit survey needs to be redefined for 3.30
converted$ctl$size_selex_types$Pattern <- sapply(converted$ctl$size_selex_types$Pattern, 
                                                 function(x) ifelse(x == 32, 0, x))

# Change fishing mortality to year-round, gets rid of ss3 warnings
converted$dat$fleetinfo$surveytiming[converted$dat$fleetinfo$type==1] <- -1

# per warnings file "simpler and takes 1 parm for each settlement"
converted$ctl$recr_dist_method <- 3
# This messes up the ctl file, but I can't figure out what is wrong.

r4ss::SS_write(converted, 
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
                     copy_exe = TRUE)
remove.research <- r4ss::SS_read(dir = here('models/no_research_catch'))
survey.ind <- grep(remove.research$dat$fleetinfo$fleetname, pattern = 'Tri|NWFSC')
remove.research$dat$catch <- dplyr::filter(remove.research$dat$catch, 
                                           !(fleet %in% survey.ind)) 
r4ss::SS_write(remove.research, 
               dir = here('models/no_research_catch'), 
               overwrite = TRUE)
r4ss::run(dir = here('models/no_research_catch'), 
          exe = 'ss_win.exe', 
          extras = '-nohess', 
          show_in_console = FALSE, 
          skipfinished = FALSE)

SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                subdir = c('2015base', 'converted', 'no_research_catch'))) |>
  SSsummarize() |>
  SSplotComparisons(legendlabels = c('2015', 'update SS3 version', 'no research catch'))
# Differences are generally not discernible.


# Update natural mortality ------------------------------------------------
r4ss::copy_SS_inputs(dir.old = here('models/no_research_catch'),
                     dir.new = here('models/updateM'), 
                     copy_exe = TRUE)
update.M <- r4ss::SS_read(dir = here('models/updateM'))

update.M$ctl$M_ageBreakPoints <- c(20,21) # or something
# I *think* it does still need two breakpoints. Otherwise it will only estimate one M per sex

max.age <- 84
update.M$ctl$MG_parms['NatM_p_1_Fem_GP_1', c('INIT', 'PRIOR', 'PR_SD')] <- c(
  round(5.4/max.age, 4), 
  round(log(5.4/max.age), 2), 
  0.31
)
# I think we should use one M for young females and all males.

SS_write(update.M, 
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
update.M <- r4ss::SS_read(dir = here('models/updateM_prior'))

max.age <- 84
update.M$ctl$MG_parms['NatM_p_1_Fem_GP_1', c('INIT', 'PRIOR', 'PR_SD')] <- c(
  round(5.4/max.age, 4), 
  round(log(5.4/max.age), 2), 
  0.31
)
# I think we should use one M for young females and all males.

SS_write(update.M, 
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

r4ss::copy_SS_inputs(dir.old = here('models/updateM'),
                     dir.new = here('models/update_catch'))
update.catch <- r4ss::SS_read(dir = here('models/update_catch'))

update.catch$dat$endyr <- 2022

catches <- read.csv(here('data/canary_total_removals.csv')) 

fleet.converter <- update.catch$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)

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

update.catch$dat$catch <- updated.catch.df

SS_write(update.catch, 
         dir = here('models/update_catch'), 
         overwrite = TRUE)

r4ss::run(dir = here('models/update_catch'), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE, 
          skipfinished = FALSE)


SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                subdir = c('no_research_catch',  'updateM_prior', 'updateM', 'update_catch'))) |>
  SSsummarize() |>
  SSplotComparisons(legendlabels = c('no research catch', 'update M prior', 'update M ramp', 'extend catch'),
                    subplots = c(9,3,1))


# extend wcgbts ------------------------------------------------------------

r4ss::copy_SS_inputs(dir.old = here('models/update_catch'),
                     dir.new = here('models/update_wcgbts'), overwrite = TRUE)
update.wcgbts <- r4ss::SS_read(dir = here('models/update_wcgbts'))

wcgbts.cpue <- read.csv(here('data/wcgbts_index.csv')) |>
  dplyr::mutate(area = ifelse(area == 'coastwide',
                              area,
                              stringr::str_to_upper(area)),
                fleet_no_num = paste0(area, '_NWFSC')) |>
  dplyr::left_join(fleet.converter) |> 
  dplyr::mutate(seas = 7) |>
  dplyr::select(year = Year, seas, index = fleet, obs = est, se_log = se)

update.wcgbts$dat$CPUE <- update.wcgbts$dat$CPUE |>
  dplyr::filter(!(index %in% wcgbts.cpue$index)) |>
  dplyr::bind_rows(wcgbts.cpue) |>
  dplyr::arrange(index, year) 

SS_write(update.wcgbts,
         dir = here('models/update_wcgbts'), 
         overwrite = TRUE)

r4ss::run(dir = here('models/update_wcgbts'), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)
beepr::beep()

SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                subdir = c('no_research_catch',  'updateM', 'update_catch', 'update_wcgbts'))) |>
  SSsummarize() |>
  SSplotComparisons(legendlabels = c('no research catch', 'update M', 'extend catch', 'extend wcgbts'),
                    subplots = c(9,3,1))

# Update wcgbts comps -----------------------------------------------------
r4ss::copy_SS_inputs(dir.old = here('models/update_catch'),
                     dir.new = here('models/update_wcgbts_comps'), overwrite = TRUE)
update.wcgbts <- r4ss::SS_read(dir = here('models/update_wcgbts_comps'))


length.min <- min(update.wcgbts$dat$lbin_vector)
length.max <- max(update.wcgbts$dat$lbin_vector)
age.min <- min(update.wcgbts$dat$agebin_vector)
age.max <- max(update.wcgbts$dat$agebin_vector)

caal <- list()
for(ii in 1:4) {
  area <- c('CA', 'OR', 'WA', 'coastwide')[ii]
  caal[[area]] <- purrr::map(list(`F` = 'Female', M = 'Male'), function(.x) {
    out <- read.csv(here(glue::glue('data/{area}_wcgbts_comps/Survey_CAAL_{sex}_Bins_{lmin}_{lmax}_{amin}_{amax}.csv',
                                    area = area,
                                    sex = .x,
                                    lmin = length.min,
                                    lmax = length.max,
                                    amin = age.min,
                                    amax = age.max)))
    out$Fleet <- fleet.converter$fleet[grep(x = fleet.converter$fleet_no_num,
                                            pattern = paste0(area, '_NWFSC'))]
    names(out) <- names(update.wcgbts$dat$agecomp)
    return(out)
  })
}

# need to add marginal ages as -surveys

caal.dfr <- caal |>
  purrr::list_flatten() |>
  purrr::list_rbind() |> 
  dplyr::mutate(dplyr::across(f1:f35, ~ ifelse(Gender == 1, .x, 0)),
                dplyr::across(m1:m35, ~ ifelse(Gender == 2, .x, 0))) |> # checked row sums, this works
  dplyr::filter(FltSvy != 28, Lbin_lo > 0) |> # This is not a good long-term thing to do!
  # caal table is in absolute length, update.wcgbts is in length index.
  # Updating caal to be in length index
  dplyr::mutate(dplyr::across(Lbin_lo:Lbin_hi, ~ match(.x, update.wcgbts$dat$lbin_vector))) 

update.wcgbts$dat$agecomp <- update.wcgbts$dat$agecomp |> 
  dplyr::filter(!(FltSvy %in% unique(caal.dfr$FltSvy))) |>
  dplyr::bind_rows(caal.dfr)

SS_write(update.wcgbts,
         dir = here('models/update_wcgbts_comps'), 
         overwrite = TRUE)

r4ss::run(dir = here('models/update_wcgbts_comps'), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)
beepr::beep()

SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                subdir = c('no_research_catch',  'updateM', 'update_catch', 
                                           'update_wcgbts', 'update_wcgbts_comps'))) |>
  SSsummarize() |>
  SSplotComparisons(legendlabels = c('no research catch', 'update M', 'update catch', 
                                     'update wcgbts', 'update wcgbts comps'),
                    subplots = c(9,3,1))

# survey alone did not move anything!
# 2015 comps have age comps in length bins that I do not think were observed! 
# At least not observed and aged.

# No triennial
# Triennial combined
# Estimate state by state or CA selectivity
# Only include commercial data from fisheries (no rec or non-trawl)
# Fix growth, remove CAAL

# Expand survey data comps