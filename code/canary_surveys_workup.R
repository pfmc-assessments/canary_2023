# Analyze and plot geographic difference in VBGF curve from survey data

# Construct model-based index

# Explore survey comps

library(magrittr)
library(ggplot2)
library(here) 
theme_set(theme_classic(base_size = 16))

# option to load data from disk
# would be good to not have the dates hard coded in.

wcgbts_date <- '2023-02-13'
triennial_date <- '2023-05-01'

load(here(paste0('data-raw/Catch__NWFSC.Combo_', wcgbts_date, '.rda')))
wcgbts_catch <- Out
load(here(paste0('data-raw/Catch__Triennial_', triennial_date, '.rda')))
triennial_catch <- Out
load(here(paste0('data-raw/Bio_All_NWFSC.Combo_', wcgbts_date, '.rda')))
wcgbts_bio <- Data
load(here(paste0('data-raw/Bio_All_Triennial_', triennial_date, '.rda')))
triennial_bio <- Data

if(Sys.getenv("USERNAME") == "Brian.Langseth") {
  wd = "L:/"
}
if(Sys.getenv("USERNAME") == "Kiva.Oken") {
  wd = "Q:/"
}

# load data from gdrive
# wcgbts_bio <- googlesheets4::read_sheet(ss = 'https://docs.google.com/spreadsheets/d/19lmADWs0doiKdxUHHfdWPVBfTp_OwD77QXxkcRbGOKw/edit#gid=0')
# triennial_bio = list()
# triennial_bio$Ages <- googlesheets4::read_sheet(ss = 'https://docs.google.com/spreadsheets/d/1oAl-qJEwGxNKjEdyIX_8LmEtF4sNeihv_-aeHhx97PQ/edit#gid=0',
#                                            sheet = 'age')
# triennial_bio$Lengths <- googlesheets4::read_sheet(ss = 'https://docs.google.com/spreadsheets/d/1oAl-qJEwGxNKjEdyIX_8LmEtF4sNeihv_-aeHhx97PQ/edit#gid=0',
#                                            sheet = 'length')
# Coos Bay latitude: 43.3672

# Combine age data from triennial and wcgbts, create flags --------

# Note the A-L models below only use WCGBTS data though

age_combo <- dplyr::select(wcgbts_bio, Year, Length_cm, Sex, Age, Latitude_dd, Longitude_dd) %>%
  dplyr::bind_rows(trawl = ., triennial = dplyr::select(triennial_bio$Ages, Year, Length_cm, Sex, Age, Latitude_dd, Longitude_dd), 
                   .id = 'survey', ) %>%
  dplyr::mutate(is_south_cb = factor(dplyr::if_else(Latitude_dd < 43.3672,
                                        TRUE, FALSE)),
                is_south_ca = factor(dplyr::if_else(Latitude_dd < 42,
                                             TRUE, FALSE)),
                is_south_wa = factor(dplyr::if_else(Latitude_dd < 46.25,
                                             TRUE, FALSE)),
                Sex = factor(Sex))




# Fit models --------------------------------------------------------------

### fit coastwide age-length model
coastwide <- nls(Length_cm ~linf*(1-exp(-k*(Age-t0))), data = age_combo, 
                 start = list(linf = 55, k = 0.3, t0 = 0), subset = survey == 'trawl') 

### fit age-length model by sex. This is a biologically significant difference
### to compare regional differences to
split_sex <- nls(Length_cm ~ linf[Sex]*(1-exp(-k[Sex]*(Age-t0[Sex]))), data = age_combo, 
      start = list(linf = rep(55,3), k = rep(0.3,3), t0 = rep(0,3)), subset = survey == 'trawl') 

### fit models for three different regional division schemes, compare them
split_region_ca <- nls(Length_cm ~ linf[is_south_ca]*(1-exp(-k[is_south_ca]*(Age-t0[is_south_ca]))), data = age_combo, 
                       start = list(linf = rep(55,2), k = rep(0.3,2), t0 = rep(0,2)),
                       subset = survey == 'trawl') 


