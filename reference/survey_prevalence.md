# Design-based prevalence of one or more binary indicators

Estimates the population prevalence of each 0/1 indicator in `vars`,
overall or within groups defined by one or more variables, using the
full survey design (strata, clusters, weights). Respondents with a
missing value for an indicator are excluded from that indicator only, by
domain estimation, so the design is never broken by dropping rows.

## Usage

``` r
survey_prevalence(design, vars, by = NULL, level = 0.95, method = "logit")
```

## Arguments

- design:

  A survey design (see
  [`dhs_design()`](https://stataid-research-lab.github.io/SurveyNCD/reference/design_helpers.md)
  or
  [`survey::svydesign()`](https://rdrr.io/pkg/survey/man/svydesign.html));
  srvyr designs are accepted.

- vars:

  Character vector of 0/1 (or logical) indicator columns.

- by:

  Optional character vector of grouping columns; estimates are produced
  for every observed combination.

- level:

  Confidence level.

- method:

  Confidence-interval method passed to
  [`survey::svyciprop()`](https://rdrr.io/pkg/survey/man/svyciprop.html);
  `"logit"` (default) keeps intervals inside 0-1.

## Value

A data frame of class `surveyncd_prevalence` with columns `indicator`,
any `by` columns, `n` (unweighted respondents with a valid answer),
`estimate`, `se`, `lower`, `upper` and `deff` (design effect relative to
simple random sampling with replacement).

## See also

[`ncd_table()`](https://stataid-research-lab.github.io/SurveyNCD/reference/ncd_table.md)
for a formatted table and `autoplot()` for a plot.

## Examples

``` r
d <- ncd_survey
d$htn <- recode_binary(d$htn_raw, yes = 1, no = 2)
#> Warning: Some values matched neither `yes` nor `no`; leaving them as NA.
d$dm  <- recode_binary(d$dm_raw,  yes = 1, no = 2)
#> Warning: Some values matched neither `yes` nor `no`; leaving them as NA.
des <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~wt,
                         data = d, nest = TRUE)
survey_prevalence(des, c("htn", "dm"))
#>   indicator    n  estimate         se      lower      upper     deff
#> 1       htn 2308 0.1700861 0.01200588 0.14759272 0.19522242 2.355773
#> 2        dm 2332 0.0714495 0.00874970 0.05593269 0.09085671 2.689824
survey_prevalence(des, "htn", by = c("sex", "residence"))
#>   indicator    sex residence   n  estimate         se     lower     upper
#> 1       htn Female     Rural 615 0.1521554 0.01552199 0.1235726 0.1859469
#> 2       htn Female     Urban 571 0.1960536 0.02095188 0.1574067 0.2414700
#> 3       htn   Male     Rural 542 0.1762592 0.02439366 0.1325337 0.2305762
#> 4       htn   Male     Urban 580 0.1753591 0.01878007 0.1408216 0.2162354
#>       deff
#> 1 1.146726
#> 2 1.587518
#> 3 2.217221
#> 4 1.412147
```
