library(r4ss)
library(here)

if(Sys.getenv("USERNAME") == "Brian.Langseth") {
  wd = "L:/"
}
if(Sys.getenv("USERNAME") == "Kiva.Oken") {
  wd = "Q:/"
}

###################################################################################################
# Run alternative states of nature models first ----
####################################################################################################


#THIS IS NOT COMPLETE AND NEEDS TO BE UPDATED STARTING FROM HERE


base <- "6_1_0_projections"
base_mod <- SS_output(here('models',base))

fore_loc = grep("ForeCatch",base_mod$derived_quants$Label)
baseABC = rbind(data.frame("Year" = c(2025:2034), "Seas" = 1, "Fleet" = 1, "Catch" = base_mod$derived_quants[fore_loc,"Value"][-c(1:2)]*0.265),
                data.frame("Year" = c(2025:2034), "Seas" = 1, "Fleet" = 2, "Catch" = base_mod$derived_quants[fore_loc,"Value"][-c(1:2)]*0.735))

model = "8_0_4b_highState_R0_baseABC"
base.804 = SS_output(file.path(wd, model),covar=TRUE)
SS_plots(base.804)

model = "8_0_5b_lowState_R0_baseABC"
base.805 = SS_output(file.path(wd, model),covar=TRUE)
SS_plots(base.805)






#CODE FROM CHANTEL

###################################################################################################
# ACL P* = 0.45 and sigma = 0.50 for both areas
####################################################################################################

run_name = "6_1_0_projections"

fore_catch <- read.csv(file.path(south_dt_loc, south_name, "Projection_Values.csv"))
south_forecast <- fore_catch$Removals.Model1
fleet_percents = c(0.04,	0.03,	0.72,	0.21)

years = 2025:2034
fore.catch = NULL 
fleets <- 4

for(y in 1:length(years)){
  for(f in 1:fleets){
    calc = c(years[y], 1, f, fleet_percents[f]*south_forecast[y])
    fore.catch = rbind(fore.catch, calc)
  }
}
colnames(fore.catch) = c("Year", "Seas", "Fleet", "Catch or F")
rownames(fore.catch) = NULL
write.csv(fore.catch, file.path(south_dt_loc, paste0(south_name, "_", run_name, ".csv")), row.names = FALSE)


wd <- file.path(user_dir, "models", "nca")
north_dt_loc = file.path(wd, "_decision_table", "pstar_45")
north_name = "10.0_south_post_star_base"
north_loc = file.path(wd, north_name)
north_forecast <- fore_catch$Removals.Model2
fleet_percents = c(0.03, 0.05,	0.38, 0.54)

years = 2025:2034
fore.catch = NULL 
fleets <- 4

for(y in 1:length(years)){
  for(f in 1:fleets){
    calc = c(years[y], 1, f, fleet_percents[f]*north_forecast[y])
    fore.catch = rbind(fore.catch, calc)
  }
}
colnames(fore.catch) = c("Year", "Seas", "Fleet", "Catch or F")
rownames(fore.catch) = NULL
write.csv(fore.catch, file.path(north_dt_loc, paste0(north_name, "_", run_name, ".csv")), row.names = FALSE)



# Grab the SO and depletion from the low state of nature
south_low <- r4ss::SS_output("C:/Assessments/2023/copper_rockfish_2023/models/sca/_decision_table/pstar_45/15.0_south_post_star_base_SR_parm[2]_decision_table_1.15_0.277_0.125")
north_low <- r4ss::SS_output("C:/Assessments/2023/copper_rockfish_2023/models/nca/_decision_table/pstar_45/10.0_north_post_star_base_SR_parm[2]_decision_table_1.15_0.3_0.125")


years <- 2023:2034
sb0 <- south_low$timeseries[south_low$timeseries$Yr == 1916, "SpawnBio"] + 
  north_low$timeseries[north_low$timeseries$Yr == 1916, "SpawnBio"]
sby <- south_low$timeseries[south_low$timeseries$Yr %in% years, "SpawnBio"] +
  north_low$timeseries[north_low$timeseries$Yr %in% years, "SpawnBio"]

