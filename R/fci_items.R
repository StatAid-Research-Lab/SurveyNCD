#' The 18 conditions of the Functional Comorbidity Index
#'
#' Returns the standard condition list for the Functional Comorbidity Index.
#'
#' @return A character vector of the 18 FCI condition descriptions.
#'
#' @references
#' Groll, D. L., To, T., Bombardier, C., & Wright, J. G. (2005). The
#' development of a comorbidity index with physical function as the outcome.
#' \emph{Journal of Clinical Epidemiology}, 58(6), 595-602.
#' \doi{10.1016/j.jclinepi.2004.10.018}
#'
#' @export
fci_items <- function() {
  c(
    "Arthritis (rheumatoid and osteoarthritis)",
    "Osteoporosis",
    "Asthma",
    "Chronic obstructive pulmonary disease (COPD), ARDS, or emphysema",
    "Angina",
    "Congestive heart failure (or heart disease)",
    "Heart attack (myocardial infarction)",
    "Neurological disease (e.g. Parkinson's, multiple sclerosis)",
    "Stroke or transient ischemic attack (TIA)",
    "Peripheral vascular disease",
    "Diabetes, type I or type II",
    "Upper gastrointestinal disease (ulcer, hernia, reflux)",
    "Depression",
    "Anxiety or panic disorders",
    "Visual impairment (e.g. cataracts, glaucoma)",
    "Hearing impairment",
    "Degenerative disc disease",
    "Obesity"
  )
}
