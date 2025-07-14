##############################################################################################################-
#
# 	Purpose: Run 2025 catch only projection.
#             This is based on template available at
#             
#             though original template is available at 
#             https://github.com/pfmc-assessments/catchonlyproj
#
#   Created: July 7, 2025
#			  by Brian Langseth 
#
##############################################################################################################-

library(dplyr)
library(tidyr)
library(here)
library(r4ss)
library(ggplot2)

##----------------------------------##-
# Model 1 - Update 2023 base model with new catches from GMT and udpated buffers -----------------
##----------------------------------##-

base_mod <- SS_read(here('models', '7_3_5_reweight'))
mod <- base_mod


## Update buffers

mod$fore$Flimitfraction_m

#Set up later buffers based on starting in 2023...
mod$fore$Flimitfraction_m <- PEPtools::get_buffer(
  years = 2023:2036,
  sigma = 0.5,
  pstar = 0.45
)
#...but set years 2023-2026 to have buffer of 1 now
mod$fore$Flimitfraction_m[which(mod$fore$Flimitfraction_m$year <= 2026), "buffer"] <- 1


## Update forecasted catch

mod$fore$ForeCatch

# GMT catches emailed to me on Jun 10, 2025, also found in
# https://docs.google.com/spreadsheets/d/1UtxsXxbwQTWMgn1TwYZaCyptq-S0BZtO3wGH0LJ7M1w/edit?gid=118359478#gid=118359478
gmt_catch <- data.frame("year" = c(2023:2026), 
                        "CA_TWL_1" = c(150.6, 114.4, 74.2, 74.2), 
                        "OR_TWL_2" = c(295.2, 259, 179.2, 179.2),  
                        "WA_TWL_3" = c(74.4, 51.2, 87.9, 87.9), 
                        "CA_NTWL_4" = c(19.2, 19.3, 34.3, 34.4), 
                        "OR_NTWL_5" = c(12, 12, 16.6, 16.6),
                        "WA_NTWL_6" = c(0.8, 0.4, 1.5, 1.5),
                        "CA_REC_7" = c(73.2, 40.2, 46.7, 46.9), 
                        "OR_REC_8" = c(57, 50.3, 26.1, 26), 
                        "WA_REC_9" = c(21.9, 26.8, 17.3, 17.4), 
                        "OR_ASHOP_11" = c(7, 1, 11.2, 11.2), 
                        "WA_ASHOP_12" = c(13.2, 0, 8.8, 8.8))
#Convert to format required by SS3
forecatch <- gmt_catch |>
  tidyr::pivot_longer(
    cols = -year,
    names_to = "fleet_name",
    values_to = "catch_or_F"
    ) |>
  dplyr::mutate(
    seas = 1,
    fleet = as.numeric(sub('.*_', '', fleet_name)) #replace everything through to the last underscore with nothing. Leaves with number
  ) |>
  dplyr::select(year, seas, fleet, catch_or_F) |>
  data.frame()

mod$fore$ForeCatch <- forecatch


## Make other adjustments to forecast file

mod$fore$Nforecastyrs <- 2036 - mod$dat$endyr

# determine new years to add to the forecast
old_Nforecastyrs <- mod$fore$Nforecastyrs
additional_years <- mod$dat$endyr + old_Nforecastyrs +
  1:(mod$fore$Nforecastyrs - old_Nforecastyrs)

mod$fore$FirstYear_for_caps_and_allocations <- max(additional_years) + 1


##
#Output new model and run
##

r4ss::SS_write(
  mod,
  dir = here('models', "catch_only_projections_2025/2025_standard"),
  overwrite = TRUE
)

r4ss::run(
  dir = here('models', "catch_only_projections_2025/2025_standard"),
  extras = "-nohess",
  exe = here('models/ss_win.exe'),
  show_in_console = TRUE,
  skipfinished = FALSE
)

pp <- SS_output(here('models', "catch_only_projections_2025/2025_standard"))
SS_plots(pp, plot = c(1:26))


##----------------------------------##-
# Model 2a - Use 2025_standard projection model but projection starting in 2026 (to obtain 2026 ACL) -----------------
##----------------------------------##-

mod <- SS_read(here('models', 'catch_only_projections_2025', '2025_standard'))


## Update buffers

mod$fore$Flimitfraction_m

#Set up later buffers based on starting in 2023...
mod$fore$Flimitfraction_m <- PEPtools::get_buffer(
  years = 2023:2036,
  sigma = 0.5,
  pstar = 0.45
)
#...this time set years 2023-2025 to have buffer of 1 now
mod$fore$Flimitfraction_m[which(mod$fore$Flimitfraction_m$year <= 2025), "buffer"] <- 1


## Update forecasted catch

mod$fore$ForeCatch <- mod$fore$ForeCatch[which(mod$fore$ForeCatch$year <= 2025), ]


##
#Output new model and run
##

r4ss::SS_write(
  mod,
  dir = here('models', "catch_only_projections_2025/2025_2026project_part1"),
  overwrite = TRUE
)

r4ss::run(
  dir = here('models', "catch_only_projections_2025/2025_2026project_part1"),
  extras = "-nohess",
  exe = here('models/ss_win.exe'),
  show_in_console = TRUE,
  skipfinished = FALSE
)

