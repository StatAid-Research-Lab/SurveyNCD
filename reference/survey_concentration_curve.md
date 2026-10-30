# Concentration curve from a survey design

Coordinates of the concentration curve: the cumulative share of the
population ranked from poorest to richest (x) against the cumulative
share of the health variable (y), both using sampling weights. A curve
above the diagonal means the variable is concentrated among poorer
people. Tied respondents are grouped into one point, consistent with
[`survey_concentration_index()`](https://stataid-research-lab.github.io/SurveyNCD/reference/survey_concentration_index.md):
the concentration index equals one minus twice the area under the curve.

## Usage

``` r
survey_concentration_curve(design, outcome, wealth, by = NULL)
```

## Arguments

- design:

  A survey design object (survey or srvyr).

- outcome:

  Unquoted name of the health variable.

- wealth:

  Unquoted name of the ranking variable.

- by:

  Optional character vector of grouping columns; ranks are computed
  within each group.

## Value

A data frame of class `surveyncd_curve` with any `by` columns,
`cum_population` and `cum_outcome`, starting at (0, 0).

## Examples

``` r
set.seed(1)
df <- data.frame(wealth = rnorm(300), wt = runif(300, 0.5, 2))
df$sick <- rbinom(300, 1, plogis(-1 - 0.6 * df$wealth))
des <- survey::svydesign(ids = ~1, weights = ~wt, data = df)
cc <- survey_concentration_curve(des, sick, wealth)
head(cc)
#>   cum_population cum_outcome
#> 1    0.000000000  0.00000000
#> 2    0.004971117  0.01829262
#> 3    0.007346090  0.02703200
#> 4    0.009712661  0.02703200
#> 5    0.012137815  0.03595604
#> 6    0.015624600  0.04878664
```
