#' Table of length and age comp Francis weights
#' (doesn't yet include other data types)
#'
#' @param output A list from [r4ss::SS_output].
#' @param caption A character string for the caption.
#' @param caption_extra Additional model-specific information pasted
#' at the end of the caption
#' @param label A character string with the label for the table.
#' No underscores allowed.
#' @param dataframe Instead of a tex table create a dataframe
#' @author Kelli F. Johnson, Ian G. Taylor
#'
table_compweight <- function(output,
                             caption = paste(
                               "Data weightings applied to length and age compositions",
                               "according to the `Francis' method. `Obs.' refers to the number of unique",
                               "composition vectors included in the likelihood. `N input' and `N adj.'",
                               "refer to the sample sizes of those vectors before and after being adjusted",
                               "by the the weights."
                             ),
                             caption_CAAL = "`CAAL' is conditional age-at-length data.",
                             caption_extra = "",
                             label = "table-compweight-base",
                             dataframe = FALSE,
                             fleetnames = "default") {
  # figure out which fleets have conditional age at length data
  CAAL_fleets <- output[["condbase"]][["Fleet"]] %>% unique()
  Age_fleets <- output[["agedbase"]][["Fleet"]] %>% unique()
  CAAL_fleets <- setdiff(CAAL_fleets, Age_fleets)
  
  df = dplyr::bind_rows(
    .id = "Type",
    Length = output[["Length_Comp_Fit_Summary"]],
    Age = output[["Age_Comp_Fit_Summary"]] %>% dplyr::filter(Fleet %in% Age_fleets),
    CAAL = output[["Age_Comp_Fit_Summary"]] %>% dplyr::filter(Fleet %in% CAAL_fleets)
  ) %>%
    # dplyr::mutate(Fleet = get_fleet(col = "label_long")[match(Fleet_name, get_fleet(col = "fleet"))]) %>%
    dplyr::mutate(Fleet = output[["FleetNames"]][Fleet]) %>%
    dplyr::mutate("Sum N adj." = mean_Nsamp_adj * Npos) %>%
    dplyr::select(
      Type,
      Fleet,
      "Francis" = Curr_Var_Adj,
      "Obs." = Npos,
      "Mean N input" = mean_Nsamp_in,
      "Mean N adj." = mean_Nsamp_adj,
      "Sum N adj."
    ) %>%
    dplyr::mutate(Francis = sprintf("%.3f", Francis)) %>% # round to 2 places
    dplyr::mutate_at(5:7, ~ sprintf("%.1f", .x)) # round to 1 places
  
  #Remove number from names and change NWFSC to WCGBTS (this is specific to the canary 2023 model)
  if(fleetnames != "default"){
    short.names <- stringr::str_remove(df$Fleet, '[:digit:]+_') |>
      stringr::str_remove('coastwide_') |>
      stringr::str_replace('NWFSC', 'WCGBTS')
    df$Fleet <- short.names
  }
    
  if(dataframe == FALSE){
      kableExtra::kbl(df,
        row.names = FALSE,
        longtable = FALSE, booktabs = TRUE,
        label = label,
        caption = paste(
          caption,
          ifelse(length(CAAL_fleets) > 0, caption_CAAL, ""),
          caption_extra
        ),
        format = "latex",
        linesep = ""
        )
  }else{
    return(df)
  }
}