test_that("recode_binary() handles numeric and character coding", {
  expect_equal(recode_binary(c(1, 2, 1), yes = 1, no = 2), c(1, 0, 1))
  expect_equal(
    recode_binary(c("Yes", "No"), yes = "Yes", no = "No"),
    c(1, 0)
  )
})

test_that("recode_binary() leaves unmatched values as NA, with a warning", {
  expect_warning(
    r <- recode_binary(c(1, 2, 9), yes = 1, no = 2)
  )
  expect_equal(r, c(1, 0, NA_real_))
})

test_that("recode_binary() preserves existing NAs", {
  expect_equal(recode_binary(c(1, NA, 2), yes = 1, no = 2), c(1, NA, 0))
})

test_that("recode_binary() validates yes/no definitions", {
  expect_error(recode_binary(c(1, 2), yes = numeric(0), no = 2))
  expect_error(recode_binary(c(1, 2), yes = 1, no = c(1, 2)))
})
