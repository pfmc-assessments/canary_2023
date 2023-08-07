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
library(ggplot2)

source(here('code/selexComp.R'))

base_mod <- '7_3_5_reweight'
base_mod_proj <- '7_3_5_reweight'
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
Can.mat<-read.csv(here("data-raw/2009_2022_Canarymaturity.csv"))

fitted.mat <- bind_rows(list(mod15 = mod15$endgrowth, mod23 = mod23$endgrowth), .id = 'model') |> 
  mutate(mat = ifelse(model == 'mod15', Len_Mat, Age_Mat)) |>
  filter(Sex == 1) |>
  select(model, Age_Mid, mat)

Can.mat |>
  filter(!is.na(Age)) |>
  group_by(Age) |>
  summarise(n.mat = sum(Functional_maturity),
            n.samp = n(),
            pct.mat = n.mat/n.samp) |>
  ggplot() +
  geom_point(aes(x = Age, y = pct.mat, size = n.samp), alpha = 0.5) +
  scale_size_area(max_size = 12, name = 'Sample size') +
  geom_line(data = fitted.mat, aes(x = Age_Mid, y = mat, col = model),
            linewidth = 1) +
  scale_color_manual(labels = c(mod15 = '2015 derived relationship',
                                mod23 = '2023 relationship'),
                     values = c(mod15 = '#DF536B', mod23 = 'black'),
                     name = '') +
  theme_classic() +
  ylab('Percent females mature')
ggsave(here('documents','figures','compare_maturity.png'), 
       width = 7.5, height = 5, units = 'in', dpi = 300)

png(
  filename = 
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
  dplyr::mutate(ABC = round(ABC, 0)) |>
  write.csv(file = here('documents/tables/ACL_history.csv'), row.names = FALSE)



##
#Bridging figures ---------------------------------------------------------------
##

#These dont include the newest updates to catch for WA 2022 rec catch and CA rec in 2020 and 2021
#but I expect those to have minimal effect so moving forward with what was done

#Convert to new .exe --------------------------------

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c('2015base',
                                                 'converted_detailed_hessian')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015:SSv3.20',
                                     '2015:SSv3.30.21'),
                    subplots = c(1:4,9,11), print = TRUE, plotdir = here('models','converted_detailed_hessian'),
                    uncertainty = c(TRUE,FALSE))

file.copy(from =  here('models','converted_detailed_hessian',
                       c("compare2_spawnbio_uncertainty.png","compare4_Bratio_uncertainty.png")),
          to = here('documents','figures',
                    c("bridge0_exe_spawnbio_uncertainty.png","bridg0_exe_compare4_Bratio_uncertainty.png")))


#Data plots --------------------------------

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models','Bridging coastwide'),
                                      subdir = c('../converted_detailed_hessian',
                                                 '3_1_2_catch',
                                                 '3_1_6_fisheryComps',
                                                 '3_1_7_fishery',
                                                 '3_1_3_survey',
                                                 '3_1_8_survey',
                                                 '3_1_1_update_data')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015:SSv3.30.21',
                                     '+Removals',
                                     '+Fishery comps',
                                     '+Fishery removals and comps',
                                     '+Surveys indices',
                                     '+Survey indices and comps',
                                     'All data updated'),
                    subplots = c(1:4,9,11), print = TRUE, uncertainty = c(TRUE,rep(FALSE,6)),
                    plotdir = here('models','Bridging coastwide', '3_1_1_update_data'))

file.copy(from =  here('models','Bridging coastwide', '3_1_1_update_data',
                       c("compare2_spawnbio_uncertainty.png","compare4_Bratio_uncertainty.png")),
          to = here('documents','figures',
                    c("bridge1_data_spawnbio_uncertainty.png","bridge1_data_compare4_Bratio_uncertainty.png")))


