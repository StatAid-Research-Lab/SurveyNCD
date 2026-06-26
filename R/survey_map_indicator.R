#' Map Survey Indicators Universally
#'
#' This function merges calculated survey indicators with any provided
#' spatial shapefile to generate a publication-ready thematic map.
#'
#' @param survey_data A data frame containing the aggregated survey indicators.
#' @param shapefile An `sf` spatial object containing regional boundaries.
#' @param join_by A character string of the column name present in both datasets to merge on.
#' @param fill_var A character string of the variable in `survey_data` to map (e.g., "Concentration_Index").
#'
#' @return A ggplot2 spatial map object.
#' @export
#'
#' @importFrom dplyr left_join
#' @importFrom rlang sym
#' @import ggplot2
survey_map_indicator <- function(survey_data, shapefile, join_by, fill_var) {

  # sf is Suggests-only, so it is checked at call time
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop(
      "Package 'sf' is required for survey_map_indicator() but is not ",
      "installed. Install it with install.packages(\"sf\").",
      call. = FALSE
    )
  }

  # Defensive check: Ensure the join column exists in both datasets
  if (!(join_by %in% names(survey_data))) {
    stop("The join_by column does not exist in your survey_data.")
  }
  if (!(join_by %in% names(shapefile))) {
    stop("The join_by column does not exist in your shapefile.")
  }

  # Merge the spatial data with the survey data
  merged_sf <- shapefile %>%
    dplyr::left_join(survey_data, by = join_by)

  # Generate the universal map
  map_plot <- ggplot2::ggplot(data = merged_sf) +
    ggplot2::geom_sf(ggplot2::aes(fill = !!rlang::sym(fill_var)), color = "white", linewidth = 0.2) +
    ggplot2::scale_fill_viridis_c(option = "magma", na.value = "grey90") +
    ggplot2::theme_void() +
    ggplot2::theme(legend.position = "bottom") +
    ggplot2::labs(fill = fill_var)

  return(map_plot)
}
