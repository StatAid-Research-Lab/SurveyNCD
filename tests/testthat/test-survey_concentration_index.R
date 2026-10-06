test_that("survey_concentration_index() matches an independent replicate-by-weight calculation", {
  set.seed(42)
  n <- 50
  df <- data.frame(
    wealth  = rnorm(n, 50, 15),
    outcome = NA_real_,
    wt      = sample(1:5, n, replace = TRUE)
  )
  df$outcome <- 0.3 * df$wealth + rnorm(n, 0, 5)

  design <- survey::svydesign(ids = ~1, weights = ~wt, data = df)
  res <- survey_concentration_index(design, outcome = outcome, wealth = wealth)

  # Independent check: replicate each row by its integer weight and compute
  # the standard *unweighted* concentration index on the expanded data.
  expanded <- df[rep(seq_len(nrow(df)), times = df$wt), ]
  expanded <- expanded[order(expanded$wealth), ]
  n_exp <- nrow(expanded)
  frac_rank <- (seq_len(n_exp) - 0.5) / n_exp
  mu_exp <- mean(expanded$outcome)
  cov_exp <- cov(expanded$outcome, frac_rank) * (n_exp - 1) / n_exp
  ci_exp <- (2 / mu_exp) * cov_exp

  expect_equal(res$Concentration_Index, ci_exp, tolerance = 0.01)
  expect_equal(res$Outcome_Mean, mu_exp, tolerance = 0.01)
})

test_that("survey_concentration_index() uses weights(), not the inverse selection probability", {
  # Regression test for the bug where design$prob (= 1/weight) was used
  # directly as the weight. With unequal weights these two give
  # meaningfully different answers, so if this ever regresses, this test
  # will fail.
  set.seed(1)
  n <- 30
  df <- data.frame(
    wealth  = runif(n, 0, 100),
    outcome = runif(n, 0, 1),
    wt      = sample(c(1, 10), n, replace = TRUE)  # deliberately extreme contrast
  )
  design <- survey::svydesign(ids = ~1, weights = ~wt, data = df)
  res <- survey_concentration_index(design, outcome = outcome, wealth = wealth)

  buggy_weight <- design$prob  # what the old, broken version used
  correct_weight <- stats::weights(design)
  expect_false(isTRUE(all.equal(buggy_weight, correct_weight)))
})

test_that("survey_concentration_index() requires a survey.design object", {
  expect_error(
    survey_concentration_index(data.frame(a = 1), outcome = a, wealth = a)
  )
})

test_that("survey_concentration_index() returns SE, CI, and p-value", {
  set.seed(42)
  n <- 50
  df <- data.frame(
    wealth  = rnorm(n, 50, 15),
    outcome = NA_real_,
    wt      = sample(1:5, n, replace = TRUE)
  )
  df$outcome <- pmax(0, 0.3 * df$wealth + rnorm(n, 0, 5))
  design <- survey::svydesign(ids = ~1, weights = ~wt, data = df)
  res <- survey_concentration_index(design, outcome = outcome, wealth = wealth)

  expect_true(all(c("Standard_Error", "Lower_CI", "Upper_CI", "p_value") %in% colnames(res)))
  expect_true(res$Standard_Error > 0)
  expect_true(res$Lower_CI <= res$Concentration_Index)
  expect_true(res$Upper_CI >= res$Concentration_Index)
  expect_true(res$p_value >= 0 && res$p_value <= 1)
})

test_that("survey_concentration_index() is invariant to row order when wealth has ties", {
  set.seed(7)
  n <- 400
  df <- data.frame(
    quintile = sample(1:5, n, replace = TRUE),
    wt       = runif(n, 0.5, 2.5)
  )
  df$y <- rbinom(n, 1, plogis(-0.5 - 0.3 * df$quintile))

  d1 <- survey::svydesign(ids = ~1, weights = ~wt, data = df)
  d2 <- survey::svydesign(ids = ~1, weights = ~wt, data = df[sample(n), ])
  r1 <- survey_concentration_index(d1, outcome = y, wealth = quintile)
  r2 <- survey_concentration_index(d2, outcome = y, wealth = quintile)
  expect_equal(r1$Concentration_Index, r2$Concentration_Index, tolerance = 1e-10)

  # Independent mid-rank calculation (tied respondents share a group mid-rank)
  o  <- order(df$quintile); y <- df$y[o]; w <- df$wt[o]; q <- df$quintile[o]
  hi <- cumsum(w); lo <- hi - w
  R  <- (ave(lo, q, FUN = min) + ave(hi, q, FUN = max)) / 2 / sum(w)
  mu <- weighted.mean(y, w)
  ci <- 2 / mu * sum(w * (y - mu) * (R - weighted.mean(R, w))) / sum(w)
  expect_equal(r1$Concentration_Index, ci, tolerance = 1e-8)
})
