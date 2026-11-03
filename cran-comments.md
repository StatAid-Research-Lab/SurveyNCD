## Resubmission: SurveyNCD 0.2.0

This is a resubmission addressing reviewer feedback from Uwe Ligges:
* Fixed invalid URL in README.md: replaced the inactive documentation URL with the active repository URL (https://github.com/StatAid-Research-Lab/SurveyNCD). All URLs in README and DESCRIPTION have been verified and return HTTP 200/301/303.

### Changes since 0.1.0
Full details are in NEWS.md. In brief:
* New survey design constructors: `dhs_design()`, `mics_design()`, `steps_design()`.
* Universal design-based prevalence: `survey_prevalence()`.
* Advanced multimorbidity analytics: `mm_patterns()`, `mm_standardize()`, `who_standard_population()`, and `mm_bounds()`.
* Complete health inequality suite: `survey_concentration_index()` gains generalized, Erreygers and Wagstaff variants, bounds, and group-wise calculation; `survey_concentration_curve()` and `survey_slope_index()` (SII and RII).
* Publication reporting: `ncd_table()` and `autoplot()` methods.
* Numerical fix: `survey_concentration_index()` now assigns respondents tied on the ranking variable a common mid-rank, so results no longer depend on row order.
* New simulated datasets: `ncd_survey` and `child_anthro` (documented, synthetic, ~30 kB compressed).
* Two new vignettes: `full-workflow` and `real-data-nhanes`.
* 154 unit tests passing (0 failures, 0 skips).

### Test environments
* Local: Windows 11 x64, R 4.6.0 (2026-04-24 ucrt)
* win-builder: R Under development (unstable) (2026-10-28 r90783 ucrt)
* win-builder: R version 4.4.1 (release)

### R CMD check results
Status: 0 errors | 0 warnings | 0 notes (local)
Status on win-builder: 1 NOTE
* 1 NOTE regarding possibly misspelled words in DESCRIPTION:
  - Doorslaer, Erreygers, Kakwani, Wagstaff: Author surnames cited in peer-reviewed literature.
  - microdata: Standard statistical term for survey response records.
  Added to `inst/WORDLIST`.

### Notes for CRAN reviewers
* `xgboost`, `sf` and `srvyr` are in Suggests and guarded with `requireNamespace()` in code, examples and vignettes. Vignette chunks requiring them are evaluated only when installed.
* The gradient boosting module is documented as exploratory.
