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
SS_write(mod, here('models/sensitivities', new_dir),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_dir), 
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
