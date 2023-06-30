library(here)
library(r4ss)

base_mod_name <- '5_5_0_hessian'
base_mod <- SS_read(here('models', base_mod_name))
fleet.converter <- base_mod$dat$fleetinfo |>
  dplyr::mutate(fleet_no_num = stringr::str_remove(fleetname, '[:digit:]+_'),
                fleet = as.numeric(stringr::str_extract(fleetname, '[:digit:]+'))) |>
  dplyr::select(fleetname, fleet_no_num, fleet)

# Canadian catches --------------------------------------------------------

# This spreadsheet sums catches in Canadian areas 3C and 3D, i.e., 
# the West Coast of Vancouver Island. 
# There is one trawl time series and one non-trawl time series. 
# These are added to WA TWL and NTWL
# Time series begins in 1918, assume zero prior

canada_catches <- readxl::read_excel(here('data-raw/Canada_WCVI_calcs.xlsx'), 
                                     sheet = 'Catch', 
                                     range = 'O3:U108') |> 
  # filter(year >=1996, year <2022) |>
  # mutate(total = NTWL + Trawl) |>
  # summarize(mean(total)) # this was just to get recent average catches
  dplyr::filter(year < 2022) %>% # history was compiled in 2022, do not know where 2022 catches came from
  dplyr::add_row(year = 2022,
                 Trawl = mean(tail(.$Trawl, 5)),
                 NTWL = mean(tail(.$NTWL, 5))) |> # instead use mean of last 5 years
  dplyr::select(year, WA_TWL = Trawl, WA_NTWL = NTWL) |>
  dplyr::mutate(seas = 1, catch_se = 0.05) |>
  tidyr::pivot_longer(cols = c(WA_TWL, WA_NTWL), 
                      names_to = 'fleet_no_num', 
                      values_to = 'canada_catch') |>
  dplyr::left_join(fleet.converter) |>
  dplyr::select(-fleetname, -fleet_no_num) |>
  dplyr::right_join(base_mod$dat$catch) |> 
  dplyr::mutate(dplyr::across(c(catch, canada_catch),
                ~ tidyr::replace_na(., replace = 0)),
                catch = catch + canada_catch) |>
  dplyr::select(year, seas, fleet, catch, catch_se) |>
  as.data.frame()

mod <- base_mod
mod$dat$catch <- canada_catches

# Write model and run
new_name <- 'canada_catches'
SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE, 
          skipfinished = FALSE)
beepr::beep()

xx <- SSgetoutput(dirvec = c(glue::glue("{models}/{subdir}", models = here('models'),
                                      subdir = c(base_mod_name,
                                                 file.path('sensitivities', new_name)))))

SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Base model',
                                     'Add WCVI catches to WA'),
                    print = TRUE, plotdir = here('models/sensitivities',new_name))

# compare rec devs
bc_recdevs <- readxl::read_excel(here('data-raw/CAR-data-for.BL.KO.xlsx'),
                                 sheet = 'Rdevs') |>
  dplyr::select(-1) |>
  tidyr::pivot_longer(cols = dplyr::everything(), names_to = 'Yr', values_to = 'recdev') |>
  dplyr::group_by(Yr) |>
  dplyr::summarise(dev = median(recdev)) |>
  dplyr::mutate(Yr = as.numeric(Yr),
                model = 'bc')

purrr::map(xx, ~ select(.$recruit, Yr, dev)) |> 
  `names<-`(c('Base', 'bc_catches')) |> 
  append(list(BC = bc_recdevs)) |> 
  dplyr::bind_rows(.id = 'Model') |> 
  filter(Model != 'bc_catches', Yr >= 1955) |>
  ggplot(aes(x = Yr, y = dev, col = Model)) +
  geom_line() + geom_point() +
  labs(x = 'Year', y = 'Rec Dev')

# These look nothing like each other. 
# BC also sees slow steady increase.
# WC sees slow steady decrease


