#' Survey-weighted concentration index
#'
#' Computes the concentration index of a health variable across a
#' socioeconomic ranking (for example a wealth score), with design-based
#' standard errors, confidence intervals and p-values that account for
#' stratification and clustering. The standard, generalized, Erreygers and
#' Wagstaff indices are available.
#'
#' @details
#' The standard concentration index is
#' \deqn{C = \frac{2}{\mu} \mathrm{cov}_w(y_i, R_i),}
#' where \eqn{\mu} is the weighted mean of \eqn{y} and \eqn{R_i} the weighted
#' fractional rank: the mid-point of each respondent's interval of the
#' cumulative weight distribution (Lerman and Yitzhaki 1989). Respondents
#' tied on the ranking variable share the mid-point of their tied group's
#' interval, so results do not depend on the order of the data.
#'
#' Each index is the slope \eqn{\beta} of the "convenient regression" of
#' Kakwani, Wagstaff and van Doorslaer (1997),
#' \eqn{2\sigma_R^2 \, h(y_i) = \alpha + \beta R_i + \varepsilon_i}, fitted
#' with [survey::svyglm()] so that its standard error is design-based. With
#' bounds \eqn{a \le y \le b} (O'Donnell et al. 2016):
#' \itemize{
#'   \item `"CI"` (standard): \eqn{h(y) = y/\mu}.
#'   \item `"generalized"`: \eqn{h(y) = y}, giving \eqn{\mu C}.
#'   \item `"erreygers"`: \eqn{h(y) = 4y/(b - a)}, giving
#'     \eqn{4\mu C/(b-a)} (Erreygers 2009).
#'   \item `"wagstaff"`: \eqn{h(y) = (b - a)y/((b - \mu)(\mu - a))}, giving
#'     \eqn{(b-a)\mu C/((b-\mu)(\mu-a))}; for binary outcomes \eqn{C/(1-\mu)}
#'     (Wagstaff 2005).
#' }
#' For bounded outcomes such as binary indicators the Erreygers or Wagstaff
#' index is usually preferred. The standard error treats the ranks and
#' \eqn{\mu} as fixed.
#'
#' @param design A survey design object (\pkg{survey} or \pkg{srvyr}).
#' @param outcome Unquoted name of the health variable.
#' @param wealth Unquoted name of the ranking variable.
#' @param conf.level Confidence level.
#' @param type One of `"CI"` (default), `"generalized"`, `"erreygers"`,
#'   `"wagstaff"`.
#' @param bounds Numeric vector `c(a, b)` of the outcome's bounds, needed for
#'   `"erreygers"` and `"wagstaff"`. Defaults to `c(0, 1)` when the outcome is
#'   binary.
#' @param by Optional character vector of grouping columns; ranks are
#'   computed within each group.
#'
#' @return A tibble of class `surveyncd_ci` with any `by` columns,
#'   `Concentration_Index`, `Standard_Error`, `Lower_CI`, `Upper_CI`,
#'   `p_value`, `Outcome_Mean`, `n` and `Type`.
#' @references
#' Kakwani, N., Wagstaff, A., & van Doorslaer, E. (1997). Socioeconomic
#' inequalities in health: Measurement, computation, and statistical inference.
#' \emph{Journal of Econometrics}, 77(1), 87-103.
#' \doi{10.1016/S0304-4076(96)01807-6}
#'
#' Erreygers, G. (2009). Correcting the concentration index.
#' \emph{Journal of Health Economics}, 28(2), 504-515.
#' \doi{10.1016/j.jhealeco.2008.02.003}
#'
#' Wagstaff, A. (2005). The bounds of the concentration index when the variable
#' of interest is binary, with an application to immunization inequality.
#' \emph{Health Economics}, 14(4), 429-432. \doi{10.1002/hec.953}
#'
#' O'Donnell, O., O'Neill, S., Van Ourti, T., & Walsh, B. (2016). conindex:
#' Estimation of concentration indices. \emph{The Stata Journal}, 16(1),
#' 112-138. \doi{10.1177/1536867X1601600112}
#'
#' @examples
#' set.seed(42)
#' n <- 50
#' df <- data.frame(
#'   wealth  = rnorm(n, 50, 15),
#'   outcome = pmax(0, 0.3 * rnorm(n, 50, 15) + rnorm(n, 0, 5)),
#'   sick    = rbinom(n, 1, 0.3),
#'   wt      = sample(1:5, n, replace = TRUE)
#' )
#' design <- survey::svydesign(ids = ~1, weights = ~wt, data = df)
#' survey_concentration_index(design, outcome = outcome, wealth = wealth)
#' survey_concentration_index(design, outcome = sick, wealth = wealth,
#'                            type = "erreygers")
#'
#' @importFrom rlang enquo eval_tidy as_name
#' @importFrom dplyr tibble
#' @importFrom stats weighted.mean weights coef qnorm pnorm
#' @importFrom survey svyglm SE
#' @export
survey_concentration_index <- function(design, outcome, wealth, conf.level = 0.95,
                                       type = c("CI", "generalized", "erreygers", "wagstaff"),
                                       bounds = NULL, by = NULL) {
  if (!inherits(design, "survey.design")) {
    stop(
      "`design` must be a survey design object created by ",
      "survey::svydesign() or srvyr::as_survey_design().",
      call. = FALSE
    )
  }
  type <- match.arg(type)
  old_opts <- options(survey.lonely.psu = "adjust")
  on.exit(options(old_opts), add = TRUE)

  outcome_q <- rlang::enquo(outcome)
  wealth_q  <- rlang::enquo(wealth)
  y_all <- as.numeric(rlang::eval_tidy(outcome_q, design$variables))
  x_all <- as.numeric(rlang::eval_tidy(wealth_q, design$variables))
  design <- .set_var(design, ".sncd_y", y_all)
  design <- .set_var(design, ".sncd_x", x_all)

  if (type %in% c("erreygers", "wagstaff")) {
    yy <- y_all[!is.na(y_all)]
    if (is.null(bounds)) {
      if (all(yy %in% c(0, 1))) bounds <- c(0, 1) else
        stop("`bounds = c(lower, upper)` is required for type = '", type,
             "' unless the outcome is binary.", call. = FALSE)
    }
    if (length(bounds) != 2 || bounds[1] >= bounds[2]) {
      stop("`bounds` must be c(lower, upper) with lower < upper.", call. = FALSE)
    }
    if (any(yy < bounds[1] | yy > bounds[2])) {
      stop("The outcome has values outside `bounds`.", call. = FALSE)
    }
  }

  doms <- .domains(design, by)
  out <- do.call(rbind, lapply(doms, function(g) {
    .bind_key(g$key, as.data.frame(.ci_one(g$design, conf.level, type, bounds)))
  }))
  if (all(c("Concentration_Index", "n") %in% names(out)) && sum(out$n) == 0) {
    stop("No complete observations found for the specified variables.", call. = FALSE)
  }
  out <- dplyr::as_tibble(out)
  class(out) <- c("surveyncd_ci", class(out))
  out
}

