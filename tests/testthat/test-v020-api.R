# Tests for the 0.2.0 design-first API. Each estimator is checked against an
# independent calculation, not just for running.

make_des <- function(seed = 3, n = 600) {
  set.seed(seed)
  df <- data.frame(
    psu = rep(1:60, each = n / 60), stratum = rep(1:6, each = n / 6),
    wt = runif(n, 0.5, 3), sex = sample(c("F", "M"), n, TRUE),
    area = sample(c("U", "R"), n, TRUE), age = sample(18:69, n, TRUE),
    wealth = round(rnorm(n), 2)
  )
  df$a <- rbinom(n, 1, plogis(-1 + 0.5 * df$wealth))
  df$b <- rbinom(n, 1, plogis(-1.2 + 0.03 * (df$age - 40)))
  df$c <- rbinom(n, 1, 0.15)
  df$b[sample(n, 20)] <- NA
  df$age_group <- cut(df$age, c(18, 30, 45, 60, 70), right = FALSE,
                      labels = c("18-29", "30-44", "45-59", "60-69"))
  survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~wt, data = df, nest = TRUE)
}

test_that("survey_prevalence() matches survey::svyciprop overall and in domains", {
  des <- make_des()
  r <- survey_prevalence(des, c("a", "b"))
  ref <- survey::svyciprop(~b, subset(des, !is.na(b)), method = "logit")
  expect_equal(r$estimate[r$indicator == "b"], as.numeric(ref), tolerance = 1e-10)
  expect_equal(r$upper[r$indicator == "b"], unname(attr(ref, "ci")[2]), tolerance = 1e-10)
  expect_equal(r$n[r$indicator == "b"], 580)

  g <- survey_prevalence(des, "a", by = c("sex", "area"))
  expect_equal(nrow(g), 4)
  ref2 <- survey::svyciprop(~a, subset(des, sex == "M" & area == "U"), method = "logit")
  expect_equal(g$estimate[g$sex == "M" & g$area == "U"], as.numeric(ref2), tolerance = 1e-10)
  expect_equal(g$se[g$sex == "M" & g$area == "U"], as.numeric(survey::SE(ref2)), tolerance = 1e-10)
  expect_s3_class(g, "surveyncd_prevalence")
  expect_error(survey_prevalence(des, "wealth"), "0, 1")
})

test_that("mm_prevalence() accepts a design, several by-variables, and keeps 0.1.0 results", {
  des <- make_des()
  s <- multimorbidity_index(des$variables, c("a", "b", "c"), na_action = "na")
  old_style <- suppressMessages(mm_prevalence(s, ids = "psu", strata = "stratum", weights = "wt"))
  d2 <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~wt, data = s, nest = TRUE)
  new_style <- suppressMessages(mm_prevalence(d2))
  expect_equal(old_style$prevalence, new_style$prevalence, tolerance = 1e-12)
  ref <- survey::svymean(~I(mm_multimorbid), subset(d2, !is.na(mm_multimorbid)))
  expect_equal(new_style$prevalence, as.numeric(ref), tolerance = 1e-7)
  two <- suppressMessages(mm_prevalence(d2, by = c("sex", "area")))
  expect_equal(nrow(two), 4)
  expect_equal(sum(two$n), sum(!is.na(s$mm_n_conditions)))
})

test_that("multimorbidity_index() threshold changes the classification", {
  df <- data.frame(a = c(1, 1, 1, 0), b = c(1, 1, 0, 0), c = c(1, 0, 0, 0))
  r2 <- multimorbidity_index(df, c("a", "b", "c"))
  r3 <- multimorbidity_index(df, c("a", "b", "c"), threshold = 3)
  expect_equal(r2$mm_multimorbid, c(1, 1, 0, 0))
  expect_equal(r3$mm_multimorbid, c(1, 0, 0, 0))
  expect_equal(as.character(r3$mm_category), c("Multimorbid", "1-2 conditions", "1-2 conditions", "None"))
  expect_error(multimorbidity_index(df, "a", threshold = 0))
})