#Biology plots --------------------------------

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models','Bridging coastwide'),
                                      subdir = c('../converted_detailed_hessian',
                                                 '3_1_1_update_data',
                                                 '3_2_2_M_justValue',
                                                 '3_2_3_maturity',
                                                 '3_2_4_steepness',
                                                 '3_2_5_fecund',
                                                 '3_2_6_WL',
                                                 '3_2_7_update_bio_Mval_phases')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015:SSv3.30.21',
                                     'All data updated',
                                     '+Mortality value',
                                     '+Maturity',
                                     '+Steepness',
                                     '+Fecundity',
                                     '+Weight-length',
                                     "All biology and data updated"),
                    subplots = c(1:4,9,11), print = TRUE, uncertainty = c(TRUE,rep(FALSE,7)),
                    plotdir = here('models','Bridging coastwide', '3_2_1_update_bio_Mval'))

file.copy(from =  here('models','Bridging coastwide', '3_2_1_update_bio_Mval',
                       c("compare2_spawnbio_uncertainty.png","compare4_Bratio_uncertainty.png")),
          to = here('documents','figures',
                    c("bridge2_bio_spawnbio_uncertainty.png","bridge2_bio_compare4_Bratio_uncertainty.png")))


#Natural mortality plots --------------------------------

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models','Bridging coastwide'),
                                      subdir = c('../converted_detailed_hessian',
                                                 '3_1_1_update_data',
                                                 '3_2_7_update_bio_Mval_phases',
                                                 '3_2_7_update_bio_Mconstant_phases')))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015:SSv3.30.21',
                                     'All data updated',
                                     'All biology values and data updated',
                                     'Mortality structure as age invariant'),
                    subplots = c(1:4,9,11), print = TRUE, uncertainty = c(TRUE,rep(FALSE,3)),
                    plotdir = here('models','Bridging coastwide', '3_2_7_update_bio_Mval_phases'))

file.copy(from =  here('models','Bridging coastwide', '3_2_7_update_bio_Mval_phases',
                       c("compare2_spawnbio_uncertainty.png","compare4_Bratio_uncertainty.png")),
          to = here('documents','figures',
                    c("bridge3_M_spawnbio_uncertainty.png","bridge3_M_compare4_Bratio_uncertainty.png")),overwrite = TRUE)


#Natural mortality for presentation

png(here('documents','figures',"natural_mortality.png"), width = 4, height = 5, units = "in", res = 300)
  curve(dlnorm(x, meanlog=log(5.4/84), sdlog=0.31), from=0, to=0.2, yaxs = 'i',
        xlab = "Natural Mortality", ylab = "Density")
  abline(v=5.4/84, lty = 3)
dev.off()



#Spatial structure and tuning --------------------------------

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models','Bridging coastwide'),
                                      subdir = c('../converted_detailed_hessian',
                                                 '3_2_7_update_bio_Mconstant_phases',
                                                 '3_3_1_coastwide',
                                                 '3_2_9_tuned',
                                                 '3_3_6_coastwide_tuned')))

dir.create(here('models','Bridging coastwide', '3_3_6_coastwide_tuned', 'for_report'))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015:SSv3.30.21',
                                     'Spatial model',
                                     "Coastwide model",
                                     'Spatial model (reweighted)',
                                     'Coastwide model (reweighted)'),
                    subplots = c(1:4,9,11), print = TRUE, uncertainty = c(TRUE,rep(FALSE,4)),
                    plotdir = here('models','Bridging coastwide', '3_3_6_coastwide_tuned', 'for_report'))

file.copy(from =  here('models','Bridging coastwide', '3_3_6_coastwide_tuned', 'for_report',
                       c("compare2_spawnbio_uncertainty.png","compare4_Bratio_uncertainty.png")),
          to = here('documents','figures',
                    c("bridge4_spatialAndTuning_spawnbio_uncertainty.png","bridge4_spatialAndTuning_compare4_Bratio_uncertainty.png")))


