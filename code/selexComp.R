####
#
#This function plots selectivities for each fleet on one panel, including all the blocks for 
#that fleet
#
#This pulls heavily from Ian Taylor and Kelli Johnson lingcod 2021 model plots at
#https://github.com/pfmc-assessments/lingcod/blob/main/R/plot_selex.R and
#https://github.com/pfmc-assessments/lingcod/blob/main/R/make_r4ss_plots_ling.R
#
#We dont have selectivity varying by sex so keeping that separate for now
####

#' Plot time-varying selectivity or selectivity
#'
#' @param mod A model object created by [get_mod()] or
#' `r4ss::SS_output()`
#' @param input A list object created by `r4ss::SS_read`
#' @param fleet a single fleet number
#' @param Factor a factor from mod$sizeselex$Factor
#' @param sex sex 1 for females, 2 for males
#' @export
#' @author Ian G. Taylor
plot_sel_ret <- function(mod,
                         fleet = 1,
                         Factor = "Lsel",
                         sex = 1,
                         legloc = "topleft", fleetnames = "default") {
  
  #input = r4ss::SS_read(mod$inputs$dir)
  
  years <- mod$startyr:mod$endyr
  # run selectivity function to get table of info on time blocks etc.
  # NOTE: this writes a png file to unfit/sel01_multiple_fleets_length1.png
  infotable <- r4ss::SSplotSelex(mod,
                                 fleets = fleet,
                                 sexes = sex,
                                 sizefactors = Factor,
                                 years = years,
                                 subplots = 1,
                                 plot = FALSE,
                                 print = TRUE,
                                 plotdir = mod$inputs$dir,
                                 fleetnames = fleetnames
  )$infotable
  # remove extra file (would need to sort out the relative path stuff)
  file.remove(file.path(mod$inputs$dir, "sel01_multiple_fleets_length1.png"))
  nlines <- nrow(infotable)
  infotable$col <- r4ss::rich.colors.short(max(6,nlines), alpha = 0.7) %>%
    rev() %>% tail(nlines)
  infotable$pch <- NA
  infotable$lty <- nrow(infotable):1
  infotable$lwd <- 3
  infotable$longname <- infotable$Yr_range
  # if(fleet == 9) { #fix table for WA rec which reports out separate 2021 and 2022
  #   newinfo <- infotable[c(1,2,4),]
  #   newinfo$lty <- infotable[2:4,"lty"]
  #   newinfo$col <- infotable[2:4,"col"]
  #   newinfo[3,c("longname","Yr_range")] <- c("2021-2022","2021-2022")
  #   infotable <- newinfo[-3,]
  # }
  if(fleet == 9) { #If running on STAR models with simplified base model use this
    newinfo <- infotable[c(1,2,4),]
    newinfo$lty <- infotable[2:4,"lty"]
    newinfo$col <- infotable[2:4,"col"]
    newinfo[3,c("longname","Yr_range")] <- c("2021-2022","2021-2022")
    infotable <- newinfo
  }
  # run plot function again, passing in the modified infotable
  r4ss::SSplotSelex(mod,
                    fleets = fleet,
                    sexes = sex,
                    sizefactors = Factor,
                    labels = c(
                      "Length (cm)",
                      "Age (yr)",
                      "Year",
                      ifelse(Factor == "Lsel", "Selectivity", "Retention"),
                      "Retention",
                      "Discard mortality"
                    ),
                    legendloc = legloc,
                    years = 1892:2021,
                    subplots = 1,
                    plot = TRUE,
                    print = FALSE,
                    infotable = infotable,
                    mainTitle = FALSE,
                    mar = c(2,2,2,1),
                    plotdir = mod$inputs$dir,
                    fleetnames = fleetnames
  )
  mtext(infotable$FleetName, side = 3, line = 0.1)
}

#' Plot selectivity and retention for the commercial fleets
#'
#' @param mod A model object created by [get_mod()] or
#' `r4ss::SS_output()`
#' @param sex Either 1 (females) or 2 (males)
#' @export
#' @author Ian G. Taylor
plot_sel_comm <- function(mod, sex = 1, fleetnames = "default") {
  
  graphics.off()
  
  filename <- "selectivity_comm.png"
  if (sex == 2) {
    filename <- gsub(".png", "_males.png", filename)
  }
  filepath <- file.path(mod$inputs$dir, filename)
  png(filepath, width = 6.5, height = 6.5, units = "in", res = 300, pointsize = 10)
  par(mfrow = c(4,3), oma = c(2,2,0,0), las = 1)
  
  #TWL
  plot_sel_ret(mod, Factor = "Lsel", fleet = 1, sex = sex, fleetnames = fleetnames)
  mtext("Selectivity", side = 2, line = 3, las = 0)
  plot_sel_ret(mod, Factor = "Lsel", fleet = 2, sex = sex, fleetnames = fleetnames)
  plot_sel_ret(mod, Factor = "Lsel", fleet = 3, sex = sex, fleetnames = fleetnames)
  #NTWL
  plot_sel_ret(mod, Factor = "Lsel", fleet = 4, sex = sex, fleetnames = fleetnames)
  mtext("Selectivity", side = 2, line = 3, las = 0)
  plot_sel_ret(mod, Factor = "Lsel", fleet = 5, sex = sex, fleetnames = fleetnames)
  plot_sel_ret(mod, Factor = "Lsel", fleet = 6, sex = sex, fleetnames = fleetnames)
  #FOREIGN
  plot_sel_ret(mod, Factor = "Lsel", fleet = 13, sex = sex, fleetnames = fleetnames)
  mtext("Selectivity", side = 2, line = 3, las = 0)
  plot_sel_ret(mod, Factor = "Lsel", fleet = 14, sex = sex, fleetnames = fleetnames)
  plot_sel_ret(mod, Factor = "Lsel", fleet = 15, sex = sex, fleetnames = fleetnames)
  #ASHOP
  plot_sel_ret(mod, Factor = "Lsel", fleet = 10, sex = sex, fleetnames = fleetnames)
  mtext("Selectivity", side = 2, line = 3, las = 0)
  mtext("Length (cm)", side = 1, line = 2.5)
  plot_sel_ret(mod, Factor = "Lsel", fleet = 11, sex = sex, fleetnames = fleetnames)
  mtext("Length (cm)", side = 1, line = 2.5)
  plot_sel_ret(mod, Factor = "Lsel", fleet = 12, sex = sex, fleetnames = fleetnames)
  mtext("Length (cm)", side = 1, line = 2.5)
  
  dev.off()
  
  print(paste0("Plot in ", filepath))
}


