# Simulated child anthropometry (DHS-style)

Children under five living in the households of
[`ncd_survey`](https://stataid-research-lab.github.io/SurveyNCD/reference/ncd_survey.md),
with height-for-age, weight-for-age and weight-for-height z-scores
stored in the DHS recode convention: multiplied by 100, with flag codes
9996 (height out of plausible range) and 9998 (missing), and a few
biologically implausible values. **The data are entirely synthetic.**

## Usage

``` r
child_anthro
```

## Format

A data frame with 1,034 rows and 14 variables:

- child_id:

  Child identifier.

- hh_id:

  Household identifier (links to `ncd_survey`).

- region, residence, stratum, psu, wt:

  Design variables, inherited from the household.

- sex:

  "Female" or "Male".

- age_months:

  Age in months (0-59).

- wealth_score, wealth_quintile:

  Household wealth, as in `ncd_survey`.

- hw70:

  Height-for-age z-score x 100 (DHS variable name).

- hw71:

  Weight-for-age z-score x 100.

- hw72:

  Weight-for-height z-score x 100.

## Source

Simulated; see `data-raw/simulate_survey.R` in
<https://github.com/StatAid-Research-Lab/SurveyNCD>.

## Examples

``` r
table(who_anthro_score(child_anthro$hw70, indicator = "stunting"),
      useNA = "ifany")
#> 
#>   Severe stunting Moderate stunting   Normal stunting              <NA> 
#>                81               209               725                19 
```
