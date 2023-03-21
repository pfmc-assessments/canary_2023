# This generates design-based age and length comps for surveys and formats them for SS3

library(magrittr)
library(ggplot2)
library(here) 

load(here('data/Catch__NWFSC.Combo_2023-02-13.rda'))
wcgbts_catch <- Out
load(here('data/Catch__Triennial_2023-01-23.rda'))
triennial_catch <- Out
load(here('data/Bio_All_NWFSC.Combo_2023-02-13.rda'))
wcgbts_bio <- Data
load(here('data/Bio_All_Triennial_2023-01-23.rda'))
triennial_bio <- Data

age_bins <- 1:35
length_bins <- seq(12, 66, by = 2)

# WCGBTS ------------------------------------------------------------------

strata <- nwfscSurvey::CreateStrataDF.fn(
  names = c("shallow_s", "deep_s", "shallow_n", "deep_n"), 
  depths.shallow = c( 55,   183,  55,   183),
  depths.deep    = c(183,   350,  183,  350),
  lats.south     = c( 32,   32,   34.5, 34.5),
  lats.north     = c( 34.5, 34.5, 49,   49))


caal <- SurveyAgeAtLen.fn(dir = here('Data'), 
                          datAL = wcgbts_bio, datTows = wcgbts_catch, 
                          strat.df = strata, ageBins = age_bins,
                          lgthBins = length_bins,
                          raw = TRUE)


length_n <- GetN.fn(dat = wcgbts_bio, 
                    type = 'length')
wcgbts_length_freq <- SurveyLFs.fn(dir = here('Data'), 
                                   datL = wcgbts_bio, 
                                   datTows = wcgbts_catch, 
                                   strat.df = strata, 
                                   nSamps = length_n,
                                   lgthBins = length_bins, 
                                   sex = 3)

age_n <- length.n <- GetN.fn(dat = wcgbts_bio, 
                             type = 'age')
wcgbts_age_freq <- SurveyAFs.fn(dir = here('data'), 
                                datA = wcgbts_bio,
                                datTows = wcgbts_catch,
                                strat.df = strata, 
                                ageBins = age_bins, 
                                nSamps = age_n)

# Triennial ---------------------------------------------------------------

# I believe even if triennial is split, the comps can be done together.
# Just need to include maximum number of strata

# Are there strata for the triennial?

length_n <- GetN.fn(dat = triennial_bio$Lengths, 
                    type = 'length')
tri_length_freq <- SurveyLFs.fn(dir = here('Data'), 
                                   datL = triennial_bio$Lengths, 
                                   datTows = triennial_catch, 
                                   strat.df = strata, 
                                   nSamps = length_n,
                                   lgthBins = length_bins, 
                                   sex = 3)

age_n <- length.n <- GetN.fn(dat = triennial_bio$Ages, 
                             type = 'age')
tri_age_freq <- SurveyAFs.fn(dir = here('data'), 
                             datA = triennial_bio$Ages,
                             datTows = triennial_catch,
                             strat.df = strata, 
                             ageBins = age_bins, 
                             nSamps = age_n)

