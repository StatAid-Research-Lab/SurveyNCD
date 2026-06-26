#' SurveyNCD: Tools for Self-Reported Health Indicators in Complex Surveys
#'
#' Provides tools for analysing population health survey data
#' (WHO STEPS, DHS, MICS, and similar complex sample surveys), where
#' chronic conditions are self-reported rather than ICD-coded and
#' estimates must account for stratification, clustering, and sampling
#' weights.
#'
#' @details
#' The package includes:
#' \itemize{
#'   \item \code{survey_concentration_index()}: Calculates the survey-weighted
#'     concentration index with design-consistent standard errors, confidence
#'     intervals, and p-values using Kakwani's convenient WLS regression.
#'   \item \code{who_anthro_score()}: Categorizes raw DHS/MICS anthropometric
#'     z-scores into WHO severity tiers, with optional removal of biologically
#'     implausible values (WHO flags) and scaling adjustments.
#'   \item \code{mm_prevalence()}: Calculates design-weighted population prevalence
#'     of multimorbidity, robust to missing grouping variables.
#'   \item \code{multimorbidity_index()}: Computes individual-level multimorbidity
#'     scores based on the Functional Comorbidity Index, safely handling all-NA
#'     cases to prevent downward prevalence bias.
#'   \item \code{survey_map_indicator()}: Merges indicators with spatial shapefiles
#'     and generates thematic maps.
#'   \item \code{survey_xgboost()}, \code{survey_shap()}, and \code{plot_shap_summary()}:
#'     Exploratory survey-weighted gradient boosting, SHAP feature importance extraction,
#'     and color-coded SHAP visualization.
#' }
#'
#' @docType package
#' @name SurveyNCD
#' @keywords internal
"_PACKAGE"
