#' Calculate WHO Anthropometric Categories from DHS Data
#'
#' Cleans raw DHS z-score variables (e.g., hw70, hw71, hw72), adjusts the decimal
#' scaling, handles DHS-specific missing flags, and categorizes them into WHO
#' severity tiers.
#'
#' @param x A numeric vector of raw DHS z-scores.
#' @param indicator The type of indicator for labeling (e.g., "stunting", "wasting").
#'
#' @return A factor vector of WHO categories (Severe, Moderate, Normal).
#' @export
who_anthro_score <- function(x, indicator = c("stunting", "wasting", "underweight")) {
  # Ensure the user picks a valid indicator
  indicator <- match.arg(indicator)

  # 1. Handle DHS missing/flagged codes (safely converting them to NA)
  x_clean <- ifelse(x %in% c(9996, 9998, 9999, 999, 9997), NA_real_, x)

  # 2. Convert DHS integer format to actual Z-scores
  z_score <- x_clean / 100

  # 3. Categorize according to strict WHO thresholds
  # < -3.0 is Severe | -3.0 to -2.0 is Moderate | >= -2.0 is Normal
  category <- cut(
    z_score,
    breaks = c(-Inf, -3.0, -2.0, Inf),
    labels = c("Severe", "Moderate", "Normal"),
    right = FALSE
  )

  # Attach the indicator name for cleaner table outputs
  levels(category) <- paste(levels(category), indicator)

  return(category)
}



