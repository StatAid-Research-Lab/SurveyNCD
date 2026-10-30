# WHO World Standard Population

The WHO World Standard Population (world average population 2000-2025;
Ahmad et al. 2001), optionally re-aggregated to custom age groups such
as the 18-29, 30-44, 45-59 and 60-69 groups used in STEPS reports.

## Usage

``` r
who_standard_population(breaks = NULL, labels = NULL)
```

## Arguments

- breaks:

  Optional increasing numeric vector of age-group boundaries. Intervals
  are `[breaks[i], breaks[i + 1])`; the last boundary is the (exclusive)
  upper limit. `NULL` returns the 21 published groups.

- labels:

  Optional labels for the intervals.

## Value

A data frame with `age_group`, `lower`, `upper` (exclusive) and
`weight`, where `weight` sums to 1.

## Details

The standard is published in 5-year groups. For `breaks` that are not
multiples of 5 (e.g. 18), the share of a 5-year group falling inside an
interval is assumed proportional to the years it covers (uniform age
distribution within the group). The 100+ group is treated as 100-104.

## References

Ahmad, O. B., Boschi-Pinto, C., Lopez, A. D., Murray, C. J. L., Lozano,
R., & Inoue, M. (2001). *Age standardization of rates: A new WHO
standard*. GPE Discussion Paper Series No. 31. Geneva: World Health
Organization.

## Examples

``` r
who_standard_population()
#>    age_group lower upper       weight
#> 1        0-4     0     5 8.856900e-02
#> 2        5-9     5    10 8.686960e-02
#> 3      10-14    10    15 8.596991e-02
#> 4      15-19    15    20 8.467037e-02
#> 5      20-24    20    25 8.217124e-02
#> 6      25-29    25    30 7.927225e-02
#> 7      30-34    30    35 7.607337e-02
#> 8      35-39    35    40 7.147498e-02
#> 9      40-44    40    45 6.587694e-02
#> 10     45-49    45    50 6.037887e-02
#> 11     50-54    50    55 5.368121e-02
#> 12     55-59    55    60 4.548408e-02
#> 13     60-64    60    65 3.718698e-02
#> 14     65-69    65    70 2.958964e-02
#> 15     70-74    70    75 2.209227e-02
#> 16     75-79    75    80 1.519468e-02
#> 17     80-84    80    85 9.096816e-03
#> 18     85-89    85    90 4.398461e-03
#> 19     90-94    90    95 1.499475e-03
#> 20     95-99    95   100 3.998600e-04
#> 21      100+   100   105 4.998251e-05
who_standard_population(breaks = c(18, 30, 45, 60, 70))
#>   age_group lower upper    weight
#> 1     18-29    18    30 0.3075494
#> 2     30-44    30    45 0.3360723
#> 3     45-59    45    60 0.2512278
#> 4     60-69    60    70 0.1051505
```
