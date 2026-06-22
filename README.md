# SurveyNCD

`SurveyNCD` provides tools for analysing population health survey data
(WHO STEPS, DHS, MICS, and similar complex sample surveys), where
chronic conditions are self-reported rather than ICD-coded, and
estimates must account for stratification, clustering, and sampling
weights.

## Installation

```r
# install.packages("devtools")
devtools::install_github("StatAid-Research-Lab/SurveyNCD")
```

## What's included

| Function | What it does | Status |
|---|---|---|
| `recode_binary()` | Clean messy raw survey coding (e.g. STEPS-style 1=yes/2=no/9=don't know) into 0/1/NA | Tested |
| `multimorbidity_index()` | Self-reported multimorbidity score (count or weighted), based on the Functional Comorbidity Index | Tested |
| `fci_items()` | The 18 standard Functional Comorbidity Index conditions (Groll et al. 2005) | Tested |
| `mm_prevalence()` | Design-weighted population prevalence of multimorbidity, accounting for survey strata/clusters/weights | Tested |
| `survey_concentration_index()` | Survey-weighted concentration index for health inequality analysis | Tested |
| `who_anthro_score()` | Categorise pre-computed DHS anthropometric z-scores (e.g. `hw70`) into WHO severity tiers | Tested |
| `survey_map_indicator()` | Choropleth map of a survey indicator joined to an `sf` shapefile | Tested (via vignette) |
| `survey_xgboost()` | Case-weighted gradient boosting on survey data, via `xgboost` | Tested|
| `survey_shap()` | Extract SHAP-style feature contributions from a `survey_xgboost()` model | Tested |
| `plot_shap_summary()` | Plot a SHAP summary from `survey_shap()` output | Tested |

**A note on `survey_xgboost()`:** it applies case weights to the boosting
loss, which is a real and reasonable thing to do, but it does **not**
propagate cluster/strata design effects into a variance estimate. Treat
its output as exploratory, not as design-based statistical inference.

## Example

```r
library(SurveyNCD)

# 1. Clean messy raw survey coding
df$hypertension <- recode_binary(df$hypertension_raw, yes = 1, no = 2)
df$diabetes     <- recode_binary(df$diabetes_raw,     yes = 1, no = 2)

# 2. Score individual-level multimorbidity
scored <- multimorbidity_index(
  df, conditions = c("hypertension", "diabetes"), na_action = "na"
)

# 3. Design-weighted population prevalence
design <- survey::svydesign(ids = ~psu, strata = ~region, weights = ~wt, data = scored)
mm_prevalence(scored, ids = "psu", strata = "region", weights = "wt")
mm_prevalence(scored, ids = "psu", strata = "region", weights = "wt", by = "sex")

# 4. Health inequality: concentration index of multimorbidity by wealth
survey_concentration_index(design, outcome = mm_n_conditions, wealth = wealth_index)
```

## Planned next

A risk-factor co-occurrence/clustering index (the WHO STEPS "≥3 risk
factors" convention) and a care-cascade calculator (awareness →
treatment → control).

## License

MIT © Sujon Mia
