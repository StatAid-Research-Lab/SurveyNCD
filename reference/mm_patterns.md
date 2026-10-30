# Most common combinations of conditions (multimorbidity patterns)

Design-based prevalence of every pair (or triad, ...) of conditions,
with the ratio of observed to expected prevalence. The expected
prevalence is the product of the single-condition prevalences, i.e. what
would be seen if the conditions occurred independently; ratios above 1
indicate conditions that cluster together.

## Usage

``` r
mm_patterns(design, conditions, order = 2, top = NULL, level = 0.95)
```

## Arguments

- design:

  A survey design containing the 0/1 condition columns.

- conditions:

  Character vector of 0/1 condition columns.

- order:

  Size of the combinations: 2 for pairs (default), 3 for triads.

- top:

  Keep only the `top` most prevalent combinations (`NULL` keeps all).

- level:

  Confidence level.

## Value

A data frame of class `surveyncd_patterns` with columns `combination`,
`n`, `prevalence`, `se`, `lower`, `upper`, `expected` and `oe_ratio`,
sorted by prevalence.

## Details

A respondent counts towards a combination only if all of its conditions
are answered; combinations are estimated by domain estimation on those
respondents. Single-condition prevalences for the expected value are
each estimated on respondents who answered that condition.

## Examples

``` r
d <- ncd_survey
for (v in c("htn", "dm", "arth", "angina"))
  d[[v]] <- suppressWarnings(recode_binary(d[[paste0(v, "_raw")]], yes = 1, no = 2))
des <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~wt,
                         data = d, nest = TRUE)
mm_patterns(des, c("htn", "dm", "arth", "angina"))
#>     combination    n  prevalence          se       lower      upper    expected
#> 1      htn + dm 2242 0.029291564 0.005559247 0.020069601 0.04256694 0.012152568
#> 2    htn + arth 2271 0.028031444 0.004912569 0.019774392 0.03959706 0.017691381
#> 3  htn + angina 2258 0.008862005 0.002119272 0.005511790 0.01421945 0.005246667
#> 4     dm + arth 2294 0.007982728 0.002086038 0.004751141 0.01338279 0.007431767
#> 5   dm + angina 2280 0.006324086 0.001882994 0.003501720 0.01139525 0.002204011
#> 6 arth + angina 2311 0.005988741 0.001944472 0.003143304 0.01138057 0.003208540
#>   oe_ratio
#> 1 2.410319
#> 2 1.584469
#> 3 1.689073
#> 4 1.074136
#> 5 2.869352
#> 6 1.866500
```