split_region_cb <- nls(Length_cm ~ linf[is_south_cb] * (1-exp(-k[is_south_cb]*(Age-t0[is_south_cb]))), data = age_combo, 
                       start = list(linf = rep(55,2), k = rep(0.3,2), t0 = rep(0,2)), subset = survey == 'trawl') 

split_region_wa <- nls(Length_cm ~ linf[is_south_wa] * (1-exp(-k[is_south_wa]*(Age-t0[is_south_wa]))), data = age_combo, 
                       start = list(linf = rep(55,2), k = rep(0.3,2), t0 = rep(0,2)), subset = survey == 'trawl') 

AIC(split_region_ca, split_region_cb, split_region_wa, coastwide, split_sex)

### fit sex sepcific models with coos bay as the split
split_cb_m <- split_region_cb <- nls(Length_cm ~ linf[is_south_cb] * (1-exp(-k[is_south_cb]*(Age-t0[is_south_cb]))), data = age_combo, 
                                       start = list(linf = rep(55,2), k = rep(0.3,2), t0 = rep(0,2)), subset = Sex == 'M' & survey == 'trawl') 

split_cb_f <- split_region_cb <- nls(Length_cm ~ linf[is_south_cb] * (1-exp(-k[is_south_cb]*(Age-t0[is_south_cb]))), data = age_combo, 
                                     start = list(linf = rep(55,2), k = rep(0.3,2), t0 = rep(0,2)), subset = Sex == 'F' & survey =='trawl') 

summary(split_cb_m)
summary(split_cb_f)


# Make beautiful plots ----------------------------------------------------


vbgf <- function(x, linf, k, t0, linf_adj = NULL) {
  (linf + ifelse(is.null(linf_adj), 0, linf_adj)) * (1-exp(-k*(x-t0)))
}

# bin2d to deal with overplotting, faceted CA vs OR/WA
ggplot(age_combo) +
  stat_bin_2d(aes(x = Age, y = Length_cm)) + 
  facet_wrap(~is_south_ca)


coefs1 <- coef(split_region_cb)[c(1,3,5)]
names(coefs1) <- gsub(pattern = '1', replacement = '', x = names(coefs1))
coefs2 <- coef(split_region_cb)[c(2,4,6)]
names(coefs2) <- gsub(pattern = '2', replacement = '', x = names(coefs2))

# data frame of two fitted lines, CA vs OR/WA
vbgf.df <- expand.grid(Age = seq(0, 60, length.out = 100),
                       is_south_cb = c(TRUE, FALSE)) %>% 
  dplyr::as_tibble() %>%
  dplyr::mutate(Length_cm_s_args = lapply(Age, function(x) c(x = x, as.list(coefs1))),
                Length_cm_n_args = lapply(Age, function(x) c(x = x, as.list(coefs2))),
                Length_cm_s = sapply(Length_cm_s_args, do.call, what = vbgf),
                Length_cm_n = sapply(Length_cm_n_args, do.call, what = vbgf),
                Length_cm = ifelse(is_south_cb, Length_cm_s, Length_cm_n))

# scatter plot with fitted lines, colored by CA vs OR/WA
age_combo %>%
  dplyr::filter(survey == 'trawl') %>%
  ggplot(aes(x = Age, y = Length_cm, col = is_south_cb)) +
  geom_point(alpha = 0.1, pch = 16) +
  geom_line(data = vbgf.df) +
  ggsidekick::theme_sleek() +
  # scale_color_discrete(name = 'Region', labels = c(`TRUE` = 'CA', 
  #                                                   `FALSE` = 'OR-WA'))
  NULL


