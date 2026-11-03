# Calculate a self-reported multimorbidity index

Computes an individual-level multimorbidity score from a set of
self-reported binary condition indicators (e.g. "Has a doctor ever told
you that you have hypertension?"). This is designed for population
health survey data (WHO STEPS, DHS, SAGE, etc.), where multimorbidity is
captured through self-report rather than ICD-coded diagnoses – a data
shape that existing comorbidity packages (which all assume ICD claims
data) don't handle.

## Usage

``` r
multimorbidity_index(
  data,
  conditions,
  weights = NULL,
  na_action = c("ignore", "na"),
  threshold = 2
)
```

## Arguments

- data:

  A data frame, one row per individual.

- conditions:

  A character vector of column names in `data`. Each column must already
  be coded 0/1/NA (1 = condition present). Use
  [`recode_binary()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/recode_binary.md)
  first if your raw data uses Yes/No, 1/2, etc.

- weights:

  Optional named numeric vector giving a weight for each condition
  (names must match `conditions`). If `NULL` (the default), every
  condition counts equally – i.e. a simple unweighted sum, which is how
  the published Functional Comorbidity Index (Groll et al. 2005) is
  scored. See
  [`fci_items()`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/fci_items.md).

- na_action:

  How to handle a row with at least one missing condition. `"ignore"`
  (default) sums whatever conditions are non-missing for that person.
  `"na"` returns NA for that person's index entirely, which is the safer
  choice once you move to population-level (survey-weighted) estimates,
  since silently treating missing as absent can bias prevalence
  downward.

- threshold:

  Number of conditions at or above which a respondent is classified as
  multimorbid. The default, 2, is the most common definition; 3 is often
  used for "complex multimorbidity".

## Value

`data` with four columns appended: `mm_n_conditions` (raw count of
conditions present), `mm_index` (the possibly weighted score),
`mm_category` (factor: "None", "Single condition" or, when
`threshold > 2`, "1-k conditions", and "Multimorbid") and
`mm_multimorbid` (1 if the count is at least `threshold`, else 0).

## References

Groll, D. L., To, T., Bombardier, C., & Wright, J. G. (2005). The
development of a comorbidity index with physical function as the
outcome. *Journal of Clinical Epidemiology*, 58(6), 595-602.
[doi:10.1016/j.jclinepi.2004.10.018](https://doi.org/10.1016/j.jclinepi.2004.10.018)

## Examples

``` r
df <- data.frame(
  id           = 1:5,
  hypertension = c(1, 0, 1, 1, 0),
  diabetes     = c(0, 0, 1, 1, 0),
  arthritis    = c(1, 0, 0, 1, NA)
)
multimorbidity_index(df, conditions = c("hypertension", "diabetes", "arthritis"))
#>   id hypertension diabetes arthritis mm_n_conditions mm_index mm_category
#> 1  1            1        0         1               2        2 Multimorbid
#> 2  2            0        0         0               0        0        None
#> 3  3            1        1         0               2        2 Multimorbid
#> 4  4            1        1         1               3        3 Multimorbid
#> 5  5            0        0        NA               0        0        None
#>   mm_multimorbid
#> 1              1
#> 2              0
#> 3              1
#> 4              1
#> 5              0
```
