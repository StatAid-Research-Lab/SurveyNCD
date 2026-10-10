#' Build a survey design from DHS, MICS or STEPS microdata
#'
#' Thin wrappers around [survey::svydesign()] that use each programme's
#' standard variable names, so the design (clusters, strata, weights) is
#' specified correctly in one line.
#'
#' * **DHS**: the Guide to DHS Statistics identifies the primary sampling unit
#'   as `v021` (`hv021`/`mv021` in household and men's files), the strata as
#'   `v023` (`hv023`/`mv023`) and the weight as `v005` (`hv005`/`mv005`)
#'   divided by 1,000,000. Check the survey report (Appendix A) where strata
#'   were not consistently defined.
#' * **MICS**: clusters are `HH1` and strata `stratum`; the weight depends on
#'   the file (`hhweight`, `wmweight`, `mnweight`, `chweight`, `fsweight`), so
#'   it must be given.
#' * **STEPS**: clusters are usually `psu` and strata `stratum`; the weight
#'   depends on the step analysed (`wstep1`, `wstep2`, `wstep3`), so it must
#'   be given. A design built with the \pkg{stepssurvey} package can be passed
#'   to SurveyNCD functions directly instead.
#'
#' All three set `nest = TRUE`, because cluster numbers are typically reused
#' across strata, and drop rows with a missing or non-positive weight with a
#' message.
#'
#' @param data A data frame of survey microdata.
#' @param psu,strata,weight Names of the cluster, stratum and weight columns.
#'   Set `strata = NULL` for an unstratified design.
#' @param weight_scale Number the weight is divided by (1e6 for raw DHS
#'   weights; 1 if the weight has already been rescaled).
#' @param ... Further arguments passed to [survey::svydesign()].
#'
#' @return A `survey.design2` object.
#'
#' @references
#' ICF. Guide to DHS Statistics: Analyzing DHS data.
#' \url{https://dhsprogram.com/data/Guide-to-DHS-Statistics/Analyzing_DHS_Data.htm}
#'
#' @examples
#' # A toy individual-recode extract with DHS variable names
#' set.seed(1)
#' ir <- data.frame(
#'   v021 = rep(1:20, each = 10),
#'   v023 = rep(1:4, each = 50),
#'   v005 = round(runif(200, 5e5, 2e6)),
#'   htn  = rbinom(200, 1, 0.2)
#' )
#' des <- dhs_design(ir)
#' survey_prevalence(des, "htn")
#'
#' # MICS and STEPS: same idea, weight column chosen for the file or step
#' names(ir) <- c("HH1", "stratum", "wmweight", "htn")
#' ir$wmweight <- ir$wmweight / 1e6
#' mics_design(ir, weight = "wmweight")
#' @name design_helpers
NULL

.build_design <- function(data, psu, strata, weight, weight_scale, ...) {
  if (!is.data.frame(data)) stop("`data` must be a data frame.", call. = FALSE)
  need <- c(psu, strata, weight)
  miss <- setdiff(need, names(data))
  if (length(miss) > 0) {
    stop("Column(s) not found in `data`: ", paste(miss, collapse = ", "),
         ". Set the `psu`, `strata` and `weight` arguments to the names used in your file.",
         call. = FALSE)
  }
  w <- as.numeric(data[[weight]]) / weight_scale
  bad <- is.na(w) | w <= 0
  if (any(bad)) {
    message(sum(bad), " row(s) with a missing or non-positive weight were dropped.")
    data <- data[!bad, , drop = FALSE]
    w <- w[!bad]
  }
  data$.surveyncd_weight <- w
  survey::svydesign(
    ids     = stats::as.formula(paste0("~`", psu, "`")),
    strata  = if (is.null(strata)) NULL else stats::as.formula(paste0("~`", strata, "`")),
    weights = ~.surveyncd_weight,
    data    = data,
    nest    = TRUE,
    ...
  )
}

#' @rdname design_helpers
#' @export
dhs_design <- function(data, psu = "v021", strata = "v023", weight = "v005",
                       weight_scale = 1e6, ...) {
  .build_design(data, psu, strata, weight, weight_scale, ...)
}

#' @rdname design_helpers
#' @export
mics_design <- function(data, weight, psu = "HH1", strata = "stratum",
                        weight_scale = 1, ...) {
  .build_design(data, psu, strata, weight, weight_scale, ...)
}

#' @rdname design_helpers
#' @export
steps_design <- function(data, weight, psu = "psu", strata = "stratum",
                         weight_scale = 1, ...) {
  .build_design(data, psu, strata, weight, weight_scale, ...)
}
