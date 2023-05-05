# Canary California Model Runs
# Brian's April exploratory model runs

#devtools::install_github("r4ss/r4ss")
library(r4ss)
#devtools::install_github("pfmc-assessments/PEPtools")
library(PEPtools)

if(Sys.getenv("USERNAME") == "Brian.Langseth") {
  wd = "C:/Users/Brian.Langseth/Desktop/canary_model_runs"
}


##########################################################################################
#                         Initial explorations
##########################################################################################

# Starting with 2015_base ---------------------------------------------------------------

## Copy 2015 base from repo
model = "0_0_2015base"
base.0 = SS_output(file.path(wd, model),covar=TRUE)
SS_plots(base.0)





# Starting with coastwide ---------------------------------------------------------------

## Copy coastwide from repo
model = "0_0_coastwide"
base.0 = SS_output(file.path(wd, model),covar=TRUE)
SS_plots(base.0)

Ideas:
  Model output
#1. Note 1 Suggestion: This model has just one settlement event. Changing to recr_dist_method 4 and removing the recruitment distribution parameters at the end of the MG parms section (below growth parameters) will produce identical results and simplify the model.
#2. Note 2 Information: Max harvest rate typically is >1.0 for F_method 2, 3 or 4 0.9
3. Warning 1 : Setting in starter does not request all priors, and 19 parameters have priors and are not estimated, so their prior not included in obj_fun.
4. Warning 2 : 1st iteration warning: ssb(endyr)/ssb(styr)= 2.02285e-10; suggest start with larger R0 to get near 0.4; or use depletion fleet option
5. Warning 3 : Final gradient: 0.00238814 is larger than final_conv: 0.0001
6. Note 3 Information: No *.ss_new and fewer *.sso files written after mceval
7. Warning 4 : Reminder: Number of lamdas !=0.0 and !=1.0:  20
8. Note 4 Information:  N parameters that are on or within 1% of min-max bound: 4; check results, variance may be suspect
4 warnings  and 4 notes

  My notes
9. Change period of recdevs to earlier because devs are non-zero. Devs only calculated since 1930s, start back at start of model
10. Whats going on with ca trawl in 1985 (comp and mean length)
11. Remove lengths with small sample sizes (to see if improve mean length etc - particularly true for unsexed)
12. Very little recrutiment signal in age comp data. What if just remove it?
13. Why are there excluded age comp data for the surveys?
14. Very little good fitting of sex ratio within age data. Very prominent sex ratio change in length data
15. Consider switching M to phase 2 instead of phase 3, and possibly select and others to phase 3
16. Check out growth parameterization - estimating as offsets or separate parameters
17. Have neg CV and L_amax parameters
18. Data weighting??
19. Run the coastwide model with a hession to see how r4ss plots come out
# 20. Something is up for length comps. They arent being generated.
#   Talked with Ian and he pointed out our detailed_age_structure == 2 in the starter, should be == 1 to
#   get full output
21. Could increase settlement for recruitment to not be january (month 1). According to love larvae settle 3-4 months and 
  spawn December-March. Thus could set at month 4.
22. Update blocks: Right now have one for after 2000 (but capped at 2014), another for 2000-2010 and 2011 after (but capped at 2014)
  and another for just 1891, which doesnt make sense
23. Set growth age for L2 at 999
24. Explore offset apporach right now set as _parameters_offset = 3 (which is like SS2)
25. Set early devs to first year of the model
26. Switch F-method to 3 (hybrid, which is recommended)
27. Remove lambda specifications (set all to 1 - or figure out why these are not 1)
28. Adjust priors. Right now have phase = 6 (normal) but have very large sd. Set phase = 0 (uniform) and reduce sd to 5

## Turn detailed_age_structure == 1 to show all plots (fix issue 20)
model = "0_1_coastwide"
base.0 = SS_output(file.path(wd, model),covar=TRUE)
SS_plots(base.0)

## Fix for notes 1 and 2 and warning 2 in coastwide model (model 0_1)
# Remove settlement parameters (recr_dist_method = 4 and delete recr_dist parameters in growth parm section)
# Set max harvest rate to 3.5 and F_method = 3 (hybrid) and add lines for 'N iterations for tuning F in hybrid method (recommend 3 to 7)'
# Set logR0 to have range of 1 to 20, and set SD to 5
model = "0_2_fixWarn"
base.0.2 = SS_output(file.path(wd, model),covar=TRUE)
SS_plots(base.0.2)

## Run coastwide model with a hessian (model 0_1)
model = "1_hessian"
base.1 = SS_output(file.path(wd, model), covar = TRUE)
SS_plots(base.1)


###########################################################################################
## Go through files and adjust model settings
###########################################################################################

#Generate and readin SS3 files from coastwide model (model 0_0)
setwd(wd)
new_mod <- "1_inputs"
copy_SS_inputs(dir.old = '0_0_coastwide', 
               dir.new = new_mod, use_ss_new = FALSE, overwrite = TRUE)
