library(here)
library(r4ss)

base_mod_name <- '5_5_0_hessian'
base_mod <- SS_read(here('models', base_mod_name))
fleet.converter <- base_mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)

# Canadian catches --------------------------------------------------------

# This spreadsheet sums catches in Canadian areas 3C and 3D, i.e., 
# the West Coast of Vancouver Island. 
# There is one trawl time series and one non-trawl time series. 
# These are added to WA TWL and NTWL
# Time series begins in 1918, assume zero prior

canada_catches <- readxl::read_excel(here('data-raw/Canada_WCVI_calcs.xlsx'), 
                                     sheet = 'Catch', 
                                     range = 'O3:U108') |> 
  # filter(year >=1996, year <2022) |>
  # mutate(total = NTWL + Trawl) |>
  # summarize(mean(total)) # this was just to get recent average catches
  dplyr::filter(year < 2022) %>% # history was compiled in 2022, do not know where 2022 catches came from
  dplyr::add_row(year = 2022,
                 Trawl = mean(tail(.$Trawl, 5)),
                 NTWL = mean(tail(.$NTWL, 5))) |> # instead use mean of last 5 years
  dplyr::select(year, WA_TWL = Trawl, WA_NTWL = NTWL) |>
  dplyr::mutate(seas = 1, catch_se = 0.05) |>
  tidyr::pivot_longer(cols = c(WA_TWL, WA_NTWL), 
                      names_to = 'fleet_no_num', 
                      values_to = 'canada_catch') |>
  dplyr::left_join(fleet.converter) |>
  dplyr::select(-fleetname, -fleet_no_num) |>
  dplyr::right_join(base_mod$dat$catch) |> 
  dplyr::mutate(dplyr::across(c(catch, canada_catch),
                ~ tidyr::replace_na(., replace = 0)),
                catch = catch + canada_catch) |>
  dplyr::select(year, seas, fleet, catch, catch_se) |>
  as.data.frame()

mod <- base_mod
mod$dat$catch <- canada_catches

# Write model and run
new_name <- 'canada_catches'
SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE, 
          skipfinished = FALSE)
beepr::beep()

xx <- SSgetoutput(dirvec = c(glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c(base_mod_name,
                                                 file.path('sensitivities', new_name)))))

SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Base model',
                                     'Add WCVI catches to WA'),
                    print = TRUE, plotdir = here('models/sensitivities',new_name))

# compare rec devs
bc_recdevs <- readxl::read_excel(here('data-raw/CAR-data-for.BL.KO.xlsx'),
                                 sheet = 'Rdevs') |>
  dplyr::select(-1) |>
  tidyr::pivot_longer(cols = dplyr::everything(), names_to = 'Yr', values_to = 'recdev') |>
  dplyr::group_by(Yr) |>
  dplyr::summarise(dev = median(recdev)) |>
  dplyr::mutate(Yr = as.numeric(Yr),
                model = 'bc')

purrr::map(xx, ~ select(.$recruit, Yr, dev)) |> 
  `names<-`(c('Base', 'bc_catches')) |> 
  append(list(BC = bc_recdevs)) |> 
  dplyr::bind_rows(.id = 'Model') |> 
  filter(Model != 'bc_catches', Yr >= 1955) |>
  ggplot(aes(x = Yr, y = dev, col = Model)) +
  geom_line() + geom_point() +
  labs(x = 'Year', y = 'Rec Dev')

# These look nothing like each other. 
# BC also sees slow steady increase.
# WC sees slow steady decrease


# Prerecruit survey add 3 years -------------------------------------------

mod <- base_mod

prerecruit <- read.csv(here('data/canary_prerecruit_indices.csv')) |>
  dplyr::mutate(fleet_no_num = paste0(region, '_prerec')) |>
  dplyr::left_join(fleet.converter) |> 
  dplyr::mutate(seas = 7,
                YEAR = ifelse(region == 'coastwide', YEAR, -YEAR)) |>
  dplyr::select(year = YEAR, seas, index = fleet, obs = est, se_log = se)

mod$dat$CPUE <- mod$dat$CPUE |>
  dplyr::filter(!(index %in% unique(prerecruit$index))) |>
  dplyr::bind_rows(prerecruit)

new_name <- 'prerec_data'
SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE, 
          skipfinished = FALSE)
beepr::beep()


# Prerecruit units --------------------------------------------------------

mod <- base_mod

mod$dat$fleetinfo[grep('prerec', mod$dat$fleetinfo$fleetname), 'units'] <- 33

# Assume survey is recruitment index but occurs after density-dependence. 
# May be more statistically defensible? This was Owen's idea.

new_name <- 'prerec_units'
SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE, 
          skipfinished = FALSE)


# Sex-constant selectivity ------------------------------------------------

mod <- base_mod

mod$ctl$size_selex_parms[grep('PFemOff_3', rownames(mod$ctl$size_selex_parms)), 'PHASE'] <- -99
mod$ctl$size_selex_parms_tv[grep('PFemOff_3', rownames(mod$ctl$size_selex_parms_tv)), 'PHASE'] <- 99

new_name <- 'no_sex_selectivity'
SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE, 
          skipfinished = FALSE)


# M ramp ------------------------------------------------------------------

mod <- base_mod

mod$ctl$natM_type <- 1
mod$ctl$N_natM <- 2
mod$ctl$M_ageBreakPoints <- c(6, 14)

# Add extra rows to MG table
M.ind <- grep('NatM', rownames(mod$ctl$MG_parms))

mod$ctl$MG_parms <- mod$ctl$MG_parms[c(rep(M.ind[1], 2), (M.ind[1]+1):(M.ind[2]-1),
                                       rep(M.ind[2], 2), (M.ind[2]+1):(nrow(mod$ctl$MG_parms))),]
M.ind <- grep('1.1', rownames(mod$ctl$MG_parms))
rownames(mod$ctl$MG_parms)[M.ind] <- stringr::str_replace(rownames(mod$ctl$MG_parms)[M.ind], 
                                                          pattern = 'p_1', 
                                                          replacement = 'p_2') |>
  stringr::str_remove(pattern = '\\.1')

# Fix young female M at male M
mod$ctl$MG_parms['NatM_p_1_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type', 'PHASE')] <-
  mod$ctl$MG_parms['NatM_p_1_Mal_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type', 'PHASE')]

new_name <- 'M_ramp'
SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE, 
          skipfinished = FALSE)