# scatter plot with fitted lines, faceted by CA vs OR/WA (compare sample sizes)
age_combo %>%
  dplyr::filter(survey == 'trawl') %>%
  ggplot() +
  geom_point(aes(x = Age, y = Length_cm), alpha = 0.05, pch=16) + 
  geom_function(data = transform(age_combo, is_south_ca = TRUE), col = 'red',
                fun = vbgf, args = as.list(coefs1)) +
  geom_function(data = transform(age_combo, is_south_ca = FALSE), col = 'red',
                fun = vbgf, args = as.list(coefs2)) +
  facet_wrap(~is_south_ca, 
             labeller = as_labeller(c(`TRUE` = 'CA', `FALSE` = 'OR-WA'))) +
  ggsidekick::theme_sleek()

#combining for STAR
age_combo %>%
  dplyr::filter(survey == 'trawl') %>%
  ggplot() +
  geom_point(aes(x = Age, y = Length_cm, col = is_south_ca), alpha = 0.25, pch=16) + 
  geom_function(data = transform(age_combo, is_south_ca = TRUE), col = 2,
                fun = vbgf, args = as.list(coefs1)) +
  geom_function(data = transform(age_combo, is_south_ca = FALSE), col = 4, lty = 2,
                fun = vbgf, args = as.list(coefs2))

dplyr::group_by(wcgbts_bio, factor(Year)) %>% 
  dplyr::summarise(n = dplyr::n()) %>%
  with(mean(n))

# Percent female by age. Around 50%, then drops off around age 17
dplyr::bind_rows(tri = triennial_bio$Ages[,c('Age', 'Sex')],
                 wcgbts = wcgbts_bio[,c('Age', 'Sex')], 
                 .id = 'survey') %>%
  dplyr::filter(!is.na(Age)) %>%
#  dplyr::mutate(Age = factor(Age)) %>%
  dplyr::group_by(Age) %>%
  dplyr::summarise(Pct_female = sum(Sex == 'F') / dplyr::n(),
                   se = sqrt(Pct_female*(1-Pct_female)/dplyr::n())) %>%
 # dplyr::mutate(Age = as.numeric(Age)) %>%
  ggplot(aes(x = Age, y = Pct_female)) +
  geom_point() +
  geom_segment(aes(y = Pct_female - se, xend = Age, yend = Pct_female + se)) +
#  geom_vline(xintercept = 19.5, col = 'red') +
  geom_hline(yintercept = 0.5) +
  geom_vline(xintercept = 20.5)

# Data workshop figures ---------------------------------------------------
## scatter plot of age-length-sex
wcgbts_bio %>%
  dplyr::filter(!is.na(Age)) %>%
  ggplot(data = ., aes(x = Age, y = Length_cm, col = Sex)) +
  geom_point(alpha = 0.15) +
  labs(x = 'Age (years)', y = 'Length (cm)') +
  scale_color_manual(values = c('F' = 'red', 'M' = 'blue', 'U' = 'darkgoldenrod1')) +
  guides(colour = guide_legend(override.aes = list(alpha = 1, size = 3))) +
  NULL
ggsave(filename = here('data_workshop_figs/len_data.png'), device = 'png', 
       height = 5, width = 9, units = 'in', dpi = 500)


## Age-length scatter plot with fitted lines by sex-region
# First get coefficients out of the regression objects in correct format
coefs_n_m <- coef(split_cb_m)[c(1,3,5)] %>%
  set_names(gsub(pattern = '1', replacement = '', x = names(.)))
coefs_s_m <- coef(split_cb_m)[c(2,4,6)] %>%
  set_names(gsub(pattern = '2', replacement = '', x = names(.)))

coefs_n_f <- coef(split_cb_f)[c(1,3,5)] %>%
  set_names(gsub(pattern = '1', replacement = '', x = names(.)))
coefs_s_f <- coef(split_cb_f)[c(2,4,6)] %>%
  set_names(gsub(pattern = '2', replacement = '', x = names(.)))

