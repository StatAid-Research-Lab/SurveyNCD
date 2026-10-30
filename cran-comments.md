## Submission: SurveyNCD 0.2.0 (update)

### Changes since 0.1.0
Full details are in NEWS.md. In brief:
* New functions: survey design helpers (`dhs_design()`, `mics_design()`,
  `steps_design()`), `survey_prevalence()`, `mm_patterns()`,
  `mm_standardize()`, `who_standard_population()`, `mm_bounds()` and
  related helpers; `survey_concentration_index()` gains generalized,
  Erreygers and Wagstaff variants, bounds, and group-wise calculation;
  `survey_concentration_curve()`, `survey_slope_index()`, `ncd_table()`,
  and `autoplot()` methods.
* Bug fix: `survey_concentration_index()` now gives respondents tied on the
  ranking variable a common mid-rank, so results no longer depend on row order.
* New simulated example datasets `ncd_survey` and `child_anthro` (documented,
  synthetic, about 30 kB compressed) and new vignettes.
* Additional tests (154 unit tests passing); author ORCID added.

### Test environments
* Local: Windows 11 x64, R 4.6.0 (2026-04-24 ucrt)
* win-builder (R Under development / R release)

### R CMD check results
Status: 0 errors | 0 warnings | 0 notes

### Notes for CRAN reviewers
* `xgboost`, `sf` and `srvyr` are in Suggests and guarded with
  `requireNamespace()` in code, examples and vignettes; vignette chunks that need them are evaluated only when
  they are installed.
* The gradient boosting module is documented as exploratory.
