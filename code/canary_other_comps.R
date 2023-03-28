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
