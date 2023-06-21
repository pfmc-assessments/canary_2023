# This generates design-based age, length, CAAL comps for surveys and formats them for SS3
# Also writes index results to csv files

# load packages
library(magrittr)
library(ggplot2)
library(here)
library(nwfscSurvey)

# load survey data
load(here('data-raw/Catch__NWFSC.Combo_2023-02-13.rda'))
wcgbts_catch <- Out
load(here('data-raw/Catch__Triennial_2023-05-01.rda'))
triennial_catch <- Out
load(here('data-raw/Bio_All_NWFSC.Combo_2023-02-13.rda'))
wcgbts_bio <- Data
load(here('data-raw/Bio_All_Triennial_2023-05-01.rda'))
triennial_bio <- Data

# hack to so there are no fish in the minus (-999) length bin
wcgbts_bio <- wcgbts_bio |>
  dplyr::mutate(Length_cm = ifelse(!is.na(Age) & Length_cm < 12, 12, Length_cm))
triennial_bio$Ages <- triennial_bio$Ages |>
  dplyr::mutate(Length_cm = ifelse(Length_cm < 12, 12, Length_cm))

# define age and length bins
age_bins <- 1:35
length_bins <- seq(12, 66, by = 2)

# randomly assign unsexed fish a sex
set.seed(29380)
wcgbts_bio <- wcgbts_bio |>
  dplyr::mutate(Sex = ifelse(Sex == 'U', 
                                 sample(c('F', 'M'), size = 1),
                                 Sex))
triennial_bio$Lengths <- triennial_bio$Lengths |>
  dplyr::mutate(Sex = ifelse(Sex == 'U', 
                             sample(c('F', 'M'), size = 1),
                             Sex))
# There is only one unsexed but aged fish in the triennial data. Throw it out.
triennial_bio$Ages <- triennial_bio$Ages |>
  dplyr::filter(Sex != 'U')

# define strata for wcgbts, triennial surveys
wcgbts_strata <- nwfscSurvey::CreateStrataDF.fn(
  names = apply(expand.grid(x = c('s.ca', 'n.ca', 'or', 'wa'), 
                            y = c('deep', 'shallow')), 
                MARGIN = 1, 
                FUN = stringr::str_flatten,
                collapse = '.'),
  depths.shallow = rep(c(55, 183), each = 4),
  depths.deep    = rep(c(183, 350), each = 4),
  lats.south     = rep(c(32, 34.5, 42, 46), 2),
  lats.north     = rep(c(34.5, 42, 46, 49), 2)
)

tri_strata <- nwfscSurvey::CreateStrataDF.fn(
  names = apply(expand.grid(x = c('ca', 'or', 'wa'), 
                            y = c('deep', 'shallow')), 
                MARGIN = 1, 
                FUN = stringr::str_flatten,
                collapse = '.'),
  depths.shallow = rep(c(55, 183), each = 3),
  depths.deep    = rep(c(183, 350), each = 3),
  lats.south     = rep(c(37, 42, 46), 2), # sampling effort changed btw pt. concep & 37 degrees
  lats.north     = rep(c(42, 46, 49), 2)
)

state_border_s <- c(32, 42, 46)
state_border_n <- c(42, 46, 49)

