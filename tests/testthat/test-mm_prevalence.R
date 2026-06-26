make_scored_data <- function(seed = 1, n = 40) {
  set.seed(seed)
  df <- data.frame(
    psu    = rep(1:8, each = 5),
    region = rep(c("A", "B"), each = 20),
    wt     = round(stats::runif(n, 0.8, 1.4), 2),
    a      = stats::rbinom(n, 1, 0.3),
    b      = stats::rbinom(n, 1, 0.3)
  )
  multimorbidity_index(df, conditions = c("a", "b"))
}

test_that("mm_prevalence() requires multimorbidity_index() output", {
  raw <- data.frame(psu = 1:4, region = rep(c("A", "B"), 2), wt = 1, a = c(1, 0, 1, 0))
  expect_error(mm_prevalence(raw, ids = "psu", strata = "region", weights = "wt"))
})

test_that("mm_prevalence() returns one row with sane bounds for the overall estimate", {
  scored <- make_scored_data()
  overall <- mm_prevalence(scored, ids = "psu", strata = "region", weights = "wt")

  expect_equal(nrow(overall), 1)
  expect_equal(overall$n, nrow(scored))
  expect_true(overall$prevalence >= 0 && overall$prevalence <= 1)
  expect_true(overall$prevalence_lower <= overall$prevalence)
  expect_true(overall$prevalence_upper >= overall$prevalence)
})

test_that("mm_prevalence() with `by` returns one row per group and n's add up", {
  scored <- make_scored_data()
  by_region <- mm_prevalence(scored, ids = "psu", strata = "region",
                              weights = "wt", by = "region")

  expect_equal(nrow(by_region), 2)
  expect_equal(sum(by_region$n), nrow(scored))
})

test_that("mm_prevalence() errors on an unknown `by` column", {
  scored <- make_scored_data()
  expect_error(
    mm_prevalence(scored, ids = "psu", strata = "region", weights = "wt",
                  by = "not_a_column")
  )
})

test_that("mm_prevalence() drops rows with missing multimorbidity scores", {
  scored <- make_scored_data()
  scored$mm_category[1] <- NA
  scored$mm_n_conditions[1] <- NA

  res <- suppressMessages(
    mm_prevalence(scored, ids = "psu", strata = "region", weights = "wt")
  )
  expect_equal(res$n, nrow(scored) - 1)
})

test_that("mm_prevalence() does not crash and excludes NA when grouping variable contains NA", {
  scored <- make_scored_data()
  scored$region[c(2, 5)] <- NA  # Add some NAs in the grouping variable

  res <- mm_prevalence(scored, ids = "psu", strata = NULL, weights = "wt", by = "region")
  expect_equal(nrow(res), 2)  # Should only return A and B, omitting NA
  expect_false(any(is.na(res$region)))
  expect_equal(sum(res$n), nrow(scored) - 2) # N = 38 (40 - 2)
})
