---
title: 'SurveyNCD: Design-based multimorbidity, inequality and anthropometric indicators from complex population health surveys in R'
tags:
  - R
  - survey statistics
  - multimorbidity
  - non-communicable diseases
  - health inequality
  - DHS
  - WHO STEPS
authors:
  - name: Sujon Mia
    orcid: 0009-0001-1032-2818
    corresponding: true
    affiliation: "1, 2"
affiliations:
  - name: StatAid Research Lab, Dhaka, Bangladesh
    index: 1
  - name: Department of Statistics, Jagannath University, Dhaka, Bangladesh
    index: 2
date: 6 October 2026
bibliography: paper.bib
---

# Summary

Non-communicable diseases (NCDs) such as hypertension, diabetes and chronic respiratory disease are now the main cause of death worldwide, and much of what is known about them in low- and middle-income countries comes from household surveys: the WHO STEPwise approach to NCD risk-factor surveillance (STEPS) [@riley2016], the Demographic and Health Surveys (DHS) [@corsi2012] and the Multiple Indicator Cluster Surveys (MICS) [@khan2019]. These surveys do not select people at random. They stratify the country, sample clusters of households, and give each respondent a different sampling weight, so a simple average or an unweighted regression gives biased estimates and confidence intervals that are too narrow.

`SurveyNCD` is an R package that takes survey responses on whether a person has been told they have each of several chronic conditions and turns them into population-level results that respect the survey design. It cleans inconsistent raw answer codes, scores each respondent's number of chronic conditions, estimates the population prevalence of multimorbidity (two or more conditions) with confidence intervals, measures how unequally a health outcome is spread across the wealth distribution, and classifies child growth measurements into WHO severity categories. It also provides a map helper and an explicitly exploratory machine-learning module.

# Statement of need

Multimorbidity is a priority for health systems in the countries where STEPS, DHS and MICS are run, and analysts routinely need design-based estimates of it. In practice each project re-implements the same steps by hand: recoding answer codes such as 1 = yes, 2 = no, 9 = don't know; summing conditions without silently treating missing answers as "no condition"; building a `survey` design object; estimating subgroup (domain) prevalence without breaking the variance structure; and computing a concentration index with a design-consistent standard error. Each step is easy to get subtly wrong, and the errors (missing values counted as zeros, subgroups estimated by dropping rows, ignored clustering) are rarely visible in the output.

`SurveyNCD` packages these steps as small, tested functions that return tidy data frames, so that the choices that matter for validity are explicit arguments rather than ad hoc code. The intended users are epidemiologists, biostatisticians and graduate students analysing STEPS, DHS, MICS or similar survey microdata in R.

# State of the field

The `survey` package [@lumley2004] provides the variance estimators for complex designs and is the foundation of this work; `SurveyNCD` does not reimplement any of it. Comorbidity-scoring packages such as `comorbidity` [@gasparini2018] and `multimorbidity` [@multimorbidity] compute Charlson-, Elixhauser- and similar scores from ICD-coded diagnoses in clinical or claims data. Population surveys record self-reported "ever told by a doctor" answers rather than diagnosis codes, so those tools do not apply to them directly. The Functional Comorbidity Index (FCI) [@groll2005] was designed for self-reported conditions, and `SurveyNCD` uses its published list of 18 conditions as a reference and its unweighted-count scoring as the default. A search of CRAN for "functional comorbidity index" on 6 October 2026 returned no package other than `SurveyNCD`.

For health inequality, `rineq` [@rineq] provides relative, generalized and Erreygers-corrected concentration indices with decomposition, and `healthequal` [@healthequal] computes summary measures of inequality from disaggregated (subgroup-level) estimates. The standard methodological reference is @odonnell2008. `SurveyNCD` does not claim a new estimator. It evaluates the convenient-regression estimator of @kakwani1997 on respondent-level microdata inside a `survey` design object, so that the standard error reflects strata, clusters and weights. This is a workflow contribution rather than a methodological one, which is why it is a separate package that builds on `survey` and not a contribution to `survey` itself, which deliberately stays domain-agnostic.

# Software design

Four design decisions shape the package.

**A thin layer over `survey`.** All variance estimation is delegated to `survey::svydesign()`, `svyciprop()`, `svymean()` and `svyglm()`. Prevalence confidence intervals use the logit method so they stay inside [0, 1]. Subgroup estimates use `subset()` on the design object, which keeps the full design for variance estimation, rather than filtering rows beforehand. Single-PSU strata, which arise easily in subgroup analyses, are handled by setting `survey.lonely.psu = "adjust"` locally and restoring the user's option on exit.