mod <- SS_read(new_mod)

#Make changes to starter
mod$start$detailed_age_structure <- 1 #all output
mod$start$N_bootstraps <- 1 #generate ss_new datafile
mod$start$SPR_basis <- 4 #This may not be needed (1 is ok) but use raw (1-SPR). 

#Make changes to forecast
mod$fore$MSY <- 2 #calculate actual MSY
mod$fore$Bmark_years <- c(-999,0, 0,0, 0,0, -999,0, -999,0) #start year and end year for all but selectivity (because of blocks) and relF
mod$fore$Nforecastyrs <- 12
mod$fore$Fcast_years <- c(0,0, -3,0, -999,0) #last year for selex, last three years for relF, full time series for average recruitment (though using fcast_rec_option = 0 ignores this)
mod$fore$ControlRuleMethod <- 3
mod$fore$Flimitfraction <- -1 #Set year and pstar buffers
mod$fore$Flimitfraction_m <- data.frame("Year" = 2023:2034, 
                                        "Fraction" = get_buffer(c(2023:2034), sigma = 0.5, pstar = 0.45)[,2])
mod$fore$FirstYear_for_caps_and_allocations <- 2025
mod$fore$InputBasis <- 2
mod$fore$ForeCatch <- data.frame("Year" = rep(2023:2024, each = mod$dat$Nfleet),
                                 "Seas" = 1,
                                 "Fleet" = rep(1:mod$dat$Nfleet, 2),
                                 "Catch or F" = 0.01)

#Make changes to data
mod$dat$area <- 1 #already one but setting up here for spatial model
mod$dat$catch$catch_se <- 0.05
mod$dat$catch[-which(mod$dat$catch$year == -999),] #remove the equilibrium catch value
#TO DO: NEED TO UPDATE SURVEY DATA
mod$dat$len_info$minsamplesize <- 0.01 #Manual says CAAL oculd have sample size < 1 so setting lower
#TO DO: UPDATE LENGTH COMP DATA
#TO DO: CONFIRM AGEING ERROR
mod$dat$age_info$minsamplesize <- 0.01 #Manual says CAAL oculd have sample size < 1 so setting lower
#TO DO: UPDATE AGE COMP DATA LINKING TO AGEING ERROR MATRICS

#Make changes to control
mod$ctl$recr_dist_method <- 4 #WOULD NEED TO CHANGE IF GO WITH SPATIAL MODEL. COULD STICK WITH 2. IF HAVE 4 CHECK WHETHER THE RECR PARAMETERS ARE NULLIFIED - THEY ARE NOT AUTOMATICALLY REMOVED
mod$ctl$recr_dist_pattern[1:4] <- c(1,1,1,0) #TO DO: DISCUSS CHANGE OF SETTLEMENT TO SPRING-SUMMER? 
#TO DO: FINALIZE BLOCKING
mod$ctl$natM_type <- 0 #TO DO: CONFIRM M SET UP
mod$ctl$M_ageBreakPoints[1:2] <- c(6,14) #TO DO: CONFIRM VALUES and apporach for M set up
mod$ctl$Growth_Age_for_L2 <- 999 #set equivalent to Linf
mod$ctl$maturity_option <- 3 #TO DO: FINALIZE AGE (?OR LENGTH?) MATURITY VALUES
mod$ctl$First_Mature_Age <- 2 #Keep at 2. IGNORED when maturity option is 3 but Id like to set it to whatever it is in case we change maturity option
mod$ctl$fecundity_option <- 2 #TO DO: confirm linear or not and values
mod$ctl$parameter_offset_approach <- 2 #TO DO: confirm apporach with M 
mod$ctl$Use_steep_init_equi <- 1
mod$ctl$Fcast_recr_phase <- mod$ctl$recdev_phase+1
mod$ctl$F_Method <- 3 #TO DO: RECOMMENDED APPROACH IS 4 but IM NOT SURE WHAT DIFFERENCE IS. Looks like its useful if the model has issues (fleet specific F phases)
mod$ctl$maxF <- 4
mod$ctl$F_iter <-  5
#TO DO: CONFIRM Q SETUP
#mod$ctl$Variance_adjustment_list$Value <- 1 #TO DO: CONFIRM HOW WE WISH TO HANDLE THESE FOR DEVELOPMENT
#mod$ctl$lambdas$value <- 1 #TO DO: CONFIRM HOW WE WISH TO HANDLE THESE FOR DEVELOPMENT

#Output changes and run model
r4ss::SS_write(mod, dir = new_mod, overwrite = TRUE)
r4ss::run(dir = new_mod, 
          exe = file.path(wd,'ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = TRUE, 
          skipfinished = FALSE)

#Compare model to base and basic coastwide models
xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = getwd(),
                                      subdir = c('0_0_2015base', '0_0_coastwide', new_mod)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015', '2023 coastwide', '2023 inputs changed'),
                    subplots = c(2,4))



