#' Most common combinations of conditions (multimorbidity patterns)
#'
#' Design-based prevalence of every pair (or triad, ...) of conditions, with
#' the ratio of observed to expected prevalence. The expected prevalence is
#' the product of the single-condition prevalences, i.e. what would be seen if
#' the conditions occurred independently; ratios above 1 indicate conditions
#' that cluster together.
#'
#' A respondent counts towards a combination only if all of its conditions
#' are answered; combinations are estimated by domain estimation on those
#' respondents. Single-condition prevalences for the expected value are each
#' estimated on respondents who answered that condition.
#'
#' @param design A survey design containing the 0/1 condition columns.
#' @param conditions Character vector of 0/1 condition columns.
#' @param order Size of the combinations: 2 for pairs (default), 3 for triads.
#' @param top Keep only the `top` most prevalent combinations (`NULL` keeps all).
#' @param level Confidence level.
#'
#' @return A data frame of class `surveyncd_patterns` with columns
#'   `combination`, `n`, `prevalence`, `se`, `lower`, `upper`, `expected` and
#'   `oe_ratio`, sorted by prevalence.
#' @examples
#' d <- ncd_survey
#' for (v in c("htn", "dm", "arth", "angina"))
#'   d[[v]] <- suppressWarnings(recode_binary(d[[paste0(v, "_raw")]], yes = 1, no = 2))
#' des <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~wt,
#'                          data = d, nest = TRUE)
#' mm_patterns(des, c("htn", "dm", "arth", "angina"))
#' @export
mm_patterns <- function(design, conditions, order = 2, top = NULL, level = 0.95) {
  .check_design(design)
  .check_vars(design, conditions, "Condition column")
  if (length(conditions) < order) {
    stop("Need at least `order` (", order, ") conditions.", call. = FALSE)
  }
  for (v in conditions) design <- .set_var(design, v, .check_binary(design$variables[[v]], v))

  marg <- survey_prevalence(design, conditions, level = level)
  p1 <- stats::setNames(marg$estimate, marg$indicator)

  combos <- utils::combn(conditions, order, simplify = FALSE)
  nm <- vapply(combos, paste, character(1), collapse = " + ")
  tmp <- paste0(".combo", seq_along(combos))
  for (i in seq_along(combos)) {
    m <- as.matrix(design$variables[, combos[[i]], drop = FALSE])
    design <- .set_var(design, tmp[i], ifelse(rowSums(is.na(m)) > 0, NA, as.numeric(rowSums(m) == order)))
  }
  est <- survey_prevalence(design, tmp, level = level)
  out <- data.frame(
    combination = nm,
    n           = est$n,
    prevalence  = est$estimate,
    se          = est$se,
    lower       = est$lower,
    upper       = est$upper,
    expected    = vapply(combos, function(cc) prod(p1[cc]), numeric(1)),
    stringsAsFactors = FALSE
  )
  out$oe_ratio <- out$prevalence / out$expected
  out <- out[order(-out$prevalence), , drop = FALSE]
  if (!is.null(top)) out <- utils::head(out, top)
  rownames(out) <- NULL
  structure(out, class = c("surveyncd_patterns", "data.frame"), order = order)
}
