library(nwfscDiag)
library(here)


# Female M profile --------------------------------------------------------

profile.settings <- get_settings_profile(parameters = 'NatM_uniform_Fem_GP_1',
                                         low = -0.01, high = 0.01,
                                         step_size = 0.0025,
                                         param_space = 'relative',
                                         use_prior_like = 1) 
settings <- get_settings(settings = list(base_name = '3_1_5_update_tri_index_KLO',
                             run = 'profile',
                             profile_details = profile.settings))
  
settings$exe <- 'ss_win'
settings$extras <- '-nohess'


tictoc::tic()
run_diagnostics(mydir = here('models'), 
                model_settings = settings)
tictoc::toc()


# Female Linf profile -----------------------------------------------------

profile.settings <- get_settings_profile(parameters = 'L_at_Amax_Fem_GP_1',
                                         low = -2, high = 2,
                                         step_size = 0.4,
                                         param_space = 'relative',
                                         use_prior_like = 1) 
settings <- get_settings(settings = list(base_name = '3_1_5_update_tri_index_KLO',
                                         run = 'profile',
                                         profile_details = profile.settings))

settings$exe <- 'ss_win'
settings$extras <- '-nohess'


tictoc::tic()
run_diagnostics(mydir = here('models'), 
                model_settings = settings)
tictoc::toc()


# R0 profile --------------------------------------------------------------

new_name <- "3_1_5_update_tri_index_KLO"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_1_5_update_tri_index'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

mod <- SS_read(here('models',new_name))

mod$ctl$MG_parms['NatM_p_1_Fem_GP_1','PHASE'] <- 1

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)

profile.settings <- get_settings_profile(parameters = 'SR_LN(R0)',
                                         low = -1, high = 1,
                                         step_size = 0.2,
                                         param_space = 'relative',
                                         use_prior_like = 1) 
settings <- get_settings(settings = list(base_name = '3_1_5_update_tri_index_KLO',
                                         run = 'profile',
                                         profile_details = profile.settings))

settings$exe <- 'ss_win'
settings$extras <- '-nohess'
settings$show_in_console


tictoc::tic()
run_diagnostics(mydir = here('models'), 
                model_settings = settings)
tictoc::toc()


# MCMC --------------------------------------------------------------------

new_name <- "3_1_6_survey_domed_KLO"

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/3_1_6_survey_domed'),  
               dir.new = here('models',new_name),
               overwrite = TRUE)

r4ss::run(dir = here('models',new_name), 
          exe = here('models/ss_win.exe'), 
          # extras = '-nohess',
          # show_in_console = TRUE, 
          skipfinished = FALSE)


thin <- 100
iter <- 3000*thin
warmup <- iter/4

# thin <- 1
# iter <- 100
# warmup <- 25

fit <- adnuts::sample_rwm(model = 'ss_win', # this is the name of the executable
                          path =  here('models', new_name), # directory with executable, input file, MLE output files (including covariance)
                          iter = iter,
                          thin = thin, # thin to save memory, could try not
                          warmup = warmup,
                          chains = 5)
saveRDS(fit, 'mcmc_run.rds')

# new_name <- '3_1_5_update_tri_index_KLO'
# tictoc::tic()
# m.prof <- r4ss::profile(dir = here('models', new_name), string = 'NatM_uniform_Fem_GP_1', 
#                         globalpar = TRUE, exe = here('models/ss_win.exe'), 
#                         profilevec = seq(0.06, 0.08, by = 0.01), prior_check = FALSE, extras = '-nohess -maxfn 0')
# tictoc::toc()
# beepr::beep()