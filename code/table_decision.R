#' Format a decision table
#'
#' Format a decision table for its inclusion in a document.
#'
#' @param ... Each element provided in the call to this function that is not
#' assigned to a particular input argument should be a vector of file paths
#' to the models you want to read for a given column of your decision table.
#' For example, if a single column has results from three models and
#' if your decision table has a low and high state of nature, then
#' there should be two vectors passed via `...` and each vector would contain
#' paths to three different models.
#' The order of the vectors will be the column order from left to right.
#' The order of the models within a vector will be the row order.
#' @param years A vector of years you want catches for.
#' @template format
#' @param caption A character string that
#' will be passed to the `caption` parameter of [kableExtra::kbl].
#' The default value is `NULL`.
#' @param label A character string without underscores that
#' will be passed to the `label` parameter of [kableExtra::kbl].
#' The default value is `NULL`.
#' @param digits A vector of digits for catch, spawning output, and fraction, 
#' unfished. It gets passed to `r4ss::SS_decision_table_stuff()`.
#' @export
#' @author Kelli F. Johnson, Ian G. Taylor, Chantel R. Wetzel
#' @examples
#' table_decision(
#'   list(mod.low.A, mod.base.A, mod.high.A),
#'   list(mod.low.B, mod.base.B, mod.high.B),
#'   list(mod.low.C, mod.base.C, mod.high.C)
#' )
table_decision <- function(
    ...,
    years = 2023:2034,
    format = c("latex", "html"),
    caption = formals(kableExtra::kbl)$caption,
    label = formals(kableExtra::kbl)$label,
    digits = c(0, 2, 3)) {
  mods <- list(...)
  # make sure that the format input is good
  # chooses first option by default
  format <- match.arg(format)
  
  # hardwired to prevent users from adding too-long inputs
  rowgroup <- c("A", "B", "C")
  
  # process output
  results <- purrr::modify_depth(
    mods,
    .depth = 2,
    .f = r4ss::SS_decision_table_stuff,
    yrs = years, digits = digits
  ) %>%
    purrr::modify_depth(1, dplyr::bind_cols) %>%
    dplyr::bind_rows(.id = "Mgmt") %>%
    dplyr::mutate(
      Mgmt = rowgroup[as.numeric(Mgmt)],
      # Catch = pmax(na.rm = TRUE, !!!rlang::syms(grep(value = TRUE, "catch", names(.))))
    ) %>%
    dplyr::rename(Year = "yr...1") %>%
    dplyr::select_if(!grepl("yr\\.+", colnames(.))) # %>%
  
  # get the catch columns and warn if they aren't all equal
  # (simpler than trying to automatically italicize values associated
  # with mismatched catch which had issues for lingcod)
  catch_cols <- results %>% dplyr::select(dplyr::starts_with("catch"))
  if (max(abs(apply(catch_cols, 1, sd))) > 0.01) {
    warning("Catch differs among columns, perhaps due to a crashed model without enough biomass.")
  }
  
  # clean up column names and remove extra catch columns
  # first rename the first catch column
  results <- results %>%
    dplyr::rename(Catch = "catch...2") %>%
    dplyr::select(-dplyr::starts_with("catch", ignore.case = FALSE))
  
  # remove repeated lables in Mgmt column
  results <- results %>% 
    dplyr::mutate(Mgmt = ifelse(duplicated(Mgmt), "", Mgmt))
  
  # # add horizontal lines between groups (only works in latex) 
  # # only works if Mgmt column has single value at the top of each group
  # results <- results %>% 
  #   kableExtra::row_spec(row = which(results$Mgmt != "")[-1] - 1, 
  #     hline_after = TRUE)
  
  # add color to the depletion column
  results <- results %>%
    dplyr::mutate_at(
      .vars = dplyr::vars(grep(value = TRUE, "^dep", colnames(.))),
      ~ kableExtra::cell_spec(
        format = format,
        x = .,
        color = "white",
        background = kableExtra::spec_color(
          .,
          begin = 0, end = 1,
          option = "D",
          scale_from = c(0, 1),
          direction = -1
        )
      )
    )
  
  # add column names
  rownames(results) <- NULL
  colnames(results) <- c(
    "Mgmt", "Year", "Catch", "Low Spawn M=0.072", "Low Frac M=0.072",
    "Base Spawn M=0.142", "Base Frac M=0.142", "High Spawn M=0.219", "High Frac M=0.219"
  )
  
  results %>%
    kableExtra::kbl(
      format = format,
      escape = FALSE,
      booktabs = TRUE,
      linesep = rep(c(rep("", length(years) - 1), "\\addlinespace"), 2),
      align = c("l", "l", "r", rep(c("r", "r"), 3)),
      caption = caption,
      label = label
    ) %>%
    kableExtra::column_spec(c(1), bold = TRUE) %>% # first column bold
    # kableExtra::column_spec(c(1, 3, 3+2*3, border_right = TRUE) %>% # vertical lines (not really needed)
    kableExtra::column_spec(3,
                            color = "white", # white text
                            background = kableExtra::spec_color(results[["Catch"]], # background coloring for catch columns
                                                                begin = 0.3,
                                                                end = 0.7,
                                                                option = "E",
                                                                direction = -1
                            )
    ) %>%
    kableExtra::column_spec(4:NCOL(results), width = "3.5em") %>%
    kableExtra::kable_classic(full_width = FALSE)
}