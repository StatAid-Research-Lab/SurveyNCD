# Train an XGBoost Model with Complex Survey Weights

**Experimental.** This function trains an Extreme Gradient Boosting
(XGBoost) model while strictly enforcing sampling weights from a complex
survey design object.

## Usage

``` r
survey_xgboost(design, formula, params = list(), nrounds = 100)
```

## Arguments

- design:

  A `survey.design` object containing the data and weights.

- formula:

  A formula specifying the response and predictor variables.

- params:

  A list of XGBoost parameters (e.g., objective, eta, max_depth).

- nrounds:

  The number of boosting iterations.

## Value

A list containing the trained `xgb.Booster` model, the `xgb.DMatrix`,
the feature names, the observation count, and the cleaned training
feature matrix `X`.

## Examples

``` r
# \donttest{
if (requireNamespace("xgboost", quietly = TRUE)) {
  set.seed(1)
  n <- 30
  df <- data.frame(
    outcome = rnorm(n, 100, 10),
    age     = round(runif(n, 18, 80)),
    bmi     = round(rnorm(n, 24, 4), 1),
    wt      = round(runif(n, 0.5, 2), 2)
  )
  design <- survey::svydesign(ids = ~1, weights = ~wt, data = df)
  model  <- survey_xgboost(design, outcome ~ age + bmi, nrounds = 5)
  model$features
}
#> [1] "age" "bmi"
# }
```
