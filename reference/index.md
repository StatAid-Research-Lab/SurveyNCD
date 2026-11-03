# Package index

## Survey designs

- [`dhs_design()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/design_helpers.md)
  [`mics_design()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/design_helpers.md)
  [`steps_design()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/design_helpers.md)
  : Build a survey design from DHS, MICS or STEPS microdata

## Cleaning and scoring

- [`recode_binary()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/recode_binary.md)
  : Recode a messy survey column into clean 0/1
- [`multimorbidity_index()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/multimorbidity_index.md)
  : Calculate a self-reported multimorbidity index
- [`fci_items()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/fci_items.md)
  : The 18 conditions of the Functional Comorbidity Index
- [`who_anthro_score()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/who_anthro_score.md)
  : Calculate WHO Anthropometric Categories from DHS/MICS Data

## Prevalence and multimorbidity

- [`survey_prevalence()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_prevalence.md)
  : Design-based prevalence of one or more binary indicators
- [`mm_prevalence()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/mm_prevalence.md)
  : Population-level multimorbidity estimates from complex survey data
- [`mm_standardize()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/mm_standardize.md)
  : Age-standardised prevalence from a survey design
- [`who_standard_population()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/who_standard_population.md)
  : WHO World Standard Population
- [`mm_patterns()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/mm_patterns.md)
  : Most common combinations of conditions (multimorbidity patterns)
- [`mm_bounds()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/mm_bounds.md)
  : Sensitivity of multimorbidity prevalence to "don't know" answers

## Inequality

- [`survey_concentration_index()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_concentration_index.md)
  : Survey-weighted concentration index
- [`survey_concentration_curve()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_concentration_curve.md)
  : Concentration curve from a survey design
- [`survey_slope_index()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_slope_index.md)
  : Slope and relative index of inequality from a survey design

## Reporting

- [`ncd_table()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/ncd_table.md)
  : Publication-ready prevalence table
- [`autoplot(`*`<surveyncd_prevalence>`*`)`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/autoplot.surveyncd.md)
  [`autoplot(`*`<surveyncd_mm_prevalence>`*`)`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/autoplot.surveyncd.md)
  [`autoplot(`*`<surveyncd_ci>`*`)`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/autoplot.surveyncd.md)
  [`autoplot(`*`<surveyncd_curve>`*`)`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/autoplot.surveyncd.md)
  [`autoplot(`*`<surveyncd_patterns>`*`)`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/autoplot.surveyncd.md)
  : Plot SurveyNCD results with ggplot2

## Example data

- [`ncd_survey`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/ncd_survey.md)
  : Simulated adult NCD survey (STEPS-style)
- [`child_anthro`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/child_anthro.md)
  : Simulated child anthropometry (DHS-style)

## Experimental

- [`survey_map_indicator()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_map_indicator.md)
  : Map Survey Indicators Universally
- [`survey_xgboost()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_xgboost.md)
  : Train an XGBoost Model with Complex Survey Weights
- [`survey_shap()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/survey_shap.md)
  : Extract SHAP Values from a Survey-Weighted XGBoost Model
- [`plot_shap_summary()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/plot_shap_summary.md)
  : Plot SHapley Additive exPlanations (SHAP) Summary

## Internal

- [`SurveyNCD-package`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/SurveyNCD.md)
  [`SurveyNCD`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/SurveyNCD.md)
  : SurveyNCD: Survey-Weighted Analysis of Self-Reported Health
  Indicators
- [`` `%>%` ``](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/pipe.md)
  : Pipe operator
