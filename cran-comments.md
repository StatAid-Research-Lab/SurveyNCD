## R CMD check results
0 errors | 0 warnings | 0 notes

Tested on: Windows 11, R 4.6.0

## Notes for CRAN reviewers
* The xgboost, sf, and srvyr packages are in Suggests (optional) and are
  guarded with requireNamespace() checks in the functions that use them.
* The gradient boosting module (survey_xgboost, survey_shap) is documented
  as exploratory; it applies case weights but does not propagate
  cluster/strata design effects into variance estimates.
* This is a first submission.