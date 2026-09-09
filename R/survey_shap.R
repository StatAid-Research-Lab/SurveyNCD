#' Extract SHAP Values from a Survey-Weighted XGBoost Model
#'
#' This function cracks open a trained survey-weighted XGBoost model and calculates
#' the SHapley Additive exPlanations (SHAP values) for every respondent.
#'
#' @param sxgb_model The list output from the \code{survey_xgboost()} function.
#'
#' @return A matrix of SHAP values detailing the marginal contribution of each
#'   feature to the final prediction for every observation.
#'
#' @examples
#' \donttest{
#' set.seed(1)
#' n <- 30
#' df <- data.frame(
#'   outcome = rnorm(n, 100, 10),
#'   age     = round(runif(n, 18, 80)),
#'   bmi     = round(rnorm(n, 24, 4), 1),
#'   wt      = round(runif(n, 0.5, 2), 2)
#' )
#' design <- survey::svydesign(ids = ~1, weights = ~wt, data = df)
#' model  <- survey_xgboost(design, outcome ~ age + bmi, nrounds = 5)
#' shap   <- survey_shap(model)
#' head(shap)
#' }
#'
#' @export
#'
#' @importFrom stats predict
survey_shap <- function(sxgb_model) {

  if (!requireNamespace("xgboost", quietly = TRUE)) {
    stop(
      "Package 'xgboost' is required for survey_shap() but is not ",
      "installed. Install it with install.packages(\"xgboost\").",
      call. = FALSE
    )
  }

  # Defensive check to ensure the user passed the correct object
  if (is.null(sxgb_model$model) || is.null(sxgb_model$dmatrix)) {
    stop(
      "Input must be the list output from survey_xgboost().",
      call. = FALSE
    )
  }

  # Extract the SHAP values using the underlying C++ xgboost engine
  # predcontrib = TRUE forces the model to return SHAP matrices instead of raw predictions
  shap_matrix <- stats::predict(
    object = sxgb_model$model,
    newdata = sxgb_model$dmatrix,
    predcontrib = TRUE
  )

  return(shap_matrix)
}
