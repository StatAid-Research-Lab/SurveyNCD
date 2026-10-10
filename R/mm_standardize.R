#' WHO World Standard Population
#'
#' The WHO World Standard Population (world average population 2000-2025;
#' Ahmad et al. 2001), optionally re-aggregated to custom age groups such as
#' the 18-29, 30-44, 45-59 and 60-69 groups used in STEPS reports.
#'
#' The standard is published in 5-year groups. For `breaks` that are not
#' multiples of 5 (e.g. 18), the share of a 5-year group falling inside an
#' interval is assumed proportional to the years it covers (uniform age
#' distribution within the group). The 100+ group is treated as 100-104.
#'
#' @param breaks Optional increasing numeric vector of age-group boundaries.
#'   Intervals are `[breaks[i], breaks[i + 1])`; the last boundary is the
#'   (exclusive) upper limit. `NULL` returns the 21 published groups.
#' @param labels Optional labels for the intervals.
#'
#' @return A data frame with `age_group`, `lower`, `upper` (exclusive) and
#'   `weight`, where `weight` sums to 1.
#' @references
#' Ahmad, O. B., Boschi-Pinto, C., Lopez, A. D., Murray, C. J. L., Lozano, R.,
#' & Inoue, M. (2001). \emph{Age standardization of rates: A new WHO standard}.
#' GPE Discussion Paper Series No. 31. Geneva: World Health Organization.
#' @examples
#' who_standard_population()
#' who_standard_population(breaks = c(18, 30, 45, 60, 70))
#' @export
who_standard_population <- function(breaks = NULL, labels = NULL) {
  pct <- c(8.86, 8.69, 8.60, 8.47, 8.22, 7.93, 7.61, 7.15, 6.59, 6.04, 5.37,
           4.55, 3.72, 2.96, 2.21, 1.52, 0.91, 0.44, 0.15, 0.04, 0.005)
  lo <- seq(0, 100, by = 5)
  base <- data.frame(
    age_group = c(paste0(lo[-21], "-", lo[-21] + 4), "100+"),
    lower = lo, upper = lo + 5, weight = pct / sum(pct),
    stringsAsFactors = FALSE
  )
  if (is.null(breaks)) return(base)
  if (!is.numeric(breaks) || length(breaks) < 2 || is.unsorted(breaks, strictly = TRUE) ||
      breaks[1] < 0 || breaks[length(breaks)] > 105) {
    stop("`breaks` must be an increasing numeric vector between 0 and 105.", call. = FALSE)
  }
  k <- length(breaks) - 1
  w <- vapply(seq_len(k), function(i) {
    ov <- pmax(0, pmin(base$upper, breaks[i + 1]) - pmax(base$lower, breaks[i]))
    sum(base$weight * ov / 5)
  }, numeric(1))
  if (is.null(labels)) labels <- paste0(breaks[-(k + 1)], "-", breaks[-1] - 1)
  data.frame(age_group = labels, lower = breaks[-(k + 1)], upper = breaks[-1],
             weight = w / sum(w), stringsAsFactors = FALSE)
}

#' Age-standardised prevalence from a survey design
#'
#' Direct age standardisation of one or more 0/1 indicators using
#' [survey::svystandardize()], so that standard errors reflect the survey
#' design. Crude (unstandardised) estimates are returned alongside.
#'
#' @param design A survey design.
#' @param vars Character vector of 0/1 indicator columns (for example
#'   `"mm_multimorbid"` from [multimorbidity_index()]).
#' @param age_group Name of a factor (or character) column of age groups.
#' @param standard Standard population: a data frame with columns
#'   `age_group` and `weight` (as returned by [who_standard_population()]), or
#'   a named numeric vector. Every age group in the data must appear in it.
#' @param by Optional character vector of grouping columns (standardisation
#'   is done within each group).
#' @param level Confidence level.
#'
#' @return A data frame with `indicator`, any `by` columns, `n`, `crude`,
#'   `standardized`, `se`, `lower` and `upper` (Wald interval for the
#'   standardised estimate).
#' @examples
#' d <- ncd_survey
#' d$htn <- recode_binary(d$htn_raw, yes = 1, no = 2)
#' d$age_group <- cut(d$age, c(18, 30, 45, 60, 70), right = FALSE,
#'                    labels = c("18-29", "30-44", "45-59", "60-69"))
#' des <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~wt,
#'                          data = d, nest = TRUE)
#' std <- who_standard_population(breaks = c(18, 30, 45, 60, 70))
#' mm_standardize(des, "htn", age_group = "age_group", standard = std, by = "sex")
#' @export
mm_standardize <- function(design, vars, age_group, standard, by = NULL, level = 0.95) {
  .check_design(design)
  .check_vars(design, c(vars, age_group, by))
  old <- .lonely_adjust(); on.exit(options(old), add = TRUE)

  if (is.data.frame(standard)) {
    if (!all(c("age_group", "weight") %in% names(standard))) {
      stop("`standard` must have columns `age_group` and `weight`.", call. = FALSE)
    }
    std <- stats::setNames(standard$weight, standard$age_group)
  } else if (is.numeric(standard) && !is.null(names(standard))) {
    std <- standard
  } else {
    stop("`standard` must be a data frame from who_standard_population() or a named numeric vector.",
         call. = FALSE)
  }
  ag <- as.character(design$variables[[age_group]])
  present <- sort(unique(ag[!is.na(ag)]))
  miss <- setdiff(present, names(std))
  if (length(miss) > 0) {
    stop("Age group(s) not in `standard`: ", paste(miss, collapse = ", "), call. = FALSE)
  }
  lev <- names(std)[names(std) %in% present]
  std <- std[lev] / sum(std[lev])
  design <- .set_var(design, ".sncd_age", factor(ag, levels = lev))

  out <- list()
  for (v in vars) {
    design <- .set_var(design, v, .check_binary(design$variables[[v]], v))
    dv <- design[!is.na(design$variables[[v]]) & !is.na(design$variables$.sncd_age), ]
    doms <- .domains(dv, by)
    out[[v]] <- do.call(rbind, lapply(doms, function(g) {
      d <- g$design
      f <- .formula(v)
      crude <- as.numeric(survey::svymean(f, d))
      lv <- levels(droplevels(d$variables$.sncd_age[.design_weights(d) > 0]))
      w <- std[lv] / sum(std[lv])
      d2 <- d[d$variables$.sncd_age %in% lv & .design_weights(d) > 0, ]
      d2 <- .set_var(d2, ".sncd_age", factor(as.character(d2$variables$.sncd_age), levels = lv))
      sd <- survey::svystandardize(d2, by = ~.sncd_age, over = ~1, population = unname(w))
      m <- survey::svymean(f, sd)
      est <- as.numeric(m); se <- as.numeric(survey::SE(m))
      z <- stats::qnorm(1 - (1 - level) / 2)
      .bind_key(g$key, data.frame(
        indicator = v, n = sum(.design_weights(d) > 0), crude = crude,
        standardized = est, se = se, lower = est - z * se, upper = est + z * se,
        stringsAsFactors = FALSE))
    }))
  }
  out <- do.call(rbind, out)
  rownames(out) <- NULL
  out[, c("indicator", setdiff(names(out), "indicator"))]
}