# Prerecruit survey add 3 years -------------------------------------------

mod <- base_mod

prerecruit <- read.csv(here('data/canary_prerecruit_indices.csv')) |>
  dplyr::mutate(fleet_no_num = paste0(region, '_prerec')) |>
  dplyr::left_join(fleet.converter) |> 
  dplyr::mutate(seas = 7,
                YEAR = ifelse(region == 'coastwide', YEAR, -YEAR)) |>
  dplyr::select(year = YEAR, seas, index = fleet, obs = est, se_log = se)

mod$dat$CPUE <- mod$dat$CPUE |>
  dplyr::filter(!(index %in% unique(prerecruit$index))) |>
  dplyr::bind_rows(prerecruit)

new_name <- 'prerec_data'
SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE, 
          skipfinished = FALSE)
beepr::beep()


# Prerecruit units --------------------------------------------------------

mod <- base_mod

mod$dat$fleetinfo[grep('prerec', mod$dat$fleetinfo$fleetname), 'units'] <- 33

# Assume survey is recruitment index but occurs after density-dependence. 
# May be more statistically defensible? This was Owen's idea.

new_name <- 'prerec_units'
SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE, 
          skipfinished = FALSE)


# Sex-constant selectivity ------------------------------------------------

mod <- base_mod

mod$ctl$size_selex_parms[grep('PFemOff_3', rownames(mod$ctl$size_selex_parms)), 'PHASE'] <- -99
mod$ctl$size_selex_parms_tv[grep('PFemOff_3', rownames(mod$ctl$size_selex_parms_tv)), 'PHASE'] <- 99

new_name <- 'no_sex_selectivity'
SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE, 
          skipfinished = FALSE)


# M ramp ------------------------------------------------------------------

mod <- base_mod

mod$ctl$natM_type <- 1
mod$ctl$N_natM <- 2
mod$ctl$M_ageBreakPoints <- c(6, 14)

# Add extra rows to MG table
M.ind <- grep('NatM', rownames(mod$ctl$MG_parms))

mod$ctl$MG_parms <- mod$ctl$MG_parms[c(rep(M.ind[1], 2), (M.ind[1]+1):(M.ind[2]-1),
                                       rep(M.ind[2], 2), (M.ind[2]+1):(nrow(mod$ctl$MG_parms))),]
M.ind <- grep('1.1', rownames(mod$ctl$MG_parms))
rownames(mod$ctl$MG_parms)[M.ind] <- stringr::str_replace(rownames(mod$ctl$MG_parms)[M.ind], 
                                                          pattern = 'p_1', 
                                                          replacement = 'p_2') |>
  stringr::str_remove(pattern = '\\.1')

# Fix young female M at male M
mod$ctl$MG_parms['NatM_p_1_Fem_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type', 'PHASE')] <-
  mod$ctl$MG_parms['NatM_p_1_Mal_GP_1', c('LO', 'HI', 'INIT', 'PRIOR', 'PR_SD', 'PR_type', 'PHASE')]

new_name <- 'M_ramp'
SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE, 
          skipfinished = FALSE)


# D-M data weighting ------------------------------------------------------

mod <- base_mod
new_name <- 'dirichlet_multinomial'
new_dir <- here('models/sensitivities', new_name)

R.utils::copyDirectory(from = here('models', base_mod_name),
                       to = new_dir, 
                       overwrite = TRUE, 
                       recursive = FALSE)
SS_output(dir = new_dir) |>
  r4ss::tune_comps(option = 'DM', 
                   dir = new_dir, 
                   niters_tuning = 1, 
                   exe = here('models/ss_win.exe'), 
                   extras = '-nohess')

xx <- SS_output(dir = new_dir)

xx$Dirichlet_Multinomial_pars
# the run times alone on this are prohibitive.

# This is not worth reporting. Most data weights are 1 or 0.5 (because there was no data, didn't move from init)


# McAllister Ianelli data weighting ------------------------------------------------------

