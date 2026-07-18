# SurveyNCD 0.1.1 (development)

* Improved defensive input validation across core functions to fail fast with
  clearer messages (`recode_binary()`, `multimorbidity_index()`,
  `mm_prevalence()`, `survey_concentration_index()`, `survey_xgboost()`,
  `survey_shap()`, `survey_map_indicator()`).
* Added targeted regression tests for invalid inputs and empty/edge-case
  scenarios in prevalence, concentration index, mapping, and XGBoost workflows.
* Hardened `survey_map_indicator()` plotting internals by using explicit
  `grid::unit()` namespacing for legend sizing.

# SurveyNCD 0.1.0

## First release

* `recode_binary()`: converts raw survey coding (e.g. 1/2/9) to clean 0/1/NA
* `multimorbidity_index()`: self-reported multimorbidity score based on the
  Functional Comorbidity Index (Groll et al. 2005)
* `fci_items()`: reference list of 18 standard FCI conditions
* `mm_prevalence()`: design-weighted population prevalence with logit
  confidence intervals via the survey package
* `survey_concentration_index()`: survey-weighted concentration index for
  health inequality analysis
* `who_anthro_score()`: WHO severity categorisation for DHS-style
  anthropometric z-scores
* `survey_map_indicator()`: choropleth mapping of survey indicators via sf
* `survey_xgboost()`: case-weighted gradient boosting for survey data
  (exploratory)
* `survey_shap()`: SHAP feature contributions from survey_xgboost() models
* `plot_shap_summary()`: SHAP summary visualisation