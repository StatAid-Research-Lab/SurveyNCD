#' Plot SHAP Summary
#'
#' Generates a SHAP summary plot (similar to the Python `shap` package) where
#' features are ranked on the y-axis by their overall importance (mean absolute
#' SHAP value), SHAP values are shown on the x-axis, and each point (representing
#' a respondent) is colored by its relative value for that feature (blue for low,
#' red for high).
#'
#' @param shap_matrix The matrix output from \code{survey_shap()}.
#' @param data The matrix or data frame of training features (e.g. the \code{X}
#'   matrix returned by \code{survey_xgboost()}) or the original data frame. If
#'   the row count does not match the SHAP matrix, rows with missing values
#'   will be automatically filtered out.
#' @param low_color A character string for the color representing low feature values.
#'   Default is \code{"#1e88e5"} (standard SHAP blue).
#' @param high_color A character string for the color representing high feature values.
#'   Default is \code{"#ff0052"} (standard SHAP red).
#' @param title A character string for the plot title. Default is \code{"SHAP Summary Plot"}.
#' @param subtitle A character string for the plot subtitle. Default is
#'   \code{"Feature impact on model predictions (ranked by mean absolute SHAP)"}.
#'
#' @return A ggplot2 object.
#' @export
#' @import ggplot2
#' @importFrom tidyr pivot_longer
#' @importFrom dplyr left_join group_by mutate ungroup everything arrange summarize
#' @importFrom stats complete.cases
plot_shap_summary <- function(shap_matrix, data,
                              low_color = "#1e88e5",
                              high_color = "#ff0052",
                              title = "SHAP Summary Plot",
                              subtitle = "Feature impact on model predictions (ranked by mean absolute SHAP)") {
  # Convert SHAP matrix to data frame
  shap_df <- as.data.frame(shap_matrix)
  # Remove the intercept column for plotting
  shap_df$'(Intercept)' <- NULL

  features <- colnames(shap_df)

  # Validate and align feature data
  if (is.matrix(data) || is.data.frame(data)) {
    if (nrow(data) == nrow(shap_df)) {
      feat_df <- as.data.frame(data)[, features, drop = FALSE]
    } else {
      # Try to align by complete cases of the SHAP features
      keep_rows <- stats::complete.cases(data[, features, drop = FALSE])
      feat_df <- as.data.frame(data)[keep_rows, features, drop = FALSE]
      if (nrow(feat_df) != nrow(shap_df)) {
        stop(
          "The number of rows in `data` (after filtering for complete cases of features: ", nrow(feat_df), ") ",
          "does not match the number of rows in `shap_matrix` (", nrow(shap_df), "). ",
          "Please ensure they represent the exact same subset of observations, ",
          "or pass the training feature matrix (e.g. `model$X` from `survey_xgboost`).",
          call. = FALSE
        )
      }
    }
  } else {
    stop("`data` must be a matrix or data frame containing the features.", call. = FALSE)
  }

  # Add row IDs for pivoting and joining
  shap_df$row_id <- seq_len(nrow(shap_df))
  feat_df$row_id <- seq_len(nrow(feat_df))

  # Pivot long
  shap_long <- tidyr::pivot_longer(
    shap_df,
    cols = -row_id,
    names_to = "feature",
    values_to = "shap_value"
  )
  feat_long <- tidyr::pivot_longer(
    feat_df,
    cols = -row_id,
    names_to = "feature",
    values_to = "feature_value"
  )

  # Join SHAP values and feature values
  plot_df <- dplyr::left_join(shap_long, feat_long, by = c("row_id", "feature"))

  # Normalize feature values between 0 (Low) and 1 (High) within each feature
  plot_df <- plot_df %>%
    dplyr::group_by(.data$feature) %>%
    dplyr::mutate(
      min_val = min(.data$feature_value, na.rm = TRUE),
      max_val = max(.data$feature_value, na.rm = TRUE),
      scaled_value = ifelse(
        .data$max_val == .data$min_val,
        0.5,
        (.data$feature_value - .data$min_val) / (.data$max_val - .data$min_val)
      )
    ) %>%
    dplyr::ungroup()

  # Calculate mean absolute SHAP value for each feature to rank them by importance
  importance <- plot_df %>%
    dplyr::group_by(.data$feature) %>%
    dplyr::summarize(
      mean_abs_shap = mean(abs(.data$shap_value), na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::arrange(.data$mean_abs_shap)

  # Set factor levels of feature based on importance order (coord_flip puts last level at the top)
  plot_df$feature <- factor(plot_df$feature, levels = importance$feature)

  # Create the SHAP summary plot using premium aesthetics
  ggplot(plot_df, aes(x = .data$feature, y = .data$shap_value, color = .data$scaled_value)) +
    geom_jitter(width = 0.25, alpha = 0.65, size = 1.6) +
    geom_hline(yintercept = 0, color = "grey40", linetype = "dashed", linewidth = 0.4) +
    coord_flip() +
    theme_classic(base_size = 11) +
    scale_color_gradient(
      low = low_color,
      high = high_color,
      name = "Feature Value",
      breaks = c(0, 1),
      labels = c("Low", "High")
    ) +
    labs(
      title = title,
      subtitle = subtitle,
      x = "Feature",
      y = "SHAP value (Impact on Prediction)"
    ) +
    theme(
      plot.title = element_text(face = "bold", size = 13, hjust = 0),
      plot.subtitle = element_text(color = "grey30", size = 9, hjust = 0),
      axis.title = element_text(face = "bold", size = 10),
      axis.text = element_text(color = "black", size = 9),
      axis.line = element_line(color = "black", linewidth = 0.5),
      axis.ticks = element_line(color = "black", linewidth = 0.5),
      legend.position = "right",
      legend.title = element_text(face = "bold", size = 9),
      legend.text = element_text(size = 8)
    )
}
