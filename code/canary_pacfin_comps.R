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
#Load PacFIN BDS data and set up data
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
colnames(catch.file)[1] = c("year")

# Clean up length data
pacfin[pacfin$FISH_LENGTH_UNITS %in% "UNK", "FISH_LENGTH_UNITS"] = "CM" #these are CMs - need to do first so cleanPacFIN runs
Pdata = cleanPacFIN(Pdata = pacfin, 
                    CLEAN = TRUE,
                    keep_length_type = c("", "F", "A", "U", NA), #removes the 2 standard length samples
                    keep_sample_type = c("M","S"), #keep ALL special project samples
                    verbose = TRUE)
Pdata <- Pdata[!(Pdata$SAMPLE_TYPE %in% c("S") & Pdata$SAMPLE_YEAR>1986),] #Filter out oregon special project data after 1986

#Convert geargrouping based on fleet structure - HKL, MSC, NET, TLS as "NTWL"; TWL and TWS as "TWL"
table(pacfin$AGENCY_GEAR_CODE,pacfin$PACFIN_GEAR_CODE)
table(Pdata$GEAR,Pdata$geargroup)
fleet <- dplyr::case_when(Pdata$geargroup %in% c("HKL","MSC","NET","TLS") ~ "NTWL",
                                Pdata$geargroup %in% c("TWL","TWS") ~ "TWL")
state <- dplyr::case_when(Pdata$state == "WA" ~ "W",
                          Pdata$state == "OR" ~ "O",
                          Pdata$state == "CA" ~ "C")
Pdata$fleet <- paste(fleet, state, sep = ".")

PdataAge = Pdata #set up for age comps later

Pdata <- Pdata[!is.na(Pdata[, 'length']),] #Remove fish without lengths. Do this here because some of these (11) have ages

# PdataCoast <- Pdata #set up coast length comps for later
# PdataCoast$fleet <- sub("\\..*", "", PdataCoast$fleet) #keep only stuff before "."


#################################################################################
# Length samples and trips by area and fleet
#################################################################################

trips_sample <- Pdata %>%
  dplyr::group_by(fleet, year) %>%
  dplyr::summarise(
    Trips = length(unique(SAMPLE_NO)),
    Lengths = length(lengthcm)
  )
colnames(trips_sample)[2] <- "Year"
# write.csv(trips_sample, row.names = FALSE, file = file.path(git_dir, "data", "Canary_PacFIN_LengthComps_trips_and_samples.csv"))
#Coast samples we can sum together


#################################################################################
# Length comp expansions
#################################################################################

Pdata_exp <- getExpansion_1(Pdata = Pdata,
                            fa = fa, fb = fb, ma = ma, mb = mb, ua = ua, ub = ub)

Pdata_exp <- getExpansion_2(Pdata = Pdata_exp, 
                            Catch = catch.file, 
                            Units = "MT",
                            maxExp = 0.95,
                            stratification.cols = "fleet")

Pdata_exp$Final_Sample_Size <- capValues(Pdata_exp$Expansion_Factor_1_L * Pdata_exp$Expansion_Factor_2, maxVal = 0.80)

# Set up lengths bins based on length sizes for all comps
myLbins = c(seq(12, 66, 2))

Lcomps = getComps(Pdata_exp, Comps = "LEN")

writeComps(inComps = Lcomps, 
           fname = file.path(git_dir, "data", "Canary_PacFIN_LengthComps.csv"), 
           lbins = myLbins, 
           partition = 0, 
           sum1 = TRUE,
           digits = 4)

# ##
# #Coastal expansion
# ##
# PdataCoast_exp <- getExpansion_1(Pdata = PdataCoast,
#                             fa = fa, fb = fb, ma = ma, mb = mb, ua = ua, ub = ub)
# 
# PdataCoast_exp <- getExpansion_2(Pdata = PdataCoast_exp,
#                             Catch = data.frame("year" = catch.file$year,
#                                                "NTWL" = rowSums(catch.file[,c("NTWL.C","NTWL.O","NTWL.W")],na.rm=T),
#                                                "TWL" = rowSums(catch.file[,c("TWL.C","TWL.O","TWL.W")],na.rm=T)),
#                             Units = "MT",
#                             maxExp = 0.95,
#                             stratification.cols = "fleet")
# 
# PdataCoast_exp$Final_Sample_Size <- capValues(PdataCoast_exp$Expansion_Factor_1_L * PdataCoast_exp$Expansion_Factor_2, maxVal = 0.80)
# 
# # Set up lengths bins based on length sizes for all comps
# myLbins = c(seq(12, 66, 2))
# 
# LcompsCoast = getComps(PdataCoast_exp, Comps = "LEN")
# 
# writeComps(inComps = LcompsCoast,
#            fname = file.path(git_dir, "data", "Canary_PacFIN_Coastal_LengthComps.csv"),
#            lbins = myLbins,
#            partition = 0,
#            sum1 = TRUE,
#            digits = 4)

##############################################################################################################
# Format and rewrite
##############################################################################################################

#Have to use header = FALSE here because when TRUE I cant read each set of comps, and the variable
#names are fixed as the ones for the combined comps
out = read.csv(file.path(git_dir, "data", "Canary_PacFIN_LengthComps.csv"), skip = 3, header = FALSE)