sb <- sby
depl <- sby / sb0
out <- cbind(years, sb, depl)
write.csv(out, file.path(south_dt_loc, paste0(run_name, "_low_state_of_nature.csv")))

# Grab the SO and depletion from the high state of nature
south_hi <- r4ss::SS_output("C:/Assessments/2023/copper_rockfish_2023/models/sca/_decision_table/pstar_45/15.0_south_post_star_base_SR_parm[2]_decision_table_1.15_0.277_0.875")
north_hi <- r4ss::SS_output("C:/Assessments/2023/copper_rockfish_2023/models/nca/_decision_table/pstar_45/10.0_north_post_star_base_SR_parm[2]_decision_table_1.15_0.3_0.875")

sb0 <- south_hi$timeseries[south_hi$timeseries$Yr == 1916, "SpawnBio"] + 
  north_hi$timeseries[north_hi$timeseries$Yr == 1916, "SpawnBio"]
sby <- south_hi$timeseries[south_hi$timeseries$Yr %in% years, "SpawnBio"] +
  north_hi$timeseries[north_hi$timeseries$Yr %in% years, "SpawnBio"]

sb <- sby
depl <- sby / sb0
out <- cbind(years, sb, depl)
write.csv(out, file.path(south_dt_loc, paste0(run_name, "_high_state_of_nature.csv")))

south <- r4ss::SS_output("C:/Assessments/2023/copper_rockfish_2023/models/sca/_decision_table/pstar_45/15.0_south_post_star_base")
north <- r4ss::SS_output("C:/Assessments/2023/copper_rockfish_2023/models/nca/_decision_table/pstar_45/10.0_north_post_star_base")
sb0 <- south$timeseries[south$timeseries$Yr == 1916, "SpawnBio"] + 
  north$timeseries[north$timeseries$Yr == 1916, "SpawnBio"]
sby <- south$timeseries[south$timeseries$Yr %in% years, "SpawnBio"] +
  north$timeseries[north$timeseries$Yr %in% years, "SpawnBio"]

sb <- sby
depl <- sby / sb0
out <- cbind(years, sb, depl)
write.csv(out, file.path(south_dt_loc, paste0(run_name, "_base_state_of_nature.csv")))

###################################################################################################
# ACL P* = 0.40 and sigma = 0.50 for both areas
####################################################################################################
wd <- file.path(user_dir, "models", area)
run_name =  "pstar_40_removals"
south_dt_loc = file.path(wd, "_decision_table", "pstar_40")
south_name = "15.0_south_post_star_base"
south_loc = file.path(wd, "_decision_table", "pstar_40", south_name)

fore_catch <- read.csv(file.path(south_loc, "Projection_Values.csv"))
south_forecast <- fore_catch$Removals.Model1
fleet_percents = c(0.04,	0.03,	0.72,	0.21)

years = 2025:2034
fore.catch = NULL 
fleets <- 4

for(y in 1:length(years)){
  for(f in 1:fleets){
    calc = c(years[y], 1, f, fleet_percents[f]*south_forecast[y])
    fore.catch = rbind(fore.catch, calc)
  }
}
colnames(fore.catch) = c("Year", "Seas", "Fleet", "Catch or F")
rownames(fore.catch) = NULL
write.csv(fore.catch, file.path(south_dt_loc, paste0(south_name, "_", run_name, ".csv")), row.names = FALSE)

wd <- file.path(user_dir, "models", "nca")
north_dt_loc = file.path(wd, "_decision_table", "pstar_40")
north_name = "10.0_south_post_star_base"
north_loc = file.path(north_dt_loc, north_name)
north_forecast <- fore_catch$Removals.Model2
fleet_percents = c(0.03, 0.05,	0.38, 0.54)

years = 2025:2034
fore.catch = NULL 
fleets <- 4

for(y in 1:length(years)){
  for(f in 1:fleets){
    calc = c(years[y], 1, f, fleet_percents[f]*north_forecast[y])
    fore.catch = rbind(fore.catch, calc)
  }
}
colnames(fore.catch) = c("Year", "Seas", "Fleet", "Catch or F")
rownames(fore.catch) = NULL
write.csv(fore.catch, file.path(north_dt_loc, paste0(north_name, "_", run_name, ".csv")), row.names = FALSE)



