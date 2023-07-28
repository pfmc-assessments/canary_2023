library(r4ss)
library(here)
library(dplyr)

if(Sys.getenv("USERNAME") == "Brian.Langseth") {
  wd = "L:/"
}
if(Sys.getenv("USERNAME") == "Kiva.Oken") {
  wd = "Q:/"
}

source(here('code/table_decision.R'))

#Set up low and high states of nature
low_state <- "sensitivities/STAR_single_M"
high_state <- "sensitivities/STAR_M_ramp"

#####-------------------------------------------####
#Run alternative states of nature for Pstar = 0.45 which we have already run for the base
#####-------------------------------------------####

pstar <- 0.45
base45 <- "7_3_5_reweight"

#Get new forecast catches
base_mod <- SS_output(here('models',base45))
fore_catch <- r4ss::SS_ForeCatch(base_mod, yrs = 2023:2034)


##
#Set up low state first
##
mod <- SS_read(here('models',low_state))
mod$fore$ForeCatch <- fore_catch

#Turn off buffers
mod$fore$Flimitfraction <- 1 #dont have years of buffer applied
mod$fore$FirstYear_for_caps_and_allocations <- 2035 #these should be overwritten with the fixed catch but putting here anyway

#Estimate from par file parameters
mod$start$init_values_src <-1

SS_write(mod,
         dir = here('models','decision_tables',paste0("low_",pstar)),
         overwrite = TRUE)

r4ss::run(dir = here('models','decision_tables',paste0("low_",pstar)),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)


##
#Now set up high state
##
mod <- SS_read(here('models',high))
mod$fore$ForeCatch <- fore_catch

#Turn off buffers
mod$fore$Flimitfraction <- 1 #dont have years of buffer applied
mod$fore$FirstYear_for_caps_and_allocations <- 2035 #these should be overwritten with the fixed catch but putting here anyway

#Estimate from par file parameters
mod$start$init_values_src <-1

SS_write(mod,
         dir = here('models','decision_tables',paste0("high_",pstar)),
         overwrite = TRUE)

r4ss::run(dir = here('models','decision_tables',paste0("high_",pstar)),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)


#####-------------------------------------------####
#Pstar = 0.40
#####-------------------------------------------####

pstar <- 0.40

#Set up base model with new pstar
mod <- SS_read(here('models',base45))
mod$fore$Flimitfraction_m <- data.frame("Year" = 2023:2034, 
                                        "Fraction" = get_buffer(c(2023:2034), sigma = 0.5, pstar = pstar)[,2])
SS_write(mod,
         dir = here('models','decision_tables',paste0("base_",pstar)),
         overwrite = TRUE)

r4ss::run(dir = here('models','decision_tables',paste0("base_",pstar)),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)

#Get new forecast catches
base_mod <- SS_output(here('models','decision_tables',paste0("base_",pstar)))
fore_catch <- r4ss::SS_ForeCatch(base_mod, yrs = 2023:2034)


##
#Set up low state first
##
mod <- SS_read(here('models',low_state))
mod$fore$ForeCatch <- fore_catch

#Turn off buffers
mod$fore$Flimitfraction <- 1 #dont have years of buffer applied
mod$fore$FirstYear_for_caps_and_allocations <- 2035 #these should be overwritten with the fixed catch but putting here anyway

#Estimate from par file parameters
mod$start$init_values_src <-1

SS_write(mod,
         dir = here('models','decision_tables',paste0("low_",pstar)),
         overwrite = TRUE)

r4ss::run(dir = here('models','decision_tables',paste0("low_",pstar)),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)


##
#Now set up high state
##
mod <- SS_read(here('models',high))
mod$fore$ForeCatch <- fore_catch

#Turn off buffers
mod$fore$Flimitfraction <- 1 #dont have years of buffer applied
mod$fore$FirstYear_for_caps_and_allocations <- 2035 #these should be overwritten with the fixed catch but putting here anyway

#Estimate from par file parameters
mod$start$init_values_src <-1

SS_write(mod,
         dir = here('models','decision_tables',paste0("high_",pstar)),
         overwrite = TRUE)

r4ss::run(dir = here('models','decision_tables',paste0("high_",pstar)),
          exe = here('models/ss_win.exe'),
          extras = '-nohess',
          # show_in_console = TRUE,
          skipfinished = FALSE)



#####-------------------------------------------####
#Decision Table
#####-------------------------------------------####

low45 <- SS_output(here('models','decision_tables',"low_0.45"))
base45 <- SS_output(here('models',"7_3_5_reweight"))
high45 <- SS_output(here('models','decision_tables',"high_0.45"))

low40 <- SS_output(here('models','decision_tables',"low_0.4"))
base40 <- SS_output(here('models','decision_tables',"base_0.4"))
high40 <- SS_output(here('models','decision_tables',"high_0.4"))


caption <- "Decision table with 10-year projections. 'Mgmt' refers to the two management scenarios (A) the default harvest control rule $P^* = 0.45$, (B) harvest control rule with a lower $P^* = 0.40$. In each case the 2023 and 2024 catches are fixed at the ACLs which have been set for that year with values provided by the GMT. The alternative states of nature ('Low', 'Base', and 'High') are provided in the columns, with Spawning Output ('Spawn', in millions of eggs) and Fraction of unfished ('Frac') provided for each state of nature. The colors of catch and fraction unfished are relative with lighter colors representing lower values."

tab <- table_decision(
  caption = caption,
  label = "es-decision",
  list(low40, base40, high40),
  list(low45, base45, high45)
)
writeLines(tab,here('documents',"tables", "decision_table.tex"))
