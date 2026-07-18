# SurveyNCD

`SurveyNCD` helps you clean, score, estimate, and visualize non-communicable
disease (NCD) indicators from complex population surveys such as WHO STEPS,
DHS, and MICS.

It is designed for settings where conditions are self-reported (not ICD-coded)
and where estimates must respect survey design features (weights, strata, and
clusters).

## Installation

```r
# install.packages("devtools")
devtools::install_github("StatAid-Research-Lab/SurveyNCD")
```

## What you can do with this package

| Function | What it does | Status |
|---|---|---|
| `recode_binary()` | Recode messy raw survey values (e.g. 1/2/9, Yes/No, True/False) into 0/1/NA | Tested |
| `multimorbidity_index()` | Build respondent-level multimorbidity scores (count or weighted), with explicit handling of missingness | Tested |
| `fci_items()` | The 18 standard Functional Comorbidity Index conditions ([Groll et al., 2005](https://doi.org/10.1016/j.jclinepi.2004.10.018)) | Tested |
| `mm_prevalence()` | Estimate design-weighted multimorbidity prevalence and mean condition count, overall or by subgroup | Tested |
| `survey_concentration_index()` | Compute survey-weighted concentration index with SE, CI, and p-value | Tested |
| `who_anthro_score()` | Convert DHS/MICS anthropometric z-scores to WHO severity categories, with plausibility filtering | Tested |
| `survey_map_indicator()` | Join any indicator table to an `sf` boundary object and produce a publication-ready map | Tested (via vignette) |
| `survey_xgboost()` | Train case-weighted gradient boosting (`xgboost`) on a survey design object | Tested |
| `survey_shap()` | Extract SHAP-style feature contributions from a `survey_xgboost()` model | Tested |
| `plot_shap_summary()` | Plot SHAP summaries with interpretable low/high feature coloring | Tested |

## Quick start

```r
library(SurveyNCD)
library(survey)

# 1) Recode raw condition columns to 0/1/NA
df$hypertension <- recode_binary(df$hypertension_raw, yes = 1, no = 2)
df$diabetes     <- recode_binary(df$diabetes_raw, yes = 1, no = 2)

# 2) Create respondent-level multimorbidity fields
scored <- multimorbidity_index(
  df,
  conditions = c("hypertension", "diabetes"),
  na_action = "na"
)

# 3) Build the survey design object
design <- svydesign(
  ids = ~psu,
  strata = ~region,
  weights = ~wt,
  data = scored,
  nest = TRUE
)

# 4) Estimate weighted multimorbidity prevalence
mm_prevalence(scored, ids = "psu", strata = "region", weights = "wt")
mm_prevalence(scored, ids = "psu", strata = "region", weights = "wt", by = "sex")

# 5) Estimate inequality (concentration index)
survey_concentration_index(design, outcome = mm_n_conditions, wealth = wealth_index)
```

## Interoperability and flexibility

`SurveyNCD` is flexible across common survey workflows:

- Works with `survey::svydesign()` and `srvyr` survey design objects (where relevant).
- Supports clustered and/or stratified designs, or unclustered designs when `ids = NULL`.
- Handles partial missingness explicitly in multimorbidity scoring (`na_action`).
- Supports optional subgroup estimation in `mm_prevalence()` through `by`.
- Uses optional dependencies (`sf`, `xgboost`) only when those features are called.

## Important interpretation note

`survey_xgboost()` applies case weights during model fitting, but does **not**
propagate full survey design variance (cluster/strata effects) into model
uncertainty estimates. Treat model outputs as exploratory, not design-based
inference.

## Planned next

- Risk-factor co-occurrence/clustering index (e.g., WHO STEPS ">=3 risk factors")
- Care-cascade calculator (awareness -> treatment -> control)

## License

MIT © Sujon Mia
