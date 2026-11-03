# Extract SHAP Values from a Survey-Weighted XGBoost Model

**Experimental.** This function cracks open a trained survey-weighted
XGBoost model and calculates the SHapley Additive exPlanations (SHAP
values) for every respondent.

## Usage

``` r
survey_shap(sxgb_model)
```

## Arguments

- sxgb_model:

  The list output from the
  [`survey_xgboost()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_xgboost.md)
  function.

## Value

A matrix of SHAP values detailing the marginal contribution of each
feature to the final prediction for every observation.

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
  shap   <- survey_shap(model)
  head(shap)
}
#>             age        bmi (Intercept)
#> [1,] -2.6015129 -0.9454343    100.8529
#> [2,]  1.9163876 -1.3642178    100.8529
#> [3,]  0.9061655 -3.7668991    100.8529
#> [4,] -0.4475244  9.1753855    100.8529
#> [5,]  2.5167103 -2.6422520    100.8529
#> [6,] -1.6387370 -2.1999223    100.8529
# }
```