mod <- base_mod
new_name <- 'mcallister_ianelli'
new_dir <- here('models/sensitivities', new_name)

copy_SS_inputs(dir.old = here('models',base_mod_name),
               dir.new = new_dir,
               overwrite = TRUE)
file.copy(from = file.path(here('models',base_mod_name),"Report.sso"),
          to = new_dir, overwrite = TRUE)
file.copy(from = file.path(here('models',base_mod_name),"CompReport.sso"),
          to = new_dir, overwrite = TRUE)
file.copy(from = file.path(here('models',base_mod_name),"warning.sso"),
          to = new_dir, overwrite = TRUE)

SS_output(dir = new_dir) |>
  r4ss::tune_comps(option = 'MI', 
                   dir = new_dir, 
                   niters_tuning = 4, 
                   exe = here('models/ss_win.exe'), 
                   extras = '-nohess',
                   allow_up_tuning = TRUE,
                   write = TRUE)


# Bomb radiocarbon bias ---------------------------------------------------


# Float Triennial Q -------------------------------------------------------

mod <- base_mod

tri.late.index <- fleet.converter$fleet[fleet.converter$fleet_no_num == 'coastwide_Tri_late']
tri.early.index <- fleet.converter$fleet[fleet.converter$fleet_no_num == 'coastwide_Tri_early']
mod$dat$CPUE <- dplyr::mutate(mod$dat$CPUE,
                              index = ifelse(index == tri.late.index, tri.early.index, index))
mod$dat$agecomp <- dplyr::mutate(mod$dat$agecomp, 
                                 FltSvy = ifelse(FltSvy == tri.late.index, tri.early.index, FltSvy),
                                 FltSvy = ifelse(FltSvy == -tri.late.index, -tri.early.index, FltSvy))
mod$dat$lencomp <- dplyr::mutate(mod$dat$lencomp, 
                                 FltSvy = ifelse(FltSvy == tri.late.index, tri.early.index, FltSvy),
                                 FltSvy = ifelse(FltSvy == -tri.late.index, -tri.early.index, FltSvy))
# Float early tri
mod$ctl$Q_options['29_coastwide_Tri_early','float'] <- 1

# Negative phase for early tri (float)
mod$ctl$Q_parms[grep('Tri_early', rownames(mod$ctl$Q_parms)),'PHASE'] <- -1

# Remove Q setup for late tri (no data)
mod$ctl$Q_parms <- mod$ctl$Q_parms[-grep('Tri_late', rownames(mod$ctl$Q_parms)),]
mod$ctl$Q_options <- mod$ctl$Q_options[-grep('Tri_late', rownames(mod$ctl$Q_options)),]

new_name <- 'Float_Q'
SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE, 
          skipfinished = FALSE)

xx <- SS_output(here('models/sensitivities', new_name)) 

tune_comps(xx, option = 'Francis', 
           niters_tuning = 1, 
           dir = here('models/sensitivities', new_name), 
           exe = here('models/ss_win.exe'), 
           extras = '-nohess')

# Unmirror triennial -------------------------------------------------------

mod <- base_mod

mod$ctl$size_selex_types['30_coastwide_Tri_late',] <- c(24, 0, 4, 0)

tri.ind <- grep('Tri', rownames(mod$ctl$size_selex_parms))

new.selex <- mod$ctl$size_selex_parms[c(1:(min(tri.ind) - 1),
                                        tri.ind, tri.ind),]

rownames(new.selex) <- rownames(new.selex) |>
  stringr::str_replace('29_coastwide_Tri_early\\(29\\).1',
                       '30_coastwide_Tri_late\\(30\\)')

mod$ctl$size_selex_parms <- new.selex

mod$ctl$Q_options$link_info <- 0
mod$ctl$Q_options$float <- 1
mod$ctl$Q_options$link <- 1

mod$ctl$Q_parms$PHASE[grep('Tri', rownames(mod$ctl$Q_parms))] <- -1

