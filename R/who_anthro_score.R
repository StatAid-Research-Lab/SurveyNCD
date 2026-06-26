#' Calculate WHO Anthropometric Categories from DHS/MICS Data
#'
#' Cleans raw DHS/MICS z-score variables (e.g., hw70, hw71, hw72), adjusts the
#' decimal scaling if needed, handles DHS-specific missing flags, applies WHO
#' biologically implausible flagging rules, and categorizes them into WHO severity tiers.
#'
#' @param x A numeric vector of raw DHS/MICS z-scores.
#' @param indicator The type of indicator for labeling and flagging: `"stunting"`
#'   (height-for-age, HAZ), `"wasting"` (weight-for-height, WHZ), or
#'   `"underweight"` (weight-for-age, WAZ).
#' @param scaled_by_100 Logical. If `TRUE` (default), divides input values by
#'   100 (standard for DHS raw recode files like `hw70`). If `FALSE`, assumes values
#'   are already on the standard z-score scale (like MICS or cleaned DHS data).
#' @param remove_implausible Logical. If `TRUE` (default), applies WHO child growth
#'   standard flagging rules to set biologically implausible values to `NA`.
#'   WHO flags are:
#'   \itemize{
#'     \item Stunting (HAZ): < -6.0 or > 6.0
#'     \item Wasting (WHZ): < -5.0 or > 5.0
#'     \item Underweight (WAZ): < -6.0 or > 5.0
#'   }
#'
#' @return A factor vector of WHO categories (Severe, Moderate, Normal) with the
#'   indicator label appended.
#' @export
who_anthro_score <- function(x, indicator = c("stunting", "wasting", "underweight"),
                             scaled_by_100 = TRUE, remove_implausible = TRUE) {
  # Ensure the user picks a valid indicator
  indicator <- match.arg(indicator)

  # 1. Handle DHS missing/flagged codes (safely converting them to NA)
  x_clean <- ifelse(x %in% c(9996, 9998, 9999, 999, 9997), NA_real_, x)

  # 2. Convert scale if needed
  z_score <- if (scaled_by_100) x_clean / 100 else x_clean

  # 3. Apply WHO child growth standards flagging rules (biologically implausible values)
  if (remove_implausible) {
    if (indicator == "stunting") {
      # HAZ flags: < -6.0 or > 6.0
      z_score[z_score < -6.0 | z_score > 6.0] <- NA_real_
    } else if (indicator == "wasting") {
      # WHZ flags: < -5.0 or > 5.0
      z_score[z_score < -5.0 | z_score > 5.0] <- NA_real_
    } else if (indicator == "underweight") {
      # WAZ flags: < -6.0 or > 5.0
      z_score[z_score < -6.0 | z_score > 5.0] <- NA_real_
    }
  }

  # 4. Categorize according to strict WHO thresholds
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



