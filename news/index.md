# Changelog

## SurveyNCD 0.2.0

### New features

- **Survey design helpers**
  [`dhs_design()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/design_helpers.md),
  [`mics_design()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/design_helpers.md)
  and
  [`steps_design()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/design_helpers.md)
  build the design from each programme’s standard variable names (DHS:
  PSU `v021`, strata `v023`, weight `v005` / 1e6).
- **[`survey_prevalence()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_prevalence.md)**:
  design-based prevalence of any number of binary indicators, overall or
  by one or more grouping variables, with design effects.
- **[`mm_prevalence()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/mm_prevalence.md)**
  now also accepts a survey design object, supports several `by`
  variables and excludes missing scores by domain estimation (same
  estimates as before for complete designs).
- **`multimorbidity_index(threshold = )`** sets the number of conditions
  defining multimorbidity (e.g. 3 for complex multimorbidity) and adds
  `mm_multimorbid`.
- **[`mm_patterns()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/mm_patterns.md)**:
  prevalence of condition pairs/triads with observed-to-expected ratios.
- **[`mm_standardize()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/mm_standardize.md)**
  and
  **[`who_standard_population()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/who_standard_population.md)**:
  direct age standardisation to the WHO World Standard Population, with
  design-based SEs.
- **[`mm_bounds()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/mm_bounds.md)**:
  sensitivity bounds for “don’t know” answers.
- **[`survey_concentration_index()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_concentration_index.md)**
  gains `type = "generalized"`, `"erreygers"` and `"wagstaff"`,
  `bounds`, and `by` for group-wise indices.
- **[`survey_concentration_curve()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_concentration_curve.md)**
  and
  **[`survey_slope_index()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_slope_index.md)**
  (slope and relative index of inequality).
- **[`ncd_table()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/ncd_table.md)**:
  publication-ready prevalence tables.
- **`autoplot()`** methods for prevalence, multimorbidity,
  concentration-index, concentration-curve and pattern results.
- New vignette
  [`vignette("real-data-nhanes")`](https://github.com/StatAid-Research-Lab/SurveyNCD/articles/real-data-nhanes.md)
  using real NHANES 2009-2010 data.

### Changes

- [`survey_map_indicator()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_map_indicator.md),
  [`survey_xgboost()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_xgboost.md),
  [`survey_shap()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_shap.md)
  and
  [`plot_shap_summary()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/plot_shap_summary.md)
  are now labelled experimental.

- Concentration-index p-values are computed as `2 * pnorm(-|z|)` for
  accuracy with very small values.

- New simulated example datasets `ncd_survey` (2,400 adults, STEPS-style
  raw response codes, stratified two-stage cluster design with unequal
  weights) and `child_anthro` (1,034 children with DHS-coded z-scores),
  drawn from a known synthetic population. Generating code is in
  `data-raw/` of the source repository.

- New vignette
  [`vignette("full-workflow")`](https://github.com/StatAid-Research-Lab/SurveyNCD/articles/full-workflow.md)
  demonstrating every exported function on the example datasets.

- [`survey_concentration_index()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_concentration_index.md):
  respondents tied on the ranking variable (for example DHS wealth
  quintiles) now share the mid-point of their group’s cumulative-weight
  interval. Previously ties were ranked by row order, so the estimate
  changed when the rows of the input were reordered. Results for untied
  ranking variables are unchanged.

- Tests: the replicate-weight validation of the concentration index now
  uses a tolerance of 1e-8 (the two calculations agree to machine
  precision); added a tie-invariance regression test and tests for
  [`survey_map_indicator()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_map_indicator.md)
  (run when `sf` is installed).

- Documentation: README status column now distinguishes tested functions
  from the exploratory machine-learning module, and a Limitations
  section was added.

- Added `CONTRIBUTING.md` and `CITATION.cff`; added the author ORCID.

## SurveyNCD 0.1.0

CRAN release: 2026-09-28

### First release (CRAN 2026-09-28)

- Initial release officially accepted and published on CRAN
  (<https://CRAN.R-project.org/package=SurveyNCD>).
- [`recode_binary()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/recode_binary.md):
  converts raw survey coding (e.g. 1/2/9) to clean 0/1/NA. When `no` is
  not specified, non-`yes` values are treated as 0.
- [`multimorbidity_index()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/multimorbidity_index.md):
  self-reported multimorbidity score based on the Functional Comorbidity
  Index (Groll et al., 2005, <doi:10.1016/j.jclinepi.2004.10.018>).
  Safely handles all-NA respondents.
- [`fci_items()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/fci_items.md):
  reference list of 18 standard FCI conditions
- [`mm_prevalence()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/mm_prevalence.md):
  design-weighted population prevalence with logit confidence intervals
  via the survey package. Includes lonely PSU protection.
- [`survey_concentration_index()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_concentration_index.md):
  survey-weighted concentration index for health inequality analysis
  with design-consistent standard errors via Kakwani’s convenient
  regression (Kakwani, Wagstaff, & van Doorslaer, 1997,
  <doi:10.1016/S0304-4076(96)01807-6>). Returns full-precision values.
- [`who_anthro_score()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/who_anthro_score.md):
  WHO severity categorisation for DHS-style anthropometric z-scores with
  biologically implausible value flagging per WHO child growth standards
  (WHO, 2006).
- [`survey_map_indicator()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_map_indicator.md):
  choropleth mapping of survey indicators via sf
- [`survey_xgboost()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_xgboost.md):
  case-weighted gradient boosting for survey data (exploratory)
- [`survey_shap()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_shap.md):
  SHAP feature contributions from survey_xgboost() models
- [`plot_shap_summary()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/plot_shap_summary.md):
  SHAP summary visualisation