new_name <- 'Unmirror_tri'
SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE,
          skipfinished = FALSE)


# Simplified blocks -----------------------------------------------------

#Based on looking at the selectivity patterns:
#No blocks for CA trawl, CA non-trawl, and one block for OR non-trawl
#No blocks for CA rec, OR rec, and only one block for WA rec (recent)

mod <- base_mod

mod$ctl$N_Block_Designs <- 3
mod$ctl$blocks_per_pattern <- c(2,2,1)
names(mod$ctl$blocks_per_pattern) <- paste0("blocks_per_pattern_",1:mod$ctl$N_Block_Designs)

#Update blocks. Blocking for NTWL is tricky. Right now have WA NTWL to WA TWL mirrored but could unmirror
#Keeping 2000 block instead of 2001 since the data seems to suggest change there (also same as last assessment)
mod$ctl$Block_Design <- list(c(2000, 2010, 2011, 2022), #OR/WA TWL fleets
                             c(2000, 2019, 2020, 2022), #OR ntwl
                             c(2021, 2022)) #WA rec

# Use new block set up
selex_new <- mod$ctl$size_selex_parms
selex_new[grepl('CA_TWL|CA_NTWL|CA_REC|OR_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block', 'Block_Fxn')] <- 0
selex_new[intersect(
  grep('CA_REC', rownames(selex_new)),
  grep('PFemOff', rownames(selex_new))), c('Block', 'Block_Fxn')] <- 0
selex_new[grepl('CA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 0
selex_new[grepl('WA_REC', rownames(selex_new)) & selex_new$PHASE > 0, c('Block')] <- 3

mod$ctl$size_selex_parms <- selex_new


#Time varying selectivity table
selex_tv_pars <- dplyr::filter(selex_new, Block > 0) |>
  dplyr::select(LO, HI, INIT, PRIOR, PR_SD, PR_type, PHASE, Block) |>
  tidyr::uncount(mod$ctl$blocks_per_pattern[Block], .id = 'id', .remove = FALSE)

rownames(selex_tv_pars) <- rownames(selex_tv_pars) |>
  stringr::str_remove('\\.\\.\\.[:digit:]+') |>
  stringr::str_c('_BLK', selex_tv_pars$Block, 'repl_', mapply("[",mod$ctl$Block_Design[selex_tv_pars$Block], selex_tv_pars$id * 2 - 1))

mod$ctl$size_selex_parms_tv <- selex_tv_pars |>
  dplyr::select(-Block, -id)

new_name <- 'simpler_block'
SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE,
          skipfinished = FALSE)


# Add released fish into length comps for CA and OR rec fleets -----------------------------------------------------

mod <- base_mod

length.min <- min(mod$dat$lbin_vector)
length.max <- max(mod$dat$lbin_vector)
age.min <- min(mod$dat$agebin_vector)
age.max <- max(mod$dat$agebin_vector)

read.fishery.comps <- function(filename, exclude) {
  
}

rec.lengths <- purrr::map(list('CA', 'OR'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_rec_not_expanded_withRELEASED_Lcomp{lmin}_{lmax}_formatted.csv',
                           area = .x,
                           lmin = length.min,
                           lmax = length.max))) |>
    dplyr::select(-Nsamp) |>
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_REC',
                                                                                           area = .x)]) |>
    `names<-`(names(mod$dat$lencomp))
}) |>
  purrr::list_rbind()

mod$dat$lencomp <- mod$dat$lencomp |> 
  dplyr::filter(!(FltSvy %in% unique(rec.lengths$FltSvy))) |>
  dplyr::bind_rows(rec.lengths)


new_name <- 'released_lengths_in'
SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE,
          skipfinished = FALSE)


# Use MRFSS lengths instead of DebWV lengths for PC mode in CA -----------------------------------------------------

mod <- base_mod

#Update CA rec length comps

