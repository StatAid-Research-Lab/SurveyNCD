#' Sensitivity of multimorbidity prevalence to "don't know" answers
#'
#' Missing answers (for example "don't know") make multimorbidity prevalence
#' uncertain beyond sampling error. This function reports three design-based
#' estimates: the complete-case estimate (respondents with any missing answer
#' excluded), a lower bound (every missing answer treated as "no") and an
#' upper bound (every missing answer treated as "yes"). The bounds contain
#' the prevalence under any assumption about the missing answers; the
#' complete-case estimate is unbiased only if answers are missing completely
#' at random.
#'
#' @param design A survey design containing the 0/1 condition columns
#'   (with `NA` for missing answers).
#' @param conditions Character vector of condition columns.
#' @param threshold Number of conditions defining multimorbidity.
#' @param by Optional character vector of grouping columns.
#' @param level Confidence level.
#'
#' @return A data frame with `scenario` ("complete case", "lower bound",
#'   "upper bound"), any `by` columns, `n`, `estimate`, `se`, `lower` and
#'   `upper`.
#' @examples
#' d <- ncd_survey
#' for (v in c("htn", "dm", "arth"))
#'   d[[v]] <- suppressWarnings(recode_binary(d[[paste0(v, "_raw")]], yes = 1, no = 2))
#' des <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~wt,
#'                          data = d, nest = TRUE)
#' mm_bounds(des, c("htn", "dm", "arth"))
#' @export
mm_bounds <- function(design, conditions, threshold = 2, by = NULL, level = 0.95) {
  .check_design(design)
  .check_vars(design, conditions, "Condition column")
  m <- sapply(conditions, function(v) .check_binary(design$variables[[v]], v))
  m <- matrix(m, ncol = length(conditions))
  any_na <- rowSums(is.na(m)) > 0
  m0 <- m; m0[is.na(m0)] <- 0
  m1 <- m; m1[is.na(m1)] <- 1
  design <- .set_var(design, ".sncd_cc", ifelse(any_na, NA, as.numeric(rowSums(m0) >= threshold)))
  design <- .set_var(design, ".sncd_lo", as.numeric(rowSums(m0) >= threshold))
  design <- .set_var(design, ".sncd_hi", as.numeric(rowSums(m1) >= threshold))
  est <- survey_prevalence(design, c(".sncd_cc", ".sncd_lo", ".sncd_hi"), by = by, level = level)
  lab <- c(.sncd_cc = "complete case", .sncd_lo = "lower bound (missing = no)",
           .sncd_hi = "upper bound (missing = yes)")
  out <- data.frame(scenario = unname(lab[est$indicator]), est[, setdiff(names(est), c("indicator", "deff")), drop = FALSE],
                    stringsAsFactors = FALSE)
  rownames(out) <- NULL
  out
}
