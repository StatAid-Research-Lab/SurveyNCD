#' Plot SHAP Summary
#'
#' @param shap_matrix The matrix output from survey_shap().
#' @param data The original dataframe used for training (to provide feature values).
#'
#' @return A ggplot2 object.
#' @export
#' @import ggplot2
#' @importFrom tidyr pivot_longer
#' @importFrom dplyr everything
plot_shap_summary <- function(shap_matrix, data) {
  # Convert matrix to long format for ggplot
  shap_df <- as.data.frame(shap_matrix)
  # Remove the intercept column for plotting
  shap_df$'(Intercept)' <- NULL

  shap_long <- shap_df %>%
    tidyr::pivot_longer(everything(), names_to = "feature", values_to = "shap_value")

  # .data$feature / .data$shap_value (rather than bare feature/shap_value)
  # tells R CMD check these are data-frame columns created above, not
  # undefined global variables -- it's a static-analysis fix, the
  # function's behavior is unchanged.
  ggplot(shap_long, aes(x = .data$feature, y = .data$shap_value, color = .data$shap_value)) +
    geom_jitter(width = 0.2, alpha = 0.5) +
    coord_flip() +
    theme_minimal() +
    labs(title = "SHAP Summary Plot", x = "Feature", y = "SHAP value (Impact on Prediction)")
}
