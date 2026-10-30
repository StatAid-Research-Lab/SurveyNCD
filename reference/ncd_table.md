# Publication-ready prevalence table

Builds a formatted table of design-based prevalence (with confidence
intervals) for several indicators, overall and by group, ready to paste
into a manuscript or pass to knitr, flextable or gt.

## Usage

``` r
ncd_table(
  design,
  vars,
  by = NULL,
  labels = NULL,
  digits = 1,
  level = 0.95,
  n_row = TRUE
)
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

  Optional single grouping column; one column of the table per group,
  plus an "Overall" column.

- labels:

  Optional named character vector of row labels
  (`c(htn = "Hypertension")`).

- digits:

  Decimal places for percentages.

- level:

  Confidence level.

- n_row:

  Add a first row with the unweighted number of respondents.

## Value

A data frame of class `ncd_table` whose first column is `Indicator` and
whose other columns hold "estimate (lower-upper)" strings in percent.
The underlying numeric estimates are in attribute `"estimates"`.

## Examples

``` r
d <- ncd_survey
d$htn <- recode_binary(d$htn_raw, yes = 1, no = 2)
#> Warning: Some values matched neither `yes` nor `no`; leaving them as NA.
d$dm  <- recode_binary(d$dm_raw,  yes = 1, no = 2)
#> Warning: Some values matched neither `yes` nor `no`; leaving them as NA.
des <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~wt,
                         data = d, nest = TRUE)
ncd_table(des, c("htn", "dm"), by = "sex",
          labels = c(htn = "Hypertension", dm = "Diabetes"))
#> Design-based % (95% CI)
#>  Indicator    Overall          Female           Male            
#>  Unweighted n 2,400            1,234            1,166           
#>  Hypertension 17.0 (14.8-19.5) 16.5 (14.1-19.1) 17.6 (14.3-21.4)
#>  Diabetes     7.1 (5.6-9.1)    7.2 (5.3-9.8)    7.0 (5.2-9.5)   
```
