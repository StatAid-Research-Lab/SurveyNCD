# SurveyNCD 0.2.0

* New simulated example datasets `ncd_survey` (2,400 adults, STEPS-style raw
  response codes, stratified two-stage cluster design with unequal weights) and
  `child_anthro` (1,034 children with DHS-coded z-scores), drawn from a known
  synthetic population. Generating code is in `data-raw/` of the source
  repository.
* New vignette `vignette("full-workflow")` demonstrating every exported function
  on the example datasets.
* `survey_concentration_index()`: respondents tied on the ranking variable
  (for example DHS wealth quintiles) now share the mid-point of their group's
  cumulative-weight interval. Previously ties were ranked by row order, so the
  estimate changed when the rows of the input were reordered. Results for
  untied ranking variables are unchanged.
* Tests: the replicate-weight validation of the concentration index now uses
  a tolerance of 1e-8 (the two calculations agree to machine precision); added
  a tie-invariance regression test and tests for `survey_map_indicator()`
  (run when `sf` is installed).
* Documentation: README status column now distinguishes tested functions from
  the exploratory machine-learning module, and a Limitations section was added.
* Added `CONTRIBUTING.md` and `CITATION.cff`; added the author ORCID.

# SurveyNCD 0.1.0

## First release (CRAN 2026-09-28)

* Initial release officially accepted and published on CRAN (<https://CRAN.R-project.org/package=SurveyNCD>).
* `recode_binary()`: converts raw survey coding (e.g. 1/2/9) to clean 0/1/NA.
  When `no` is not specified, non-`yes` values are treated as 0.
* `multimorbidity_index()`: self-reported multimorbidity score based on the
  Functional Comorbidity Index (Groll et al., 2005,
  doi:10.1016/j.jclinepi.2004.10.018). Safely handles all-NA respondents.
* `fci_items()`: reference list of 18 standard FCI conditions
* `mm_prevalence()`: design-weighted population prevalence with logit
  confidence intervals via the survey package. Includes lonely PSU protection.
* `survey_concentration_index()`: survey-weighted concentration index for
  health inequality analysis with design-consistent standard errors via
  Kakwani's convenient regression (Kakwani, Wagstaff, & van Doorslaer, 1997,
  doi:10.1016/S0304-4076(96)01807-6). Returns full-precision values.
* `who_anthro_score()`: WHO severity categorisation for DHS-style
  anthropometric z-scores with biologically implausible value flagging
  per WHO child growth standards (WHO, 2006).
* `survey_map_indicator()`: choropleth mapping of survey indicators via sf
* `survey_xgboost()`: case-weighted gradient boosting for survey data
  (exploratory)
* `survey_shap()`: SHAP feature contributions from survey_xgboost() models
* `plot_shap_summary()`: SHAP summary visualisation