test_that("mm_patterns() pair prevalence and O/E ratio are correct", {
  des <- make_des()
  p <- mm_patterns(des, c("a", "b", "c"))
  expect_equal(nrow(p), 3)
  d <- des
  d$variables$ab <- ifelse(is.na(d$variables$b), NA, d$variables$a * d$variables$b)
  ref <- survey::svyciprop(~ab, subset(d, !is.na(ab)), method = "logit")
  expect_equal(p$prevalence[p$combination == "a + b"], as.numeric(ref), tolerance = 1e-10)
  pa <- as.numeric(survey::svymean(~a, des))
  pb <- as.numeric(survey::svymean(~b, subset(des, !is.na(b))))
  expect_equal(p$expected[p$combination == "a + b"], pa * pb, tolerance = 1e-10)
  expect_equal(nrow(mm_patterns(des, c("a", "b", "c"), order = 3)), 1)
})

test_that("who_standard_population() reproduces the WHO table and aggregates correctly", {
  w <- who_standard_population()
  expect_equal(nrow(w), 21)
  expect_equal(sum(w$weight), 1)
  pct <- c(8.86, 8.69, 8.60, 8.47, 8.22, 7.93, 7.61, 7.15, 6.59, 6.04, 5.37,
           4.55, 3.72, 2.96, 2.21, 1.52, 0.91, 0.44, 0.15, 0.04, 0.005)
  expect_equal(w$weight, pct / sum(pct), tolerance = 1e-12)   # published table, rescaled to 1
  a <- who_standard_population(c(18, 30, 45, 60, 70))
  # 18-29 = 2/5 of 15-19 + 20-24 + 25-29, relative to the 18-69 total
  num <- 0.4 * 8.47 + 8.22 + 7.93
  den <- 0.4 * 8.47 + sum(c(8.22, 7.93, 7.61, 7.15, 6.59, 6.04, 5.37, 4.55, 3.72, 2.96))
  expect_equal(a$weight[1], num / den, tolerance = 1e-12)
  expect_equal(a$age_group, c("18-29", "30-44", "45-59", "60-69"))
})

test_that("mm_standardize() equals the weighted sum of age-specific prevalences", {
  des <- make_des()
  std <- who_standard_population(c(18, 30, 45, 60, 70))
  r <- mm_standardize(des, "a", age_group = "age_group", standard = std)
  p_k <- sapply(std$age_group, function(g) as.numeric(survey::svymean(~a, subset(des, age_group == g))))
  expect_equal(r$standardized, sum(std$weight * p_k), tolerance = 1e-10)
  expect_equal(r$crude, as.numeric(survey::svymean(~a, des)), tolerance = 1e-10)
  expect_true(r$se > 0)
  expect_error(mm_standardize(des, "a", "age_group", c(`18-29` = 1)), "not in")
})

test_that("mm_bounds() lower and upper bounds bracket every imputation", {
  des <- make_des()
  b <- mm_bounds(des, c("a", "b", "c"))
  expect_equal(nrow(b), 3)
  lo <- b$estimate[grepl("lower", b$scenario)]; hi <- b$estimate[grepl("upper", b$scenario)]
  expect_lte(lo, hi)
  v <- des$variables
  ref_lo <- weighted.mean((v$a + ifelse(is.na(v$b), 0, v$b) + v$c) >= 2, v$wt)
  expect_equal(lo, ref_lo, tolerance = 1e-7)
})

test_that("concentration index types follow their closed forms", {
  des <- make_des()
  base <- survey_concentration_index(des, a, wealth)
  mu <- base$Outcome_Mean; C <- base$Concentration_Index
  g <- survey_concentration_index(des, a, wealth, type = "generalized")
  e <- survey_concentration_index(des, a, wealth, type = "erreygers")
  w <- survey_concentration_index(des, a, wealth, type = "wagstaff")
  expect_equal(g$Concentration_Index, mu * C, tolerance = 1e-10)
  expect_equal(e$Concentration_Index, 4 * mu * C, tolerance = 1e-10)
  expect_equal(w$Concentration_Index, C / (1 - mu), tolerance = 1e-10)
  # identical z statistics: each index is a fixed rescaling of the same regression
  expect_equal(g$p_value, base$p_value, tolerance = 1e-8)
  expect_error(survey_concentration_index(des, wealth, wealth, type = "erreygers"), "bounds")
})

