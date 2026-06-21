#' The 18 conditions of the Functional Comorbidity Index
#'
#' Returns the standard condition list for the Functional Comorbidity Index.
#'
#' @return A character vector of the 18 FCI condition descriptions.
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
