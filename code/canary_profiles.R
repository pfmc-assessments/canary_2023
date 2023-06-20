library(nwfscDiag)
library(r4ss)
library(here)

base_model <- '5_0_1_base'

# Female M profile --------------------------------------------------------

profile.settings <- get_settings_profile(parameters = 'NatM_uniform_Fem_GP_1',
                                         low = -0.005, high = 0.005,
                                         step_size = 0.001,
                                         param_space = 'relative',
                                         use_prior_like = 1) 
settings <- get_settings(settings = list(base_name = base_model,
                             run = 'profile',
                             profile_details = profile.settings,
                             exe = 'ss_win',
                             extras = '-nohess',
                             usepar = TRUE,
                             parlinenum = 5,
                             init_values_src = 1))


tictoc::tic()
run_diagnostics(mydir = here('models'), 
                model_settings = settings)
tictoc::toc()
beepr::beep()

# Female Linf profile -----------------------------------------------------
# 
# profile.settings <- get_settings_profile(parameters = 'L_at_Amax_Fem_GP_1',
#                                          low = -2, high = 2,
#                                          step_size = 0.4,
#                                          param_space = 'relative',
#                                          use_prior_like = 0) 
# settings <- get_settings(settings = list(base_name = base_model,
#                                          run = 'profile',
#                                          profile_details = profile.settings))
# 
# settings$exe <- 'ss_win'
# settings$extras <- '-nohess'
# 
# 
# tictoc::tic()
# run_diagnostics(mydir = here('models'), 
#                 model_settings = settings)
# tictoc::toc()
# 
# steepness profile -------------------------------------------------------

profile.settings <- get_settings_profile(parameters = 'SR_BH_steep',
                                         low = -0.1, high = 0.1,
                                         step_size = 0.02, 
                                         param_space = 'relative',
                                         use_prior_like = 0) 
settings <- get_settings(settings = list(base_name = base_model,
                                         run = 'profile',
                                         profile_details = profile.settings,
                                         exe = 'ss_win',
                                         extras = '-nohess',
                                         usepar = TRUE,
                                         parlinenum = 51,
                                         init_values_src = 1))

tictoc::tic()
run_diagnostics(mydir = here('models'), 
                model_settings = settings)
tictoc::toc()
beepr::beep()


# R0 profile --------------------------------------------------------------

new_name <- paste0(base_model, '_phases')

##
#Copy inputs
##

R.utils::copyDirectory(from = here('models', base_model),
                       to = here('models', new_name),
                       overwrite = TRUE)

mod <- SS_read(here('models',new_name))

mod$ctl$MG_parms['NatM_p_1_Fem_GP_1','PHASE'] <- 1

SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

profile.settings <- get_settings_profile(parameters = 'SR_LN(R0)',
                                         low = -0.5, high = 0.5,
                                         step_size = 0.1, 
                                         param_space = 'relative',
                                         use_prior_like = 0) 
settings <- get_settings(settings = list(base_name = new_name,
                                         run = 'profile',
                                         profile_details = profile.settings,
                                         exe = 'ss_win',
                                         extras = '-nohess',
                                         usepar = TRUE,
                                         parlinenum = 49,
                                         init_values_src = 1))

tictoc::tic()
run_diagnostics(mydir = here('models'), 
                model_settings = settings)
tictoc::toc()
beepr::beep()


# Jitter ------------------------------------------------------------------

settings <- get_settings(settings = list(base_name = base_model,
                                         run = 'jitter',
                                         Njitter = 50,
                                         exe = 'ss_win',
                                         extras = '-nohess'))

set.seed(230958)
run_diagnostics(mydir = here('models'), 
                model_settings = settings)


# rerun best jitter
new_name <- paste0(base_model, '_best_jitter')
r4ss::copy_SS_inputs(dir.old = here('models', base_model),
                     dir.new = here('models', new_name))
file.copy(from = here('models', paste0(base_model, '_jitter_0.05'), 'ss.par_43.sso'),
          to = here('models', new_name, 'ss.par'))
mod <- SS_read(here('models', new_name))
mod$start$init_values_src <- 1
SS_write(mod)

pp <- SS_output(here('models', new_name))
SS_plots(pp)

# MCMC --------------------------------------------------------------------

# new_name <- "3_1_6_survey_domed_KLO"

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
saveRDS(fit, here('models', new_name, 'mcmc_run.rds'))