#Selectivity changes --------------------------------

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = here('models','Bridging coastwide'),
                                      subdir = c('../converted_detailed_hessian',
                                                 '3_3_6_coastwide_tuned',
                                                 '3_3_4_coastwide_tuned',
                                                 '3_3_8_sexDependentSelex',
                                                 '../7_3_5_reweight')))

SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015:SSv3.30.21',
                                     'Coastwide model (reweighted)',
                                     'Update selectivity (reweighted)',
                                     'Sex dependent selectivity parameter 4',
                                     'Various changes (base model)'),
                    subplots = c(1:4,9,11), print = TRUE, uncertainty = c(TRUE,rep(FALSE,4)),
                    plotdir = here('models','Bridging coastwide', '3_3_8_sexDependentSelex'))

file.copy(from =  here('models','Bridging coastwide', '3_3_8_sexDependentSelex',
                       c("compare2_spawnbio_uncertainty.png","compare4_Bratio_uncertainty.png")),
          to = here('documents','figures',
                    c("bridge5_selex_spawnbio_uncertainty.png","bridge5_selex_compare4_Bratio_uncertainty.png")), 
          overwrite = TRUE)


# Parameter table ---------------------------------------------------------

mod_params = mod23$parameters[, 
                              (names(mod23$parameters) %in%
                                 c("Num","Label","Value","Phase","Min",
                                   "Max","Status","Parm_StDev",
                                   "Pr_type","Prior","Pr_SD"))] 

#Remove female offsets that aren't used
rm <- grep("Fem_Peak|Fem_Ascend|Fem_Final|Fem_Scale",mod_params$Label)
mod_params <- mod_params[-rm, ]

#Set parameters with scientific values to round to 3 units
sci_note <- which(mod_params$Label %in% c("Wtlen_1_Fem_GP_1", "Wtlen_1_Mal_GP_1", "Eggs_scalar_Fem_GP_1"))
mod_params[-sci_note,'Value'] <- round(as.numeric(mod_params[-sci_note,'Value']), 3)

# Combine bounds into one column
mod_params$Min = paste('(', mod_params$Min, ', ', mod_params$Max, ')', sep='')

# Set Male M prior to lognormal
mod_params$Pr_type[grep("NatM_uniform_Mal_GP_1",mod_params$Label)] <- "Log_Norm"

# Combine prior info to one column
mod_params$PR_type = ifelse(mod_params$Pr_type == 'No_prior' , 'None', paste(mod_params$Pr_type,' (', mod_params$Prior,  ', ', mod_params$Pr_SD, ')', sep = ''))
#Remove priors for things that aren't ever used
mod_params$PR_type[-grep("NatM|steep",mod_params$Label)] <- "None"

# Set long value to scientific notation
mod_params[mod_params$Label == "Wtlen_1_Fem_GP_1",3] = format(mod_params[mod_params$Label == "Wtlen_1_Fem_GP_1",3], scientific = TRUE)
mod_params[mod_params$Label == "Wtlen_1_Mal_GP_1",3] = format(as.numeric(mod_params[mod_params$Label == "Wtlen_1_Mal_GP_1",3]), scientific = TRUE)
mod_params[mod_params$Label == "Eggs_scalar_Fem_GP_1",3] = format(as.numeric(mod_params[mod_params$Label == "Eggs_scalar_Fem_GP_1",3]), scientific = TRUE)

#Change offset to be on normal scale
mod_params[mod_params$Label == "L_at_Amin_Mal_GP_1",3] = exp(as.numeric(mod_params[mod_params$Label == "L_at_Amin_Mal_GP_1",3])) * as.numeric(mod_params[mod_params$Label == "L_at_Amin_Fem_GP_1",3])

remove <- which(grepl("ForeRecr", mod_params$Label ))
mod_params <- mod_params[-remove, ]
mod_params[,'Parm_StDev'] = round(as.numeric(mod_params[,'Parm_StDev']), 3) 

