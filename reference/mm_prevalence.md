# Population-level multimorbidity estimates from complex survey data

Design-weighted prevalence of multimorbidity and mean number of
conditions, accounting for stratification, clustering and sampling
weights. Run
[`multimorbidity_index()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/multimorbidity_index.md)
first to create `mm_category` and `mm_n_conditions`.

## Usage

``` r
mm_prevalence(
  data,
  ids = NULL,
  strata = NULL,
  weights = NULL,
  by = NULL,
  nest = TRUE,
  level = 0.95
)
```

## Arguments

- data:

  A survey design whose data contain the output of
  [`multimorbidity_index()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/multimorbidity_index.md),
  or such a data frame.

- ids, strata, weights:

  Column names of the clusters, strata and weights (only when `data` is
  a data frame). `ids = NULL` means no clustering and `strata = NULL` no
  stratification.

- by:

  Optional character vector of one or more grouping columns.

- nest:

  Passed to
  [`survey::svydesign()`](https://rdrr.io/pkg/survey/man/svydesign.html)
  when `data` is a data frame.

- level:

  Confidence level.

## Value

A data frame of class `surveyncd_mm_prevalence` with any `by` columns,
`n`, `prevalence`, `prevalence_se`, `prevalence_lower`,
`prevalence_upper`, `mean_conditions` and `mean_conditions_se`.

## Details

`data` can be either a survey design object (recommended; for example
from
[`dhs_design()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/design_helpers.md)
or
[`survey::svydesign()`](https://rdrr.io/pkg/survey/man/svydesign.html))
or a data frame plus the names of the design columns. Respondents with a
missing multimorbidity score are excluded by domain estimation: the full
design is kept for variance estimation and the number excluded is
reported.

## Examples

``` r
set.seed(1)
n <- 40
df <- data.frame(
  psu    = rep(1:8, each = 5),
  region = rep(c("A", "B"), each = 20),
  sex    = rep(c("F", "M"), 20),
  wt     = round(runif(n, 0.8, 1.4), 2),
  htn    = rbinom(n, 1, 0.3),
  dm     = rbinom(n, 1, 0.2)
)
scored <- multimorbidity_index(df, conditions = c("htn", "dm"))
mm_prevalence(scored, ids = "psu", strata = "region", weights = "wt")
#>    n   prevalence prevalence_se prevalence_lower prevalence_upper
#> 1 40 2.887882e-12             0     2.758321e-12      3.02353e-12
#>   mean_conditions mean_conditions_se
#> 1       0.4551398         0.06129464

# Design-first interface, several grouping variables
des <- survey::svydesign(ids = ~psu, strata = ~region, weights = ~wt,
                         data = scored, nest = TRUE)
mm_prevalence(des, by = c("region", "sex"))
#>   region sex  n   prevalence prevalence_se prevalence_lower prevalence_upper
#> 1      A   F 10 2.135976e-11             0     1.608318e-11     2.836749e-11
#> 2      A   M 10 2.132197e-11             0     1.325349e-11     3.430240e-11
#> 3      B   F 10 2.133984e-11             0     1.456301e-11     3.127023e-11
#> 4      B   M 10 2.138658e-11             0     1.399270e-11     3.268745e-11
#>   mean_conditions mean_conditions_se
#> 1       0.3841355         0.16739307
#> 2       0.2864629         0.19339947
#> 3       0.5395189         0.14974578
#> 4       0.6288557         0.04935576
```
