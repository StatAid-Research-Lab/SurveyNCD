#' Calculate a multimorbidity index from self-reported conditions
#'
#' Computes respondent-level multimorbidity from binary condition indicators,
#' tailored to survey datasets where conditions are self-reported rather than
#' ICD-coded.
#'
#' @param data A data frame with one row per respondent.
#' @param conditions A character vector of column names in `data`. Each
#'   column must already be coded 0/1/NA (1 = condition present). Use
#'   `recode_binary()` first if your raw data uses Yes/No, 1/2, etc.
#' @param weights Optional named numeric vector giving a weight for each
#'   condition (names must match `conditions`). If `NULL` (the default),
#'   every condition counts equally -- i.e. a simple unweighted sum, which
#'   is how the published Functional Comorbidity Index (Groll et al. 2005)
#'   is scored. See `fci_items()`.
#' @param na_action How to handle rows with at least one missing condition.
#'   `"ignore"` (default) computes scores from available non-missing
#'   conditions. `"na"` sets the respondent's index fields to `NA`.
#'
#' @return `data` with three appended columns: `mm_n_conditions` (count of
#'   conditions present), `mm_index` (possibly weighted score), and
#'   `mm_category` (`"None"`, `"Single condition"`, `"Multimorbid"`).
#'
#' @references
#' Groll, D. L., To, T., Bombardier, C., & Wright, J. G. (2005). The
#' development of a comorbidity index with physical function as the outcome.
#' \emph{Journal of Clinical Epidemiology}, 58(6), 595-602.
#' \doi{10.1016/j.jclinepi.2004.10.018}
#'
#' @examples
#' df <- data.frame(
#'   id           = 1:5,
#'   hypertension = c(1, 0, 1, 1, 0),
#'   diabetes     = c(0, 0, 1, 1, 0),
#'   arthritis    = c(1, 0, 0, 1, NA)
#' )
#' multimorbidity_index(df, conditions = c("hypertension", "diabetes", "arthritis"))
#' @export
multimorbidity_index <- function(data,
                                  conditions,
                                  weights = NULL,
                                  na_action = c("ignore", "na")) {

  na_action <- match.arg(na_action)

  # ---- 1. validate inputs --------------------------------------------------
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }

  missing_cols <- setdiff(conditions, names(data))
  if (length(missing_cols) > 0) {
    stop(
      "These condition columns are not in `data`: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  cond_df <- data[, conditions, drop = FALSE]

  is_numeric <- vapply(cond_df, is.numeric, logical(1))
  if (!all(is_numeric)) {
    stop(
      "These condition columns are not numeric: ",
      paste(conditions[!is_numeric], collapse = ", "),
      ". Use recode_binary() to convert Yes/No, 1/2, or TRUE/FALSE ",
      "columns to 0/1 first.",
      call. = FALSE
    )
  }

  cond_mat <- as.matrix(cond_df)
  vals <- unique(as.vector(cond_mat))
  vals <- vals[!is.na(vals)]
  bad_vals <- setdiff(vals, c(0, 1))
  if (length(bad_vals) > 0) {
    stop(
      "Condition columns must contain only 0, 1, or NA. Found: ",
      paste(bad_vals, collapse = ", "),
      ". Use recode_binary() to clean these first.",
      call. = FALSE
    )
  }

  # ---- 2. build the weight vector ------------------------------------------
  if (is.null(weights)) {
    w <- stats::setNames(rep(1, length(conditions)), conditions)
  } else {
    if (is.null(names(weights)) || !all(conditions %in% names(weights))) {
      stop(
        "`weights` must be a named numeric vector with one entry for ",
        "every name in `conditions`.",
        call. = FALSE
      )
    }
    w <- weights[conditions]
  }

  # ---- 3. compute the index -------------------------------------------
  weighted_mat <- sweep(cond_mat, 2, w, `*`)
  na_rm <- (na_action == "ignore")

  data$mm_n_conditions <- rowSums(cond_mat, na.rm = na_rm)
  data$mm_index        <- rowSums(weighted_mat, na.rm = na_rm)

  # Check if all conditions are missing for each respondent
  all_na <- rowSums(!is.na(cond_mat)) == 0

  data$mm_category <- cut(
    data$mm_n_conditions,
    breaks = c(-Inf, 0, 1, Inf),
    labels = c("None", "Single condition", "Multimorbid")
  )

  if (na_action == "na") {
    has_na <- rowSums(is.na(cond_mat)) > 0
    data$mm_n_conditions[has_na] <- NA
    data$mm_index[has_na]        <- NA
    data$mm_category[has_na]     <- NA
  } else {
    # Even if ignoring individual NAs, a respondent with ALL conditions missing must be NA
    data$mm_n_conditions[all_na] <- NA
    data$mm_index[all_na]        <- NA
    data$mm_category[all_na]     <- NA
  }

  data
}
