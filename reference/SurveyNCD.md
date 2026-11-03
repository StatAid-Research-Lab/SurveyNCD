# SurveyNCD: Survey-Weighted Analysis of Self-Reported Health Indicators

Analyses population health survey data from the World Health
Organization (WHO) Stepwise Approach to Non-Communicable Disease (NCD)
Risk Factor Surveillance (STEPS), Demographic and Health Surveys (DHS),
Multiple Indicator Cluster Surveys (MICS), and similar complex sample
surveys, where chronic conditions are self-reported rather than coded
using the International Classification of Diseases (ICD) and estimates
must account for stratification, clustering, and sampling weights.

## Details

A typical analysis has four steps:

1.  **Design**:
    [`dhs_design()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/design_helpers.md),
    [`mics_design()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/design_helpers.md),
    [`steps_design()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/design_helpers.md)
    (or any survey/srvyr design).

2.  **Clean and score**:
    [`recode_binary()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/recode_binary.md),
    [`multimorbidity_index()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/multimorbidity_index.md),
    [`fci_items()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/fci_items.md),
    [`who_anthro_score()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/who_anthro_score.md).

3.  **Estimate**:
    [`survey_prevalence()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_prevalence.md),
    [`mm_prevalence()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/mm_prevalence.md),
    [`mm_standardize()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/mm_standardize.md)
    with
    [`who_standard_population()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/who_standard_population.md),
    [`mm_patterns()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/mm_patterns.md),
    [`mm_bounds()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/mm_bounds.md).

4.  **Inequality**:
    [`survey_concentration_index()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_concentration_index.md),
    [`survey_concentration_curve()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_concentration_curve.md),
    [`survey_slope_index()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_slope_index.md).

Results can be reported with
[`ncd_table()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/ncd_table.md)
and plotted with `autoplot()`.
[`survey_map_indicator()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_map_indicator.md),
[`survey_xgboost()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_xgboost.md),
[`survey_shap()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_shap.md)
and
[`plot_shap_summary()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/plot_shap_summary.md)
are experimental. See
[`vignette("full-workflow")`](https://github.com/StatAid-Research-Lab/SurveyNCD/articles/full-workflow.md)
and
[`vignette("real-data-nhanes")`](https://github.com/StatAid-Research-Lab/SurveyNCD/articles/real-data-nhanes.md).

## References

Groll, D. L., To, T., Bombardier, C., & Wright, J. G. (2005). The
development of a comorbidity index with physical function as the
outcome. *Journal of Clinical Epidemiology*, 58(6), 595-602.
[doi:10.1016/j.jclinepi.2004.10.018](https://doi.org/10.1016/j.jclinepi.2004.10.018)

## See also

Useful links:

- <https://github.com/StatAid-Research-Lab/SurveyNCD>

- Report bugs at
  <https://github.com/StatAid-Research-Lab/SurveyNCD/issues>

## Author

**Maintainer**: Sujon Mia <sujonsgc@gmail.com>
([ORCID](https://orcid.org/0009-0001-1032-2818))

Authors:

- Sujon Mia <sujonsgc@gmail.com>
  ([ORCID](https://orcid.org/0009-0001-1032-2818))

Other contributors:

- Md. Atiqul Islam <atique@stat.jnu.ac.bd> (Professor & Academic Mentor,
  Department of Statistics) \[contributor\]
