##################################################################################################
#
#	Create composition data for commercial and recreational fleets
# 		
#		Written by Brian Langseth
#
##################################################################################################

#devtools::install_github("nwfsc-assess/PacFIN.Utilities")
library(PacFIN.Utilities)
library(ggplot2)

dir = "//nwcfile/FRAM/Assessments/Assessment Data/2023 Assessment Cycle/canary rockfish/PacFIN data"

#User directories
if(Sys.getenv("USERNAME") == "Brian.Langseth") {
  git_dir <- "U:/Stock assessments/canary_2023/"
}

################################
#Load PacFIN BDS data
################################
load(file.path(dir, "PacFIN.CNRY.bds.01.Sep.2022.RData"))
pacfin <- bds.pacfin

# Load in the current weight-at-length estimates by sex
wlcoef <- utils::read.csv(file.path(git_dir, "data", "W_L_pars.csv"), header = TRUE)
fa = wlcoef[wlcoef$Sex=="F","A"] 
ma = wlcoef[wlcoef$Sex=="M","A"]
ua = wlcoef[wlcoef$Sex=="U","A"]
fb = wlcoef[wlcoef$Sex=="F","B"] 
mb = wlcoef[wlcoef$Sex=="M","B"] 
ub = wlcoef[wlcoef$Sex=="U","B"] 

# Read in the PacFIN catch data to based expansion on
catch.file <- data.frame(googlesheets4::read_sheet('https://docs.google.com/spreadsheets/d/17x0PT_vqTv1kvHAwaqgz7jmKvCvRwm7OcFb4jrh_AWo/edit#gid=2086044691',
                                                   sheet = "catch_mt"))
colnames(catch.file)[1] = c("Year")

# Clean up length data
pacfin[pacfin$FISH_LENGTH_UNITS %in% "UNK", "FISH_LENGTH_UNITS"] = "CM" #these are CMs
Pdata = cleanPacFIN(Pdata = pacfin, 
                    CLEAN = TRUE,
                    keep_length_type = c("", "F", "A", "U", NA), #removes the 2 standard length samples
                    keep_sample_type = c("M","S"), #keep special project samples
                    verbose = TRUE)
Pdata <- Pdata[!(Pdata$SAMPLE_TYPE %in% c("S") & Pdata$SAMPLE_YEAR>1986),] #Keep oregon special project data before and including 1986


##<<<<<<<<<<<<<<<<<<<CONTINUE HERE
Pdata$fleet = Pdata$state
Pdata$stratification = Pdata$fleet

PdataAge = Pdata #set up for age comps later

Pdata <- Pdata[!is.na(Pdata[, 'length']),] #Remove fish without lengths. Do this here because some of these (11) have ages


#################################################################################
# Length comp expansions
#################################################################################

Pdata_exp <- getExpansion_1(Pdata = Pdata,
                            fa = fa, fb = fb, ma = ma, mb = mb, ua = ua, ub = ub)

Pdata_exp <- getExpansion_2(Pdata = Pdata_exp, 
                            Catch = catch.file, 
                            Units = "MT",
                            maxExp = 0.80)

Pdata_exp$Final_Sample_Size <- capValues(Pdata_exp$Expansion_Factor_1_L * Pdata_exp$Expansion_Factor_2, maxVal = 0.80)

# Set up lengths bins based on length sizes for all comps
myLbins = c(seq(10, 50, 2))

calcSamplesL() #run function (at end) to report and save sample sizes by sex

# Since quillback is a single sex model I am going to change all fish to be unsexed.
Pdata_exp$SEX = "U"

Lcomps = getComps(Pdata_exp, Comps = "LEN")

writeComps(inComps = Lcomps, 
           fname = file.path(dir, "forSS", "Lcomps.QLBK.Feb.2021.csv"), 
           lbins = myLbins, 
           partition = 0, 
           sum1 = TRUE,
           digits = 4)
































################################
#Load RecFIN length BDS data, check for any issues
################################

recfin_bdsWA = read.csv(file.path(dir, "RecFIN_SD001_WA_canary_1983_2021.csv"),header=TRUE)
recfin_bdsOR = read.csv(file.path(dir, "RecFIN_SD001_OR_canary_1999_2021.csv"),header=TRUE)
recfin_bdsCA = read.csv(file.path(dir, "RecFIN_SD001_CA_canary_2003_2021.csv"),header=TRUE)
recfin_bds = rbind(recfin_bdsWA,recfin_bdsOR,recfin_bdsCA)


################################
#Load Washington provided Sport and Research BDS data, check for any issues
#################################

#Only need to pull from googledrive once
# googledrive::drive_download(file = "WA_CanaryBiodata2023_Feb7version.xlsx",
#                             path = file.path(git_dir,"data-raw","WA_CanaryBiodata2023.xlsx"))
wa_bds_sport <- readxl::read_excel(path = file.path(git_dir,"data-raw","WA_CanaryBiodata2023.xlsx"),
                                   sheet = "Sport")
wa_bds_research <- readxl::read_excel(path = file.path(git_dir,"data-raw","WA_CanaryBiodata2023.xlsx"),
                                      sheet = "Research")

wa_bds <- rbind(wa_bds_sport, wa_bds_research[,which(names(wa_bds_research)!="fish_sample_date")])
