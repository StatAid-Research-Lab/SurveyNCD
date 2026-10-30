# Sensitivity of multimorbidity prevalence to "don't know" answers

Missing answers (for example "don't know") make multimorbidity
prevalence uncertain beyond sampling error. This function reports three
design-based estimates: the complete-case estimate (respondents with any
missing answer excluded), a lower bound (every missing answer treated as
"no") and an upper bound (every missing answer treated as "yes"). The
bounds contain the prevalence under any assumption about the missing
answers; the complete-case estimate is unbiased only if answers are
missing completely at random.

## Usage

``` r
mm_bounds(design, conditions, threshold = 2, by = NULL, level = 0.95)
```

## Arguments

- design:

  A survey design containing the 0/1 condition columns (with `NA` for
  missing answers).

- conditions:

  Character vector of condition columns.

- threshold:

  Number of conditions defining multimorbidity.

- by:

  Optional character vector of grouping columns.

- level:

  Confidence level.

## Value

A data frame with `scenario` ("complete case", "lower bound", "upper
bound"), any `by` columns, `n`, `estimate`, `se`, `lower` and `upper`.

## Examples

``` r
d <- ncd_survey
for (v in c("htn", "dm", "arth"))
  d[[v]] <- suppressWarnings(recode_binary(d[[paste0(v, "_raw")]], yes = 1, no = 2))
des <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~wt,
                         data = d, nest = TRUE)
mm_bounds(des, c("htn", "dm", "arth"))
#>                      scenario    n   estimate          se      lower      upper
#> 1               complete case 2205 0.05298076 0.008198489 0.03889263 0.07179086
#> 2  lower bound (missing = no) 2400 0.05036984 0.007557559 0.03733181 0.06764141
#> 3 upper bound (missing = yes) 2400 0.06991718 0.008339936 0.05508717 0.08836622
```
