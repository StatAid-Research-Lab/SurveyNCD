#' Design-weighted multimorbidity prevalence and severity
#'
#' Computes population-level multimorbidity estimates from complex survey data,
#' accounting for weights and optional clustering/stratification. Run
#' `multimorbidity_index()` first to create required fields.
#'
#' @param data A data frame that already contains `mm_category` and
#'   `mm_n_conditions` (typically from `multimorbidity_index()`), plus the
#'   survey design columns referenced below.
#' @param ids Name of the cluster/PSU column, or `NULL` if the design has
#'   no clustering (e.g. simple random sample).
#' @param strata Name of the stratification column, or `NULL` if the
#'   design is unstratified.
#' @param weights Name of the sampling weight column.
#' @param by Optional single column name for subgroup estimates (e.g.
#'   `"sex"` or `"region"`). `NULL` returns one overall estimate row.
#' @param nest Passed to `survey::svydesign()`. `TRUE` (default) assumes
#'   cluster IDs repeat across strata (true for most DHS/STEPS-style
#'   designs, where e.g. cluster "1" exists in every region).
#'
#' @return A data frame with one row (or one row per `by` level), containing:
#'   `n`, `prevalence`, `prevalence_se`, `prevalence_lower`,
#'   `prevalence_upper`, `mean_conditions`, and `mean_conditions_se`.
#'
#' @examples
#' \dontrun{
#' scored <- multimorbidity_index(steps_data, conditions = c("htn", "dm"))
#' mm_prevalence(scored, ids = "psu", strata = "region", weights = "wt")
#' mm_prevalence(scored, ids = "psu", strata = "region", weights = "wt",
#'               by = "sex")
#' }
#' @export
#' @importFrom survey svydesign svyciprop svymean SE
mm_prevalence <- function(data, ids = NULL, strata = NULL, weights,
                           by = NULL, nest = TRUE) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  if (missing(weights) || !is.character(weights) || length(weights) != 1 || is.na(weights)) {
    stop("`weights` must be a single column name in `data`.", call. = FALSE)
  }

  required_cols <- c("mm_category", "mm_n_conditions")
  missing_req <- setdiff(required_cols, names(data))
  if (length(missing_req) > 0) {
    stop(
      "`data` is missing: ", paste(missing_req, collapse = ", "),
      ". Run multimorbidity_index() first.",
      call. = FALSE
    )
  }

  build_formula <- function(col) {
    if (is.null(col)) return(~1)
    if (!is.character(col) || length(col) != 1 || is.na(col)) {
      stop("Design columns must be provided as single column names.", call. = FALSE)
    }
    if (!col %in% names(data)) {
      stop("Column '", col, "' not found in `data`.", call. = FALSE)
    }
    stats::as.formula(paste0("~", col))
  }

  ids_f     <- build_formula(ids)
  strata_f  <- if (is.null(strata)) NULL else build_formula(strata)
  weights_f <- build_formula(weights)

  if (!is.null(by) && !by %in% names(data)) {
    stop("`by` column '", by, "' not found in `data`.", call. = FALSE)
  }

  n_dropped <- sum(is.na(data$mm_category) | is.na(data$mm_n_conditions))
  if (n_dropped > 0) {
    message(
      n_dropped, " of ", nrow(data), " rows have a missing multimorbidity ",
      "score and are excluded from the survey-weighted estimate."
    )
  }
  data <- data[!is.na(data$mm_category) & !is.na(data$mm_n_conditions), ]
  if (nrow(data) == 0) {
    stop(
      "No complete rows remain after removing missing `mm_category`/`mm_n_conditions`.",
      call. = FALSE
    )
  }
  data$mm_multimorbid <- as.numeric(data$mm_category == "Multimorbid")

  design <- survey::svydesign(
    ids = ids_f, strata = strata_f, weights = weights_f,
    data = data, nest = nest
  )

  summarise_design <- function(d) {
    prev      <- survey::svyciprop(~mm_multimorbid, d, method = "logit")
    ci        <- attr(prev, "ci")
    mean_cond <- survey::svymean(~mm_n_conditions, d)

    data.frame(
      n                  = nrow(d$variables),
      prevalence         = as.numeric(prev),
      prevalence_se      = as.numeric(survey::SE(prev)),
      prevalence_lower   = unname(ci[1]),
      prevalence_upper   = unname(ci[2]),
      mean_conditions    = as.numeric(mean_cond),
      mean_conditions_se = as.numeric(survey::SE(mean_cond))
    )
  }

  if (is.null(by)) {
    return(summarise_design(design))
  }

  groups <- sort(unique(data[[by]]))
  groups <- groups[!is.na(groups)] # Exclude NA grouping category
  
  out <- lapply(groups, function(g) {
    # subset() is the mathematically correct way to perform domain estimation on survey designs
    sub_design <- subset(design, design$variables[[by]] %in% g)
    cbind(group = g, summarise_design(sub_design))
  })
  out <- do.call(rbind, out)
  names(out)[names(out) == "group"] <- by
  rownames(out) <- NULL
  out
}
