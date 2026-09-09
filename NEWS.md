# SurveyNCD 0.1.0

## First release

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