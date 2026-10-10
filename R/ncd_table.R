#' Publication-ready prevalence table
#'
#' Builds a formatted table of design-based prevalence (with confidence
#' intervals) for several indicators, overall and by group, ready to paste into
#' a manuscript or pass to \pkg{knitr}, \pkg{flextable} or \pkg{gt}.
#'
#' @inheritParams survey_prevalence
#' @param by Optional single grouping column; one column of the table per
#'   group, plus an "Overall" column.
#' @param labels Optional named character vector of row labels
#'   (`c(htn = "Hypertension")`).
#' @param digits Decimal places for percentages.
#' @param n_row Add a first row with the unweighted number of respondents.
#'
#' @return A data frame of class `ncd_table` whose first column is
#'   `Indicator` and whose other columns hold "estimate (lower-upper)" strings
#'   in percent. The underlying numeric estimates are in attribute
#'   `"estimates"`.
#' @examples
#' d <- ncd_survey
#' d$htn <- recode_binary(d$htn_raw, yes = 1, no = 2)
#' d$dm  <- recode_binary(d$dm_raw,  yes = 1, no = 2)
#' des <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~wt,
#'                          data = d, nest = TRUE)
#' ncd_table(des, c("htn", "dm"), by = "sex",
#'           labels = c(htn = "Hypertension", dm = "Diabetes"))
#' @export
ncd_table <- function(design, vars, by = NULL, labels = NULL, digits = 1,
                      level = 0.95, n_row = TRUE) {
  if (length(by) > 1) stop("`ncd_table()` takes a single `by` column.", call. = FALSE)
  fmt <- function(e, l, u) ifelse(is.na(e), "-",
    sprintf(paste0("%.", digits, "f (%.", digits, "f-%.", digits, "f)"), 100 * e, 100 * l, 100 * u))
  lab <- vapply(vars, function(v) if (!is.null(labels) && v %in% names(labels)) labels[[v]] else v,
                character(1))
  overall <- survey_prevalence(design, vars, level = level)
  tab <- data.frame(Indicator = unname(lab), Overall = fmt(overall$estimate, overall$lower, overall$upper),
                    stringsAsFactors = FALSE, check.names = FALSE)
  ns <- c(Overall = sum(.design_weights(design) > 0))
  est <- overall
  if (!is.null(by)) {
    grp <- survey_prevalence(design, vars, by = by, level = level)
    est <- rbind(cbind(group = "Overall", overall[, setdiff(names(overall), by)]),
                 cbind(group = as.character(grp[[by]]), grp[, setdiff(names(grp), by)]))
    for (g in unique(as.character(grp[[by]]))) {
      s <- grp[as.character(grp[[by]]) == g, ]
      s <- s[match(vars, s$indicator), ]
      tab[[g]] <- fmt(s$estimate, s$lower, s$upper)
      gv <- design$variables[[by]]
      ns[g] <- sum(!is.na(gv) & as.character(gv) == g & .design_weights(design) > 0)
    }
  }
  if (n_row) {
    tab <- rbind(c(Indicator = "Unweighted n", as.list(format(ns[names(tab)[-1]], big.mark = ","))), tab)
  }
  rownames(tab) <- NULL
  structure(tab, class = c("ncd_table", "data.frame"), estimates = est,
            note = sprintf("Design-based %% (%g%% CI)", 100 * level))
}

#' @export
print.ncd_table <- function(x, ...) {
  cat(attr(x, "note"), "\n", sep = "")
  print(as.data.frame(unclass(x)[names(x)], check.names = FALSE, stringsAsFactors = FALSE),
        row.names = FALSE, right = FALSE)
  invisible(x)
}
