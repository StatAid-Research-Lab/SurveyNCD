#' Calculate Survey-Weighted Concentration Index
#'
#' Computes the concentration index (the Wagstaff/O'Donnell "convenient
#' covariance" formula) for a health outcome across a socioeconomic
#' ranking variable, using proper survey sampling weights, and computes
#' design-consistent standard errors, confidence intervals, and p-values.
#'
#' @param design A survey design object created by \code{survey::svydesign()}
#'   or \code{srvyr::as_survey_design()} -- anything inheriting from
#'   \code{"survey.design"} (srvyr's \code{tbl_svy} objects do).
#' @param outcome Unquoted name of the health indicator (e.g. stunting_clean).
#' @param wealth Unquoted name of the wealth/ranking variable (e.g. wealth_index).
#' @param conf.level Confidence level for the confidence interval. Default is 0.95.
#'
#' @return A tibble with \code{Concentration_Index}, \code{Standard_Error},
#'   \code{Lower_CI}, \code{Upper_CI}, \code{p_value}, \code{Outcome_Mean},
#'   and \code{n}.
#'
#' @details
#' \deqn{CI = \frac{2}{\mu} \times Cov_w(y_i, R_i)}
#' where \eqn{y_i} is the outcome for individual i, \eqn{\mu} is the
#' weighted mean outcome, and \eqn{R_i} is each individual's weighted
#' fractional rank in the wealth distribution.
#'
#' The standard error, confidence intervals, and p-value are calculated using the
#' "convenient regression" method (Kakwani, Wagstaff, and van Doorslaer 1997)
#' run via \code{survey::svyglm()}:
#' \deqn{2 \sigma_R^2 (y_i / \mu) = \alpha + \beta R_i + \epsilon_i}
#' where \eqn{\sigma_R^2} is the weighted variance of the fractional rank. The
#' coefficient \eqn{\beta} is mathematically identical to the concentration index,
#' and its standard error from the regression model is a design-consistent standard
#' error that fully accounts for stratification and clustering.
#'
#' @importFrom rlang enquo eval_tidy
#' @importFrom dplyr tibble
#' @importFrom stats weighted.mean weights coef qnorm pnorm
#' @importFrom survey svyglm SE
#' @export
survey_concentration_index <- function(design, outcome, wealth, conf.level = 0.95) {

  if (!inherits(design, "survey.design")) {
    stop(
      "`design` must be a survey design object created by ",
      "survey::svydesign() or srvyr::as_survey_design().",
      call. = FALSE
    )
  }

  # Set lonely PSU option locally to 'adjust' to prevent crash on single-PSU strata
  # resulting from subsetting, and restore original on exit.
  old_opts <- options(survey.lonely.psu = "adjust")
  on.exit(options(old_opts), add = TRUE)

  outcome_q <- rlang::enquo(outcome)
  wealth_q  <- rlang::enquo(wealth)

  # Extract data to determine complete cases
  calc_outcome <- as.numeric(rlang::eval_tidy(outcome_q, design$variables))
  calc_wealth  <- as.numeric(rlang::eval_tidy(wealth_q, design$variables))

  keep <- !is.na(calc_outcome) & !is.na(calc_wealth)
  if (sum(keep) == 0) {
    stop("No complete observations found for the specified variables.", call. = FALSE)
  }

  # Subset and sort the design object by wealth to calculate ranks
  design_clean <- design[keep, ]
  ord <- order(as.numeric(rlang::eval_tidy(wealth_q, design_clean$variables)))
  design_sorted <- design_clean[ord, ]

  # Calculate fractional rank using sorted sampling weights
  calc_weight  <- stats::weights(design_sorted)
  sum_weights <- sum(calc_weight)
  cum_weight <- cumsum(calc_weight)
  frac_rank  <- (cum_weight - 0.5 * calc_weight) / sum_weights

  # Calculate outcome mean
  outcome_vals <- as.numeric(rlang::eval_tidy(outcome_q, design_sorted$variables))
  mu <- stats::weighted.mean(outcome_vals, calc_weight)

  if (mu == 0) {
    warning("Outcome mean is 0; concentration index cannot be calculated.", call. = FALSE)
    return(
      dplyr::tibble(
        Concentration_Index = NA_real_,
        Standard_Error      = NA_real_,
        Lower_CI            = NA_real_,
        Upper_CI            = NA_real_,
        p_value             = NA_real_,
        Outcome_Mean        = 0.0,
        n                   = nrow(design_sorted$variables)
      )
    )
  }

  # Calculate mean and variance of fractional rank
  frac_rank_mean <- stats::weighted.mean(frac_rank, calc_weight)
  frac_rank_var  <- stats::weighted.mean((frac_rank - frac_rank_mean)^2, calc_weight)

  # Construct y_star for the convenient regression
  y_star <- 2 * frac_rank_var * (outcome_vals / mu)

  # Add variables to the sorted design
  design_sorted$variables$frac_rank <- frac_rank
  design_sorted$variables$y_star    <- y_star

  # Run convenient regression to get point estimate and design-consistent standard error
  model <- survey::svyglm(y_star ~ frac_rank, design = design_sorted)
  ci_value <- as.numeric(stats::coef(model)["frac_rank"])
  se_value <- as.numeric(survey::SE(model)["frac_rank"])

  # Calculate confidence intervals and p-value
  alpha <- 1 - conf.level
  z_crit <- stats::qnorm(1 - alpha / 2)
  ci_lower <- ci_value - z_crit * se_value
  ci_upper <- ci_value + z_crit * se_value
  p_val <- 2 * (1 - stats::pnorm(abs(ci_value / se_value)))

  dplyr::tibble(
    Concentration_Index = round(ci_value, 4),
    Standard_Error      = round(se_value, 4),
    Lower_CI            = round(ci_lower, 4),
    Upper_CI            = round(ci_upper, 4),
    p_value             = round(p_val, 4),
    Outcome_Mean        = round(mu, 4),
    n                   = nrow(design_sorted$variables)
  )
}
