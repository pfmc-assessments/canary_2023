####################
#
# Pull trawl survey data for the 2021 data moderate assessments
# Right now just for Quillback and Squarespot
#
####################

devtools::install_github("nwfsc-assess/nwfscSurvey", build_vignettes = TRUE, force = TRUE)
library(nwfscSurvey)
vignette("nwfscSurvey")

#####
##Quillback rockfish
#####
spec = "canary rockfish"

#Catch records
setwd("L:\\Assessments\\CurrentAssessments\\DataModerate_2021\\Quillback_Rockfish\\data\\Trawl Survey Catch")

catch_combo = nwfscSurvey::PullCatch.fn(Name = spec, SurveyName = "NWFSC.Combo", SaveFile = TRUE, Dir = getwd())
catch_triennial = nwfscSurvey::PullCatch.fn(Name = spec, SurveyName = "Triennial", SaveFile = TRUE, Dir = getwd()) 

#These had no or VERY few (video, shelf) records 
#catch_shelf = nwfscSurvey::PullCatch.fn(Name = spec, SurveyName = "NWFSC.Shelf", SaveFile = TRUE, Dir = getwd()) 
#catch_slope = nwfscSurvey::PullCatch.fn(Name = spec, SurveyName = "NWFSC.Slope", SaveFile = TRUE, Dir = getwd())
#catch_AFSCslope = nwfscSurvey::PullCatch.fn(Name = spec, SurveyName = "AFSC.Slope", SaveFile = TRUE, Dir = getwd())
#catch_hypoxia = nwfscSurvey::PullCatch.fn(Name = spec, SurveyName = "NWFSC.Hypoxia", SaveFile = TRUE, Dir = getwd())
#catch_SantaBarbara = nwfscSurvey::PullCatch.fn(Name = spec, SurveyName = "NWFSC.Santa.Barb.Basin", SaveFile = TRUE, Dir = getwd())
#catch_shelfRock = nwfscSurvey::PullCatch.fn(Name = spec, SurveyName = "NWFSC.Shelf.Rockfish", SaveFile = TRUE, Dir = getwd()) 
#catch_video = nwfscSurvey::PullCatch.fn(Name = spec, SurveyName = "NWFSC.Video", SaveFile = TRUE, Dir = getwd())


#Biological records
setwd("L:\\Assessments\\CurrentAssessments\\DataModerate_2021\\Quillback_Rockfish\\data\\Trawl Survey Bio")

bio_combo = nwfscSurvey::PullBio.fn(Name = spec, SurveyName = "NWFSC.Combo", SaveFile = TRUE, Dir = getwd())
bio_triennial = nwfscSurvey::PullBio.fn(Name = spec, SurveyName = "Triennial", SaveFile = TRUE, Dir = getwd())

#These had no or VERY few (video) records 
#bio_shelf = nwfscSurvey::PullBio.fn(Name = spec, SurveyName = "NWFSC.Shelf", SaveFile = TRUE, Dir = getwd())
#bio_slope = nwfscSurvey::PullBio.fn(Name = spec, SurveyName = "NWFSC.Slope", SaveFile = TRUE, Dir = getwd())
#bio_AFSCslope = nwfscSurvey::PullBio.fn(Name = spec, SurveyName = "AFSC.Slope", SaveFile = TRUE, Dir = getwd())
#bio_hypoxia = nwfscSurvey::PullBio.fn(Name = spec, SurveyName = "NWFSC.Hypoxia", SaveFile = TRUE, Dir = getwd())
#bio_SantaBarba = nwfscSurvey::PullBio.fn(Name = spec, SurveyName = "NWFSC.Santa.Barb.Basin", SaveFile = TRUE, Dir = getwd())
#bio_shelfRock = nwfscSurvey::PullBio.fn(Name = spec, SurveyName = "NWFSC.Shelf.Rockfish", SaveFile = TRUE, Dir = getwd())
#bio_video = nwfscSurvey::PullBio.fn(Name = spec, SurveyName = "NWFSC.Video", SaveFile = TRUE, Dir = getwd())
