# Analyze and plot geographic difference in VBGF curve from survey data

library(magrittr)
library(ggplot2)
library(here) 

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

### Combine age data from triennial and wcgbts, create flags for different regional divisions
age_combo <- dplyr::select(wcgbts_bio, Year, Length_cm, Sex, Age_years, Latitude_dd, Longitude_dd) %>%
  dplyr::bind_rows(dplyr::select(triennial_bio, Year, Length_cm, Sex, Age_years, Latitude_dd, Longitude_dd)) %>%
  dplyr::mutate(is_south_cb = factor(dplyr::if_else(Latitude_dd < 43.3672,
                                        TRUE, FALSE)),
                is_south_ca = factor(dplyr::if_else(Latitude_dd < 42,
                                             TRUE, FALSE)),
                is_south_wa = factor(dplyr::if_else(Latitude_dd < 46.25,
                                             TRUE, FALSE)),
                Sex = factor(Sex))


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
split_region_m <- nls(Length_cm ~ (linf+linf_adj*is_south_cb)*(1-exp(-k*(Age_years-t0))), data = age_combo, 
                    start = list(linf = 55, linf_adj = 0, k = 0.3, t0 = 0), 
                    subset = Sex == 'M') 
summary(split_region_m)

split_region_f <- nls(Length_cm ~ (linf+linf_adj*is_south_cb)*(1-exp(-k*(Age_years-t0))), data = age_combo, 
                      start = list(linf = 55, linf_adj = 0, k = 0.3, t0 = 0), 
                      subset = Sex == 'F') 
summary(split_region_f)

### Make beauitful plots of data and fits

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
