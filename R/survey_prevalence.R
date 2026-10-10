#' Design-based prevalence of one or more binary indicators
#'
#' Estimates the population prevalence of each 0/1 indicator in `vars`,
#' overall or within groups defined by one or more variables, using the full
#' survey design (strata, clusters, weights). Respondents with a missing value
#' for an indicator are excluded from that indicator only, by domain
#' estimation, so the design is never broken by dropping rows.
#'
#' @param design A survey design (see [dhs_design()] or
#'   [survey::svydesign()]); \pkg{srvyr} designs are accepted.
#' @param vars Character vector of 0/1 (or logical) indicator columns.
#' @param by Optional character vector of grouping columns; estimates are
#'   produced for every observed combination.
#' @param level Confidence level.
#' @param method Confidence-interval method passed to [survey::svyciprop()];
#'   `"logit"` (default) keeps intervals inside 0-1.
#'
#' @return A data frame of class `surveyncd_prevalence` with columns
#'   `indicator`, any `by` columns, `n` (unweighted respondents with a valid
#'   answer), `estimate`, `se`, `lower`, `upper` and `deff` (design effect
#'   relative to simple random sampling with replacement).
#'
#' @seealso [ncd_table()] for a formatted table and `autoplot()` for a plot.
#' @examples
#' d <- ncd_survey
#' d$htn <- recode_binary(d$htn_raw, yes = 1, no = 2)
#' d$dm  <- recode_binary(d$dm_raw,  yes = 1, no = 2)
#' des <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~wt,
#'                          data = d, nest = TRUE)
#' survey_prevalence(des, c("htn", "dm"))
#' survey_prevalence(des, "htn", by = c("sex", "residence"))
#' @export
survey_prevalence <- function(design, vars, by = NULL, level = 0.95,
                              method = "logit") {
  .check_design(design)
  .check_vars(design, vars, "Indicator column")
  old <- .lonely_adjust(); on.exit(options(old), add = TRUE)
  for (v in vars) design <- .set_var(design, v, .check_binary(design$variables[[v]], v))

  doms <- .domains(design, by)
  out <- lapply(vars, function(v) {
    do.call(rbind, lapply(doms, function(g) {
      .bind_key(g$key, .prev_one(g$design, v, level, method))
    }))
  })
  out <- do.call(rbind, Map(function(v, df) cbind(indicator = v, df), vars, out))
  rownames(out) <- NULL
  out$indicator <- as.character(out$indicator)
  structure(out, class = c("surveyncd_prevalence", "data.frame"),
            level = level, by = by)
}

.prev_one <- function(d, v, level, method) {
  y <- d$variables[[v]]
  w <- .design_weights(d)
  ok <- !is.na(y) & w > 0
  n <- sum(ok)
  empty <- data.frame(n = n, estimate = NA_real_, se = NA_real_,
                      lower = NA_real_, upper = NA_real_, deff = NA_real_)
  if (n == 0) return(empty)
  dd <- d[!is.na(y), ]
  f <- .formula(v)
  p <- tryCatch(suppressWarnings(survey::svyciprop(f, dd, method = method, level = level)),
                error = function(e) NULL)
  if (is.null(p)) return(empty)
  ci <- attr(p, "ci")
  m <- tryCatch(suppressWarnings(survey::svymean(f, dd, deff = "replace")),
                error = function(e) NULL)
  data.frame(
    n        = n,
    estimate = as.numeric(p),
    se       = as.numeric(survey::SE(p)),
    lower    = unname(ci[1]),
    upper    = unname(ci[2]),
    deff     = if (is.null(m)) NA_real_ else as.numeric(survey::deff(m))
  )
}
