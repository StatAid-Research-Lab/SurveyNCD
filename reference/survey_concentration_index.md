# Survey-weighted concentration index

Computes the concentration index of a health variable across a
socioeconomic ranking (for example a wealth score), with design-based
standard errors, confidence intervals and p-values that account for
stratification and clustering. The standard, generalized, Erreygers and
Wagstaff indices are available.

## Usage

``` r
survey_concentration_index(
  design,
  outcome,
  wealth,
  conf.level = 0.95,
  type = c("CI", "generalized", "erreygers", "wagstaff"),
  bounds = NULL,
  by = NULL
)
```

## Arguments

- design:

  A survey design object (survey or srvyr).

- outcome:

  Unquoted name of the health variable.

- wealth:

  Unquoted name of the ranking variable.

- conf.level:

  Confidence level.

- type:

  One of `"CI"` (default), `"generalized"`, `"erreygers"`, `"wagstaff"`.

- bounds:

  Numeric vector `c(a, b)` of the outcome's bounds, needed for
  `"erreygers"` and `"wagstaff"`. Defaults to `c(0, 1)` when the outcome
  is binary.

- by:

  Optional character vector of grouping columns; ranks are computed
  within each group.

## Value

A tibble of class `surveyncd_ci` with any `by` columns,
`Concentration_Index`, `Standard_Error`, `Lower_CI`, `Upper_CI`,
`p_value`, `Outcome_Mean`, `n` and `Type`.

## Details

The standard concentration index is \$\$C = \frac{2}{\mu}
\mathrm{cov}\_w(y_i, R_i),\$\$ where \\\mu\\ is the weighted mean of
\\y\\ and \\R_i\\ the weighted fractional rank: the mid-point of each
respondent's interval of the cumulative weight distribution (Lerman and
Yitzhaki 1989). Respondents tied on the ranking variable share the
mid-point of their tied group's interval, so results do not depend on
the order of the data.

Each index is the slope \\\beta\\ of the "convenient regression" of
Kakwani, Wagstaff and van Doorslaer (1997), \\2\sigma_R^2 \\ h(y_i) =
\alpha + \beta R_i + \varepsilon_i\\, fitted with
[`survey::svyglm()`](https://rdrr.io/pkg/survey/man/svyglm.html) so that
its standard error is design-based. With bounds \\a \le y \le b\\
(O'Donnell et al. 2016):

- `"CI"` (standard): \\h(y) = y/\mu\\.

- `"generalized"`: \\h(y) = y\\, giving \\\mu C\\.

- `"erreygers"`: \\h(y) = 4y/(b - a)\\, giving \\4\mu C/(b-a)\\
  (Erreygers 2009).

- `"wagstaff"`: \\h(y) = (b - a)y/((b - \mu)(\mu - a))\\, giving
  \\(b-a)\mu C/((b-\mu)(\mu-a))\\; for binary outcomes \\C/(1-\mu)\\
  (Wagstaff 2005).

For bounded outcomes such as binary indicators the Erreygers or Wagstaff
index is usually preferred. The standard error treats the ranks and
\\\mu\\ as fixed.

## References

Kakwani, N., Wagstaff, A., & van Doorslaer, E. (1997). Socioeconomic
inequalities in health: Measurement, computation, and statistical
inference. *Journal of Econometrics*, 77(1), 87-103.
[doi:10.1016/S0304-4076(96)01807-6](https://doi.org/10.1016/S0304-4076%2896%2901807-6)

Erreygers, G. (2009). Correcting the concentration index. *Journal of
Health Economics*, 28(2), 504-515.
[doi:10.1016/j.jhealeco.2008.02.003](https://doi.org/10.1016/j.jhealeco.2008.02.003)

Wagstaff, A. (2005). The bounds of the concentration index when the
variable of interest is binary, with an application to immunization
inequality. *Health Economics*, 14(4), 429-432.
[doi:10.1002/hec.953](https://doi.org/10.1002/hec.953)

O'Donnell, O., O'Neill, S., Van Ourti, T., & Walsh, B. (2016). conindex:
Estimation of concentration indices. *The Stata Journal*, 16(1),
112-138.
[doi:10.1177/1536867X1601600112](https://doi.org/10.1177/1536867X1601600112)

## Examples

``` r
set.seed(42)
n <- 50
df <- data.frame(
  wealth  = rnorm(n, 50, 15),
  outcome = pmax(0, 0.3 * rnorm(n, 50, 15) + rnorm(n, 0, 5)),
  sick    = rbinom(n, 1, 0.3),
  wt      = sample(1:5, n, replace = TRUE)
)
design <- survey::svydesign(ids = ~1, weights = ~wt, data = df)
survey_concentration_index(design, outcome = outcome, wealth = wealth)
#> # A tibble: 1 × 8
#>   Concentration_Index Standard_Error Lower_CI Upper_CI p_value Outcome_Mean
#>                 <dbl>          <dbl>    <dbl>    <dbl>   <dbl>        <dbl>
#> 1             -0.0242         0.0370  -0.0967   0.0483   0.513         15.1
#> # ℹ 2 more variables: n <int>, Type <chr>
survey_concentration_index(design, outcome = sick, wealth = wealth,
                           type = "erreygers")
#> # A tibble: 1 × 8
#>   Concentration_Index Standard_Error Lower_CI Upper_CI p_value Outcome_Mean
#>                 <dbl>          <dbl>    <dbl>    <dbl>   <dbl>        <dbl>
#> 1             -0.0101          0.188   -0.379    0.359   0.957        0.336
#> # ℹ 2 more variables: n <int>, Type <chr>
```
