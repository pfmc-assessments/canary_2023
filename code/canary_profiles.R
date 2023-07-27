library(nwfscDiag)
library(r4ss)
library(here)
library(tictoc)

base_model <- '7_3_2_tuned'

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


# Male M ------------------------------------------------------------------

profile.settings <- get_settings_profile(parameters = 'NatM_uniform_Mal_GP_1',
                                         low = -0.02, high = 0.02,
                                         step_size = 0.005,
                                         param_space = 'relative',
                                         use_prior_like = 1) 
settings <- get_settings(settings = list(base_name = '5_5_0_hessian_KLO',
                                         run = 'profile',
                                         profile_details = profile.settings,
                                         exe = 'ss_win',
                                         extras = '-nohess',
                                         usepar = TRUE,
                                         parstring = 'MGparm[13]',
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

# sigmaR profile -------------------------------------------------------

profile.settings <- get_settings_profile(parameters = 'SR_sigmaR',
                                         low = 0.4, high = 1,
                                         step_size = 0.1, 
                                         param_space = 'real',
                                         use_prior_like = 0) 
settings <- get_settings(settings = list(base_name = base_model,
                                         run = 'profile',
                                         profile_details = profile.settings,
                                         exe = 'ss_win',
                                         extras = '-nohess',
                                         usepar = TRUE,
                                         parlinenum = 53,
                                         init_values_src = 1))

run_diagnostics(mydir = here('models'), 
                model_settings = settings)

load(here('models', 
          paste0(base_model, '_profile_SR_sigmaR_prior_like_0'), 
          'SR_sigmaR_profile_output.Rdata'))

no.rec.dev <- SS_output(here('models/sensitivities/no_recdevs'))

sigmaR.summary <- append(list(no.rec.dev), profilemodels) |> 
  r4ss::SSsummarize()

r4ss::SSplotComparisons(sigmaR.summary, subplots = c(1,3,9,11,13,14), print = TRUE,
                        plotdir = here('models', 
                                       paste0(base_model, '_profile_SR_sigmaR_prior_like_0')),
                        legendlabels = c('No rec dev',
                                         paste('SR_SigmaR =', seq(0.4, 1, 0.1))))

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



# Combination of profiling, jittering, and retros --------------------------------------------------

# Need to run on a model with .exe included in the folder, and which has phase for another parameter set to 1

base_model <- '7_0_2_hessian'
base_model <- '7_3_2_tuned'
base_model <- '7_3_5_reweight'



# new_name <- '5_5_0_profile'
# 
# copy_SS_inputs(dir.old = here('models/5_5_0_hessian'),
#                dir.new = here('models',new_name),
#                overwrite = TRUE)
# 
# mod <- SS_read(here('models',new_name))
# 
# mod$ctl$MG_parms['NatM_p_1_Fem_GP_1','PHASE'] <- 1
# 
# SS_write(mod,
#          dir = here('models',new_name),
#          overwrite = TRUE)
# 
# r4ss::run(dir = here('models',new_name),
#           exe = here('models/ss_win.exe'),
#           extras = '-nohess',
#           # show_in_console = TRUE,
#           skipfinished = FALSE)
# 

get = get_settings_profile( parameters =  c("NatM_uniform_Fem_GP_1", "NatM_uniform_Mal_GP_1", "SR_BH_steep", "SR_LN(R0)"),
                            low =  c(-0.02, -0.01, 0.50, -0.5),
                            high = c(0.02, 0.01, 0.95,  0.5),
                            step_size = c(0.005, 0.0025, 0.05, 0.1),
                            use_prior_like = c(1,1,1,0),
                            param_space = c('relative', 'relative', 'real', 'relative'))

#Should do usepar because stabilizes. Testing this showed instability with some runs when not using it
#No effect with globalpar so using it for consistency
model_settings = get_settings(settings = list(base_name = base_model,
                                              run = c("jitter"),
                                              # profile_details = get[4,], #adjust value in get[x,] to each individually
                                              exe = 'ss_win',
                                              extras = '-nohess',
                                              verbose = FALSE,
                                              globalpar = TRUE,
                                              usepar = TRUE,
                                              parlinenum = 49,#c(5,29,51,49), #adjust to corresponding number
                                              init_values_src = 1))
set.seed(230958)
model_settings$Njitter <- 50
model_settings$jitter_fraction <- 0.05
model_settings$show_in_console <- FALSE

tictoc::tic()
run_diagnostics(mydir = here('models'), model_settings = model_settings)
tictoc::toc()



# rerun best jitter
new_name <- paste0(base_model, '_best_jitter')
r4ss::copy_SS_inputs(dir.old = here('models', base_model),
                     dir.new = here('models', new_name))
file.copy(from = here('models', paste0(base_model, '_jitter_0.05'), 'ss.par_18.sso'),
          to = here('models', new_name, 'ss.par'))
mod <- SS_read(here('models', new_name))
mod$start$init_values_src <- 1
#mod$ctl$size_selex_parms_tv[grep("SizeSel_PFemOff_3_9_WA_REC\\(9\\)_BLK5repl_2021",rownames(mod$ctl$size_selex_parms_tv)),c("INIT","PHASE")] <- c(9,-99)
SS_write(mod,
         dir = here('models',new_name),
         overwrite = TRUE)

pp <- SS_output(here('models',new_name))
SS_plots(pp, plot = c(1:26)[-c(12:19)])

plot_sel_comm(pp, sex=1)
plot_sel_comm(pp, sex=2)
plot_sel_noncomm(pp, sex=1, spatial = FALSE)
plot_sel_noncomm(pp, sex=2, spatial = FALSE)



