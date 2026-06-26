test_that("survey_xgboost() and survey_shap() run end to end and handle missing data", {
  testthat::skip_if_not_installed("xgboost")

  set.seed(1)
  n <- 30
  df <- data.frame(
    outcome = rnorm(n, 100, 10),
    age     = round(runif(n, 18, 80)),
    bmi     = round(rnorm(n, 24, 4), 1),
    wealth  = sample(1:5, n, replace = TRUE),
    wt      = round(runif(n, 0.5, 2), 2)
  )
  df$age[3] <- NA  # one missing value, to check complete-case handling

  design <- survey::svydesign(ids = ~1, weights = ~wt, data = df)

  model <- survey_xgboost(design, outcome ~ age + bmi + wealth, nrounds = 5)
  expect_setequal(model$features, c("age", "bmi", "wealth"))
  expect_equal(model$n_obs, n - 1)  # the NA row should be dropped
  expect_true(is.matrix(model$X))
  expect_equal(nrow(model$X), n - 1)
  expect_equal(ncol(model$X), 3)

  shap <- survey_shap(model)
  expect_equal(nrow(shap), n - 1)
  expect_true("(Intercept)" %in% colnames(shap))

  # Test plot_shap_summary runs without error and returns a ggplot object
  p <- plot_shap_summary(shap, model$X)
  expect_s3_class(p, "ggplot")
})

test_that("survey_shap() rejects objects that aren't survey_xgboost() output", {
  expect_error(survey_shap(list(not = "the right shape")))
})
