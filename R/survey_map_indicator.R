#' Map Survey Indicators Universally
#'
#' This function merges calculated survey indicators with any provided
#' spatial shapefile to generate a publication-ready thematic map.
#'
#' @param survey_data A data frame containing the aggregated survey indicators.
#' @param shapefile An `sf` spatial object containing regional boundaries.
#' @param join_by A character string of the column name present in both datasets to merge on.
#' @param fill_var A character string of the variable in `survey_data` to map (e.g., "Concentration_Index").
#' @param palette A character string specifying the viridis color palette option to use:
#'   `"magma"` (default), `"viridis"`, `"plasma"`, `"inferno"`, or `"cividis"`.
#' @param legend_title A character string for the legend title. If `NULL` (default),
#'   the `fill_var` name is used.
#' @param border_color A character string for the region border line color. Default is `"white"`.
#' @param border_width A numeric value for the border line width. Default is `0.2`.
#'
#' @return A ggplot2 spatial map object.
#' @export
#'
#' @importFrom dplyr left_join
#' @importFrom rlang sym
#' @import ggplot2
survey_map_indicator <- function(survey_data, shapefile, join_by, fill_var,
                                 palette = c("magma", "viridis", "plasma", "inferno", "cividis"),
                                 legend_title = NULL, border_color = "white", border_width = 0.2) {

  # sf is Suggests-only, so it is checked at call time
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop(
      "Package 'sf' is required for survey_map_indicator() but is not ",
      "installed. Install it with install.packages(\"sf\").",
      call. = FALSE
    )
  }

  palette <- match.arg(palette)
  leg_title <- if (is.null(legend_title)) fill_var else legend_title

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
    ggplot2::geom_sf(ggplot2::aes(fill = !!rlang::sym(fill_var)), color = border_color, linewidth = border_width) +
    ggplot2::scale_fill_viridis_c(
      option = palette,
      na.value = "grey90",
      guide = guide_colorbar(
        title.position = "top",
        title.hjust = 0.5,
        barwidth = unit(15, "lines"),
        barheight = unit(0.5, "lines")
      )
    ) +
    ggplot2::theme_void(base_size = 11) +
    ggplot2::theme(
      legend.position = "bottom",
      legend.title = element_text(face = "bold", size = 10),
      legend.text = element_text(size = 9),
      plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
      plot.margin = margin(5, 5, 5, 5)
    ) +
    ggplot2::labs(fill = leg_title)

  return(map_plot)
}