##
#Extract Unsexed fish
##
start = which(as.character(out[,1]) %in% c(" Usexed only ")) + 2
end   = nrow(out)
cut_out = out[start:end,]
colnames(cut_out) <- out[start-1,]

ind = which(colnames(cut_out) %in% "U12"):which(colnames(cut_out) %in% "U.66") #For 2 sex model need to go to U.66
format = cbind(cut_out$fleet, cut_out$year, cut_out$month, cut_out$fleet, cut_out$sex, cut_out$partition, 
               cut_out$Ntows, cut_out$Nsamps, cut_out$InputN, cut_out[,ind])
colnames(format) = c("state", "fishyr", "month", "fleet", "sex", "part", "Ntows", "Nsamps", "InputN", colnames(cut_out[ind]))

format$state <- sub("^.*\\.","", format$state) #keep only stuff after "."
format$fleet <- sub("\\..*", "", format$fleet) #keep only stuff before "."

ca_comps = format[format$state == "C", ]
or_comps = format[format$state == "O", ]
wa_comps = format[format$state == "W", ]

##
#Extract sexed fish
##
start = 1 + 1
end   = which(as.character(out[,1]) %in% c(" Females only "))
cut_out = out[start:end,]
colnames(cut_out) <- out[1,]

ind = which(colnames(cut_out) %in% "F12"):which(colnames(cut_out) %in% "M66")
format = cbind(cut_out$fleet, cut_out$year, cut_out$month, cut_out$fleet, cut_out$sex, cut_out$partition, 
               cut_out$Ntows, cut_out$Nsamps, cut_out$InputN, cut_out[,ind])
colnames(format) = c("state", "fishyr", "month", "fleet", "sex", "part", "Ntows", "Nsamps", "InputN", colnames(cut_out[ind]))

format$state <- sub("^.*\\.","", format$state) #keep only stuff after "."
format$fleet <- sub("\\..*", "", format$fleet) #keep only stuff before "."

ca_sexed_comps = format[format$state == "C", ]
or_sexed_comps = format[format$state == "O", ]
wa_sexed_comps = format[format$state == "W", ]

#Set up same names so as to combine unsexed and sexed comps
colnames(ca_comps) <- colnames(ca_sexed_comps)
colnames(or_comps) <- colnames(or_sexed_comps)
colnames(wa_comps) <- colnames(wa_sexed_comps)

ca_all_comps = rbind(ca_comps, ca_sexed_comps)
or_all_comps = rbind(or_comps, or_sexed_comps)
wa_all_comps = rbind(wa_comps, wa_sexed_comps)

# write.csv(ca_all_comps, file = file.path(git_dir, "data", "forSS","CA_PacFIN_Lcomps_12_66_formatted.csv"), row.names = FALSE)
# write.csv(or_all_comps, file = file.path(git_dir, "data", "forSS","OR_PacFIN_Lcomps_12_66_formatted.csv"), row.names = FALSE)
# write.csv(wa_all_comps, file = file.path(git_dir, "data", "forSS","WA_PacFIN_Lcomps_12_66_formatted.csv"), row.names = FALSE)
# 

# ##
# #Coastal expansion
# ##
# out = read.csv(file.path(git_dir, "data", "Canary_PacFIN_Coastal_LengthComps.csv"), skip = 3, header = FALSE)
# 
# ##Extract Unsexed fish
# start = which(as.character(out[,1]) %in% c(" Usexed only ")) + 2
# end   = nrow(out)
# cut_out = out[start:end,]
# colnames(cut_out) <- out[start-1,]
# 
# ind = which(colnames(cut_out) %in% "U12"):which(colnames(cut_out) %in% "U.66") #For 2 sex model need to go to U.66
# format = cbind(cut_out$fleet, cut_out$year, cut_out$month, cut_out$fleet, cut_out$sex, cut_out$partition,
#                cut_out$Ntows, cut_out$Nsamps, cut_out$InputN, cut_out[,ind])
# colnames(format) = c("state", "fishyr", "month", "fleet", "sex", "part", "Ntows", "Nsamps", "InputN", colnames(cut_out[ind]))
# 
# format$state <- "coastal"
# 
# ##Extract sexed fish
# start = 1 + 1
# end   = which(as.character(out[,1]) %in% c(" Females only "))
# cut_out = out[start:end,]
# colnames(cut_out) <- out[1,]
# 
# ind = which(colnames(cut_out) %in% "F12"):which(colnames(cut_out) %in% "M66")
# format_coastal = cbind(cut_out$fleet, cut_out$year, cut_out$month, cut_out$fleet, cut_out$sex, cut_out$partition,
#                cut_out$Ntows, cut_out$Nsamps, cut_out$InputN, cut_out[,ind])
# colnames(format_coastal) = c("state", "fishyr", "month", "fleet", "sex", "part", "Ntows", "Nsamps", "InputN", colnames(cut_out[ind]))
# 
# format_coastal$state <- "coastal"
# 
# #Set up same names so as to combine unsexed and sexed comps
# colnames(format) <- colnames(format_coastal)
# 
# coastal_all_comps = rbind(format, format_coastal)
# 
# # write.csv(coastal_all_comps, file = file.path(git_dir, "data", "forSS","Coastal_PacFIN_Lcomps_12_66_formatted.csv"), row.names = FALSE)


##############################################################################################################
# Plot the comps
##############################################################################################################

