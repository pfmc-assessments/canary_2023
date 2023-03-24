library(here)
library(magrittr)

# catch
wcgbts_catch <- nwfscSurvey::PullCatch.fn(Name = 'canary rockfish', 
                                          SurveyName = 'NWFSC.Combo', 
                                          Dir = here('data-raw'), 
                                          SaveFile = TRUE) %>%
  dplyr::mutate(Date = as.character(Date),
                State = dplyr::case_when(Latitude_dd < 42 ~ 'CA',
                                         Latitude_dd < 46.25 ~ 'OR',
                                         TRUE ~ 'WA'))

triennial_catch <- nwfscSurvey::PullCatch.fn(Name = 'canary rockfish', 
                                             SurveyName = 'Triennial',
                                             Dir = here('data-raw'),
                                             SaveFile = TRUE) %>%
  dplyr::mutate(Date = as.character(Date),
                State = dplyr::case_when(Latitude_dd < 42 ~ 'CA',
                                         Latitude_dd < 46.25 ~ 'OR',
                                         TRUE ~ 'WA'))


# bio data
wcgbts_bio <- nwfscSurvey::PullBio.fn(Name = 'canary rockfish', 
                                      SurveyName = 'NWFSC.Combo',
                                      Dir = here('data-raw'),
                                      SaveFile = TRUE) %>%
  dplyr::mutate(Date = as.character(Date),
                State = dplyr::case_when(Latitude_dd < 42 ~ 'CA',
                                         Latitude_dd < 46.25 ~ 'OR',
                                         TRUE ~ 'WA'))

triennial_bio <- nwfscSurvey::PullBio.fn(Name = 'canary rockfish', 
                                       SurveyName = 'Triennial',
                                       Dir = here('data-raw'),
                                       SaveFile = TRUE) %>%
  purrr::map(.f = function(df) dplyr::mutate(df, Date = as.character(Date)))


# bio samples
wcgbts_bio_samples <- nwfscSurvey::pull_biological_samples(common_name = 'canary rockfish', 
                                                           dir = here('data-raw'), 
                                                           survey = 'NWFSC.Combo')
triennial_bio_samples <- nwfscSurvey::pull_biological_samples(common_name = 'canary rockfish', 
                                                           dir = here('data-raw'), 
                                                           survey = 'NWFSC.Combo')

# Calculate total research catches
research_catch <- list(NWFSC.Combo = dplyr::select(wcgbts_catch, Year, total_catch_numbers,
                                                   total_catch_wt_kg, cpue_kg_km2, State),
                       Triennial = dplyr::select(triennial_catch, Year, total_catch_numbers,
                                                 total_catch_wt_kg, cpue_kg_km2, State)) %>%
  dplyr::bind_rows(.id = 'Survey') %>%
  dplyr::group_by(Year, State, Survey) %>%
  dplyr::summarise(total_catch_numbers = sum(total_catch_numbers),
                   total_catch_wt_kg = sum(total_catch_wt_kg))

# upload to gdrive!!!!!
xx <- googledrive::drive_create(name = 'wcgbts_catch',
                                path = 'https://drive.google.com/drive/folders/1Lx4JN-nmJkWtcqmelODZYoVrHyVLzegP', 
                                type = 'spreadsheet', overwrite = TRUE)
googlesheets4::sheet_write(wcgbts_catch, ss = xx, sheet = 1)

xx <- googledrive::drive_create(name = 'triennial_catch',
                                path = 'https://drive.google.com/drive/folders/1Lx4JN-nmJkWtcqmelODZYoVrHyVLzegP', 
                                type = 'spreadsheet', overwrite = TRUE)
googlesheets4::sheet_write(triennial_catch, ss = xx, sheet = 1)

xx <- googledrive::drive_create(name = 'wcgbts_bio',
                                path = 'https://drive.google.com/drive/folders/1Lx4JN-nmJkWtcqmelODZYoVrHyVLzegP', 
                                type = 'spreadsheet', overwrite = TRUE)
googlesheets4::sheet_write(wcgbts_bio, ss = xx, sheet = 1)

xx <- googledrive::drive_create(name = 'triennial_bio',
                                path = 'https://drive.google.com/drive/folders/1Lx4JN-nmJkWtcqmelODZYoVrHyVLzegP', 
                                type = 'spreadsheet', overwrite = TRUE)
googlesheets4::sheet_write(triennial_bio$Lengths, ss = xx, sheet = 'length')
googlesheets4::sheet_write(triennial_bio$Ages, ss = xx, sheet = 'age')

xx <- googledrive::drive_create(name = 'research_catch',
                                path = 'https://drive.google.com/drive/folders/1Lx4JN-nmJkWtcqmelODZYoVrHyVLzegP', 
                                type = 'spreadsheet', overwrite = TRUE)
googlesheets4::sheet_write(research_catch, ss = xx, sheet = 1)