#' Extract SHAP values from a `survey_xgboost()` model
#'
#' Computes SHAP contributions for each feature and observation from a fitted
#' survey-weighted XGBoost model.
#'
#' @param sxgb_model A fitted model object returned by `survey_xgboost()`.
#'
#' @return A numeric matrix of SHAP values with one row per observation and one
#'   column per feature (plus intercept).
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
