test_that("ncd_survey has the documented structure and design variables", {
  expect_equal(dim(ncd_survey), c(2400L, 18L))
  expect_equal(length(unique(ncd_survey$stratum)), 12L)
  expect_equal(length(unique(ncd_survey$psu)), 120L)
  expect_equal(mean(ncd_survey$wt), 1, tolerance = 1e-6)
  expect_true(all(ncd_survey$wt > 0))
  for (v in c("htn_raw", "dm_raw", "arth_raw", "asthma_raw",
              "angina_raw", "stroke_raw")) {
    expect_true(all(ncd_survey[[v]] %in% c(1, 2, 9)), info = v)
  }
  expect_setequal(unique(ncd_survey$dep_raw), c("Yes", "No", "Don't know"))
  expect_setequal(unique(ncd_survey$wealth_quintile), 1:5)
})

test_that("child_anthro links to households and uses DHS z-score coding", {
  expect_equal(ncol(child_anthro), 14L)
  expect_true(all(child_anthro$hh_id %in% ncd_survey$hh_id))
  expect_true(any(child_anthro$hw70 %in% c(9996, 9998)))
  expect_true(all(child_anthro$age_months >= 0 & child_anthro$age_months <= 59))
})

test_that("the shipped datasets run through the core workflow", {
  d <- ncd_survey
  d$htn <- recode_binary(d$htn_raw, yes = 1, no = 2)
  d$dm  <- recode_binary(d$dm_raw,  yes = 1, no = 2)
  d$dep <- recode_binary(d$dep_raw, yes = "Yes", no = "No")
  s <- multimorbidity_index(d, c("htn", "dm", "dep"), na_action = "na")
  est <- suppressMessages(
    mm_prevalence(s, ids = "psu", strata = "stratum", weights = "wt")
  )
  expect_true(est$prevalence > 0 && est$prevalence < 1)
  expect_true(est$prevalence_lower < est$prevalence)
})