# Giant for loop to create age, length, caal comps for each state and coastwide for both surveys
for(survey in 1:2) {
  if(survey == 1) { # wcgbts
    catch <- wcgbts_catch
    bio <- wcgbts_bio
    strata <- wcgbts_strata
  } else { # triennial
    catch <- triennial_catch
    bio <- triennial_bio
    strata <- tri_strata
  }
  
  for(ii in 1:4) {
    # First subset survey data for wcgbts and triennial
    if(ii < 4) { # state comps
      if(survey == 1) { # wcgbts
        catch_subset <- dplyr::filter(catch, 
                                      Latitude_dd > state_border_s[ii],
                                      Latitude_dd < state_border_n[ii])
        bio_subset <- dplyr::filter(bio, 
                                    Latitude_dd > state_border_s[ii],
                                    Latitude_dd < state_border_n[ii])
        ages <- lengths <- bio_subset
      } else { # tri
        catch_subset <- dplyr::filter(catch, 
                                      Latitude_dd > strata$Latitude_dd.1[ii],
                                      Latitude_dd < state_border_n[ii])
        bio_subset <- purrr::map(bio, 
                                 ~ dplyr::filter(.,  
                                                 Latitude_dd > strata$Latitude_dd.1[ii],
                                                 Latitude_dd < state_border_n[ii])
        )  
        ages <- bio_subset$Ages
        lengths <- bio_subset$Lengths
      }
    } else { # coastwide comps
      if(survey == 1) { # wcgbts
        catch_subset <- catch 
        ages <- lengths <- bio
      } else { # tri
        catch_subset <- dplyr::filter(catch, Latitude_dd > 37)
        bio_subset <- purrr::map(bio, 
                                 ~ dplyr::filter(., Latitude_dd > 37)
        )
        ages <- bio_subset$Ages
        lengths <- bio_subset$Lengths
      }
    }
    # output  
    printfolder <- paste(c('CA', 'OR', 'WA', 'coastwide')[ii],
                         c('wcgbts', 'tri')[survey],
                         'comps', sep = '_')
    
    # now calculate comps
    caal <- SurveyAgeAtLen.fn(dir = here('Data'), 
                              datAL = ages, datTows = catch_subset, 
                              strat.df = strata, ageBins = age_bins,
                              lgthBins = length_bins,
                              raw = TRUE, sex = 3,
                              printfolder = printfolder,
                              month = '7', ageErr = '1',
                              verbose = FALSE)
    
    length_n <- GetN.fn(dat = lengths, 
                        type = 'length', 
                        species = 'shelfrock')
    length_freq <- SurveyLFs.fn(dir = here('Data'), 
                                datL = lengths, 
                                datTows = catch_subset, 
                                strat.df = strata, 
                                nSamps = length_n,
                                lgthBins = length_bins, 
                                sex = 3, 
                                month = '7',
                                verbose = FALSE,
                                printfolder = printfolder)
    
    age_n <- length.n <- GetN.fn(dat = ages, 
                                 type = 'age', 
                                 species = 'shelfrock')
    age_freq <- SurveyAFs.fn(dir = here('data'), 
                             datA = ages,
                             datTows = catch_subset,
                             strat.df = strata, 
                             ageBins = age_bins, 
                             nSamps = age_n,
                             sex = 3,
                             printfolder = printfolder,
                             month = '7', ageErr = '1',
                             verbose = FALSE)
    
    
  }
}
# whew!

# Also write table for document
bio.summary <- wcgbts_bio |>
  dplyr::group_by(Year) |>
  dplyr::summarise(`N ages` = sum(!is.na(Age)),
                   `N lengths` = sum(!is.na(Length_cm)))

wcgbts_catch |>
  dplyr::group_by(Year) |>
  dplyr::summarise(`N tows` = dplyr::n(),
                   `N positive tows` = sum(total_catch_numbers > 0),
                   `N caught` = sum(total_catch_numbers)) |>
  dplyr::left_join(bio.summary) |>
  write.csv(here('documents/tables/wcgbts_summary.csv'), row.names = FALSE)

length.summary <- triennial_bio$Lengths |>
  dplyr::group_by(Year) |>
  dplyr::summarise(`N lengths` = dplyr::n())
age.summary <- triennial_bio$Ages |>
  dplyr::group_by(Year) |>
  dplyr::summarise(`N ages` = dplyr::n())

triennial_catch |>
  dplyr::group_by(Year) |>
  dplyr::summarise(`N tows` = dplyr::n(),
                   `N positive tows` = sum(total_catch_numbers > 0),
                   `N caught` = sum(total_catch_numbers)) |>
  dplyr::left_join(age.summary) |>
  dplyr::left_join(length.summary) |>
  write.csv(here('documents/tables/triennial_summary.csv'), row.names = FALSE)
