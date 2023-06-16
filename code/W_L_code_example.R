# Estimate weight-length parameters
# I think this code is pretty good and should be added to nwfscSurvey

# read in data
wcgbts_date <- '2023-02-13'
triennial_date <- '2023-05-01'
load(here(paste0('data-raw/Bio_All_NWFSC.Combo_', wcgbts_date, '.rda')))

# plot data
ggplot(Data) +
  geom_point(aes(x = Length_cm, y = Weight, col = Sex),
             alpha = .1)
# There is really no sexual dimorphism, but whatever

# Estimate
W_L_pars <- Data |>
  dplyr::mutate(Sex = 'B') |>
  dplyr::bind_rows(Data) |>
  dplyr::filter(Sex %in% c('F', 'M', 'B')) |>
  tidyr::nest(data = -Sex) |> 
                                         # Fit model
  dplyr::mutate(fit = purrr::map(data, ~ lm(log(Weight) ~ log(Length_cm), data = .)),
                tidied = purrr::map(fit, broom::tidy),
                # Transform W-L parameters, account for lognormal bias
                out = purrr::map2(tidied, fit, function(.x, .y) {
                  sd_res <- sigma(.y)
                  .x |>
                    dplyr::mutate(term = c('A', 'B'),
                                  median = ifelse(term == 'A', exp(estimate), estimate),
                                  mean = ifelse(term == 'A', median * exp(0.5 * sd_res^2),
                                                median)) |>
                    dplyr::select(term, mean)
                }),
                n = purrr::map(fit, ~ length(resid(.)))) |>
  tidyr::unnest(c(out, n)) |>
  dplyr::select(Sex, term, mean, n) |>
  tidyr::pivot_wider(names_from = term, values_from = mean)

write.csv(W_L_pars, file = here('data/W_L_pars.csv'), row.names = FALSE)

# Plot W-L curves
W_L_pars |>
  dplyr::mutate(out.dfr = purrr::map2(A, B, ~ dplyr::tibble(x = 1:66, y = .x*x^.y))) |>
  tidyr::unnest(out.dfr) |>
  dplyr::filter(Sex != 'B') |>
  ggplot() +
  geom_point(aes(x = Length_cm, y = Weight, col = Sex), alpha = 0.05, 
             data = dplyr::filter(Data, Sex != 'U')) +
  geom_line(aes(x, y, col = Sex), linewidth = 1) +
  labs(x = 'Length (cm)', y = 'Weight') +
  scale_color_manual(values = c('F' = 'red', 'M' = 'blue')) +
  theme_classic()
