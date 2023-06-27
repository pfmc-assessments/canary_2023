##################################################################################################
#
#	Set up for running sa4ss report
# 		
#		Written by Brian Langseth
#
##################################################################################################

#I assume the user has already set up the sa4ss package and
#tested according to README instructions at https://github.com/pfmc-assessments/sa4ss

#Install sa4ss package
#tryCatch(expr = pkgload::unload("sa4ss"), error = function(x) "")
#remotes::install_github("pfmc-assessments/sa4ss")
library(sa4ss)
library(here)

# Specify the directory for the document
#User directories
if(Sys.getenv("USERNAME") == "Brian.Langseth") {
  dir <- "C:\\Users\\Brian.Langseth\\Desktop\\canary_2023"
}
if(Sys.getenv("USERNAME") == "Kiva.Oken") {
  dir <- "C:/Users/Kiva.Oken/Desktop/canary_2023"
}
#Create directory
doc_dir <- file.path(dir, "documents","pre-Star")
if(!dir.exists(doc_dir)){
  dir.create(doc_dir,recursive=TRUE)
}
setwd(doc_dir)

# Create the needed items to generate the "right" template that would be based on the inputs here:
# Need to only do this once. Commenting out so dont accidentally run
# sa4ss::draft(
#   authors = c("Brian J. Langseth", "Kiva L. Oken"),
#   species = "Canary Rockfish",
#   latin = "Sebastes pinniger",
#   coast = "U.S. West",
#   type = c("sa"),
#   create_dir = FALSE,
#   edit = FALSE
# )

model_name <- "5_5_0_hessian"
model_dir <- file.path(dir, "models", model_name)

sa4ss::read_model(mod_loc = model_dir, 
                  save_loc = doc_dir, 
                  create_plots = FALSE)

R.utils::copyDirectory(from = file.path(model_dir, 'plots'),
                       to = file.path(dir, 'documents/figures/plots'),
                       overwrite = TRUE)


# Compile command
if(file.exists("_main.Rmd")){
  file.remove("_main.Rmd")
}
# Render the pdf
bookdown::render_book(
  "00a.Rmd", 
  clean = FALSE, 
  output_dir = getwd()
)