# Now plot
lwd = .5
age_combo %>%
  dplyr::filter(!is.na(Age)) %>%
  dplyr::mutate(Region = ifelse(is_south_cb == 'TRUE', 'South', 'North')) %>%
  ggplot() +
  geom_point(aes(x = Age, y = Length_cm, col = Sex, shape = Region), 
             alpha = 0.25) + 
  geom_function(data = transform(age_combo, is_south_cb = TRUE), fun = vbgf, args = as.list(coefs_n_m), 
                aes(linetype = 'South', col = 'M'), linewidth = lwd) +

  geom_function(data = transform(age_combo, is_south_cb = FALSE), fun = vbgf, args = as.list(coefs_s_m), 
                aes(linetype = 'North', col = 'M'), linewidth = lwd) +
  
  geom_function(data = transform(age_combo, is_south_cb = TRUE), fun = vbgf, args = as.list(coefs_n_f), 
                aes(linetype = 'South', col = 'F'), linewidth = lwd) +
  
  geom_function(data = transform(age_combo, is_south_cb = FALSE), fun = vbgf, args = as.list(coefs_s_f), 
                aes(linetype = 'North', col = 'F'), linewidth = lwd) +
  scale_color_manual(values = c('F' = 'red', 'M' = 'blue', 'U' = 'darkgoldenrod1')) +
  labs(x = 'Age (years)', y = 'Length (cm)') +
  scale_linetype_discrete(name = 'Region', guide = guide_legend(override.aes = list(alpha=1, size = 3))) +
  guides(colour = guide_legend(override.aes = list(alpha = 1, size = 3))) +
  NULL
ggsave(filename = here('data_workshop_figs/growth_diffs.png'), device = 'png', 
       height = 5, width = 9, units = 'in', dpi = 1000)


## Triennial age and length compositions
triennial_n_age <- triennial_bio$Ages %>%
  dplyr::group_by(Year) %>%
  dplyr::summarise(ages = sum(!is.na(Age)))

triennial_n_length <- triennial_bio$Lengths %>%
  dplyr::group_by(Year) %>%
  dplyr::summarise(lengths = sum(!is.na(Length_cm)))

triennial_bio$Ages %>%
  ggplot() +
  ggridges::geom_density_ridges(aes(y = factor(Year), x = Age), fill = 'gray80') +
  geom_label(aes(y = factor(Year), label = ages), x = 50, data = triennial_n_age) +
  labs(y = 'Year', x = 'Age (yrs)')
ggsave(filename = here('data_workshop_figs/triennial_ages.png'), device = 'png', 
       height = 5, width = 9, units = 'in', dpi = 500)

triennial_bio$Lengths %>%
  ggplot() +
  ggridges::geom_density_ridges(aes(y = factor(Year), x = Length_cm), fill = 'gray80') +
  geom_label(aes(y = factor(Year), label = lengths), x = 70, data = triennial_n_length) +
  labs(y = 'Year', x = 'Length (cm)') +
  xlim(0,75)
ggsave(filename = here('data_workshop_figs/triennial_lengths.png'), device = 'png', 
       height = 5, width = 9, units = 'in', dpi = 500)

dplyr::right_join(triennial_n_age, triennial_n_length) %>%
  dplyr::mutate(aalength_only = lengths - ages) %>%
  tidyr::pivot_longer(cols = c(ages, aalength_only), names_to = 'type', values_to = 'n') %>%
  ggplot() + 
  geom_col(aes(x = Year, y = n, fill = type)) +
  scale_fill_discrete(labels = c('Length only', 'Length and Age')) +
  labs(y = 'Number of samples', fill = '')
ggsave(filename = here('data_workshop_figs/triennial_n.png'), device = 'png', 
       height = 5, width = 9, units = 'in', dpi = 500)

## WCGBTS age and length comps
wcgbts_n <- wcgbts_bio %>%
  dplyr::group_by(Year) %>%
  dplyr::summarise(lengths = sum(!is.na(Length_cm)),
                   ages = sum(!is.na(Age)))

