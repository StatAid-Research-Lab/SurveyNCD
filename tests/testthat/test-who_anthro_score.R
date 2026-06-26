test_that("who_anthro_score() applies the correct WHO severity cutoffs", {
  z <- c(-4.0, -3.0, -2.5, -2.0, -1.0, 0)
  res <- who_anthro_score(z * 100, indicator = "stunting")  # DHS-style x100 scaling
  expect_equal(
    as.character(res),
    c("Severe stunting", "Moderate stunting", "Moderate stunting",
      "Normal stunting", "Normal stunting", "Normal stunting")
  )
})

test_that("who_anthro_score() converts DHS missing-value flags to NA", {
  res <- who_anthro_score(c(-200, 9996, 9999), indicator = "wasting")
  expect_true(is.na(res[2]))
  expect_true(is.na(res[3]))
  expect_false(is.na(res[1]))
})

test_that("who_anthro_score() requires a valid indicator", {
  expect_error(who_anthro_score(c(-200), indicator = "not_a_real_indicator"))
})

test_that("who_anthro_score() removes biologically implausible values (WHO flags)", {
  # HAZ flags: < -6.0 or > 6.0
  res_stunting <- who_anthro_score(c(-650, -300, 200, 650), indicator = "stunting")
  expect_true(is.na(res_stunting[1]))   # -6.5 HAZ is NA
  expect_false(is.na(res_stunting[2]))  # -3.0 HAZ is OK
  expect_true(is.na(res_stunting[4]))   # 6.5 HAZ is NA

  # WHZ flags: < -5.0 or > 5.0
  res_wasting <- who_anthro_score(c(-550, -200, 550), indicator = "wasting")
  expect_true(is.na(res_wasting[1]))
  expect_true(is.na(res_wasting[3]))

  # WAZ flags: < -6.0 or > 5.0
  res_underweight <- who_anthro_score(c(-650, -200, 550), indicator = "underweight")
  expect_true(is.na(res_underweight[1]))
  expect_true(is.na(res_underweight[3]))

  # Disabling flag removal should retain these values
  res_noflags <- who_anthro_score(c(-650, 650), indicator = "stunting", remove_implausible = FALSE)
  expect_false(is.na(res_noflags[1]))
  expect_false(is.na(res_noflags[2]))
})

test_that("who_anthro_score() handles unscaled (already divided by 100) z-scores", {
  res <- who_anthro_score(c(-2.5, 0.5), indicator = "stunting", scaled_by_100 = FALSE)
  expect_equal(as.character(res), c("Moderate stunting", "Normal stunting"))
})