#Set recruitment sd's to not be in scientific notation
find <- which(mod_params$Label == "Early_RecrDev_1892"):which(mod_params$Label == "Main_RecrDev_2022")
mod_params[find, "Value"] <- round(as.numeric(mod_params[find, "Value"]), 3)

# Remove the max, prior and prior sd columns
drops = c('Max', 'Prior', 'Pr_type', 'Pr_SD', 'Num')
mod_params = mod_params[, !(names(mod_params) %in% drops)]
rownames(mod_params) = c()
mod_params[,"Label"] = gsub("\\_", " ", mod_params[,"Label"])
mod_params[,"PR_type"] = gsub("\\_", " ", mod_params[,"PR_type"])

# Set all negative phase values to -99
mod_params[mod_params$Phase <0 ,"Phase"] <- -99

# FracFemale max value with fewer digits
mod_params[mod_params$Label=="FracFemale GP 1","Min"] <- "(1e-06, 0.999)"

#Remove the late triennial q value which should is mirrored but still an estimated parameter
mod_params <- mod_params[mod_params$Label!="LnQ base 30 coastwide Tri late(30)",]

# Add column names
names(mod_params) <- c('Parameter',
                       'Value',
                       'Phase',
                       'Bounds',
                       'Status',
                       'SD',
                       'Prior (Exp. Val, SD)')

write.csv(mod_params, 
          file = here('Documents/tables/parameters.csv'), 
          row.names = FALSE)

# Reference point table ---------------------------------------------------

labels <- expand.grid(c('SSB', 'SPR', 'annF', 'Dead_Catch'),
                      c('Btgt', 'SPR', 'MSY')) |>
  dplyr::mutate(label = paste(Var1, Var2, sep = '_'))

ref.tab <- dplyr::filter(mod23$derived_quants, Label %in% labels$label) |>
  dplyr::mutate(ref = sapply(stringr::str_split(Label, pattern = '_'), tail, 1),
                met = stringr::str_remove(Label, paste0('_', ref))) |>
  dplyr::mutate(value.fmt = glue::glue('${x}\\pm {sd}$',
                                       x = sapply(Value, format, scientific = FALSE,
                                                  digits = 3),
                                       sd = sapply(StdDev, format, scientific = FALSE,
                                                   digits = 2))) |>
  dplyr::select(value.fmt, ref, met) |>
  tidyr::pivot_wider(names_from = met, values_from = value.fmt) |>
  dplyr::mutate(ref = c('$B_{40\\%}$', 'SPR$_{0.5}$', 'MSY'))


names(ref.tab) <- c('Mgmt target', 'Spawning output ($10^6$ eggs)', 'SPR', 'F (1/yr)', 'Dead Catch (mt)')

ref.tab$SPR[1] <- stringr::str_remove(string = ref.tab$SPR[1], pattern = '\\\\pm 0.[:digit:]+')
ref.tab$SPR[2] <- '0.5'

write.csv(ref.tab, here('documents/tables/ref_points.csv'), row.names = FALSE)

# Data weight (Francis versus MI) table ---------------------------------------------------

source(here('code/table_compweight.R'))
mod23_mi <- SS_output(here('models', 'sensitivities', 'mcallister_ianelli'))

fran <- table_compweight(mod23,
                 caption_extra = paste("The WCGBTS age comps are conditioned on length,",
                                       "so there are more observations with fewer samples per observation."),
                 label = "data-weights", dataframe = TRUE, fleetnames = "short") 

mi <- table_compweight(mod23_mi,
                 caption_extra = paste("The WCGBTS age comps are conditioned on length,",
                                       "so there are more observations with fewer samples per observation."),
                 label = "data-weights", dataframe = TRUE, fleetnames = "short") 

both <- cbind(fran[,c("Type","Fleet","Francis")], mi[,c("Francis")])
colnames(both)[4] <- "MI"

write.csv(both, here('documents','tables','data-weight-compare.csv'), row.names = FALSE)


# Canadian recruitment ----------------------------------------------------

