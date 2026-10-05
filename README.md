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

## Key Features & Functions

| Function | Module | Description | Status |
|---|---|---|---|
| `recode_binary()` | Data Cleaning | Cleans messy raw survey codes (e.g., 1=Yes, 2=No, 9=Don't Know) into clean 0/1/NA | Tested |
| `multimorbidity_index()` | Morbidity | Computes individual-level multimorbidity count/score based on the Functional Comorbidity Index (FCI). Safely handles all-NA respondents to prevent downward prevalence bias. | Tested |
| `fci_items()` | Reference | Returns the 18 standard Functional Comorbidity Index conditions ([Groll et al., 2005](https://doi.org/10.1016/j.jclinepi.2004.10.018)) | Tested |
| `mm_prevalence()` | Epidemiology | Calculates design-weighted population prevalence of single conditions or multimorbidity with logit confidence intervals, accounting for strata/clusters/weights and lonely PSUs. | Tested |
| `survey_concentration_index()` | Health Economics | Calculates the survey-weighted concentration index for socioeconomic health inequality, with design-consistent standard errors, confidence intervals, and p-values via Kakwani's convenient WLS regression. | Tested |
| `who_anthro_score()` | Nutrition | Categorises raw DHS/MICS anthropometric z-scores (HAZ, WHZ, WAZ) into WHO severity tiers, with automatic flagging and optional removal of biologically implausible values (WHO flags). | Tested |
| `survey_map_indicator()` | Geospatial | Joins survey indicator estimates with spatial shapefiles (`sf`) and generates publication-grade choropleth maps. | Tested |
| `survey_xgboost()` | Machine Learning | Implements case-weighted gradient boosting on survey data via `xgboost` (exploratory). | Tested |
| `survey_shap()` | Explainability | Extracts SHapley Additive exPlanations (SHAP) feature contributions for each survey respondent from `survey_xgboost()` models. | Tested |
| `plot_shap_summary()` | Visualization | Visualizes SHAP summary plots ranked by mean absolute SHAP value and colored by feature values (blue = low, red = high). | Tested |

> **Note on `survey_xgboost()`:** This module applies survey case weights to the boosting objective function. It is intended for exploratory pattern discovery and predictive feature ranking, rather than design-based asymptotic inference.

---

## Quick Start Example

```r
library(SurveyNCD)
library(survey)

# 1. Clean messy raw survey coding
df$hypertension <- recode_binary(df$hypertension_raw, yes = 1, no = 2)
df$diabetes     <- recode_binary(df$diabetes_raw,     yes = 1, no = 2)

# 2. Score individual-level multimorbidity (safely handling all-NA cases)
scored <- multimorbidity_index(
  df, 
  conditions = c("hypertension", "diabetes"), 
  na_action = "na"
)

# 3. Create a complex survey design object
design <- svydesign(
  ids = ~psu, 
  strata = ~region, 
  weights = ~wt, 
  data = scored, 
  nest = TRUE
)

# 4. Design-weighted population prevalence
mm_prevalence(scored, ids = "psu", strata = "region", weights = "wt")
mm_prevalence(scored, ids = "psu", strata = "region", weights = "wt", by = "sex")

# 5. Measure health inequality (Concentration Index with Kakwani standard errors)
survey_concentration_index(design, outcome = mm_n_conditions, wealth = wealth_index)
```

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
