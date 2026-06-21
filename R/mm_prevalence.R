#' Population-level multimorbidity estimates from complex survey data
#'
#' Wraps the `survey` package to compute design-weighted multimorbidity
#' prevalence and mean condition count, properly accounting for the
#' stratification, clustering, and sampling weights of a complex survey
#' design (WHO STEPS, DHS, MICS, etc.). This is the step that turns an
#' individual-level score into a defensible population estimate -- run
#' `multimorbidity_index()` first to create `mm_category` and
#' `mm_n_conditions`.
#'
#' @param data A data frame already processed by `multimorbidity_index()`
#'   (must contain `mm_category` and `mm_n_conditions`), plus the survey
#'   design columns named below.
#' @param ids Name of the cluster/PSU column, or `NULL` if the design has
#'   no clustering (e.g. simple random sample).
#' @param strata Name of the stratification column, or `NULL` if the
#'   design is unstratified.
#' @param weights Name of the sampling weight column.
#' @param by Optional single column name to compute subgroup estimates by
#'   (e.g. `"sex"`, `"region"`). `NULL` (default) returns one overall row.
#'   Multi-variable grouping isn't supported yet -- a natural v2 addition.
#' @param nest Passed to `survey::svydesign()`. `TRUE` (default) assumes
#'   cluster IDs repeat across strata (true for most DHS/STEPS-style
#'   designs, where e.g. cluster "1" exists in every region).
#'
#' @return A data frame with one row (or one row per `by` group),
#'   containing `n` (unweighted sample size), `prevalence` /
#'   `prevalence_se` / `prevalence_lower` / `prevalence_upper` (design-
#'   weighted proportion "Multimorbid" with a logit-CI), and
#'   `mean_conditions` / `mean_conditions_se`.
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
  out <- lapply(groups, function(g) {
    sub_design <- design[design$variables[[by]] == g, ]
    cbind(group = g, summarise_design(sub_design))
  })
  out <- do.call(rbind, out)
  names(out)[names(out) == "group"] <- by
  rownames(out) <- NULL
  out
}