test_that("concentration index by group equals separate subset calls", {
  des <- make_des()
  byg <- survey_concentration_index(des, a, wealth, by = "area")
  u <- survey_concentration_index(subset(des, area == "U"), a, wealth)
  expect_equal(byg$Concentration_Index[byg$area == "U"], u$Concentration_Index, tolerance = 1e-10)
  expect_equal(byg$Standard_Error[byg$area == "U"], u$Standard_Error, tolerance = 1e-10)
})

test_that("concentration curve: C = 1 - 2 x area under the curve", {
  des <- make_des()
  cc <- survey_concentration_curve(des, a, wealth)
  expect_equal(cc$cum_population[1], 0)
  expect_equal(tail(cc$cum_outcome, 1), 1)
  auc <- sum(diff(cc$cum_population) * (head(cc$cum_outcome, -1) + tail(cc$cum_outcome, -1)) / 2)
  C <- survey_concentration_index(des, a, wealth)$Concentration_Index
  expect_equal(1 - 2 * auc, C, tolerance = 1e-10)
})

test_that("slope index equals a weighted regression on the fractional rank", {
  des <- make_des()
  r <- survey_slope_index(des, a, wealth)
  v <- des$variables
  o <- order(v$wealth); hi <- cumsum(v$wt[o]); lo <- hi - v$wt[o]
  R <- numeric(nrow(v))
  R[o] <- (ave(lo, v$wealth[o], FUN = min) + ave(hi, v$wealth[o], FUN = max)) / 2 / sum(v$wt)
  expect_equal(r$SII, unname(coef(lm(v$a ~ R, weights = v$wt))[2]), tolerance = 1e-8)
  expect_true(r$RII > 1 && r$SII > 0)   # 'a' was simulated to rise with wealth
})

test_that("design helpers apply the documented conventions", {
  set.seed(1)
  ir <- data.frame(v021 = rep(1:10, each = 5), v023 = rep(1:2, each = 25),
                   v005 = round(runif(50, 5e5, 2e6)), y = rbinom(50, 1, .3))
  d <- dhs_design(ir)
  expect_equal(as.numeric(weights(d)), ir$v005 / 1e6)
  expect_error(dhs_design(ir[, -1]), "v021")
  names(ir)[1:3] <- c("HH1", "stratum", "wmweight")
  expect_s3_class(mics_design(ir, weight = "wmweight"), "survey.design2")
  ir$wmweight[1] <- NA
  expect_message(mics_design(ir, weight = "wmweight"), "dropped")
  names(ir)[1] <- "psu"
  expect_s3_class(suppressMessages(steps_design(ir, weight = "wmweight")), "survey.design2")
})

test_that("ncd_table() formats the survey_prevalence() estimates", {
  des <- make_des()
  t1 <- ncd_table(des, c("a", "b"), by = "sex", labels = c(a = "Cond A"))
  expect_equal(names(t1), c("Indicator", "Overall", "F", "M"))
  expect_equal(t1$Indicator, c("Unweighted n", "Cond A", "b"))
  p <- survey_prevalence(des, "a")
  expect_equal(t1$Overall[2], sprintf("%.1f (%.1f-%.1f)", 100 * p$estimate, 100 * p$lower, 100 * p$upper))
  expect_output(print(t1), "Design-based")
})

test_that("autoplot methods return ggplot objects", {
  des <- make_des()
  expect_s3_class(ggplot2::autoplot(survey_prevalence(des, c("a", "c"), by = "sex")), "ggplot")
  expect_s3_class(ggplot2::autoplot(mm_patterns(des, c("a", "b", "c"))), "ggplot")
  expect_s3_class(ggplot2::autoplot(survey_concentration_curve(des, a, wealth, by = "area")), "ggplot")
  expect_s3_class(ggplot2::autoplot(survey_concentration_index(des, a, wealth, by = "area")), "ggplot")
  s <- multimorbidity_index(des$variables, c("a", "b", "c"))
  d2 <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~wt, data = s, nest = TRUE)
  expect_s3_class(ggplot2::autoplot(suppressMessages(mm_prevalence(d2, by = "sex"))), "ggplot")
})
