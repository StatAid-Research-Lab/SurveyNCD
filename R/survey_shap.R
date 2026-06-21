#' Extract SHAP Values from a Survey-Weighted XGBoost Model
#'
#' This function cracks open a trained survey-weighted XGBoost model and calculates
#' the SHapley Additive exPlanations (SHAP values) for every respondent.
#'
#' @param sxgb_model The list output from the \code{survey_xgboost()} function.
#'
#' @return A matrix of SHAP values detailing the marginal contribution of each
#'   feature to the final prediction for every observation.
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
