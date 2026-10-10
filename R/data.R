#' Simulated adult NCD survey (STEPS-style)
#'
#' A simulated nationally representative-style survey of adults aged 18-69,
#' drawn from a known synthetic population by stratified two-stage cluster
#' sampling. It mimics the structure of WHO STEPS and DHS microdata (strata,
#' primary sampling units, unequal sampling weights, raw response codes with
#' "don't know" answers) so that every function in the package can be
#' demonstrated. \strong{The data are entirely synthetic}; regions are
#' fictitious and no estimate describes any real country.
#'
#' The population has 6 regions of unequal size, each divided into urban and
#' rural enumeration areas (12 strata). Ten enumeration areas were selected by
#' simple random sampling in every stratum and 20 households in each, so small
#' regions and urban areas are over-sampled and the weights vary about 15-fold.
#' The code that generates the population and the sample is in
#' \code{data-raw/} in the package source repository.
#'
#' @format A data frame with 2,400 rows (one adult per household) and 18
#'   variables:
#' \describe{
#'   \item{hh_id}{Household identifier (links to \code{child_anthro}).}
#'   \item{region}{Region (6 fictitious regions, "Region A" to "Region F").}
#'   \item{residence}{"Urban" or "Rural".}
#'   \item{stratum}{Sampling stratum (region x residence, 12 strata).}
#'   \item{psu}{Primary sampling unit (enumeration area), 120 in total.}
#'   \item{wt}{Sampling weight, normalised to mean 1 (as in DHS).}
#'   \item{sex}{"Female" or "Male".}
#'   \item{age}{Age in completed years (18-69).}
#'   \item{wealth_score}{Continuous household wealth index (higher = richer).}
#'   \item{wealth_quintile}{Weighted wealth quintile, 1 (poorest) to 5 (richest).}
#'   \item{bmi}{Body mass index (kg/m^2).}
#'   \item{htn_raw, dm_raw, arth_raw, asthma_raw, angina_raw, stroke_raw}{Raw
#'     answers to "Has a doctor or health worker ever told you that you have
#'     hypertension / diabetes / arthritis / asthma / angina or heart disease /
#'     stroke?", coded 1 = yes, 2 = no, 9 = don't know.}
#'   \item{dep_raw}{Raw answer for depression, coded as text: "Yes", "No",
#'     "Don't know".}
#' }
#' @source Simulated; see \code{data-raw/simulate_survey.R} in
#'   \url{https://github.com/StatAid-Research-Lab/SurveyNCD}.
#' @seealso \code{\link{child_anthro}}
#' @examples
#' head(ncd_survey)
#' ncd_survey$htn <- recode_binary(ncd_survey$htn_raw, yes = 1, no = 2)
"ncd_survey"

#' Simulated child anthropometry (DHS-style)
#'
#' Children under five living in the households of \code{\link{ncd_survey}},
#' with height-for-age, weight-for-age and weight-for-height z-scores stored in
#' the DHS recode convention: multiplied by 100, with flag codes 9996 (height
#' out of plausible range) and 9998 (missing), and a few biologically
#' implausible values. \strong{The data are entirely synthetic.}
#'
#' @format A data frame with 1,034 rows and 14 variables:
#' \describe{
#'   \item{child_id}{Child identifier.}
#'   \item{hh_id}{Household identifier (links to \code{ncd_survey}).}
#'   \item{region, residence, stratum, psu, wt}{Design variables, inherited
#'     from the household.}
#'   \item{sex}{"Female" or "Male".}
#'   \item{age_months}{Age in months (0-59).}
#'   \item{wealth_score, wealth_quintile}{Household wealth, as in
#'     \code{ncd_survey}.}
#'   \item{hw70}{Height-for-age z-score x 100 (DHS variable name).}
#'   \item{hw71}{Weight-for-age z-score x 100.}
#'   \item{hw72}{Weight-for-height z-score x 100.}
#' }
#' @source Simulated; see \code{data-raw/simulate_survey.R} in
#'   \url{https://github.com/StatAid-Research-Lab/SurveyNCD}.
#' @examples
#' table(who_anthro_score(child_anthro$hw70, indicator = "stunting"),
#'       useNA = "ifany")
"child_anthro"