wcgbts_bio %>%
  ggplot() +
  ggridges::geom_density_ridges(aes(y = factor(Year), x = Age), fill = 'gray80') +
  geom_label(aes(y = factor(Year), label = ages), x = 55, data = wcgbts_n) +
  labs(y = 'Year', x = 'Age (yrs)')
ggsave(filename = here('data_workshop_figs/wcgbts_ages.png'), device = 'png', 
       height = 5, width = 9, units = 'in', dpi = 500)

wcgbts_bio %>%
  ggplot() +
  ggridges::geom_density_ridges(aes(y = factor(Year), x = Length_cm), fill = 'gray80') +
  geom_label(aes(y = factor(Year), label = lengths), x = 70, data = wcgbts_n) +
  labs(y = 'Year', x = 'Length (cm)') +
  xlim(0,75)
ggsave(filename = here('data_workshop_figs/wcgbts_lengths.png'), device = 'png', 
       height = 5, width = 9, units = 'in', dpi = 500)

wcgbts_n %>%
  dplyr::mutate(aalength_only = lengths - ages) %>%
  tidyr::pivot_longer(cols = c(ages, aalength_only), names_to = 'type', values_to = 'n') %>%
  ggplot() + 
  geom_col(aes(x = Year, y = n, fill = type)) +
  scale_fill_discrete(labels = c('Length only', 'Length and Age')) +
  labs(y = 'Number of samples', fill = '')
ggsave(filename = here('data_workshop_figs/wcgbts_n.png'), device = 'png', 
       height = 5, width = 9, units = 'in', dpi = 500)
# Sex ratios by length and age
nwfscSurvey::PlotSexRatio.fn(wcgbts_bio, dir = here('data_workshop_figs'), data.type = 'length')
nwfscSurvey::PlotSexRatio.fn(wcgbts_bio, dir = here('data_workshop_figs'), data.type = 'age')

nwfscSurvey::PlotMap.fn(wcgbts_catch, dir = here('data_workshop_figs'))


ggplot() +
  geom_density(aes(x = Length_cm, col = 'Triennial', fill = 'Triennial'), 
               data = triennial_bio$Lengths, alpha = 0.25) +
  geom_density(aes(x = Length_cm, col = 'WCGBTS', fill = 'WCGBTS'), 
               data = wcgbts_bio, alpha = 0.25) +
  scale_color_discrete(name = 'Survey') +
  scale_fill_discrete(name = 'Survey')
ggsave(here('data_workshop_figs/length_comparison.png'), height = 5, width = 6, units = 'in', dpi = 500)

ggplot() +
  geom_density(aes(x = Age, col = 'Triennial', fill = 'Triennial'), 
               data = triennial_bio$Ages, alpha = 0.25) +
  geom_density(aes(x = Age, col = 'WCGBTS', fill = 'WCGBTS'), 
               data = wcgbts_bio, alpha = 0.25) +
  scale_color_discrete(name = 'Survey') +
  scale_fill_discrete(name = 'Survey')
ggsave(here('data_workshop_figs/age_comparison.png'), height = 5, width = 6, units = 'in', dpi = 500)

# Design-based index -------------------------------------------------------

temp <- wcgbts_catch %>%
  dplyr::mutate(new = factor(
    cpue_kg_km2 <= 0,
    levels = c(FALSE, TRUE),
    labels = c("Present", "Absent")
  ))
nwfscSurvey::plot_proportion(data = temp, column_factor = new, column_bin = 'Depth_m', width = 50)
ggsave(here('data_workshop_figs/presence_by_depth.png'), device = 'png',
       height = 5, width = 9, units = 'in', dpi = 500)
with(wcgbts_catch, sum(total_catch_wt_kg > 0 & Depth_m > 350) / sum(total_catch_wt_kg > 0))
# Choose 350 as cutoff, includes 99.9% of all positive tows. 

