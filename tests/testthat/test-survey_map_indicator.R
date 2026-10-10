test_that("survey_map_indicator() returns a renderable ggplot and validates inputs", {
  testthat::skip_if_not_installed("sf")

  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  metrics <- data.frame(
    NAME       = c("Ashe", "Alleghany", "Surry"),
    prevalence = c(0.12, 0.08, 0.15)
  )

  p <- survey_map_indicator(metrics, nc, join_by = "NAME", fill_var = "prevalence")
  expect_s3_class(p, "ggplot")
  # regions without an estimate stay on the map (NA fill), none are dropped
  expect_equal(nrow(p$data), nrow(nc))
  expect_s3_class(ggplot2::ggplot_build(p), "ggplot_built")

  # custom palette and legend title are accepted
  p2 <- survey_map_indicator(metrics, nc, "NAME", "prevalence",
                             palette = "viridis", legend_title = "Prevalence")
  expect_s3_class(p2, "ggplot")

  # join column missing from the survey data / from the shapefile
  expect_error(
    survey_map_indicator(metrics[, "prevalence", drop = FALSE], nc, "NAME", "prevalence"),
    "survey_data"
  )
  bad <- transform(metrics, zzz = NAME)
  expect_error(survey_map_indicator(bad, nc, "zzz", "prevalence"), "shapefile")

  # invalid palette is rejected
  expect_error(survey_map_indicator(metrics, nc, "NAME", "prevalence", palette = "nope"))
})
