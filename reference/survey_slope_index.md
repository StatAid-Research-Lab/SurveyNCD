# Slope and relative index of inequality from a survey design

Regression-based measures of socioeconomic inequality on the weighted
fractional rank \\R\\ (0 = poorest, 1 = richest; tie-aware as in
[`survey_concentration_index()`](https://stataid-research-lab.github.io/SurveyNCD/reference/survey_concentration_index.md)):

- the slope index of inequality (SII), the slope of a linear regression
  of the outcome on \\R\\: the absolute difference in the outcome
  between the richest and the poorest end of the distribution;

- the relative index of inequality (RII), \\\exp(\beta)\\ from a
  log-link quasi-Poisson regression on \\R\\: the ratio of the outcome
  at the richest to the poorest end.

Both models are fitted with
[`survey::svyglm()`](https://rdrr.io/pkg/survey/man/svyglm.html), giving
design-based confidence intervals. Values of SII above 0 (RII above 1)
mean higher levels among richer people.

## Usage

``` r
survey_slope_index(design, outcome, wealth, conf.level = 0.95, by = NULL)
```

## Arguments

- design:

  A survey design object (survey or srvyr).

- outcome:

  Unquoted name of the health variable.

- wealth:

  Unquoted name of the ranking variable.

- conf.level:

  Confidence level.

- by:

  Optional character vector of grouping columns; ranks are computed
  within each group.

## Value

A data frame with any `by` columns, `n`, `SII`, `SII_lower`,
`SII_upper`, `RII`, `RII_lower`, `RII_upper`.

## References

Mackenbach, J. P., & Kunst, A. E. (1997). Measuring the magnitude of
socio-economic inequalities in health: An overview of available measures
illustrated with two examples from Europe. *Social Science & Medicine*,
44(6), 757-771.
[doi:10.1016/S0277-9536(96)00073-1](https://doi.org/10.1016/S0277-9536%2896%2900073-1)

## Examples

``` r
set.seed(1)
df <- data.frame(wealth = rnorm(300), wt = runif(300, 0.5, 2))
df$sick <- rbinom(300, 1, plogis(-1 - 0.6 * df$wealth))
des <- survey::svydesign(ids = ~1, weights = ~wt, data = df)
survey_slope_index(des, sick, wealth)
#>     n        SII  SII_lower  SII_upper       RII RII_lower RII_upper
#> 1 300 -0.4911095 -0.6561048 -0.3261142 0.1473663 0.0752914 0.2884371
```