triennial_catch %>%
  tibble::as_tibble() %>%
  dplyr::filter(total_catch_numbers > 0) %>%
  dplyr::arrange(desc(Depth_m)) %>% View
# 350m depth excludes 1 fish in 1 tow.

strata <- nwfscSurvey::CreateStrataDF.fn(
  names = c("shallow_s", "deep_s", "shallow_n", "deep_n"), 
  depths.shallow = c( 55,   183,  55,   183),
  depths.deep    = c(183,   350,  183,  350),
  lats.south     = c( 32,   32,   34.5, 34.5),
  lats.north     = c( 34.5, 34.5, 49,   49))

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

biomass <- nwfscSurvey::Biomass.fn(dir = NULL, 
                                   dat = wcgbts_catch,  
                                   strat.df = wcgbts_strata)

# Compare to model-based indices
lognormal.ind <- read.csv(
  paste0(wd, 'Assessments/Assessment Data/2023 Assessment Cycle/canary rockfish/wcgbts/delta_lognormal/index/est_by_area.csv')) |>
  dplyr::filter(area == 'coastwide') |>
  dplyr::select(Year = year, Value = est)

gamma.ind <- read.csv(
  paste0(wd, '
         Assessments/Assessment Data/2023 Assessment Cycle/canary rockfish/wcgbts/delta_gamma/index/est_by_area.csv')) |>
  dplyr::filter(area == 'coastwide') |>
  dplyr::select(Year = year, Value = est)

design.ind <- biomass$Bio |>
  dplyr::select(Year, Value) |>
  dplyr::mutate(Year = as.integer(Year))
  
dplyr::bind_rows(list(lognormal = lognormal.ind, 
                      gamma = gamma.ind,
                      design = design.ind),
                 .id = 'method') |>
  ggplot(aes(x = Year, y = Value, col = method)) +
  geom_point() +
  geom_line()

plot_comps(age.freq)

ggplot(biomass$Bio,
       aes(x = as.numeric(Year),
           y = Value,
           ymin = exp(log(Value) - 1.96*seLogB),
           ymax = exp(log(Value) + 1.96*seLogB))) +
  geom_pointrange() +
  geom_line() +
  labs(x = 'Year', y = 'Index')
ggsave(here('data_workshop_figs/design_based_index.png'), device = 'png', 
       height = 5, width = 9, units = 'in', dpi = 500)


wcgbts_bio_samples %>%
  dplyr::filter(biologically_mature_certain_indicator == 'Biologically Mature Certain') %>% 
  dplyr::mutate(year = factor(year)) %>%
  dplyr::group_by(year) %>%
  dplyr::summarize(n_ovaries = dplyr::n()) %>%
  dplyr::mutate(last_assessment = c(49, 83, 82, 52, 54, 116, NA, NA))

yoy_data_raw %>%
  dplyr::group_by(STATION) %>%
  dplyr::summarize(lat = first(LATDD), lon = first(LONDD)) %>%
  ggplot() +
  geom_point(aes(x = lon, y = lat)) +
  draw_land() + 
  draw_USEEZ(range(yoy_data_raw$LONDD), range(yoy_data_raw$LATDD)) + 
  label_land() + label_axes() + theme(legend.position = "right")
ggsave(here('data_workshop_figs/yoy_stations.png'),  device = 'png', 
       height = 5, width = 9, units = 'in', dpi = 500)


# YOY survey --------------------------------------------------------------

yoy_survey <- readxl::read_excel(here('data/YOYcanary100day.xlsx'), sheet = 'PlaceholderResults', skip = 2) %>%
  dplyr::select(1:5) %>%
  `colnames<-`(c('Year', 'Index', 'SD', '2.5%', '97.5%')) %>%
  dplyr::filter(Index != 0)

# KFJ advised not to trust the "placeholder" index from SWFSC. But I do not have time before
# workshop to develop my own.

yoy_data_raw %>%
  dplyr::filter(YEAR == 2020) %>%
  with(max(TOTAL_NO))
  dplyr::group_by(YEAR) %>%
  dplyr::summarise(dplyr::n()) %>% View

ggplot(yoy_survey,
       aes(x = Year,
           y = Index,
           ymin = `2.5%`,
           ymax = `97.5%`)) +
  geom_pointrange() +
  geom_line() +
  labs(x = 'Year', y = 'Index')
ggsave(here('data_workshop_figs/RREAS_index.png'), device = 'png', 
       height = 5, width = 9, units = 'in', dpi = 500)
head(yoy_survey)


wcgbts_bio_samples %>%
  dplyr::filter(biologically_mature_certain_indicator == 'Biologically Mature Certain') %>%
  dplyr::mutate(mature_binary = ifelse(biologically_mature_indicator == 'Biologically Mature', 1, 0)) %>%
  glm(mature_binary ~ age_years, data = ., family = binomial) %>%
  summary()

plot(x = 1:25,
     y = boot::inv.logit(-3.56775 + 0.39712*1:25), type = 'l')

ggplot() +
  geom_col(aes(x = age_years, y = pct_mat))


yoy_data_raw %>% head


# Growth variability for ages that are sampled in WCGBTS every year
wcgbts_bio %>%
  dplyr::group_by(Age, Year) %>%
  dplyr::summarise(Length_cm = mean(Length_cm), n = dplyr::n()) %>%
  dplyr::filter(dplyr::n() == 19, !is.na(Age)) %>% 
  ggplot() +
  geom_line(aes(x = Year, y = Length_cm, col = Age, group = Age))

canary.converted$dat$catch %>% 
  dplyr::filter(fleet == 6, catch>0) %>%
  # ggplot() +
  # geom_line(aes(x = year, y = catch))
  write.csv(file = here('data/wa_historical.csv'), row.names = FALSE)


library(sdmTMB)

load(here('data-raw/NWFSC.Combo/index/lognormal/sdmTMB_save.rdata')) # this has the index
data_with_residuals |>
  ggplot() +
  geom_point(aes(x = Lat, y = residuals, col = Year), alpha = 0.25)

data_with_residuals |>
  ggplot() +
ggridges::geom_density_ridges(aes(x = residuals, y = factor(Year)), alpha = 0.25) +
  geom_vline(xintercept = 0)

head(predictions)


# Get fraction of survey by state -----------------------------------------

readr::read_csv('Q:/assessments/assessment data/2023 assessment cycle/canary rockfish/wcgbts/delta_lognormal/index/est_by_area.csv') |>
  dplyr::select(area, year, est) |>
  tidyr::pivot_wider(names_from = area, values_from = est) |>
  tail(5) |>
  dplyr::summarise(dplyr::across(WA:CA, ~ mean(.x))) |>
  dplyr::mutate(dplyr::across(WA:CA, ~ .x/(WA+OR+CA)))

purrr::imap(biomass$All$Strata, ~ tibble::tibble(year = as.numeric(stringr::str_remove(.y, '[:alpha:]+')),
                                                 WA = sum(.x[c('wa.deep', 'wa.shallow'),'Bhat']),
                                                 OR = sum(.x[c('or.deep', 'or.shallow'),'Bhat']),
                                                 CA = sum(.x[c('s.ca.deep', 's.ca.shallow', 'n.ca.deep', 'n.ca.shallow'), 'Bhat']))) |>
  purrr::list_rbind() |>
  # tail(5) |>
  dplyr::summarise(dplyr::across(WA:CA, ~ mean(.x))) |>
  dplyr::mutate(dplyr::across(WA:CA, ~ .x/(WA+OR+CA)))

# Design-based is very different over last 5 years due to 2 big catch events off of OR
# More similar to model-based over full time series
# Model-based is basically the same last 5 years or full time series
# Use model-based last 5 years.