.ci_one <- function(d, conf.level, type, bounds) {
  y <- d$variables$.sncd_y; x <- d$variables$.sncd_x
  w <- .design_weights(d)
  keep <- !is.na(y) & !is.na(x) & w > 0
  na_row <- function(mu = NA_real_, n = 0L) data.frame(
    Concentration_Index = NA_real_, Standard_Error = NA_real_, Lower_CI = NA_real_,
    Upper_CI = NA_real_, p_value = NA_real_, Outcome_Mean = mu, n = n, Type = type)
  if (sum(keep) == 0) return(na_row())
  dc <- d[keep, ]
  y <- y[keep]; x <- x[keep]; w <- w[keep]
  R <- .frac_rank(x, w)
  mu <- stats::weighted.mean(y, w)
  if (type %in% c("CI", "wagstaff") && mu == 0) {
    warning("Outcome mean is 0; concentration index cannot be calculated.", call. = FALSE)
    return(na_row(0, nrow(dc$variables)))
  }
  s2 <- stats::weighted.mean((R - stats::weighted.mean(R, w))^2, w)
  h <- switch(type,
    CI          = y / mu,
    generalized = y,
    erreygers   = 4 * y / (bounds[2] - bounds[1]),
    wagstaff    = (bounds[2] - bounds[1]) * y / ((bounds[2] - mu) * (mu - bounds[1]))
  )
  dc <- .set_var(dc, ".sncd_R", R)
  dc <- .set_var(dc, ".sncd_ystar", 2 * s2 * h)
  model <- survey::svyglm(.sncd_ystar ~ .sncd_R, design = dc)
  est <- as.numeric(stats::coef(model)[".sncd_R"])
  se  <- as.numeric(survey::SE(model)[".sncd_R"])
  z <- stats::qnorm(1 - (1 - conf.level) / 2)
  data.frame(
    Concentration_Index = est,
    Standard_Error      = se,
    Lower_CI            = est - z * se,
    Upper_CI            = est + z * se,
    p_value             = 2 * stats::pnorm(-abs(est / se)),
    Outcome_Mean        = mu,
    n                   = nrow(dc$variables),
    Type                = type
  )
}
