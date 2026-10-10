# SurveyNCD: Survey-Weighted Analysis of Self-Reported Health Indicators

<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/SurveyNCD)](https://CRAN.R-project.org/package=SurveyNCD)
[![CRAN Downloads](https://cranlogs.r-pkg.org/badges/grand-total/SurveyNCD)](https://CRAN.R-project.org/package=SurveyNCD)
[![CRAN Monthly Downloads](https://cranlogs.r-pkg.org/badges/SurveyNCD)](https://CRAN.R-project.org/package=SurveyNCD)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![CRAN checks](https://badges.cranchecks.info/worst/SurveyNCD.svg)](https://cran.r-project.org/web/checks/check_results_SurveyNCD.html)
<!-- badges: end -->

**SurveyNCD** provides specialized tools for analysing population health survey data from the World Health Organization (WHO) Stepwise Approach to Non-Communicable Disease (NCD) Risk Factor Surveillance (STEPS), Demographic and Health Surveys (DHS), Multiple Indicator Cluster Surveys (MICS), and similar complex sample surveys. 

In population surveys, chronic conditions are typically self-reported rather than coded using the International Classification of Diseases (ICD). Standard statistical functions (like `mean()` or unweighted regression) produce biased estimates and misleading p-values because they ignore the survey design. **SurveyNCD** bridges this gap by accounting for stratification, clustering (PSUs), and sampling weights throughout the analytical workflow.

---

## Installation

### Released version from CRAN (Recommended)
You can install the published version directly from [CRAN](https://CRAN.R-project.org/package=SurveyNCD):

```r
install.packages("SurveyNCD")
```

### Development version from GitHub
To install the latest development build from GitHub:

```r
# install.packages("remotes")
remotes::install_github("StatAid-Research-Lab/SurveyNCD")
```

---

## What SurveyNCD does

Four steps cover a typical analysis: build the design once, clean and score the
answers, estimate, then report.

| Step | Functions |
|---|---|
| **1. Design** | `dhs_design()`, `mics_design()`, `steps_design()`: the correct design from each programme's standard variable names (or any `survey`/`srvyr` design) |
| **2. Clean and score** | `recode_binary()` (1/2/9 or text codes to 0/1/NA), `multimorbidity_index()` (condition count, adjustable threshold), `fci_items()`, `who_anthro_score()` (DHS-coded child z-scores) |
| **3. Estimate** | `survey_prevalence()` (any binary indicators, several grouping variables), `mm_prevalence()`, `mm_standardize()` with `who_standard_population()` (age standardisation), `mm_patterns()` (pairs and triads, observed/expected), `mm_bounds()` ("don't know" sensitivity bounds) |
| **4. Inequality** | `survey_concentration_index()` (standard, generalized, Erreygers, Wagstaff; by group), `survey_concentration_curve()`, `survey_slope_index()` (SII and RII) |
| **Report** | `ncd_table()` (publication-ready table), `autoplot()` methods for every result |
| *Experimental* | `survey_map_indicator()`, `survey_xgboost()`, `survey_shap()`, `plot_shap_summary()` |

All variance estimation is done by the [survey](https://CRAN.R-project.org/package=survey) package, so every standard error reflects strata, clusters and weights. Each estimator is tested against an independent calculation.

> **Experimental functions.** The machine-learning functions apply sampling weights as case weights but do not carry strata and clusters into any measure of uncertainty. Use them to explore patterns, not for inference. Their interface may change.

---

## Quick start

```r
library(SurveyNCD)

d <- ncd_survey                                   # simulated STEPS-style data
d$htn <- recode_binary(d$htn_raw, yes = 1, no = 2)
d$dm  <- recode_binary(d$dm_raw,  yes = 1, no = 2)
d$dep <- recode_binary(d$dep_raw, yes = "Yes", no = "No")
d <- multimorbidity_index(d, c("htn", "dm", "dep"), na_action = "na")

des <- steps_design(d, weight = "wt")             # psu / stratum / weight

ncd_table(des, c("htn", "dm", "dep"), by = "sex")             # formatted table
survey_prevalence(des, "htn", by = c("sex", "residence"))     # numbers behind it
mm_prevalence(des, by = "residence")                          # multimorbidity
mm_patterns(des, c("htn", "dm", "dep"))                       # common pairs
survey_concentration_index(des, dm, wealth_score, type = "erreygers")
ggplot2::autoplot(survey_concentration_curve(des, dm, wealth_score))
```

With DHS data:

```r
des <- dhs_design(ir_data)    # PSU v021, strata v023, weight v005 / 1e6
```

## Example data and a complete worked analysis

Two **simulated** datasets ship with the package so that every function can be tried
immediately: `ncd_survey` (2,400 adults, STEPS-style raw codes, 12 strata, 120 PSUs,
unequal weights) and `child_anthro` (1,034 children with DHS-coded z-scores). They are
drawn from a known synthetic population (`data-raw/`), so estimates can be checked
against the truth. Regions are fictitious.

```r
vignette("full-workflow", package = "SurveyNCD")   # simulated data, every function
vignette("real-data-nhanes", package = "SurveyNCD") # real NHANES 2009-2010 data
```

The repository's `analysis/` folder reproduces every table and figure in the papers
describing the package, including a 1,000-sample simulation study of bias and
confidence-interval coverage (`Rscript analysis/run_all.R`).

---

## Limitations

* **Complete-case handling.** With `na_action = "na"`, any respondent with a missing
  condition gets a missing score and is excluded from `mm_prevalence()` (the number
  excluded is reported). No weight adjustment for this exclusion is made, which can
  bias estimates when missingness is common.
* **"Multimorbid" is a convention.** It means at least `threshold` (default 2) of the conditions
  you supply. With fewer than the 18 FCI conditions this is a condition count, not the validated FCI.
  `mm_bounds()` shows how much the "don't know" answers could matter.
* `who_anthro_score()` categorises undernutrition tiers only (no overweight category).
* The gradient-boosting module applies case weights only; it does not propagate strata
  and clusters into uncertainty and is not design-based inference.
* Concentration-index standard errors treat the ranks as fixed; a design bootstrap gave
  standard errors within about 11% in the validation study.
* Validated on simulated data with a known population and against independent calculations,
  and demonstrated on real NHANES data (`vignette("real-data-nhanes")`). Not yet benchmarked
  against a published STEPS, DHS or MICS report.

---

## Citation

If you use **SurveyNCD** in your research, academic publications, or policy reports, please cite it:

```r
citation("SurveyNCD")
```

```bibtex
@Manual{,
  title = {SurveyNCD: Survey-Weighted Analysis of Self-Reported Health Indicators},
  author = {Sujon Mia},
  year = {2026},
  note = {R package version 0.1.0},
  url = {https://CRAN.R-project.org/package=SurveyNCD},
  doi = {10.32614/CRAN.package.SurveyNCD}
}
```

---

## Acknowledgments

The development of the `SurveyNCD` package and the establishment of StatAid Research Lab were conducted under the academic mentorship and guidance of **Dr. Md. Atiqul Islam**, Professor in the Department of Statistics, Jagannath University. The author is deeply grateful for his continuous guidance, statistical advice, and support of this research initiative.

---

## License

MIT © [Sujon Mia](https://github.com/StatAid-Research-Lab)
