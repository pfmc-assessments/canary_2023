library(r4ss)
library(here)

r4ss::run(dir = here('models/2015base'), exe = 'ss3.exe', #extras = '-nohess', 
          show_in_console = FALSE, skipfinished = FALSE)

copy_SS_inputs(dir.old = here('models/2015base'), 
               dir.new = here('models/transition'))

data.converted <- SS_readdat(here('models/converted/data.ss'))
control.converted <- SS_readctl(here('models/converted/control.ss'), datlist = data.converted)

canary.converted <- SS_read(here('models/converted'))

canary.converted$dat$lbin_vector_pop

# eliminate age comp rows with input sample sizes of zero (From Triennial)
data.converted$agecomp <- data.converted$agecomp[data.converted$agecomp[,'Nsamp'] > 0,]

# prerecruit survey needs to be redefined for 3.30
data.converted$fleetinfo$units[grep('prerec', data.converted$fleetinfo$fleetname)] <- 32

r4ss::SS_writedat(data.converted, outfile = here('models/converted/data.ss'), 
                  overwrite = TRUE)

# prerecruit survey needs to be redefined for 3.30
control.converted$size_selex_types$Pattern <- sapply(control.converted$size_selex_types$Pattern, 
                                                     function(x) ifelse(x == 32, 0, x))

r4ss::SS_writectl(control.converted, outfile = here('models/converted/control.ss'), 
                  overwrite = TRUE)

r4ss::run(dir = here('models/converted'), exe = 'ss_win.exe', #extras = '-nohess', 
          show_in_console = FALSE, skipfinished = FALSE)

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                subdir = c('2015base', 'converted')))

SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015', 'update SS3 version'))

# No triennial
# Triennial combined
# Estimate state by state or CA selectivity
# Only include commercial data from fisheries (no rec or non-trawl)
# Fix growth, remove CAAL

# Expand survey data comps
