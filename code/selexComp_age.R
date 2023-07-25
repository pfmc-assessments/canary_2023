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
plot_sel_ret_age <- function(mod,
                         fleet = 1,
                         Factor = "Asel2",
                         subplots = 2,
                         sex = 1,
                         legloc = "topleft") {
  
  #input = r4ss::SS_read(mod$inputs$dir)

  years <- mod$startyr:mod$endyr
  # run selectivity function to get table of info on time blocks etc.
  # NOTE: this writes a png file to unfit/sel01_multiple_fleets_length1.png
  infotable <- r4ss::SSplotSelex(mod,
                                 fleets = fleet,
                                 sexes = sex,
                                 years = years,
                                 subplots = subplots,
                                 agefactors = Factor,
                                 plot = FALSE,
                                 print = TRUE,
                                 plotdir = mod$inputs$dir
  )$infotable
  # remove extra file (would need to sort out the relative path stuff)
  file.remove(file.path(mod$inputs$dir, "sel02_multiple_fleets_age1.png"))
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
  #   infotable <- newinfo
  # }
  # run plot function again, passing in the modified infotable
  r4ss::SSplotSelex(mod,
                    fleets = fleet,
                    sexes = sex,
                    agefactors = Factor,
                    labels = c(
                      "Length (cm)",
                      "Age (yr)",
                      "Year",
                      ifelse(Factor == "Lsel", "Selectivity", "Retention"),
                      "Retention",
                      "Discard mortality"
                    ),
                    legendloc = legloc,
                    years = 1892:2022,
                    subplots = subplots,
                    plot = TRUE,
                    print = FALSE,
                    infotable = infotable,
                    mainTitle = FALSE,
                    mar = c(2,2,2,1),
                    plotdir = mod$inputs$dir
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
plot_sel_comm_age <- function(mod, sex = 1, fact = "Asel2") {
  
  graphics.off()
  
  filename <- "selectivity_comm_Asel.png"
  if (sex == 2) {
    filename <- gsub(".png", "_males.png", filename)
  }
  filepath <- file.path(mod$inputs$dir, filename)
  png(filepath, width = 6.5, height = 6.5, units = "in", res = 300, pointsize = 10)
  par(mfrow = c(4,3), oma = c(2,2,0,0), las = 1)
  
  #TWL
  plot_sel_ret_age(mod, Factor = fact, fleet = 1, sex = sex)
  mtext("Selectivity", side = 2, line = 3, las = 0)
  plot_sel_ret_age(mod, Factor = fact, fleet = 2, sex = sex)
  plot_sel_ret_age(mod, Factor = fact, fleet = 3, sex = sex)
  #NTWL
  plot_sel_ret_age(mod, Factor = fact, fleet = 4, sex = sex)
  mtext("Selectivity", side = 2, line = 3, las = 0)
  plot_sel_ret_age(mod, Factor = fact, fleet = 5, sex = sex)
  plot_sel_ret_age(mod, Factor = fact, fleet = 6, sex = sex)
  #FOREIGN
  plot_sel_ret_age(mod, Factor = fact, fleet = 13, sex = sex)
  mtext("Selectivity", side = 2, line = 3, las = 0)
  plot_sel_ret_age(mod, Factor = fact, fleet = 14, sex = sex)
  plot_sel_ret_age(mod, Factor = fact, fleet = 15, sex = sex)
  #ASHOP
  plot_sel_ret_age(mod, Factor = fact, fleet = 10, sex = sex)
  mtext("Selectivity", side = 2, line = 3, las = 0)
  mtext("Age", side = 1, line = 2.5)
  plot_sel_ret_age(mod, Factor = fact, fleet = 11, sex = sex)
  mtext("Age", side = 1, line = 2.5)
  plot_sel_ret_age(mod, Factor = fact, fleet = 12, sex = sex)
  mtext("Age", side = 1, line = 2.5)
  
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
plot_sel_noncomm_age <- function(mod, sex = 1, spatial = TRUE, fact = "Asel2") {
  
  graphics.off()
  
  filename <- "selectivity_noncomm_Asel.png"
  if (sex == 2) {
    filename <- gsub(".png", "_males.png", filename)
  }
  filepath <- file.path(mod$inputs$dir, filename)
  png(filepath, width = 6.5, height = 6.5, units = "in", res = 300, pointsize = 10)
  
  par(mfrow = c(4,3), oma = c(2,2,0,0), las = 1)
    
  #REC
  plot_sel_ret_age(mod, Factor = fact, fleet = 7, sex = sex, legloc = "topright")
  mtext("Selectivity", side = 2, line = 3, las = 0)
  plot_sel_ret_age(mod, Factor = fact, fleet = 8, sex = sex, legloc = "topright")
  plot_sel_ret_age(mod, Factor = fact, fleet = 9, sex = sex, legloc = "topright")
  #NWFSC trawl coastal
  plot_sel_ret_age(mod, Factor = fact, fleet = 28, sex = sex)
  mtext("Selectivity", side = 2, line = 3, las = 0)
  mtext("Age", side = 1, line = 2.5)
  #Triennial early coastal
  plot_sel_ret_age(mod, Factor = fact, fleet = 29, sex = sex)
  mtext("Age", side = 1, line = 2.5)
 #Triennial late coastal
  plot_sel_ret_age(mod, Factor = fact, fleet = 30, sex = sex)
  mtext("Age", side = 1, line = 2.5)
  
  dev.off()
  
  print(paste0("Plot in ", filepath))
}


