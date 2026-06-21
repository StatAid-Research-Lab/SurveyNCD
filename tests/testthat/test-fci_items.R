test_that("fci_items() returns the 18 standard, unique FCI conditions", {
  items <- fci_items()
  expect_length(items, 18)
  expect_equal(length(unique(items)), 18)
  expect_type(items, "character")
})
