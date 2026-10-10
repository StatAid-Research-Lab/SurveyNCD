# Reproducible analyses for the SurveyNCD papers

Everything here uses the **simulated** datasets shipped with SurveyNCD
(`ncd_survey`, `child_anthro`) and the population generator in `data-raw/`.
No real survey data are used; regions are fictitious.

| Script | What it produces |
|---|---|
| `01_worked_example.R` | Tables of condition prevalence, multimorbidity by group, child undernutrition, concentration indices, SHAP importance; figures for wealth gradient, concentration indices, regional map, SHAP summary. Uses all ten exported functions. |
| `02_validation.R` | Comparison of `survey_concentration_index()` with `rineq::ci()` and a 500-replicate design bootstrap; tie-handling check (v0.1.0 vs v0.2.0). |
| `03_simulation_study.R` | Monte Carlo study (1,000 samples from the known population): bias, SE ratio and 95% CI coverage for full-design, weights-only and unweighted analyses. |
| `diagram/fig_workflow.tex` | Workflow diagram (TikZ; `pdflatex fig_workflow.tex`). |
| `04_export_to_rjournal.R` | Copies figures and tables into `rjournal/`. |
| `run_all.R` | Runs 01-04 (about 6 minutes; the simulation is cached). |

Outputs are written to `output/tables/` (CSV, Markdown, LaTeX) and
`output/figures/` (PDF and 300-dpi PNG).

Run from the package source root:

```sh
Rscript analysis/run_all.R
```

Required packages: SurveyNCD (>= 0.2.0), survey, ggplot2, knitr, sf, xgboost, rineq.
