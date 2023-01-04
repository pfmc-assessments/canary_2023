# Analyze and plot geographic difference in VBGF curve from survey data

library(magrittr)
library(ggplot2)
library(here) 
theme_set(theme_classic())

# option to load data from disk
# would be good to not have the dates hard coded in.
# load(here('data/catch_canary rockfish_NWFSC.Combo_2022-11-04.rda'))
# wcgbts_catch <- catch
# load(here('data/catch_canary rockfish_Triennial_2022-11-04.rda'))
# triennial_catch <- catch
# load(here('data/bio_canary rockfish_NWFSC.Combo_2022-11-03.rda'))
# wcgbts_bio <- bio
# load(here('data/bio_canary rockfish_Triennial_2022-11-03.rda'))
# triennial_bio <- bio

# load data from gdrive
wcgbts_bio <- googlesheets4::read_sheet(ss = 'https://docs.google.com/spreadsheets/d/1VRGKrehGl2zelBxytpKI7QJWjk8ACPSEGY6VKXLIbpc/edit#gid=0')
triennial_bio <- googlesheets4::read_sheet(ss = 'https://docs.google.com/spreadsheets/d/10nBQ0pB1gOpEAESCV331THjErRAZ6zqNAAkySMIzjLg/edit#gid=0', 
                                           sheet = 'age')
# Coos Bay latitude: 43.3672