length.min <- min(mod$dat$lbin_vector)
length.max <- max(mod$dat$lbin_vector)
age.min <- min(mod$dat$agebin_vector)
age.max <- max(mod$dat$agebin_vector)

read.fishery.comps <- function(filename, exclude) {
  
}

rec.lengths <- purrr::map(list('CA'), function(.x) {
  read.csv(here(glue::glue('data/forSS/{area}_rec_not_expanded_noDebWV_Lcomp{lmin}_{lmax}_formatted.csv',
                           area = .x,
                           lmin = length.min,
                           lmax = length.max))) |>
    dplyr::select(-Nsamp) |>
    dplyr::mutate(fleet = fleet.converter$fleet[fleet.converter$fleet_no_num == glue::glue('{area}_REC',
                                                                                           area = .x)]) |>
    `names<-`(names(mod$dat$lencomp))
}) |>
  purrr::list_rbind()

mod$dat$lencomp <- mod$dat$lencomp |> 
  dplyr::filter(!(FltSvy %in% unique(rec.lengths$FltSvy))) |>
  dplyr::bind_rows(rec.lengths)


new_name <- 'noDebWV_lengths'
SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE,
          skipfinished = FALSE)

# Sex-constant M (TOR)-----------------------------------------------------

mod <- base_mod

mod$ctl$MG_parms['NatM_p_1_Fem_GP_1', 'PHASE'] <- -50

new_name <- 'single_M'
SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE,
          skipfinished = FALSE)

# One asymptotic fleet (TOR) ----------------------------------------------

#For WA NTWL
mod <- base_mod

mod$ctl$size_selex_parms[grep("P_4_6_WA_NTWL",rownames(mod$ctl$size_selex_parms)),c("INIT","PHASE")] <- c(15,-99)
mod$ctl$size_selex_parms[grep("PFemOff_3_6_WA_NTWL",rownames(mod$ctl$size_selex_parms)),"PHASE"] <- -99

new_name <- 'wa_ntwl_asymptotic'

SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE,
          skipfinished = FALSE)


#For WCGBTS
mod <- base_mod

mod$ctl$size_selex_parms[grep("P_3_28_coastwide",rownames(mod$ctl$size_selex_parms)),c("INIT","PHASE")] <- c(15,-99)
mod$ctl$size_selex_parms[grep("PFemOff_3_28_coastwide",rownames(mod$ctl$size_selex_parms)),"PHASE"] <- -99

new_name <- 'wcgbts_asymptotic'

SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE,
          skipfinished = FALSE)


# Turn on the fourth selectivity parameter (param 6) ------------------------------------------------------

mod <- base_mod

# Turn on parameter 6 and setup inits
mod$ctl$size_selex_parms[grep("P_6",rownames(mod$ctl$size_selex_parms)),"LO"] <- -9 
mod$ctl$size_selex_parms[grep("P_6",rownames(mod$ctl$size_selex_parms)),"HI"] <- 9
mod$ctl$size_selex_parms[grep("P_6",rownames(mod$ctl$size_selex_parms)),"INIT"] <- 0
mod$ctl$size_selex_parms[grep("P_6",rownames(mod$ctl$size_selex_parms)),"PHASE"] <- 6

mod$ctl$size_selex_parms[grep("P_6",rownames(mod$ctl$size_selex_parms)),c("Block","Block_Fxn")] <- 
  mod$ctl$size_selex_parms[grep("P_4",rownames(mod$ctl$size_selex_parms)),c("Block","Block_Fxn")] 

selex_new = mod$ctl$size_selex_parms

# Time varying selectivity table
selex_tv_pars <- dplyr::filter(selex_new, Block > 0) |>
  dplyr::select(LO, HI, INIT, PRIOR, PR_SD, PR_type, PHASE, Block) |>
  tidyr::uncount(mod$ctl$blocks_per_pattern[Block], .id = 'id', .remove = FALSE)

