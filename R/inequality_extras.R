#' Concentration curve from a survey design
#'
#' Coordinates of the concentration curve: the cumulative share of the
#' population ranked from poorest to richest (x) against the cumulative share
#' of the health variable (y), both using sampling weights. A curve above the
#' diagonal means the variable is concentrated among poorer people. Tied
#' respondents are grouped into one point, consistent with
#' [survey_concentration_index()]: the concentration index equals one minus
#' twice the area under the curve.
#'
#' @inheritParams survey_concentration_index
#' @return A data frame of class `surveyncd_curve` with any `by` columns,
#'   `cum_population` and `cum_outcome`, starting at (0, 0).
#' @examples
#' set.seed(1)
#' df <- data.frame(wealth = rnorm(300), wt = runif(300, 0.5, 2))
#' df$sick <- rbinom(300, 1, plogis(-1 - 0.6 * df$wealth))
#' des <- survey::svydesign(ids = ~1, weights = ~wt, data = df)
#' cc <- survey_concentration_curve(des, sick, wealth)
#' head(cc)
#' @export
survey_concentration_curve <- function(design, outcome, wealth, by = NULL) {
  .check_design(design)
  design <- .set_var(design, ".sncd_y", as.numeric(rlang::eval_tidy(rlang::enquo(outcome), design$variables)))
  design <- .set_var(design, ".sncd_x", as.numeric(rlang::eval_tidy(rlang::enquo(wealth), design$variables)))
  doms <- .domains(design, by)
  out <- do.call(rbind, lapply(doms, function(g) {
    v <- g$design$variables; w <- .design_weights(g$design)
    keep <- !is.na(v$.sncd_y) & !is.na(v$.sncd_x) & w > 0
    y <- v$.sncd_y[keep]; x <- v$.sncd_x[keep]; w <- w[keep]
    if (sum(w * y) <= 0) stop("The outcome total must be positive.", call. = FALSE)
    agg_w  <- tapply(w, x, sum)
    agg_wy <- tapply(w * y, x, sum)
    o <- order(as.numeric(names(agg_w)))
    df <- data.frame(cum_population = c(0, cumsum(agg_w[o]) / sum(w)),
                     cum_outcome    = c(0, cumsum(agg_wy[o]) / sum(w * y)))
    .bind_key(g$key, df)
  }))
  rownames(out) <- NULL
  structure(out, class = c("surveyncd_curve", "data.frame"), by = by)
}

#' Slope and relative index of inequality from a survey design
#'
#' Regression-based measures of socioeconomic inequality on the weighted
#' fractional rank \eqn{R} (0 = poorest, 1 = richest; tie-aware as in
#' [survey_concentration_index()]):
#' \itemize{
#'   \item the slope index of inequality (SII), the slope of a linear
#'     regression of the outcome on \eqn{R}: the absolute difference in the
#'     outcome between the richest and the poorest end of the distribution;
#'   \item the relative index of inequality (RII), \eqn{\exp(\beta)} from a
#'     log-link quasi-Poisson regression on \eqn{R}: the ratio of the outcome
#'     at the richest to the poorest end.
#' }
#' Both models are fitted with [survey::svyglm()], giving design-based
#' confidence intervals. Values of SII above 0 (RII above 1) mean higher
#' levels among richer people.
#'
#' @inheritParams survey_concentration_index
#' @return A data frame with any `by` columns, `n`, `SII`, `SII_lower`,
#'   `SII_upper`, `RII`, `RII_lower`, `RII_upper`.
#' @references
#' Mackenbach, J. P., & Kunst, A. E. (1997). Measuring the magnitude of
#' socio-economic inequalities in health: An overview of available measures
#' illustrated with two examples from Europe. \emph{Social Science & Medicine},
#' 44(6), 757-771. \doi{10.1016/S0277-9536(96)00073-1}
#' @examples
#' set.seed(1)
#' df <- data.frame(wealth = rnorm(300), wt = runif(300, 0.5, 2))
#' df$sick <- rbinom(300, 1, plogis(-1 - 0.6 * df$wealth))
#' des <- survey::svydesign(ids = ~1, weights = ~wt, data = df)
#' survey_slope_index(des, sick, wealth)
#' @export
survey_slope_index <- function(design, outcome, wealth, conf.level = 0.95, by = NULL) {
  .check_design(design)
  old <- .lonely_adjust(); on.exit(options(old), add = TRUE)
  design <- .set_var(design, ".sncd_y", as.numeric(rlang::eval_tidy(rlang::enquo(outcome), design$variables)))
  design <- .set_var(design, ".sncd_x", as.numeric(rlang::eval_tidy(rlang::enquo(wealth), design$variables)))
  z <- stats::qnorm(1 - (1 - conf.level) / 2)
  doms <- .domains(design, by)
  out <- do.call(rbind, lapply(doms, function(g) {
    d <- g$design; v <- d$variables; w <- .design_weights(d)
    keep <- !is.na(v$.sncd_y) & !is.na(v$.sncd_x) & w > 0
    dc <- d[keep, ]
    dc <- .set_var(dc, ".sncd_R", .frac_rank(v$.sncd_x[keep], w[keep]))
    lin <- survey::svyglm(.sncd_y ~ .sncd_R, design = dc)
    b <- stats::coef(lin)[[".sncd_R"]]; s <- survey::SE(lin)[[".sncd_R"]]
    rel <- tryCatch(suppressWarnings(
      survey::svyglm(.sncd_y ~ .sncd_R, design = dc, family = stats::quasipoisson(link = "log"))),
      error = function(e) NULL)
    if (is.null(rel)) { rb <- NA_real_; rs <- NA_real_ } else {
      rb <- stats::coef(rel)[[".sncd_R"]]; rs <- survey::SE(rel)[[".sncd_R"]]
    }
    .bind_key(g$key, data.frame(
      n = nrow(dc$variables),
      SII = b, SII_lower = b - z * s, SII_upper = b + z * s,
      RII = exp(rb), RII_lower = exp(rb - z * rs), RII_upper = exp(rb + z * rs)))
  }))
  rownames(out) <- NULL
  out
}
