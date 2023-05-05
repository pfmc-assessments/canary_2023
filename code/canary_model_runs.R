##########################################################################################
#
# Model runs for 2023 Canary rockfish 
#   By: Kiva Oken and Brian Langseth
#
##########################################################################################

#devtools::install_github("r4ss/r4ss")
library(r4ss)
#devtools::install_github("pfmc-assessments/PEPtools")
library(PEPtools)
library(here)

#Add file managing section here 
#I will try to get 'here' to work but if I can I will go with what I had
#if(Sys.getenv("USERNAME") == "Brian.Langseth") {
#  wd = "C:/Users/Brian.Langseth/Desktop/canary_model_runs"
#}


##########################################################################################
#                         Set up from 2015 base to current version
##########################################################################################


### Model name here with numbering (these should be all 0_X_Y) --------------------------------

##
#Copy inputs
##

copy_SS_inputs(dir.old = here('models/2015base'), 
               dir.new = here('models/transition'))

mod <- SS_read(here('models/converted'))


##
#Make Changes
##

#LOTS OF STUFF HERE


##
#Output files and run
##
SS_write(mod,
         dir = here('models/update_wcgbts_comps'), 
         overwrite = TRUE)

r4ss::run(dir = here('models/update_wcgbts_comps'), 
          exe = here('models/ss_win.exe'), 
          extras = '-nohess', 
          # show_in_console = TRUE, 
          skipfinished = FALSE)


##
#Comparison plots
##

xx <- SSgetoutput(dirvec = glue::glue("{models}/{subdir}", models = getwd(),
                                      subdir = c('0_0_2015base', '0_0_coastwide', new_mod)))
SSsummarize(xx) |>
  SSplotComparisons(legendlabels = c('2015', '2023 coastwide', '2023 inputs changed'),
                    subplots = c(2,4))



##########################################################################################
#               Explorations with up-to-date current version to decide base
##########################################################################################

### Model name here with numbering (starting with 1_0_0) --------------------------------

##
#Copy inputs
##


##
#Make Changes
##


##
#Output files and run
##


##
#Comparison plots
##




##########################################################################################

#Sensitivities on base can probably go into separate script
##########################################################################################