# compare rec devs
bc_recdevs <- readxl::read_excel(here('data-raw/CAR-data-for.BL.KO.xlsx'),
                                 sheet = 'Rdevs') |>
  dplyr::select(-1) |>
  tidyr::pivot_longer(cols = dplyr::everything(), names_to = 'Yr', values_to = 'recdev') |>
  dplyr::group_by(Yr) |>
  dplyr::summarise(dev = median(recdev)) |>
  dplyr::mutate(Yr = as.numeric(Yr)) |>
  dplyr::filter(Yr < 2022)

dplyr::select(mod23$recruit, Yr, dev) |>
  list(bc_recdevs) |>
  `names<-`(c('Base', 'BC')) |>
  dplyr::bind_rows(.id = 'Model') |> 
  dplyr::filter(Yr >= 1955) |>
  tidyr::nest(data = -Model) |>
  dplyr::mutate(fit = purrr::map(data, ~lm(dev ~ Yr, data = .)),
                detrended = purrr::map(fit, resid)) |>
  dplyr::select(-fit) |>
  tidyr::unnest(cols = c(data, detrended)) |>
  dplyr::select(-dev) |> 
  tidyr::pivot_wider(names_from = Model, values_from = detrended) |> #with(cor.test(Base, BC, use = 'pairwise.complete.obs'))
  ggplot(aes(x = Base, y = BC, col = Yr)) +
  geom_point() +
  geom_abline(slope = 1, intercept = 0, linetype = 'dotted') +
  geom_hline(yintercept = 0) + geom_vline(xintercept = 0) +
  labs(x = 'Detrended base model recruitment deviation', y = 'Detrended BC model recruitment deviation', col = 'Year') +
  theme_classic()

ggsave(here('documents/figures/canada_rec.png'), device = 'png', width = 6.5,
       height = 5, units = 'in', dpi = 300)



# Projection table ----------------------------------------------------

tab = readr::read_csv(here('models',base_mod_proj, "tables", "g_Projections_ES.csv")) |> data.frame()
man = readr::read_csv(here('data/ACLs.csv')) |> data.frame()

out = cbind(tab$Year,
            c(round(man[man$YEAR %in% c(2023, 2024) & man$SPECIFICATION_TYPE == "OFL", "VAL"],0), rep("-",10)),
            c(round(man[man$YEAR %in% c(2023, 2024) & man$SPECIFICATION_TYPE == "ABC", "VAL"],0), rep("-",10)),
            c(round(man[man$YEAR %in% c(2023, 2024) & man$SPECIFICATION_TYPE == "ACL", "VAL"],0), rep("-",10)),
            c(round(tab[1:2,'ABC.Catch..mt.'],2), rep("-",10)),
            c(rep("-",2), round(tab[3:12,"Predicted.OFL..mt."], 2)),
            c(rep("-",2), PEPtools::get_buffer(2023:2034,0.5,0.45)[-c(1,2),2]),
            c(rep("-",2), round(round(tab[3:12,'Predicted.OFL..mt.'],2)*PEPtools::get_buffer(2023:2034,0.5,0.45)[-c(1,2),2],2)),  
            c(rep("-",2), round(tab[3:12,'ABC.Catch..mt.'],2)),
            round(tab[ ,5:ncol(tab)], 2))

col_names = c('Year',
              'Adopted OFL (mt)',
              'Adopted ABC (mt)',
              'Adopted ACL (mt)',
              "Assumed removals (mt)",
              "OFL (mt)",
              "Buffer",
              "ABC",
              "ACL",
              "Spawning Output",
              "Fraction Unfished")

colnames(out)<-col_names

write.csv(out, here('documents','tables','projections.csv'), row.names = FALSE)



#Sample sizes figures for STAR presentation -----------------------------------