rownames(selex_tv_pars) <- rownames(selex_tv_pars) |>
  stringr::str_remove('\\.\\.\\.[:digit:]+') |>
  stringr::str_c('_BLK', selex_tv_pars$Block, 'repl_', mapply("[",mod$ctl$Block_Design[selex_tv_pars$Block], selex_tv_pars$id * 2 - 1))

mod$ctl$size_selex_parms_tv <- selex_tv_pars |>
  dplyr::select(-Block, -id)

new_name <- "selex_parm6"

SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE,
          skipfinished = FALSE)


# No survey extra SD ------------------------------------------------------

mod <- base_mod

mod$ctl$Q_options$extra_se <- 0
mod$ctl$Q_parms <- mod$ctl$Q_parms[-grep('extraSD', rownames(mod$ctl$Q_parms)),]

new_name <- 'no_q_extrasd'

SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE,
          skipfinished = FALSE)

pp <- SS_output(here('models/sensitivities', new_name))

SS_plots(pp, plot = c(3, 4, 11))

xx <- SSgetoutput(dirvec = c(glue::glue("{models}/{subdir}", models = here('models'),
                                        subdir = c(base_mod_name,
                                                   file.path('sensitivities', new_name)))))

SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('Base model',
                                     'No survey extra SE'), subplots = c(1,3, 11),
                    print = TRUE, plotdir = here('models/sensitivities',new_name))



# Estimate male natural mortality ------------------------------------------------------

mod <- base_mod

#CHANGE THE PRIOR TYPE TO LOGNORMAL
mod$ctl$MG_parms[grep("NatM_p_1_Mal",rownames(mod$ctl$MG_parms)), c("PR_type", "PHASE")] <- c(3,2)

new_name <- 'est_male_M'

SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE,
          skipfinished = FALSE)


# Estimate steepness ------------------------------------------------------

mod <- base_mod

mod$ctl$SR_parms[grep("steep",rownames(mod$ctl$SR_parms)), c("PHASE")] <- 2

new_name <- 'est_h'

SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE,
          skipfinished = FALSE)



# Various down weighting of individual data sets ------------------------------------------------------

#Exclude marginal and conditional ages by setting lambda to zero

mod <- base_mod

fleetAge <- unique(mod$dat$agecomp$FltSvy)[unique(mod$dat$agecomp$FltSvy)>0]
mod$ctl$lambdas <- data.frame("like_comp" = 5, 
                              "fleet" = sort(fleetAge),
                              "phase" = 1,
                              "value" = 1,
                              "sizefreq_method" = 1)
rownames(mod$ctl$lambdas) = paste0("ages_",fleet.converter[fleet.converter$fleet %in% fleetAge,"fleetname"])

#Exclude spatial surveys (not used) but not coastwide survey (which are CAAL)
mod$ctl$lambdas <- mod$ctl$lambdas[!mod$ctl$lambdas$fleet %in% c(16:24),]
#mod$ctl$lambdas <- mod$ctl$lambdas[!mod$ctl$lambdas$fleet %in% c(28:30),]

#Set lambdas
mod$ctl$N_lambdas <- nrow(mod$ctl$lambdas)
mod$ctl$lambdas$value <- 0


new_name <- 'age_lambda0'

SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE,
          skipfinished = FALSE)


#Reduce marginal lengths by setting lambda to 0.01

mod <- base_mod

fleetLen <- unique(mod$dat$lencomp$FltSvy)[unique(mod$dat$lencomp$FltSvy)>0]
mod$ctl$lambdas <- data.frame("like_comp" = 4, 
                              "fleet" = sort(fleetLen),
                              "phase" = 1,
                              "value" = 1,
                              "sizefreq_method" = 1)
rownames(mod$ctl$lambdas) = paste0("lengths_",fleet.converter[fleet.converter$fleet %in% fleetLen,"fleetname"])

#Exclude spatial surveys (not used) but not coastwide surveys
mod$ctl$lambdas <- mod$ctl$lambdas[!mod$ctl$lambdas$fleet %in% c(16:24),]
#mod$ctl$lambdas <- mod$ctl$lambdas[!mod$ctl$lambdas$fleet %in% c(28:30),]

