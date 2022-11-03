# catch
wcgbts_catch <- nwfscSurvey::pull_catch(common_name = 'canary rockfish', 
                                        survey = 'NWFSC.Combo')
wcgbts_catch$Date_formatted <- as.character(wcgbts_catch$Date_formatted)

triennial_catch <- nwfscSurvey::pull_catch(common_name = 'canary rockfish', 
                                           survey = 'Triennial')
triennial_catch$Date_formatted <- as.character(triennial_catch$Date_formatted)


#bio data
wcgbts_bio <- nwfscSurvey::pull_bio(common_name = 'canary rockfish', 
                                    survey = 'NWFSC.Combo')
wcgbts_bio$Date_formatted <- as.character(wcgbts_bio$Date_formatted)

triennial_bio <- nwfscSurvey::pull_bio(common_name = 'canary rockfish', 
                                    survey = 'Triennial')
triennial_bio$length_data$Date_formatted <- as.character(triennial_bio$length_data$Date_formatted)
triennial_bio$age_data$Date_formatted <- as.character(triennial_bio$age_data$Date_formatted)

#upload to gdrive!!!!!
xx <- googledrive::drive_create(name = 'wcgbts_bio',
                                path = 'https://drive.google.com/drive/folders/1fleYIaLvdIYMLv14--P1804akQvnWu5J', 
                                type = 'spreadsheet')
googlesheets4::write_sheet(wcgbts_catch, ss = xx)

xx <- googledrive::drive_create(name = 'triennial_catch',
                                path = 'https://drive.google.com/drive/folders/1fleYIaLvdIYMLv14--P1804akQvnWu5J', 
                                type = 'spreadsheet')
googlesheets4::write_sheet(triennial_catch, ss = xx)

xx <- googledrive::drive_create(name = 'wcgbts_bio',
                                path = 'https://drive.google.com/drive/folders/1fleYIaLvdIYMLv14--P1804akQvnWu5J', 
                                type = 'spreadsheet')
googlesheets4::write_sheet(wcgbts_bio, ss = xx)

xx <- googledrive::drive_create(name = 'triennial_bio_length',
                                path = 'https://drive.google.com/drive/folders/1fleYIaLvdIYMLv14--P1804akQvnWu5J', 
                                type = 'spreadsheet')
googlesheets4::write_sheet(triennial_bio$length_data, ss = xx)

xx <- googledrive::drive_create(name = 'triennial_bio_age',
                                path = 'https://drive.google.com/drive/folders/1fleYIaLvdIYMLv14--P1804akQvnWu5J', 
                                type = 'spreadsheet')
googlesheets4::write_sheet(triennial_bio$age_data, ss = xx)