# Combine age data from triennial and wcgbts, create flags --------
age_combo <- dplyr::select(wcgbts_bio, Year, Length_cm, Sex, Age_years, Latitude_dd, Longitude_dd) %>%
  dplyr::bind_rows(trawl = ., triennial = dplyr::select(triennial_bio, Year, Length_cm, Sex, Age_years, Latitude_dd, Longitude_dd), 
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
coastwide <- nls(Length_cm ~linf*(1-exp(-k*(Age_years-t0))), data = age_combo, 
                 start = list(linf = 55, k = 0.3, t0 = 0)) 

### fit age-length model by sex. This is a biologically significant difference
### to compare regional differences to
split_sex <- nls(Length_cm ~ linf[Sex]*(1-exp(-k[Sex]*(Age_years-t0[Sex]))), data = age_combo, 
      start = list(linf = rep(55,3), k = rep(0.3,3), t0 = rep(0,3))) 

### fit models for three different regional division schemes, compare them
split_region_ca <- nls(Length_cm ~ linf[is_south_ca]*(1-exp(-k[is_south_ca]*(Age_years-t0[is_south_ca]))), data = age_combo, 
                       start = list(linf = rep(55,2), k = rep(0.3,2), t0 = rep(0,2))) 


split_region_cb <- nls(Length_cm ~ linf[is_south_cb] * (1-exp(-k[is_south_cb]*(Age_years-t0[is_south_cb]))), data = age_combo, 
                       start = list(linf = rep(55,2), k = rep(0.3,2), t0 = rep(0,2))) 

split_region_wa <- nls(Length_cm ~ linf[is_south_wa] * (1-exp(-k[is_south_wa]*(Age_years-t0[is_south_wa]))), data = age_combo, 
                       start = list(linf = rep(55,2), k = rep(0.3,2), t0 = rep(0,2))) 

AIC(split_region_ca, split_region_cb, split_region_wa, coastwide, split_sex)

### fit sex sepcific models with coos bay as the split
split_cb_m <- split_region_cb <- nls(Length_cm ~ linf[is_south_cb] * (1-exp(-k[is_south_cb]*(Age_years-t0[is_south_cb]))), data = age_combo, 
                                       start = list(linf = rep(55,2), k = rep(0.3,2), t0 = rep(0,2)), subset = Sex == 'M') 

split_cb_f <- split_region_cb <- nls(Length_cm ~ linf[is_south_cb] * (1-exp(-k[is_south_cb]*(Age_years-t0[is_south_cb]))), data = age_combo, 
                                     start = list(linf = rep(55,2), k = rep(0.3,2), t0 = rep(0,2)), subset = Sex == 'F') 

summary(split_cb_m)
summary(split_cb_f)


# Make beautiful plots ----------------------------------------------------


vbgf <- function(x, linf, k, t0, linf_adj = NULL) {
  (linf + ifelse(is.null(linf_adj), 0, linf_adj)) * (1-exp(-k*(x-t0)))
}

# bin2d to deal with overplotting, faceted CA vs OR/WA
ggplot(age_combo) +
  stat_bin_2d(aes(x = Age_years, y = Length_cm)) + 
  facet_wrap(~is_south_ca)


coefs1 <- coef(split_region_cb)[c(1,3,5)]
names(coefs1) <- gsub(pattern = '1', replacement = '', x = names(coefs1))
coefs2 <- coef(split_region_cb)[c(2,4,6)]
names(coefs2) <- gsub(pattern = '2', replacement = '', x = names(coefs2))

# data frame of two fitted lines, CA vs OR/WA
vbgf.df <- expand.grid(Age_years = seq(0, 60, length.out = 100),
                       is_south_cb = c(TRUE, FALSE)) %>% 
  dplyr::as_tibble() %>%
  dplyr::mutate(Length_cm_s_args = lapply(Age_years, function(x) c(x = x, as.list(coefs1))),
                Length_cm_n_args = lapply(Age_years, function(x) c(x = x, as.list(coefs2))),
                Length_cm_s = sapply(Length_cm_s_args, do.call, what = vbgf),
                Length_cm_n = sapply(Length_cm_n_args, do.call, what = vbgf),
                Length_cm = ifelse(is_south_cb, Length_cm_s, Length_cm_n))

# scatter plot with fitted lines, colored by CA vs OR/WA
age_combo %>%
  ggplot(aes(x = Age_years, y = Length_cm, col = is_south_cb)) +
  geom_point(alpha = 0.1, pch = 16) +
  geom_line(data = vbgf.df) +
  ggsidekick::theme_sleek() +
  # scale_color_discrete(name = 'Region', labels = c(`TRUE` = 'CA', 
  #                                                   `FALSE` = 'OR-WA'))
  NULL


# scatter plot with fitted lines, faceted by CA vs OR/WA (compare sample sizes)
age_combo %>%
  ggplot() +
  geom_point(aes(x = Age_years, y = Length_cm), alpha = 0.05, pch=16) + 
  geom_function(data = transform(age_combo, is_south_ca = TRUE), col = 'red',
                fun = vbgf, args = as.list(coefs1)) +
  geom_function(data = transform(age_combo, is_south_ca = FALSE), col = 'red',
                fun = vbgf, args = as.list(coefs2)) +
  facet_wrap(~is_south_ca, 
             labeller = as_labeller(c(`TRUE` = 'CA', `FALSE` = 'OR-WA'))) +
  ggsidekick::theme_sleek()

dplyr::group_by(wcgbts_bio, Year) %>% 
  dplyr::summarise(n = dplyr::n()) %>%
  with(mean(n))

# Percent female by age. Around 50%, then drops off around age 17
age_combo %>%
  dplyr::filter(!is.na(Age_years)) %>%
#  dplyr::mutate(Age_years = factor(Age_years)) %>%
  dplyr::group_by(Age_years) %>%
  dplyr::summarise(Pct_female = sum(Sex == 'F') / dplyr::n(),
                   se = sqrt(Pct_female*(1-Pct_female)/dplyr::n())) %>%
 # dplyr::mutate(Age_years = as.numeric(Age_years)) %>%
  ggplot() +
  geom_point(aes(x = Age_years, y = Pct_female)) +
  geom_segment(aes(x = Age_years, y = Pct_female - se, xend = Age_years, yend = Pct_female + se))


# Data workshop figures ---------------------------------------------------
## scatter plot of age-length-sex
wcgbts_bio %>%
  dplyr::filter(!is.na(Age_years)) %>%
  ggplot(data = ., aes(x = Age_years, y = Length_cm, col = Sex)) +
  geom_point(alpha = 0.25) +
  labs(x = 'Age (years)', y = 'Length (cm)') +
  scale_color_manual(values = c('F' = 'blue', 'M' = 'red', 'U' = 'darkgoldenrod1'))
  
ggsave(filename = here('data_workshop_figs/len_data.png'), device = 'png', 
       height = 5, width = 7, units = 'in', dpi = 500)

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
# The legend could be better but this is good enough
lwd = 1
age_combo %>%
  dplyr::filter(!is.na(Age_years)) %>%
  ggplot() +
  geom_point(aes(x = Age_years, y = Length_cm, col = Sex, shape = is_south_cb), 
             alpha = 0.25) + 
  geom_function(data = transform(age_combo, is_south_cb = TRUE), col = 'red',
                fun = vbgf, args = as.list(coefs_n_m), aes(linetype = 'South'), linewidth = lwd) +
  geom_function(data = transform(age_combo, is_south_cb = FALSE), col = 'red',
                fun = vbgf, args = as.list(coefs_s_m), aes(linetype = 'North'), linewidth = lwd) +
  geom_function(data = transform(age_combo, is_south_cb = TRUE), col = 'blue',
                fun = vbgf, args = as.list(coefs_n_f), aes(linetype = 'South'), linewidth = lwd) +
  geom_function(data = transform(age_combo, is_south_cb = FALSE), col = 'blue',
                fun = vbgf, args = as.list(coefs_s_f), aes(linetype = 'North'), linewidth = lwd) +
  scale_color_manual(values = c('F' = 'blue', 'M' = 'red', 'U' = 'darkgoldenrod1')) +
  labs(x = 'Age (years)', y = 'Length (cm)') +
  scale_shape_discrete(name = 'Region', labels = c('TRUE' = 'South', 'FALSE' = 'North')) +
  scale_linetype_discrete(name = 'Region') +
  NULL
ggsave(filename = here('data_workshop_figs/growth_diffs.png'), device = 'png', 
       height = 5, width = 7, units = 'in', dpi = 500)


## Triennial age and length compositions
triennial_ca <- dplyr::filter(age_combo, survey == 'triennial', is_south_ca == 'TRUE')
triennial_n <- triennial_ca %>%
  dplyr::group_by(Year) %>%
  dplyr::summarise(lengths = sum(!is.na(Length_cm)),
                   ages = sum(!is.na(Age_years)))
triennial_ca %>%
  ggplot() +
  ggridges::geom_density_ridges(aes(y = factor(Year), x = Age_years), fill = 'gray80') +
  geom_label(aes(y = factor(Year), label = ages), x = 30, data = triennial_n) +
  labs(y = 'Year', x = 'Age (yrs)')
ggsave(filename = here('data_workshop_figs/triennial_ages.png'), device = 'png', 
       height = 5, width = 9, units = 'in', dpi = 500)

triennial_ca %>%
  ggplot() +
  ggridges::geom_density_ridges(aes(y = factor(Year), x = Length_cm), fill = 'gray80') +
  geom_label(aes(y = factor(Year), label = lengths), x = 70, data = triennial_n) +
  labs(y = 'Year', x = 'Length (cm)') +
  xlim(0,75)
ggsave(filename = here('data_workshop_figs/triennial_lengths.png'), device = 'png', 
       height = 5, width = 9, units = 'in', dpi = 500)

## WCGBTS age and length comps
wcgbts_ca <- dplyr::filter(age_combo, survey == 'trawl', is_south_ca == 'TRUE')
wcgbts_n <- wcgbts_ca %>%
  dplyr::group_by(Year) %>%
  dplyr::summarise(lengths = sum(!is.na(Length_cm)),
                   ages = sum(!is.na(Age_years)))

wcgbts_ca %>%
  ggplot() +
  ggridges::geom_density_ridges(aes(y = factor(Year), x = Age_years), fill = 'gray80') +
  geom_label(aes(y = factor(Year), label = ages), x = 55, data = wcgbts_n) +
  labs(y = 'Year', x = 'Age (yrs)')
ggsave(filename = here('data_workshop_figs/wcgbts_ages.png'), device = 'png', 
       height = 5, width = 9, units = 'in', dpi = 500)

wcgbts_ca %>%
  ggplot() +
  ggridges::geom_density_ridges(aes(y = factor(Year), x = Length_cm), fill = 'gray80') +
  geom_label(aes(y = factor(Year), label = lengths), x = 70, data = wcgbts_n) +
  labs(y = 'Year', x = 'Length (cm)') +
  xlim(0,75)
ggsave(filename = here('data_workshop_figs/wcgbts_lengths.png'), device = 'png', 
       height = 5, width = 9, units = 'in', dpi = 500)