#Sample sizes for fishery data
fdlen <- left_join(full_join(readr::read_csv(here('documents/tables/pacfin_lengths.csv')),
                   readr::read_csv(here('data/Canary_ashop_LengthComps_hauls_and_samples.csv')),
                   by = "Year"),
                   readr::read_csv(here('documents/tables/rec_lengths.csv')), by = join_by(Year == year)) |>
  dplyr::select(contains("Lengths") | contains("N", ignore.case=FALSE) | contains("Year")) |>
  dplyr::select(!contains("Trips")) |>
  dplyr::rename("Lengths_ASHOP.O" = "OR_N",
                "Lengths_ASHOP.W" = "WA_N",
                "Lengths_REC.C" = "N_CA",
                "Lengths_REC.O" = "N_OR",
                "Lengths_REC.W" = "N_WA") |>
  tidyr::pivot_longer(cols = - Year, names_pattern = "(Lengths)_(.*).(.)", 
                      names_to = c(".value", "fleet", "state"))
fdlen$fleet <- factor(fdlen$fleet, levels = c("ASHOP","REC","NTWL","TWL"))

fdage <- left_join(full_join(readr::read_csv(here('documents/tables/pacfin_ages_fixAges.csv')),
                             readr::read_csv(here('data/Canary_ashop_AgeComps_hauls_and_samples.csv')),
                             by = "Year"),
                   readr::read_csv(here('documents/tables/rec_ages.csv')), by = join_by(Year == year)) |>
  dplyr::select(contains("Ages") | contains("N", ignore.case=FALSE) | contains("Year")) |>
  dplyr::select(!contains("Trips")) |>
  dplyr::rename("Ages_ASHOP.O" = "OR_N",
                "Ages_ASHOP.W" = "WA_N",
                "Ages_REC.O" = "O_or_ora_N",
                "Ages_REC.W" = "W_wa_sport_N") |>
  tidyr::pivot_longer(cols = - Year, names_pattern = "(Ages)_(.*).(.)", 
                      names_to = c(".value", "fleet", "state"))
fdage$fleet <- factor(fdage$fleet, levels = c("ASHOP","REC","NTWL","TWL"))
  

lab_val = c("California", "Oregon", "Washington")
names(lab_val) = c("C","O","W")


ggplot(fdlen, aes(fill=fleet, x=Year, y = Lengths)) + 
  geom_bar(position="stack", stat="identity", color = "gray", width = 1) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of length samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) +
  scale_fill_manual(values=viridis::viridis(n=4))
ggsave(file.path(here('documents','figures',"lenN_fleet.png")),
       width = 6, height = 6)

ggplot(fdage, aes(fill=fleet, x=Year, y = Ages)) + 
  geom_bar(position="stack", stat="identity", color = "gray", width = 1) +
  facet_wrap("state", ncol=1, labeller = labeller(state = lab_val)) +
  xlab("Year") +
  ylab("# of aged samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) +
  scale_fill_manual(values=viridis::viridis(n=4))
ggsave(file.path(here('documents','figures',"ageN_fleet_fixAges.png")),
       width = 6, height = 6)



#Sample size figures for survey data
fi <- full_join(readr::read_csv(here('documents/tables/wcgbts_summary.csv')),
                             readr::read_csv(here('documents/tables/triennial_summary.csv')),
                             by = "Year") |>
  dplyr::select(contains("lengths") | contains("ages") | contains("Year")) |>
  dplyr::rename("N_Lengths_WCGBTS" = "N lengths.x",
                "N_Lengths_Triennial" = "N lengths.y",
                "N_Ages_WCGBTS" = "N ages.x",
                "N_Ages_Triennial" = "N ages.y") |>
  tidyr::pivot_longer(cols = - Year, names_pattern = "(N)_(.*)_(.*)", 
                      names_to = c(".value", "type", "fleet"))
fi$type <- factor(fi$type, levels = c("Lengths","Ages"))


ggplot(fi, aes(fill=fleet, x=Year, y = N)) + 
  geom_bar(position="stack", stat="identity", color = "gray", width = 1) +
  facet_wrap("type") +
  xlab("Year") +
  ylab("# of samples") + 
  theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) +
  scale_fill_manual(values=viridis::viridis(n=2))