**Missing data are an explicit policy.** `recode_binary()` maps raw codes to 0/1/NA and, when the "no" codes are given, warns about any value it cannot place instead of guessing. `multimorbidity_index()` takes a `na_action` argument. Under `"na"`, any respondent with a missing condition gets a missing score. Under `"ignore"`, available conditions are summed but a respondent with *all* conditions missing is still scored as missing and never as healthy. `mm_prevalence()` reports how many rows were excluded. The trade-off is that exclusion is complete-case without weight adjustment, which can bias estimates when missingness is common; this is documented, not hidden.

**The concentration index is computed by convenient regression.** The index is obtained as the slope of a weighted regression of a rescaled outcome on the weighted fractional wealth rank, fitted with `svyglm()`, which yields a design-based standard error, confidence interval and p-value. Respondents tied on the wealth variable, as with DHS wealth quintiles, share the mid-point of their group's cumulative-weight interval, so the estimate does not depend on row order. The point estimate is tested against an independent calculation that replicates rows by their integer weights (agreement to machine precision on the test data), and in a stratified, clustered simulation the standard error was within about 5% of a bootstrap standard error that recomputes the ranks in every replicate (`paper/validation.R`).

**Exploratory methods are fenced off.** `survey_xgboost()`, `survey_shap()` and `plot_shap_summary()` apply case weights to gradient boosting [@chen2016] and extract SHAP attributions [@lundberg2017]. They do not propagate strata and clusters into uncertainty, so they are in `Suggests`, are guarded by `requireNamespace()` checks, and are documented as exploratory rather than inferential.

The package exports ten functions, has a `testthat` suite, two vignettes, and continuous integration on five operating-system and R-version configurations. A short example follows; it uses simulated STEPS-style data generated from a seed, and the complete script is `paper/example.R` in the repository.

```r
library(SurveyNCD); library(survey)
sim$htn  <- recode_binary(sim$htn_raw,  yes = 1, no = 2)
sim$dm   <- recode_binary(sim$dm_raw,   yes = 1, no = 2)
sim$arth <- recode_binary(sim$arth_raw, yes = 1, no = 2)
scored <- multimorbidity_index(sim, c("htn", "dm", "arth"), na_action = "na")
mm_prevalence(scored, ids = "psu", strata = "region", weights = "wt")
design <- svydesign(ids = ~psu, strata = ~region, weights = ~wt,
                    data = scored, nest = TRUE)
survey_concentration_index(design, outcome = mm_n_conditions, wealth = wealth)
```

On the simulated data (1,500 respondents, 60 clusters in 3 strata), the design-based multimorbidity prevalence is 5.8% (95% CI 4.7 to 7.3%), the concentration index of the condition count is $-0.105$ (95% CI $-0.151$ to $-0.059$), indicating that conditions concentrate among poorer respondents, and 148 respondents with an unknown answer are excluded and reported. These numbers illustrate the output format only; the data are simulated.

# Research impact statement

`SurveyNCD` 0.1.0 was released on CRAN on 28 September 2026. The package has an automated test suite, continuous integration on five operating-system and R-version configurations, two vignettes, and independent validation of its concentration-index estimator (see Software design). At the time of writing the software has not yet been used in a published or preprint analysis, and there is no external adoption to report.

[TODO, BLOCKING: JOSS requires evidence that the software is already used in research and does not accept aspirational statements. Replace this bracket with specific, verifiable evidence once it exists: a manuscript, preprint or thesis that used `SurveyNCD` (with citation), the survey and wave analysed, and any external users, issues, pull requests or citations. Submitting without this is expected to result in desk rejection.]

# AI usage disclosure

Generative AI was used in this project, as follows.

- **Package code.** Claude Sonnet 5.5 (Anthropic) was used to help write the package's R code. [TODO, REQUIRED: state the nature of that assistance (for example generating functions, refactoring, debugging), and say whether the tests, vignettes, documentation and README were also AI-assisted or written by you.]
- **This paper and recent repository changes.** Claude Sonnet 5.5 (Anthropic) was used in October 2026 to draft and edit the text of this paper, to write the example and validation scripts (`paper/example.R`, `paper/validation.R`), to prepare a fix with a regression test for tied ranks in `survey_concentration_index()`, to add tests for `survey_map_indicator()`, and to draft `CONTRIBUTING.md`, `CITATION.cff` and the README limitations section.

[TODO, REQUIRED, AUTHOR TO CONFIRM BEFORE SUBMISSION: JOSS asks authors to assert that the human authors reviewed, edited and validated all AI-assisted outputs and made the core design decisions. Add that sentence only if it is true, and make sure you can explain each design decision in the Software design section in your own words. JOSS treats incomplete or inaccurate disclosure as an ethical breach.]

# Acknowledgements

The author thanks Professor Md. Atiqul Islam, Department of Statistics, Jagannath University, for academic mentorship and guidance. [TODO: confirm; add any funding, or state that no funding was received.]

# References
