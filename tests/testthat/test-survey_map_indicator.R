test_that("survey_map_indicator() validates required input structures", {
  survey_data <- data.frame(region = c("A", "B"), value = c(1, 2))
  bad_shape <- data.frame(region = c("A", "B"))

  expect_error(survey_map_indicator(list(), bad_shape, "region", "value"))
  expect_error(survey_map_indicator(survey_data, bad_shape, "region", "value"))
  expect_error(survey_map_indicator(survey_data, structure(list(), class = "sf"), "region", "missing_value"))
  expect_error(
    survey_map_indicator(
      data.frame(region = c("A", "B"), value = c("x", "y")),
      structure(list(region = c("A", "B")), class = "sf"),
      "region",
      "value"
    )
  )
})
