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

# Specify the directory for the document
#User directories
if(Sys.getenv("USERNAME") == "Brian.Langseth") {
  dir <- "U:/Stock assessments/canary_2023"
}

#Create directory
doc_dir <- file.path(dir, "documents","pre-Star")
if(!dir.exists(doc_dir)){
  dir.create(doc_dir,recursive=TRUE)
}
setwd(doc_dir)

# Create the needed items to generate the "right" template that would be based on the inputs here:
# Need to only do this once
sa4ss::draft(
  authors = c("Brian J. Langseth", "Kiva L. Oken"),
  species = "Canary Rockfish",
  latin = "Sebastes pinniger",
  coast = "U.S. West",
  type = c("sa"),
  create_dir = FALSE,
  edit = FALSE
)

model_name <- "2015base"
model_dir <- file.path(dir, "models", model_name)

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
