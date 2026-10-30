# Plot SurveyNCD results with ggplot2

`autoplot()` methods for the results of
[`survey_prevalence()`](https://stataid-research-lab.github.io/SurveyNCD/reference/survey_prevalence.md),
[`mm_prevalence()`](https://stataid-research-lab.github.io/SurveyNCD/reference/mm_prevalence.md),
[`survey_concentration_index()`](https://stataid-research-lab.github.io/SurveyNCD/reference/survey_concentration_index.md),
[`survey_concentration_curve()`](https://stataid-research-lab.github.io/SurveyNCD/reference/survey_concentration_curve.md)
and
[`mm_patterns()`](https://stataid-research-lab.github.io/SurveyNCD/reference/mm_patterns.md).
Each returns a `ggplot` object that can be modified with the usual
ggplot2 layers.

## Usage

``` r
# S3 method for class 'surveyncd_prevalence'
autoplot(object, ...)

# S3 method for class 'surveyncd_mm_prevalence'
autoplot(object, ...)

# S3 method for class 'surveyncd_ci'
autoplot(object, ...)

# S3 method for class 'surveyncd_curve'
autoplot(object, ...)

# S3 method for class 'surveyncd_patterns'
autoplot(object, ...)
```

## Arguments

- object:

  A result object from one of the functions above.

- ...:

  Not used.

## Value

A `ggplot` object.

## Examples

``` r
d <- ncd_survey
d$htn <- recode_binary(d$htn_raw, yes = 1, no = 2)
#> Warning: Some values matched neither `yes` nor `no`; leaving them as NA.
d$dm  <- recode_binary(d$dm_raw,  yes = 1, no = 2)
#> Warning: Some values matched neither `yes` nor `no`; leaving them as NA.
des <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~wt,
                         data = d, nest = TRUE)
ggplot2::autoplot(survey_prevalence(des, c("htn", "dm"), by = "residence"))

ggplot2::autoplot(survey_concentration_curve(des, dm, wealth_score))
```
