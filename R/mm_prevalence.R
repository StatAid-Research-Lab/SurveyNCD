#' Population-level multimorbidity estimates from complex survey data
#'
#' Design-weighted prevalence of multimorbidity and mean number of
#' conditions, accounting for stratification, clustering and sampling weights.
#' Run [multimorbidity_index()] first to create `mm_category` and
#' `mm_n_conditions`.
#'
#' `data` can be either a survey design object (recommended; for example from
#' [dhs_design()] or [survey::svydesign()]) or a data frame plus the names of
#' the design columns. Respondents with a missing multimorbidity score are
#' excluded by domain estimation: the full design is kept for variance
#' estimation and the number excluded is reported.
#'
#' @param data A survey design whose data contain the output of
#'   [multimorbidity_index()], or such a data frame.
#' @param ids,strata,weights Column names of the clusters, strata and weights
#'   (only when `data` is a data frame). `ids = NULL` means no clustering and
#'   `strata = NULL` no stratification.
#' @param by Optional character vector of one or more grouping columns.
#' @param nest Passed to [survey::svydesign()] when `data` is a data frame.
#' @param level Confidence level.
#'
#' @return A data frame of class `surveyncd_mm_prevalence` with any `by`
#'   columns, `n`, `prevalence`, `prevalence_se`, `prevalence_lower`,
#'   `prevalence_upper`, `mean_conditions` and `mean_conditions_se`.
#'
#' @examples
#' set.seed(1)
#' n <- 40
#' df <- data.frame(
#'   psu    = rep(1:8, each = 5),
#'   region = rep(c("A", "B"), each = 20),
#'   sex    = rep(c("F", "M"), 20),
#'   wt     = round(runif(n, 0.8, 1.4), 2),
#'   htn    = rbinom(n, 1, 0.3),
#'   dm     = rbinom(n, 1, 0.2)
#' )
#' scored <- multimorbidity_index(df, conditions = c("htn", "dm"))
#' mm_prevalence(scored, ids = "psu", strata = "region", weights = "wt")
#'
#' # Design-first interface, several grouping variables
#' des <- survey::svydesign(ids = ~psu, strata = ~region, weights = ~wt,
#'                          data = scored, nest = TRUE)
#' mm_prevalence(des, by = c("region", "sex"))
#' @export
#' @importFrom survey svydesign svyciprop svymean SE
mm_prevalence <- function(data, ids = NULL, strata = NULL, weights = NULL,
                          by = NULL, nest = TRUE, level = 0.95) {
  old <- .lonely_adjust(); on.exit(options(old), add = TRUE)

  if (inherits(data, "survey.design") || inherits(data, "svyrep.design")) {
    design <- data
  } else {
    if (!is.data.frame(data)) {
      stop("`data` must be a survey design or a data frame.", call. = FALSE)
    }
    if (is.null(weights)) stop("Supply `weights` when `data` is a data frame.", call. = FALSE)
    cols <- c(ids, strata, weights)
    miss <- setdiff(cols, names(data))
    if (length(miss) > 0) {
      stop("Column '", miss[1], "' not found in `data`.", call. = FALSE)
    }
    design <- survey::svydesign(
      ids     = if (is.null(ids)) ~1 else stats::as.formula(paste0("~`", ids, "`")),
      strata  = if (is.null(strata)) NULL else stats::as.formula(paste0("~`", strata, "`")),
      weights = stats::as.formula(paste0("~`", weights, "`")),
      data    = data, nest = nest
    )
  }

  required <- c("mm_category", "mm_n_conditions")
  miss_req <- setdiff(required, names(design$variables))
  if (length(miss_req) > 0) {
    stop("`data` is missing: ", paste(miss_req, collapse = ", "),
         ". Run multimorbidity_index() first.", call. = FALSE)
  }
  if (!is.null(by)) .check_vars(design, by, "`by` column")

  v <- design$variables
  valid <- !is.na(v$mm_category) & !is.na(v$mm_n_conditions)
  n_dropped <- sum(!valid & .design_weights(design) > 0)
  if (n_dropped > 0) {
    message(n_dropped, " of ", sum(.design_weights(design) > 0),
            " rows have a missing multimorbidity score and are excluded from ",
            "the survey-weighted estimate.")
  }
  design <- .set_var(design, "mm_multimorbid",
                     as.numeric(as.character(v$mm_category) == "Multimorbid"))
  design <- design[valid, ]

  doms <- .domains(design, by)
  out <- do.call(rbind, lapply(doms, function(g) {
    d <- g$design
    n <- sum(.design_weights(d) > 0)
    prev <- suppressWarnings(survey::svyciprop(~mm_multimorbid, d, method = "logit",
                                               level = level))
    ci <- attr(prev, "ci")
    mc <- survey::svymean(~mm_n_conditions, d)
    .bind_key(g$key, data.frame(
      n                  = n,
      prevalence         = as.numeric(prev),
      prevalence_se      = as.numeric(survey::SE(prev)),
      prevalence_lower   = unname(ci[1]),
      prevalence_upper   = unname(ci[2]),
      mean_conditions    = as.numeric(mc),
      mean_conditions_se = as.numeric(survey::SE(mc))
    ))
  }))
  rownames(out) <- NULL
  structure(out, class = c("surveyncd_mm_prevalence", "data.frame"), by = by)
}
