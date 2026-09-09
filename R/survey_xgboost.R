#' Train an XGBoost Model with Complex Survey Weights
#'
#' This function trains an Extreme Gradient Boosting (XGBoost) model while
#' strictly enforcing sampling weights from a complex survey design object.
#'
#' @param design A \code{survey.design} object containing the data and weights.
#' @param formula A formula specifying the response and predictor variables.
#' @param params A list of XGBoost parameters (e.g., objective, eta, max_depth).
#' @param nrounds The number of boosting iterations.
#'
#' @return A list containing the trained \code{xgb.Booster} model, the
#'   \code{xgb.DMatrix}, the feature names, the observation count, and the
#'   cleaned training feature matrix \code{X}.
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
#' model$features
#' }
#'
#' @export
#'
#' @importFrom stats model.matrix model.response model.frame complete.cases
survey_xgboost <- function(design, formula, params = list(), nrounds = 100) {

  # xgboost is Suggests-only (it's a heavy compiled dependency, not
  # everyone building this package needs it) -- so it's checked at call
  # time with requireNamespace(), not pulled in via @import/NAMESPACE,
  # which would force it as a hard dependency regardless of what
  # DESCRIPTION says.
  if (!requireNamespace("xgboost", quietly = TRUE)) {
    stop(
      "Package 'xgboost' is required for survey_xgboost() but is not ",
      "installed. Install it with install.packages(\"xgboost\").",
      call. = FALSE
    )
  }

  # 1. Extract raw data and sampling weights from the survey design
  raw_data <- design$variables
  raw_weights <- stats::weights(design)

  # 2. Defensive Alignment: Identify complete cases to prevent weight misalignment
  mf_temp <- stats::model.frame(formula, data = raw_data, na.action = stats::na.pass)
  valid_rows <- stats::complete.cases(mf_temp)

  clean_data <- raw_data[valid_rows, ]
  clean_weights <- raw_weights[valid_rows]

  # 3. Create the feature matrix (X) and target vector (y)
  mf_clean <- stats::model.frame(formula, data = clean_data)
  X <- stats::model.matrix(formula, mf_clean)[, -1, drop = FALSE] # Remove intercept
  y <- stats::model.response(mf_clean)

  # 4. Construct the weighted XGBoost DMatrix
  dtrain <- xgboost::xgb.DMatrix(data = X, label = y, weight = clean_weights)

  # 5. Train the model
  xgb_model <- xgboost::xgb.train(params = params, data = dtrain, nrounds = nrounds)

  # Return the model, the DMatrix (needed for SHAP extraction later), the
  # feature names, and the row count actually used after dropping
  # incomplete cases. n_obs is tracked explicitly here rather than via
  # nrow(dtrain) because xgb.DMatrix is an opaque external-pointer object
  # (its $data is NOT a plain subsettable matrix), so anything that needs
  # to know how many rows were used -- including tests -- shouldn't have
  # to reach into xgboost's internals to find out.
  return(list(
    model    = xgb_model,
    dmatrix  = dtrain,
    features = colnames(X),
    n_obs    = nrow(X),
    X        = X
  ))
}
