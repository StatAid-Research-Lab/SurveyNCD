#' Calculate Survey-Weighted Concentration Index
#'
#' Computes the concentration index (the Wagstaff/O'Donnell "convenient
#' covariance" formula) for a health outcome across a socioeconomic
#' ranking variable, using proper survey sampling weights.
#'
#' @param design A survey design object created by \code{survey::svydesign()}
#'   or \code{srvyr::as_survey_design()} -- anything inheriting from
#'   \code{"survey.design"} (srvyr's \code{tbl_svy} objects do).
#' @param outcome Unquoted name of the health indicator (e.g. stunting_clean).
#' @param wealth Unquoted name of the wealth/ranking variable (e.g. wealth_index).
#'
#' @return A tibble with \code{Concentration_Index}, \code{Outcome_Mean},
#'   and \code{n}. This is a point estimate only -- it does not return a
#'   standard error or confidence interval, which would require
#'   propagating the design's clustering and stratification through a
#'   linearization or replicate-weights variance estimator. That's a
#'   known limitation, not a hidden one.
#'
#' @details
#' \deqn{CI = \frac{2}{\mu} \times Cov(y_i, R_i)}
#' where \eqn{y_i} is the outcome for individual i, \eqn{\mu} is the
#' weighted mean outcome, and \eqn{R_i} is each individual's weighted
#' fractional rank in the wealth distribution.
#'
#' @importFrom rlang enquo eval_tidy
#' @importFrom dplyr tibble
#' @importFrom stats weighted.mean cov.wt weights
#' @export
survey_concentration_index <- function(design, outcome, wealth) {

  if (!inherits(design, "survey.design")) {
    stop(
      "`design` must be a survey design object created by ",
      "survey::svydesign() or srvyr::as_survey_design().",
      call. = FALSE
    )
  }

  outcome_q <- rlang::enquo(outcome)
  wealth_q  <- rlang::enquo(wealth)

  calc_data <- design$variables
  # stats::weights() is the correct accessor for sampling weights on a
  # survey design object. design$prob is the *inverse* selection
  # probability (1/weight), not the weight itself -- using it directly,
  # as an earlier version of this function did, inverts the intended
  # weighting (a person representing many people in the population would
  # be treated as if they barely counted, and vice versa).
  calc_data$calc_weight  <- stats::weights(design)
  calc_data$calc_outcome <- as.numeric(rlang::eval_tidy(outcome_q, calc_data))
  calc_data$calc_wealth  <- as.numeric(rlang::eval_tidy(wealth_q, calc_data))

  keep <- !is.na(calc_data$calc_outcome) & !is.na(calc_data$calc_wealth)
  calc_data <- calc_data[keep, ]
  calc_data <- calc_data[order(calc_data$calc_wealth), ]

  sum_weights <- sum(calc_data$calc_weight)
  calc_data$cum_weight <- cumsum(calc_data$calc_weight)
  calc_data$frac_rank  <- (calc_data$cum_weight - 0.5 * calc_data$calc_weight) / sum_weights

  mu <- stats::weighted.mean(calc_data$calc_outcome, calc_data$calc_weight)
  cov_w <- stats::cov.wt(
    cbind(calc_data$calc_outcome, calc_data$frac_rank),
    wt = calc_data$calc_weight / sum_weights,
    method = "ML"
  )$cov[1, 2]

  ci_value <- (2 / mu) * cov_w

  dplyr::tibble(
    Concentration_Index = round(ci_value, 4),
    Outcome_Mean = round(mu, 4),
    n = nrow(calc_data)
  )
}
