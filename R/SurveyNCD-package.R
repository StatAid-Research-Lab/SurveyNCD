#' SurveyNCD: Survey-Weighted Analysis of Self-Reported Health Indicators
#'
#' Analyses population health survey data from the World Health Organization
#' (WHO) Stepwise Approach to Non-Communicable Disease (NCD) Risk Factor
#' Surveillance (STEPS), Demographic and Health Surveys (DHS), Multiple
#' Indicator Cluster Surveys (MICS), and similar complex sample surveys, where chronic conditions are
#' self-reported rather than coded using the International Classification of
#' Diseases (ICD) and estimates must account for stratification, clustering,
#' and sampling weights.
#'
#' @details
#' A typical analysis has four steps:
#' \enumerate{
#'   \item \strong{Design}: [dhs_design()], [mics_design()], [steps_design()]
#'     (or any \pkg{survey}/\pkg{srvyr} design).
#'   \item \strong{Clean and score}: [recode_binary()], [multimorbidity_index()],
#'     [fci_items()], [who_anthro_score()].
#'   \item \strong{Estimate}: [survey_prevalence()], [mm_prevalence()],
#'     [mm_standardize()] with [who_standard_population()], [mm_patterns()],
#'     [mm_bounds()].
#'   \item \strong{Inequality}: [survey_concentration_index()],
#'     [survey_concentration_curve()], [survey_slope_index()].
#' }
#' Results can be reported with [ncd_table()] and plotted with `autoplot()`.
#' [survey_map_indicator()], [survey_xgboost()], [survey_shap()] and
#' [plot_shap_summary()] are experimental. See `vignette("full-workflow")` and
#' `vignette("real-data-nhanes")`.
#'
#' @references
#' Groll, D. L., To, T., Bombardier, C., & Wright, J. G. (2005). The
#' development of a comorbidity index with physical function as the outcome.
#' \emph{Journal of Clinical Epidemiology}, 58(6), 595-602.
#' \doi{10.1016/j.jclinepi.2004.10.018}
#'
#' @docType package
#' @name SurveyNCD
#' @keywords internal
"_PACKAGE"