pp <- SS_output(here('models', "catch_only_projections_2025/2025_2026project_part1"))
SS_plots(pp, plot = c(1:26))


##----------------------------------##-
# Model 2b - Use 2025_2026project_part1 projection model back to fixed catch in 2026 -----------------
##----------------------------------##-

#Fixed catch in 2026 is based on the % allocation of the 2026 GMT estimate to the ACL in regulation in 2026 
#multiplied by the model estimated 2026 ACL from when  2026 catch is projected (from 2025_2026project_part1)

mod <- SS_read(here('models', 'catch_only_projections_2025', '2025_2026project_part1'))
mod_out <- SS_output(here('models', "catch_only_projections_2025/2025_2026project_part1"))


## Update buffers

mod$fore$Flimitfraction_m

#Set up later buffers based on starting in 2023...
mod$fore$Flimitfraction_m <- PEPtools::get_buffer(
  years = 2023:2036,
  sigma = 0.5,
  pstar = 0.45
)
#...back to original set of years (2023-2026) to have buffer of 1 now
mod$fore$Flimitfraction_m[which(mod$fore$Flimitfraction_m$year <= 2026), "buffer"] <- 1


## Update forecasted catch (include back 2026)

mod$fore$ForeCatch

# GMT catches emailed to me on Jun 10, 2025, also found in
# https://docs.google.com/spreadsheets/d/1UtxsXxbwQTWMgn1TwYZaCyptq-S0BZtO3wGH0LJ7M1w/edit?gid=118359478#gid=118359478
gmt_catch <- data.frame("year" = c(2023:2026), 
                        "CA_TWL_1" = c(150.6, 114.4, 74.2, 74.2), 
                        "OR_TWL_2" = c(295.2, 259, 179.2, 179.2),  
                        "WA_TWL_3" = c(74.4, 51.2, 87.9, 87.9), 
                        "CA_NTWL_4" = c(19.2, 19.3, 34.3, 34.4), 
                        "OR_NTWL_5" = c(12, 12, 16.6, 16.6),
                        "WA_NTWL_6" = c(0.8, 0.4, 1.5, 1.5),
                        "CA_REC_7" = c(73.2, 40.2, 46.7, 46.9), 
                        "OR_REC_8" = c(57, 50.3, 26.1, 26), 
                        "WA_REC_9" = c(21.9, 26.8, 17.3, 17.4), 
                        "OR_ASHOP_11" = c(7, 1, 11.2, 11.2), 
                        "WA_ASHOP_12" = c(13.2, 0, 8.8, 8.8))
#Convert to format required by SS3
forecatch <- gmt_catch |>
  tidyr::pivot_longer(
    cols = -year,
    names_to = "fleet_name",
    values_to = "catch_or_F"
  ) |>
  dplyr::mutate(
    seas = 1,
    fleet = as.numeric(sub('.*_', '', fleet_name)) #replace everything through to the last underscore with nothing. Leaves with number
  ) |>
  dplyr::select(year, seas, fleet, catch_or_F) |>
  data.frame()

mod$fore$ForeCatch <- forecatch


## Adjust the 2026 fixed value based on the % of allocation from the original 2026 GMT fixed value (504)
## to the 2026 ACL in regulation (573) multiplied by the 2026 ACL from part 1 (model 2a)

new2026ACL <- mod_out$derived_quants[mod_out$derived_quants$Label == "ForeCatch_2026", "Value"]
scaled2026catch <- new2026ACL * (rowSums(gmt_catch[,-1])[4] / 573)
#allocate new scaled 2026 total catch to fleets based on same percentage as original allocation
temp <- mod$fore$ForeCatch[mod$fore$ForeCatch$year == 2026,]
allocated2026catch <- round(scaled2026catch * temp$catch_or_F/sum(temp$catch_or_F), 1)

mod$fore$ForeCatch[mod$fore$ForeCatch$year == 2026, "catch_or_F"] <- allocated2026catch


##
#Output new model and run
##

r4ss::SS_write(
  mod,
  dir = here('models', "catch_only_projections_2025/2025_2026project_part2"),
  overwrite = TRUE
)

r4ss::run(
  dir = here('models', "catch_only_projections_2025/2025_2026project_part2"),
  extras = "-nohess",
  exe = here('models/ss_win.exe'),
  show_in_console = TRUE,
  skipfinished = FALSE
)

pp <- SS_output(here('models', "catch_only_projections_2025/2025_2026project_part2"))
SS_plots(pp, plot = c(1:26))



##----------------------------------##-
# Render markdown template based on template -----------------
##----------------------------------##-

#Download from Ian's revised version (done automatically below)
#and then update to make specific to canary (done manually)
# download.file(url = "https://raw.githubusercontent.com/pfmc-assessments/petrale/refs/heads/main/catch-only_projections/catch_only_projection_petrale_2025_plus_alternative.qmd",
#               destfile = here("models", "catch_only_projections_2025", "catch_only_projection_canary_2025.qmd"))


# #The render here automatically
# #Can also rendering directly within the open .qmd file
# quarto::quarto_render(
#   file.path(here("models",
#                  "catch_only_projections_2025", 
#                  "catch_only_projection_canary_2025.qmd")
#   )
# )