# Grab the SO and depletion from the low state of nature
south_low <- r4ss::SS_output("C:/Assessments/2023/copper_rockfish_2023/models/sca/_decision_table/pstar_40/15.0_south_post_star_base_SR_parm[2]_decision_table_1.15_0.277_0.125")
north_low <- r4ss::SS_output("C:/Assessments/2023/copper_rockfish_2023/models/nca/_decision_table/pstar_40/10.0_north_post_star_base_SR_parm[2]_decision_table_1.15_0.3_0.125")

years <- 2023:2034
sb0 <- south_low$timeseries[south_low$timeseries$Yr == 1916, "SpawnBio"] + 
  north_low$timeseries[north_low$timeseries$Yr == 1916, "SpawnBio"]
sby <- south_low$timeseries[south_low$timeseries$Yr %in% years, "SpawnBio"] +
  north_low$timeseries[north_low$timeseries$Yr %in% years, "SpawnBio"]

sb <- sby
depl <- sby / sb0
out <- cbind(years, sb, depl)
write.csv(out, file.path(south_dt_loc, paste0(run_name, "_low_state_of_nature.csv")))

# Grab the SO and depletion from the high state of nature
south_hi <- r4ss::SS_output("C:/Assessments/2023/copper_rockfish_2023/models/sca/_decision_table/pstar_40/15.0_south_post_star_base_SR_parm[2]_decision_table_1.15_0.277_0.875")
north_hi <- r4ss::SS_output("C:/Assessments/2023/copper_rockfish_2023/models/nca/_decision_table/pstar_40/10.0_north_post_star_base_SR_parm[2]_decision_table_1.15_0.3_0.875")

sb0 <- south_hi$timeseries[south_hi$timeseries$Yr == 1916, "SpawnBio"] + 
  north_hi$timeseries[north_hi$timeseries$Yr == 1916, "SpawnBio"]
sby <- south_hi$timeseries[south_hi$timeseries$Yr %in% years, "SpawnBio"] +
  north_hi$timeseries[north_hi$timeseries$Yr %in% years, "SpawnBio"]

sb <- sby
depl <- sby / sb0
out <- cbind(years, sb, depl)
write.csv(out, file.path(south_dt_loc, paste0(run_name, "_high_state_of_nature.csv")))

south <- r4ss::SS_output("C:/Assessments/2023/copper_rockfish_2023/models/sca/_decision_table/pstar_40/15.0_south_post_star_base")
north <- r4ss::SS_output("C:/Assessments/2023/copper_rockfish_2023/models/nca/_decision_table/pstar_40/10.0_north_post_star_base")
sb0 <- south$timeseries[south$timeseries$Yr == 1916, "SpawnBio"] + 
  north$timeseries[north$timeseries$Yr == 1916, "SpawnBio"]
sby <- south$timeseries[south$timeseries$Yr %in% years, "SpawnBio"] +
  north$timeseries[north$timeseries$Yr %in% years, "SpawnBio"]

sb <- sby
depl <- sby / sb0
out <- cbind(years, sb, depl)
write.csv(out, file.path(south_dt_loc, paste0(run_name, "_base_state_of_nature.csv")))


###################################################################################################
# ACL P* = 0.35 and sigma = 0.50 for both areas
####################################################################################################
wd <- file.path(user_dir, "models", area)
run_name =  "pstar_35_removals"
south_dt_loc = file.path(wd, "_decision_table", "pstar_35")
south_name = "15.0_south_post_star_base"
south_loc = file.path(wd, "_decision_table", "pstar_35", south_name)

fore_catch <- read.csv(file.path(south_loc, "Projection_Values.csv"))
south_forecast <- fore_catch$Removals.Model1
fleet_percents = c(0.04,	0.03,	0.72,	0.21)

years = 2025:2034
fore.catch = NULL 
fleets <- 4

for(y in 1:length(years)){
  for(f in 1:fleets){
    calc = c(years[y], 1, f, fleet_percents[f]*south_forecast[y])
    fore.catch = rbind(fore.catch, calc)
  }
}
colnames(fore.catch) = c("Year", "Seas", "Fleet", "Catch or F")
rownames(fore.catch) = NULL
write.csv(fore.catch, file.path(south_dt_loc, paste0(south_name, "_", run_name, ".csv")), row.names = FALSE)


