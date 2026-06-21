#' Calculate a self-reported multimorbidity index
#'
#' Computes an individual-level multimorbidity score from a set of
#' self-reported binary condition indicators (e.g. "Has a doctor ever told
#' you that you have hypertension?"). This is designed for population
#' health survey data (WHO STEPS, DHS, SAGE, etc.), where multimorbidity is
#' captured through self-report rather than ICD-coded diagnoses -- a data
#' shape that existing comorbidity packages (which all assume ICD claims
#' data) don't handle.
#'
#' @param data A data frame, one row per individual.
#' @param conditions A character vector of column names in `data`. Each
#'   column must already be coded 0/1/NA (1 = condition present). Use
#'   `recode_binary()` first if your raw data uses Yes/No, 1/2, etc.
#' @param weights Optional named numeric vector giving a weight for each
#'   condition (names must match `conditions`). If `NULL` (the default),
#'   every condition counts equally -- i.e. a simple unweighted sum, which
#'   is how the published Functional Comorbidity Index (Groll et al. 2005)
#'   is scored. See `fci_items()`.
#' @param na_action How to handle a row with at least one missing
#'   condition. `"ignore"` (default) sums whatever conditions are
#'   non-missing for that person. `"na"` returns NA for that person's
#'   index entirely, which is the safer choice once you move to
#'   population-level (survey-weighted) estimates, since silently treating
#'   missing as absent can bias prevalence downward.
#'
#' @return `data` with three columns appended: `mm_n_conditions` (raw
#'   count of conditions present), `mm_index` (the possibly weighted
#'   score), and `mm_category` (factor: "None", "Single condition",
#'   "Multimorbid").
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
  }

  data
}
