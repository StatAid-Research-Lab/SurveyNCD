## Resubmission

This is a resubmission. In this version we have addressed all three
points raised by Leonore Hochhauser on 2026-09-17:

1. **Title no longer starts with "Tools for".**
   Changed from: "Tools for Self-Reported Health Indicators in Complex Surveys"
   Changed to: "Survey-Weighted Analysis of Self-Reported Health Indicators"

2. **Reference year placed in parentheses with proper format.**
   The Groll et al. reference now reads `Groll et al. (2005)
   <doi:10.1016/j.jclinepi.2004.10.018>` (year in parentheses, no space
   after `doi:`).

3. **All acronyms expanded in the Description text.**
   - WHO: World Health Organization
   - NCD: Non-Communicable Disease
   - STEPS: Stepwise Approach to Non-Communicable Disease (NCD) Risk Factor Surveillance
   - DHS: Demographic and Health Surveys
   - MICS: Multiple Indicator Cluster Surveys
   - ICD: International Classification of Diseases
   - FCI: Functional Comorbidity Index
   - SHAP: SHapley Additive exPlanations

## Test environments
* Windows 11, R 4.6.0 (local)

## R CMD check results
0 errors | 0 warnings | 1 note

* NOTE: New submission / possible misspelled words in DESCRIPTION
  (Groll, NCD, categoriser). "Groll" is the surname of the first author
  in the cited reference. "NCD" is the package name acronym for
  Non-Communicable Diseases. "categoriser" is the British English spelling.

## Notes for CRAN reviewers
* The xgboost, sf, and srvyr packages are in Suggests (optional) and are
  guarded with requireNamespace() checks in the functions that use them.
* Vignettes conditionally evaluate code chunks depending on availability
  of suggested packages (sf, srvyr).
* The gradient boosting module (survey_xgboost, survey_shap) is documented
  as exploratory; it applies case weights but does not propagate
  cluster/strata design effects into variance estimates.