##########################################################################################
#
# Figure generation for write up
#   By: Kiva Oken and Brian Langseth
#
##########################################################################################


library(r4ss)
#devtools::install_github("pfmc-assessments/PEPtools")
library(PEPtools)
library(here)
library(dplyr)

source(here('code/selexComp.R'))

base_mod <- '5_5_0_hessian'
mod15 <- SS_output(here('models','2015base'))
mod23 <- SS_output(here('models', base_mod))


##
#Compare fecundity from previous assessment
##
png(
  filename = here('documents','figures','compare_fecundity.png'),
  width = 6.5, height = 5.0, units = "in", res = 300, pointsize = 10
)

plot(mod15$biology$Len_mean, mod15$biology$Fec, type = "l", lwd=3, col = 2,
     ylab = "Fecundity (millions of eggs)", xlab = "Length (cm)")
lines(mod23$biology$Len_mean, mod23$biology$Fec, lwd = 3, col = 1)

legend("topleft", c("2015 relationship", "2023 relationship"), 
       lty = 1, lwd = 3, col = c(2,1), bty = "n")
dev.off()


##
#Plot WL relationship
##
wcgbts_date <- '2023-02-13'
load(here(paste0('data-raw/Bio_All_NWFSC.Combo_', wcgbts_date, '.rda')))

read.csv(here('data/W_L_pars.csv')) |>
  dplyr::mutate(out.dfr = purrr::map2(A, B, ~ dplyr::tibble(x = 1:66, y = .x*x^.y))) |>
  tidyr::unnest(out.dfr) |>
  dplyr::filter(Sex != 'B') |>
  ggplot() +
  geom_point(aes(x = Length_cm, y = Weight, col = Sex), alpha = 0.05, 
             data = dplyr::filter(Data, Sex != 'U')) +
  geom_line(aes(x, y, col = Sex), linewidth = 1) +
  labs(x = 'Length (cm)', y = 'Weight (kg)') +
  scale_color_manual(values = c('F' = 'red', 'M' = 'blue')) +
  theme_classic()
ggsave(here('documents/figures/WL.png'), device = 'png', width = 6.5,
       height = 5, units = 'in', dpi = 300)

##
#Compare WL relationship with previous assessment
##
png(
  filename = here('documents','figures','compare_WL.png'),
  width = 6.5, height = 5.0, units = "in", res = 300, pointsize = 10
)

plot(mod23$biology$Len_mean, mod23$parameters['Wtlen_1_Fem', 'Value']*
       mod23$biology$Len_mean^mod23$parameters['Wtlen_2_Fem', 'Value'], 
     type = "n", lty = 1, lwd=3, col = 2, ylab = "Weight (kg)", xlab = "Length (cm)")

#Females
lines(mod23$biology$Len_mean, mod23$parameters['Wtlen_1_Fem', 'Value']*
       mod23$biology$Len_mean^mod23$parameters['Wtlen_2_Fem', 'Value'], 
      lty = 1, lwd=3, col = 2)
lines(mod15$biology$Len_mean, mod15$parameters['Wtlen_1_Fem', 'Value']*
        mod15$biology$Len_mean^mod15$parameters['Wtlen_2_Fem', 'Value'], 
      lwd = 3, lty = 3, col = 2)

#Males
lines(mod23$biology$Len_mean, mod23$parameters['Wtlen_1_Mal', 'Value']*
        mod23$biology$Len_mean^mod23$parameters['Wtlen_2_Mal', 'Value'], 
      lty = 1, lwd = 3, col = 4)
lines(mod15$biology$Len_mean, mod15$parameters['Wtlen_1_Mal', 'Value']*
        mod15$biology$Len_mean^mod15$parameters['Wtlen_2_Mal', 'Value'], 
      lty = 2, lwd = 3, col = 4)

legend("topleft", c("2023 relationship", "2015 relationship", "Female", "Male"), 
       lty = c(1,2,1,1), lwd = 3, col = c(1,1,2,4), bty = "n")

dev.off()


##
#Compare Maturity relationship with previous assessment
##
png(
  filename = here('documents','figures','compare_maturity.png'),
  width = 6.5, height = 5.0, units = "in", res = 300, pointsize = 10
)

#Because the 2015 assumed maturity at length, the maturity at age is in a column called (len_mat)
#which means length based maturity at age
#The 2023 model assumed maturity at age, and so is in a column called (age_mat)
#which means age based maturity at age
plot(mod15$endgrowth[mod15$endgrowth$Sex==1,]$Age_Mid, mod15$endgrowth[mod15$endgrowth$Sex==1,]$Len_Mat,
     ylab = "Female maturity", xlab = "Age",
     type = "l", lwd = 3, col = 2, ylim=c(0,1))
lines(mod23$endgrowth[mod23$endgrowth$Sex==1,]$Age_Mid, mod23$endgrowth[mod23$endgrowth$Sex==1,]$Age_Mat,
      lwd = 3, col = 1)

legend("bottomright", c("2015 derived relationship", "2023 relationship"), 
       lty = 1, lwd = 3, col = c(2,1), bty = "n")
dev.off()


##
#Compare maturity * fecundity. This comparison is going to be affected by the growth curve due
#to fecundity (at length or weight) being translated to age which is different between the two models
##
png(
  filename = here('documents','figures','compare_maturity-fecundity.png'),
  width = 6.5, height = 5.0, units = "in", res = 300, pointsize = 10
)

plot(mod15$endgrowth[mod15$endgrowth$Sex==1,]$Age_Mid, mod15$endgrowth[mod15$endgrowth$Sex==1,]$`Mat*Fecund`,
     ylab = "Spawning output at age (mat x fec)", xlab = "Age",
     type = "l", lwd = 3, col = 2, ylim=c(0,1.5))
lines(mod23$endgrowth[mod23$endgrowth$Sex==1,]$Age_Mid, mod23$endgrowth[mod23$endgrowth$Sex==1,]$`Mat*Fecund`,
      lwd = 3, col = 1)

legend("topleft", c("2015 relationship", "2023 relationship"), 
       lty = 1, lwd = 3, col = c(2,1), bty = "n")
dev.off()


# ACL table ---------------------------------------------------------------
catch.ts <- readr::read_csv(here('models', base_mod, 'tables/a_Catches_ES.csv')) |>
  dplyr::mutate(TWL = `1_CA_TWL` + `2_OR_TWL` + `3_WA_TWL`,
              NTWL = `4_CA_NTWL` + `5_OR_NTWL` + `6_WA_NTWL`,
              REC = `7_CA_REC` + `8_OR_REC` + `9_WA_REC`,
              ASHOP = `10_CA_ASHOP` + `11_OR_ASHOP` + `12_WA_ASHOP`,
              FOR = `13_CA_FOR` + `14_OR_FOR` + `15_WA_FOR`,
              TOTAL = TWL + NTWL + REC + ASHOP + FOR) |>
  dplyr::select(Year, TOTAL, TWL, NTWL, REC, ASHOP, FOR) 

readr::read_csv(here('data/ACLs.csv')) |>
  dplyr::select(-STOCK_NAME, -AREA_NAME, -OUTPUT_ORDER, -SPECIFICATION_NAME) |>
  tidyr::pivot_wider(names_from = SPECIFICATION_TYPE, values_from = VAL) |> 
  dplyr::arrange(YEAR) |>
  dplyr::select(Year = YEAR, OFL:ACL) |>
  dplyr::inner_join(dplyr::select(catch.ts, Year, `Total Mortality` = TOTAL)) |>
  write.csv(file = here('documents/tables/ACL_history.csv'), row.names = FALSE)
