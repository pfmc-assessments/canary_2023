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

# No triennial
# Triennial combined
# Estimate state by state or CA selectivity
# Only include commercial data from fisheries (no rec or non-trawl)
# Fix growth, remove CAAL

# Expand survey data comps