#Set lambdas
mod$ctl$N_lambdas <- nrow(mod$ctl$lambdas)
mod$ctl$lambdas$value <- 0.01

new_name <- 'len_lambda0.01'

SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE,
          skipfinished = FALSE)


# Various up weighting of individual data sets ------------------------------------------------------

#Increase marginal and conditional ages by setting francis weights x10

mod <- base_mod

mod$ctl$Variance_adjustment_list[mod$ctl$Variance_adjustment_list$Data_type==5,"Value"] = 10 *
  mod$ctl$Variance_adjustment_list[mod$ctl$Variance_adjustment_list$Data_type==5,"Value"]

new_name <- 'age_francisX10'

SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE,
          skipfinished = FALSE)


#Increase marginal lengths by setting francis weights x10

mod <- base_mod

mod$ctl$Variance_adjustment_list[mod$ctl$Variance_adjustment_list$Data_type==4,"Value"] = 10 *
  mod$ctl$Variance_adjustment_list[mod$ctl$Variance_adjustment_list$Data_type==4,"Value"]

new_name <- 'len_francisX10'

SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE,
          skipfinished = FALSE)


# Remove any comps with sample inputs less than 5 ------------------------------------------------------

mod <- base_mod

#75 length entries with total Nsamp = 186
mod$dat$lencomp[mod$dat$lencomp$Yr>0 & mod$dat$lencomp$Nsamp <= 5,]$Yr <- -1*mod$dat$lencomp[mod$dat$lencomp$Yr>0 & mod$dat$lencomp$Nsamp <= 5,]$Yr
#37 age entries with total Nsamp = 107
mod$dat$agecomp[mod$dat$agecomp$Yr>0 & 
                  mod$dat$agecomp$Nsamp <= 5 & 
                  mod$dat$agecomp$Lbin_lo < 0 ,]$Yr <- -1*mod$dat$agecomp[mod$dat$agecomp$Yr>0 & 
                                                                            mod$dat$agecomp$Nsamp <= 5 & 
                                                                            mod$dat$agecomp$Lbin_lo < 0 ,]$Yr
new_name <- 'no_sparse_comps'

SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE,
          skipfinished = FALSE)

SS_output(here('models/sensitivities', new_name)) |>
  tune_comps(dir = here('models/sensitivities', new_name), 
             niters_tuning = 1, 
             exe = here('models/ss_win.exe'), 
             extras = '-nohess')

# Remove recruitment deviations ------------------------------------------------------

mod <- base_mod

mod$ctl$recdev_phase <- -5
mod$ctl$recdev_early_phase <- -5

new_name <- 'no_recdevs'

SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE,
          skipfinished = FALSE)


# Increase uncertainty around catch ------------------------------------------------------

mod <- base_mod

mod$dat$catch[mod$dat$catch$year < 1980, "catch_se"] = 0.1

new_name <- 'catch_se_0.1'

SS_write(mod, here('models/sensitivities', new_name),
         overwrite = TRUE)

r4ss::run(dir = here('models/sensitivities', new_name), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          show_in_console = FALSE,
          skipfinished = FALSE)


# Summaries ---------------------------------------------------------------

