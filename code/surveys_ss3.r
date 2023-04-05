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
load(here('data-raw/Catch__Triennial_2023-01-23.rda'))
triennial_catch <- Out
load(here('data-raw/Bio_All_NWFSC.Combo_2023-02-13.rda'))
wcgbts_bio <- Data
load(here('data-raw/Bio_All_Triennial_2023-01-23.rda'))
triennial_bio <- Data

# define age and length bins
age_bins <- 1:35
length_bins <- seq(12, 66, by = 2)

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
                              raw = TRUE,
                              printfolder = printfolder,
                              month = '7', ageErr = '1',
                              verbose = FALSE)
    
    for(sex in 1:2){
      length_n <- GetN.fn(dat = lengths, 
                          type = 'length', 
                          species = 'shelfrock')
      length_freq <- SurveyLFs.fn(dir = here('Data'), 
                                  datL = lengths, 
                                  datTows = catch_subset, 
                                  strat.df = strata, 
                                  nSamps = length_n,
                                  lgthBins = length_bins, 
                                  sex = sex, 
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
                               sex = sex,
                               printfolder = printfolder,
                               month = '7', ageErr = '1',
                               verbose = FALSE)
      
    }
  }
}
# whew!

# Also write table for document
wcgbts_catch |>
  dplyr::group_by(Year) |>
  dplyr::summarise(n_tows = dplyr::n(),
                   n_pos_tows = sum(total_catch_numbers > 0),
                   n_caught = sum(total_catch_numbers)) |>
  dplyr::mutate(eff_n_age = GetN.fn(dat = wcgbts_bio, 
                               type = 'age',
                               species = 'shelfrock',
                               verbose = FALSE))


# Write index to csv
load(here('data-raw/NWFSC.Combo/index/lognormal/sdmTMB_save.Rdata'))
write.csv(all_indices, here('data/wcgbts_index.csv'), row.names = FALSE)