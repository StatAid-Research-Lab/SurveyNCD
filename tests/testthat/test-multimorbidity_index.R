test_that("multimorbidity_index() counts conditions correctly", {
  df <- data.frame(
    id = 1:4,
    a  = c(1, 0, 1, 1),
    b  = c(0, 0, 1, 1),
    c  = c(1, 0, 0, NA)
  )

  res <- multimorbidity_index(df, conditions = c("a", "b", "c"))

  # row 4 is a=1, b=1, c=NA -- with the default na_action = "ignore", the
  # NA is skipped rather than treated as 0, so it correctly counts as 2.
  expect_equal(res$mm_n_conditions, c(2, 0, 2, 2))
  expect_equal(
    as.character(res$mm_category),
    c("Multimorbid", "None", "Multimorbid", "Multimorbid")
  )
})

test_that("na_action = 'na' propagates missingness instead of ignoring it", {
  df <- data.frame(a = c(1, 1), b = c(1, NA))
  res <- multimorbidity_index(df, conditions = c("a", "b"), na_action = "na")
  expect_false(is.na(res$mm_index[1]))
  expect_true(is.na(res$mm_index[2]))
})

test_that("custom weights apply correctly", {
  df <- data.frame(a = 1, b = 1, c = 0)
  res <- multimorbidity_index(
    df, conditions = c("a", "b", "c"),
    weights = c(a = 1, b = 2, c = 3)
  )
  expect_equal(res$mm_index, 3)  # 1*1 + 1*2 + 0*3
})

test_that("invalid input raises an error instead of silently miscoding", {
  df <- data.frame(a = c(1, 2, 3))  # 2 and 3 are not valid 0/1 codes
  expect_error(multimorbidity_index(df, conditions = "a"))
  expect_error(multimorbidity_index(df, conditions = "not_a_real_column"))
})

test_that("weights must be a named vector covering every condition", {
  df <- data.frame(a = c(1, 0), b = c(1, 1))
  expect_error(
    multimorbidity_index(df, conditions = c("a", "b"), weights = c(1, 2))
  )
})

test_that("multimorbidity_index() handles rows with all missing values correctly", {
  df <- data.frame(a = c(NA, 1), b = c(NA, 0))
  # With default na_action = "ignore", the all-NA row should still be evaluated as NA, not 0
  res <- multimorbidity_index(df, conditions = c("a", "b"))
  expect_true(is.na(res$mm_n_conditions[1]))
  expect_true(is.na(res$mm_index[1]))
  expect_true(is.na(res$mm_category[1]))

  # Row 2 (which has data) should be OK
  expect_equal(res$mm_n_conditions[2], 1)
  expect_equal(as.character(res$mm_category[2]), "Single condition")
})
