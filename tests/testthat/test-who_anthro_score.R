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
