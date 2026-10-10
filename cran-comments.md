## Submission: SurveyNCD 0.2.0 (update)

### Changes since 0.1.0
* Bug fix: `survey_concentration_index()` now gives respondents tied on the
  ranking variable a common mid-rank, so results no longer depend on row order.
* New simulated example datasets `ncd_survey` and `child_anthro` (documented,
  synthetic, about 30 kB compressed) and a new vignette.
* Additional tests; author ORCID added.

### Test environments
* [TODO: fill in before submitting, e.g. local Windows 11 R 4.6.x;
  win-builder (devel and release); GitHub Actions ubuntu/macos/windows]

### R CMD check results
[TODO: paste the result of devtools::check(args = "--as-cran") run locally.
The pre-submission check in a Linux sandbox (R 4.3.3) gave 0 errors.]

### Notes for CRAN reviewers
* `xgboost`, `sf` and `srvyr` are in Suggests and guarded with
  `requireNamespace()`; vignette chunks that need them are evaluated only when
  they are installed.
* The gradient boosting module is documented as exploratory.