ggsave(file.path(here('documents','figures',"N_survey.png")),
       width = 6, height = 4)


#Discard ratio plots -----------------------------------

removals <- read.csv(here::here('data-raw',"CONFIDENTIAL_canary_removals_forStateApproval_June8.csv"), header = TRUE)

removals$TWL.mt <- removals$TWL.C + removals$TWL.O + removals$TWL.W
removals$TWL.dis <- removals$TWL.C.dis + removals$TWL.O.dis + removals$TWL.W.dis
removals$TWL.dis.ratio <- removals$TWL.dis/(removals$TWL.mt + removals$TWL.dis)

removals$NTWL.mt <- removals$NTWL.C + removals$NTWL.O + removals$NTWL.W
removals$NTWL.dis <- removals$NTWL.C.dis + removals$NTWL.O.dis + removals$NTWL.W.dis
removals$NTWL.dis.ratio <- removals$NTWL.dis/(removals$NTWL.mt + removals$NTWL.dis)

png(here('documents',"figures","commercial_discard_ratio.png"), width = 6, height = 4, units = "in", res=300)
plot(removals$Year, removals$TWL.dis.ratio,type = "b", 
     xlim = c(1975,2022), ylim = c(0,1), yaxs = 'i',
     lwd = 3, ylab = "Proportion of removals that are discards")
lines(removals$Year, removals$NTWL.dis.ratio, type = "b", lwd = 3, col = 2)
legend("topleft",c("Trawl", "Non-trawl"), lwd = 3, col = c(1,2), lty = 1, bty = "n")
dev.off()

#Squid plot for retro recruitments -----------------------------------

retro_model = "7_3_5_reweight_retro"

base <- mod23
retro1 = SS_output(here('models',retro_model, "retro", "retro-1"), printstats = FALSE, verbose = FALSE, covar = FALSE)
retro2 = SS_output(here('models',retro_model, "retro", "retro-2"), printstats = FALSE, verbose = FALSE, covar = FALSE)
retro3 = SS_output(here('models',retro_model, "retro", "retro-3"), printstats = FALSE, verbose = FALSE, covar = FALSE)
retro4 = SS_output(here('models',retro_model, "retro", "retro-4"), printstats = FALSE, verbose = FALSE, covar = FALSE)
retro5 = SS_output(here('models',retro_model, "retro", "retro-5"), printstats = FALSE, verbose = FALSE, covar = FALSE)
modelnames <- c("Base Model", paste0("Retro -", 1:5))

mysummary <- SSsummarize(list(base, retro1, retro2, retro3, retro4, retro5))

png(here('models',retro_model,"retrospective_dev_plots.png"), width = 6, height = 8, units = "in", res=300)
par(mfrow = c(2, 1))
SSplotRetroRecruits(retroSummary = mysummary,
                    endyrvec = rev(2016:2022), #rev(2008:2023),
                    cohorts = 2016:2022, #2010:2023,
                    ylim=NULL,
                    uncertainty=FALSE,
                    labels=c('Recruitment deviation', 'Recruitment (millions)', 'relative to recent estimate', 'Age'),
                    main="",
                    mcmcVec=FALSE,devs=TRUE,
                    relative=FALSE,labelyears=TRUE,legend=FALSE,leg.ncols=4)
SSplotRetroRecruits(retroSummary = mysummary,
                    endyrvec = rev(2016:2022), #rev(2008:2023),
                    cohorts = 2016:2022, #2010:2023,
                    ylim=NULL,
                    uncertainty=FALSE,
                    labels=c('Recruitment deviation', 'Recruitment (millions)', 'relative to recent estimate', 'Age'),
                    main="",
                    mcmcVec=FALSE,devs=TRUE,
                    relative=TRUE,labelyears=TRUE,legend=FALSE,leg.ncols=4)
dev.off()  

