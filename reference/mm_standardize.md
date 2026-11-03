# Age-standardised prevalence from a survey design

Direct age standardisation of one or more 0/1 indicators using
[`survey::svystandardize()`](https://rdrr.io/pkg/survey/man/svystandardize.html),
so that standard errors reflect the survey design. Crude
(unstandardised) estimates are returned alongside.

## Usage

``` r
mm_standardize(design, vars, age_group, standard, by = NULL, level = 0.95)
```

## Arguments

- design:

  A survey design.

- vars:

  Character vector of 0/1 indicator columns (for example
  `"mm_multimorbid"` from
  [`multimorbidity_index()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/multimorbidity_index.md)).

- age_group:

  Name of a factor (or character) column of age groups.

- standard:

  Standard population: a data frame with columns `age_group` and
  `weight` (as returned by
  [`who_standard_population()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/who_standard_population.md)),
  or a named numeric vector. Every age group in the data must appear in
  it.

- by:

  Optional character vector of grouping columns (standardisation is done
  within each group).

- level:

  Confidence level.

## Value

A data frame with `indicator`, any `by` columns, `n`, `crude`,
`standardized`, `se`, `lower` and `upper` (Wald interval for the
standardised estimate).

## Examples

``` r
d <- ncd_survey
d$htn <- recode_binary(d$htn_raw, yes = 1, no = 2)
#> Warning: Some values matched neither `yes` nor `no`; leaving them as NA.
d$age_group <- cut(d$age, c(18, 30, 45, 60, 70), right = FALSE,
                   labels = c("18-29", "30-44", "45-59", "60-69"))
des <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~wt,
                         data = d, nest = TRUE)
std <- who_standard_population(breaks = c(18, 30, 45, 60, 70))
mm_standardize(des, "htn", age_group = "age_group", standard = std, by = "sex")
#>   indicator    sex    n     crude standardized         se     lower     upper
#> 1       htn Female 1186 0.1647403    0.2025083 0.01474037 0.1736177 0.2313989
#> 2       htn   Male 1122 0.1759783    0.2062249 0.02179429 0.1635089 0.2489410
```