#' Plot selectivity and retention for the non-commercial fleets
#'
#' @param mod A model object created by [get_mod()] or
#' `r4ss::SS_output()`
#' @param sex Either 1 (females) or 2 (males)
#' @param spatial TRUE/FALSE on whether the model is spatial
#' @export
#' @author Ian G. Taylor
plot_sel_noncomm <- function(mod, sex = 1, spatial = TRUE, fleetnames = "default") {
  
  graphics.off()
  
  filename <- "selectivity_noncomm.png"
  if (sex == 2) {
    filename <- gsub(".png", "_males.png", filename)
  }
  filepath <- file.path(mod$inputs$dir, filename)
  png(filepath, width = 6.5, height = 6.5, units = "in", res = 300, pointsize = 10)
  
  if(spatial) {
    par(mfrow = c(4,3), oma = c(2,2,0,0), las = 1)
    
    #REC
    plot_sel_ret(mod, Factor = "Lsel", fleet = 7, sex = sex, fleetnames = fleetnames)
    mtext("Selectivity", side = 2, line = 3, las = 0)
    plot_sel_ret(mod, Factor = "Lsel", fleet = 8, sex = sex, fleetnames = fleetnames)
    plot_sel_ret(mod, Factor = "Lsel", fleet = 9, sex = sex, fleetnames = fleetnames)
    #NWFSC trawl
    plot_sel_ret(mod, Factor = "Lsel", fleet = 16, sex = sex, fleetnames = fleetnames)
    mtext("Selectivity", side = 2, line = 3, las = 0)
    plot_sel_ret(mod, Factor = "Lsel", fleet = 17, sex = sex, fleetnames = fleetnames)
    plot_sel_ret(mod, Factor = "Lsel", fleet = 18, sex = sex, fleetnames = fleetnames)
    #Triennial early
    plot_sel_ret(mod, Factor = "Lsel", fleet = 19, sex = sex, fleetnames = fleetnames)
    mtext("Selectivity", side = 2, line = 3, las = 0)
    plot_sel_ret(mod, Factor = "Lsel", fleet = 20, sex = sex, fleetnames = fleetnames)
    plot_sel_ret(mod, Factor = "Lsel", fleet = 21, sex = sex, fleetnames = fleetnames)
    #Triennial late
    plot_sel_ret(mod, Factor = "Lsel", fleet = 22, sex = sex, fleetnames = fleetnames)
    mtext("Selectivity", side = 2, line = 3, las = 0)
    mtext("Length (cm)", side = 1, line = 2.5)
    plot_sel_ret(mod, Factor = "Lsel", fleet = 23, sex = sex, fleetnames = fleetnames)
    mtext("Length (cm)", side = 1, line = 2.5)
    plot_sel_ret(mod, Factor = "Lsel", fleet = 24, sex = sex, fleetnames = fleetnames)
    mtext("Length (cm)", side = 1, line = 2.5)
    
  }
  
  if(!spatial) {
    par(mfrow = c(2,3), oma = c(2,2,0,0), las = 1)
    
    #REC
    plot_sel_ret(mod, Factor = "Lsel", fleet = 7, sex = sex, legloc = "topright", fleetnames = fleetnames)
    mtext("Selectivity", side = 2, line = 3, las = 0)
    plot_sel_ret(mod, Factor = "Lsel", fleet = 8, sex = sex, legloc = "topright", fleetnames = fleetnames)
    plot_sel_ret(mod, Factor = "Lsel", fleet = 9, sex = sex, legloc = "topright", fleetnames = fleetnames)
    #NWFSC trawl coastal
    plot_sel_ret(mod, Factor = "Lsel", fleet = 28, sex = sex, fleetnames = fleetnames)
    mtext("Selectivity", side = 2, line = 3, las = 0)
    mtext("Length (cm)", side = 1, line = 2.5)
    #Triennial early coastal
    plot_sel_ret(mod, Factor = "Lsel", fleet = 29, sex = sex, fleetnames = fleetnames)
    mtext("Length (cm)", side = 1, line = 2.5)
   #Triennial late coastal
    plot_sel_ret(mod, Factor = "Lsel", fleet = 30, sex = sex, fleetnames = fleetnames)
    mtext("Length (cm)", side = 1, line = 2.5)
    
  }
  
  dev.off()
  
  print(paste0("Plot in ", filepath))
}