wd <- file.path(user_dir, "models", "nca")
north_dt_loc = file.path(wd, "_decision_table", "pstar_35")
north_name = "10.0_south_post_star_base"
north_loc = file.path(north_dt_loc, north_name)
north_forecast <- fore_catch$Removals.Model2
fleet_percents = c(0.03, 0.05,	0.38, 0.54)

years = 2025:2034
fore.catch = NULL 
fleets <- 4

for(y in 1:length(years)){
  for(f in 1:fleets){
    calc = c(years[y], 1, f, fleet_percents[f]*north_forecast[y])
    fore.catch = rbind(fore.catch, calc)
  }
}
colnames(fore.catch) = c("Year", "Seas", "Fleet", "Catch or F")
rownames(fore.catch) = NULL
write.csv(fore.catch, file.path(north_dt_loc, paste0(north_name, "_", run_name, ".csv")), row.names = FALSE)


# Grab the SO and depletion from the low state of nature
south_low <- r4ss::SS_output("C:/Assessments/2023/copper_rockfish_2023/models/sca/_decision_table/pstar_35/15.0_south_post_star_base_SR_parm[2]_decision_table_1.15_0.277_0.125")
north_low <- r4ss::SS_output("C:/Assessments/2023/copper_rockfish_2023/models/nca/_decision_table/pstar_35/10.0_north_post_star_base_SR_parm[2]_decision_table_1.15_0.3_0.125")


years <- 2023:2034
sb0 <- south_low$timeseries[south_low$timeseries$Yr == 1916, "SpawnBio"] + 
  north_low$timeseries[north_low$timeseries$Yr == 1916, "SpawnBio"]
sby <- south_low$timeseries[south_low$timeseries$Yr %in% years, "SpawnBio"] +
  north_low$timeseries[north_low$timeseries$Yr %in% years, "SpawnBio"]

sb <- sby
depl <- sby / sb0
out <- cbind(years, sb, depl)
write.csv(out, file.path(south_dt_loc, "low_state_of_nature.csv"))

# Grab the SO and depletion from the high state of nature
south_hi <- r4ss::SS_output("C:/Assessments/2023/copper_rockfish_2023/models/sca/_decision_table/pstar_35/15.0_south_post_star_base_SR_parm[2]_decision_table_1.15_0.277_0.875")
north_hi <- r4ss::SS_output("C:/Assessments/2023/copper_rockfish_2023/models/nca/_decision_table/pstar_35/10.0_north_post_star_base_SR_parm[2]_decision_table_1.15_0.3_0.875")

sb0 <- south_hi$timeseries[south_hi$timeseries$Yr == 1916, "SpawnBio"] + 
  north_hi$timeseries[north_hi$timeseries$Yr == 1916, "SpawnBio"]
sby <- south_hi$timeseries[south_hi$timeseries$Yr %in% years, "SpawnBio"] +
  north_hi$timeseries[north_hi$timeseries$Yr %in% years, "SpawnBio"]

sb <- sby
depl <- sby / sb0
out <- cbind(years, sb, depl)
write.csv(out, file.path(south_dt_loc, paste0(run_name, "_high_state_of_nature.csv")))

south <- r4ss::SS_output("C:/Assessments/2023/copper_rockfish_2023/models/sca/_decision_table/pstar_35/15.0_south_post_star_base")
north <- r4ss::SS_output("C:/Assessments/2023/copper_rockfish_2023/models/nca/_decision_table/pstar_35/10.0_north_post_star_base")
sb0 <- south$timeseries[south$timeseries$Yr == 1916, "SpawnBio"] + 
  north$timeseries[north$timeseries$Yr == 1916, "SpawnBio"]
sby <- south$timeseries[south$timeseries$Yr %in% years, "SpawnBio"] +
  north$timeseries[north$timeseries$Yr %in% years, "SpawnBio"]

sb <- sby
depl <- sby / sb0
out <- cbind(years, sb, depl)
write.csv(out, file.path(south_dt_loc, paste0(run_name, "_base_state_of_nature.csv")))