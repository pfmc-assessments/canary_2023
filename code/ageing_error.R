library(nwfscAgeingError)
library(here)

git_dir <- here()

# this will load the WA PacFIN double reads
source(textConnection(readLines(here('code/canary_pacfin_comps.R'))[c(9:14,19:79)]))
# the number of wa ages with double reads after cleaning is 7858

# WA RecFIN double reads
source(textConnection(readLines(here('code/canary_recreational_comps.R'))[47:64]))

wdfw_for_estimation <- wa_dReads |>
  dplyr::mutate(dplyr::across(c(age1, agedby1), ~ ifelse(AGE_METHOD1 == 'S', NA, .x))) |>
  # no other ages are surface reads, just age1
  dplyr::filter(!is.na(FISH_AGE_YEARS_FINAL)) |>
  dplyr::select(age1, age2, age3, agedby1, agedby2, agedby3) |>
  dplyr::bind_rows(
    dplyr::select(wa_dReads_sport,
                  age1 = age_1, age2 = age_2, age3 = age_3,
                  agedby1 = age_reader_code_1, agedby2 = age_reader_code_2,
                  agedby3 = age_reader_code_3)
  ) |>
  dplyr::mutate(id = 1:dplyr::n(),
                dplyr::across(agedby1:agedby3, 
                              ~ paste0(stringr::str_remove(.x, '/[:alnum:]+'), # agency
                                       stringr::str_sub(dplyr::cur_column(), -1L)))) |> # reader number (1,2,3)
  tidyr::pivot_longer(cols = c(age1, age2, age3), names_to = 'reader_num', values_to = 'age') |>
  dplyr::filter(!is.na(age)) |>
  dplyr::mutate(ager = dplyr::case_when(reader_num == 'age1' ~ agedby1,
                                        reader_num == 'age2' ~ agedby2,
                                        reader_num == 'age3' ~ agedby3,
                                        TRUE ~ NA)) |>
  tidyr::pivot_wider(id_cols = id, names_from = ager, values_from = age) |> 
  dplyr::select(-NA1,-Unknown1, -id)

caps_double_reads <- readxl::read_excel(here('data-raw/Double_reads_all_CNRY_20230426.xlsx'), 
                                   sheet = 2, skip = 5) |>
  dplyr::filter(age_method != 'SR') 

caps_for_estimation <- caps_double_reads |> 
  dplyr::mutate(ager_id = 'NMFS1') |> # only double reads from WDFW
  dplyr::mutate(double_reader_tmp = ifelse(
                  double_read_ager_id %in% c('mschultz', 'wdfw'),
                  'WDFW', 'NMFS')) |>
  dplyr::group_by(age_structure_id, double_reader_tmp) |>
  dplyr::mutate(ind = 2:(dplyr::n() + 1),
                double_read_ager_id = paste0(double_reader_tmp, ind)) |>
  dplyr::ungroup() |>
  tidyr::pivot_longer(cols = c(age_original, double_read_age),
                      names_to = 'order',
                      values_to = 'age') |>
  dplyr::mutate(ager = ifelse(order == 'age_original', ager_id, double_read_ager_id)) |>
  tidyr::pivot_wider(id_cols = age_structure_id, 
                     names_from = ager, 
                     values_from = age,
                     values_fill = NA, 
                     values_fn = mean) |> # the values are repeated, sd of mean = 0 or NA 
  dplyr::select(-age_structure_id) 

all_for_estimation <- dplyr::bind_rows(
  wdfw_for_estimation,
  caps_for_estimation
  ) |>
  dplyr::count(dplyr::across(dplyr::everything())) |>
  dplyr::mutate(dplyr::across(-n, ~ ifelse(is.na(.x), -999, .x))) |>
  dplyr::select(n, dplyr::everything())

xx <- nwfscAgeingError::RunFn(Data = all_for_estimation,
                        SigOpt = c(1, 1, -2, -2, 1, -5, -5, -5),
                        BiasOpt = c(1, 1, -2, -2, 0, -5, -5, -5),
                        MinAge = 0,
                        MaxAge = 90,
                        RefAge = 10,
                        MinusAge = 1,
                        PlusAge = 30,
                        KnotAges = list(NA, NA, NA, NA, NA, NA, NA, NA),
                        SaveFile = here('data-raw'))

#Figuring this out still
save.image(file = here('data-raw/ageErr/ageerr_output.Rdata'))



# Plot output
PlotOutputFn(Data = all_for_estimation, MaxAge = 90,
             SaveFile = here('data-raw/ageErr'), PlotType = "PDF"
)

#How do we get SearchMat?
SearchMat <- array(NA,
                   dim = c(Nreaders * 2 + 2, 7),
                   dimnames = list(c(paste("Error_Reader", 1:Nreaders),
                                     paste("Bias_Reader", 1:Nreaders), "MinusAge", "PlusAge"),
                                   paste("Option", 1:7))
)

# Run model selection
# This outputs a series of files
# 1. "Stepwise - Model loop X.txt" --
#   Shows the AIC/BIC/AICc value for all different combinations
#   of parameters arising from changing one parameter at a time
#   according to SearchMat during loop X
# 2. "Stepwise - Record.txt" --
#   The Xth row of IcRecord shows the record of the
#   Information Criterion for all trials in loop X,
#   while the Xth row of StateRecord shows the current selected values
#   for all parameters at the end of loop X
# 3. Standard plots for each loop
# WARNING: One run of this stepwise model building example can take
# 8+ hours, and should be run overnight
StepwiseFn(SearchMat = SearchMat, Data = all_for_estimation,
           NDataSets = 1, MinAge = 0, MaxAge = 90,
           RefAge = 10, MaxSd = 40, MaxExpectedAge = MaxAge+10,
           SaveFile = here('data-raw/ageErr'),
           InformationCriterion = c("AIC", "AICc", "BIC")[3]
)