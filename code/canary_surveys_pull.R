library(here)

# catch
wcgbts_catch <- nwfscSurvey::pull_catch(common_name = 'canary rockfish', 
                                        survey = 'NWFSC.Combo', 
                                        dir = here('data'),
                                        convert = TRUE) %>%
  dplyr::mutate(Date_formatted = as.character(Date_formatted),
                State = dplyr::case_when(Latitude_dd < 42 ~ 'CA',
                                         Latitude_dd < 46.25 ~ 'OR',
                                         TRUE ~ 'WA'))

triennial_catch <- nwfscSurvey::pull_catch(common_name = 'canary rockfish', 
                                           survey = 'Triennial',
                                           dir = here('data'),
                                           convert = TRUE) %>%
  dplyr::mutate(Date_formatted = as.character(Date_formatted),
                State = dplyr::case_when(Latitude_dd < 42 ~ 'CA',
                                         Latitude_dd < 46.25 ~ 'OR',
                                         TRUE ~ 'WA'))


# bio data
wcgbts_bio <- nwfscSurvey::pull_bio(common_name = 'canary rockfish', 
                                    survey = 'NWFSC.Combo',
                                    dir = here('data'),
                                    convert = TRUE)
wcgbts_bio$Date_formatted <- as.character(wcgbts_bio$Date_formatted)

triennial_bio <- nwfscSurvey::pull_bio(common_name = 'canary rockfish', 
                                    survey = 'Triennial',
                                    dir = here('data'),
                                    convert = TRUE)
triennial_bio$length_data$Date_formatted <- as.character(triennial_bio$length_data$Date_formatted)
triennial_bio$age_data$Date_formatted <- as.character(triennial_bio$age_data$Date_formatted)

xx <- nwfscSurvey::pull_biological_samples('canary rockfish')

# bio samples
wcgbts_bio_samples <- nwfscSurvey::pull_biological_samples(common_name = 'canary rockfish', 
                                                           dir = here('data'), 
                                                           survey = 'NWFSC.Combo')
triennial_bio_samples <- nwfscSurvey::pull_biological_samples(common_name = 'canary rockfish', 
                                                           dir = here('data'), 
                                                           survey = 'NWFSC.Combo')

# Calculate total research catches
research_catch <- list(NWFSC.Combo = dplyr::select(wcgbts_catch, Year, Total_catch_numbers,
                                Total_catch_wt_kg, CPUE_kg_km2, State),
                       Triennial = dplyr::select(triennial_catch, Year, Total_catch_numbers,
                                                 Total_catch_wt_kg, CPUE_kg_km2, State)) %>%
  dplyr::bind_rows(.id = 'Survey') %>%
  dplyr::group_by(Year, State, Survey) %>%
  dplyr::summarise(Total_catch_numbers = sum(Total_catch_numbers),
                   Total_catch_wt_kg = sum(Total_catch_wt_kg))

# upload to gdrive!!!!!
xx <- googledrive::drive_create(name = 'wcgbts_catch',
                                path = 'https://drive.google.com/drive/folders/1fleYIaLvdIYMLv14--P1804akQvnWu5J', 
                                type = 'spreadsheet', overwrite = TRUE)
googlesheets4::sheet_write(wcgbts_catch, ss = xx, sheet = 1)

xx <- googledrive::drive_create(name = 'triennial_catch',
                                path = 'https://drive.google.com/drive/folders/1fleYIaLvdIYMLv14--P1804akQvnWu5J', 
                                type = 'spreadsheet', overwrite = TRUE)
googlesheets4::sheet_write(triennial_catch, ss = xx, sheet = 1)

xx <- googledrive::drive_create(name = 'wcgbts_bio',
                                path = 'https://drive.google.com/drive/folders/1fleYIaLvdIYMLv14--P1804akQvnWu5J', 
                                type = 'spreadsheet', overwrite = TRUE)
googlesheets4::sheet_write(wcgbts_bio, ss = xx, sheet = 1)

xx <- googledrive::drive_create(name = 'triennial_bio',
                                path = 'https://drive.google.com/drive/folders/1fleYIaLvdIYMLv14--P1804akQvnWu5J', 
                                type = 'spreadsheet', overwrite = TRUE)
googlesheets4::sheet_write(triennial_bio$length_data, ss = xx, sheet = 'length')
googlesheets4::sheet_write(triennial_bio$age_data, ss = xx, sheet = 'age')

xx <- googledrive::drive_create(name = 'research_catch',
                                path = 'https://drive.google.com/drive/folders/1fleYIaLvdIYMLv14--P1804akQvnWu5J', 
                                type = 'spreadsheet', overwrite = TRUE)
googlesheets4::sheet_write(research_catch, ss = xx, sheet = 1)