make_detailed_sensitivites <- function(biglist, mods_to_include, pretty_names = mods_to_include, 
                                       outdir, grp_name) {
  
  shortlist <-   big_sensitivity_output[c('base', mods_to_include)] |>
    r4ss::SSsummarize() 
  
  r4ss::SSplotComparisons(shortlist,
                          subplots = c(2,4), 
                          print = TRUE,  
                          plot = FALSE,
                          plotdir = outdir, 
                          filenameprefix = grp_name,
                          legendlabels = c('Base', pretty_names))
  
  SStableComparisons(shortlist, 
                     modelnames = c('base', pretty_names),
                     names =c("Recr_Virgin", "R0", "steep", "NatM", "L_at_Amax", "VonBert_K", "SSB_Virg",
                              "Bratio_2023", "SPRratio_2022")) |>
    dplyr::filter(!(Label %in% c('SR_BH_steep', 'NatM_break_1_Fem_GP_1',
                                 'NatM_break_1_Mal_GP_1', 'NatM_break_2_Mal_GP_1')),
                  Label != 'NatM_uniform_Mal_GP_1' | any(grep('break', Label))) |>
    dplyr::mutate(dplyr::across(-Label, ~ sapply(., format, digits = 3, scientific = FALSE) |>
                                  stringr::str_replace('NA', ''))) |>
    dplyr::rename(` ` = 'Label') |>
    write.csv(file.path(outdir, paste0(grp_name, '_table.csv')), 
              row.names = FALSE)
  
}

selectivity <- c('no_sex_selectivity', 
                 # 'selex_parm6', does not converge
                 'simpler_block', 
                 'wa_ntwl_asymptotic',
                 # 'wcgbts_asymptotic' does not converge
                 'float_q',
                 'unmirror_tri')
selec_pretty <- c('No sex selectivity',
                  'Simpler blocks',
                  'WA NTWL asymptotic',
                  'Float Q',
                  'Unmirror Tri')

weighting <- c(
#  'dirichlet_multinomial', does not converge
  'mcallister_ianelli',
  'no_q_extrasd',
  'age_francisX10',
  # 'age_lambda0',
  'len_francisX10')
  # 'len_lambda0.01')

weighting_pretty <- c('McAllister-Ianelli',
                      'No extra SD',
                      'Francis ages X10',
                      'Francis lengths X10')

data_choices <- c('no_sparse_comps',
                  #                  'noDebWV_lengths', minor
                  'prerec_data',
                  'released_lengths_in',
                  'canada_catches', 
                  'catch_se_0.1')
data_pretty <- c('No sparse comps',
                 'Pre-recruit data',
                 'Canada catches',
                 'Catch SE 0.1')

productivity <- c('est_h',
                  'est_male_M',
                  'M_ramp',
                  'single_M')
prod_pretty <- c('Estimate h',
                 'Estimate male M',
                 'M ramp',
                 'single M')

sens_names <- c(selectivity,
                weighting,
                data_choices,
                productivity)

pretty_names <- sens_names

big_sensitivity_output <- SSgetoutput(dirvec = c(here('models', base_mod_name),
                                                 glue::glue("{models}/{subdir}", 
                                                            models = here('models/sensitivities'),
                                                            subdir = sens_names))) 



#tmp <- SS_output(here('models/sensitivities', 'len_lambda0.01'))
#big_sensitivity_output[[15]] <- tmp

names(big_sensitivity_output) <- c('base', sens_names)

# test to make sure they all read correctly:
sapply(big_sensitivity_output, length)

make_detailed_sensitivites(big_sensitivity_output, 
                           mods_to_include = selectivity,
                           outdir = here('models/sensitivities/00_comparison_plots'),
                           grp_name = 'selectivity', 
                           pretty_names = selec_pretty)


make_detailed_sensitivites(big_sensitivity_output, 
                           mods_to_include = weighting,
                           outdir = here('models/sensitivities/00_comparison_plots'),
                           grp_name = 'weighting',
                           pretty_names = weighting_pretty)

make_detailed_sensitivites(big_sensitivity_output, 
                           mods_to_include = data_choices,
                           outdir = here('models/sensitivities/00_comparison_plots'),
                           grp_name = 'data')

make_detailed_sensitivites(big_sensitivity_output, 
                           mods_to_include = productivity,
                           outdir = here('models/sensitivities/00_comparison_plots'),
                           grp_name = 'productivity')

sensitivity_output <- SSsummarize(big_sensitivity_output) 
lapply(big_sensitivity_output, function(.)
  .$warnings[grep('gradient', .$warnings)])

