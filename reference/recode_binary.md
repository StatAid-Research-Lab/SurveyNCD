# Recode a messy survey column into clean 0/1

Converts alternative survey response values into clean standard numeric
0 or 1 scores. When `no` is not specified, every value that is neither
in `yes` nor `NA` is treated as 0. When `no` *is* specified, values
matching neither `yes` nor `no` are left as `NA` and a warning is
issued.

## Usage

``` r
recode_binary(x, yes, no = NULL)
```

## Arguments

- x:

  A vector coding a single condition.

- yes:

  The raw value(s) that should become 1.

- no:

  Optional raw value(s) that should become 0. If `NULL` (the default),
  every non-`yes`, non-`NA` value becomes 0.

## Value

A numeric vector of 0, 1, or `NA`.

## Examples

``` r
# STEPS-style coding: 1 = yes, 2 = no
recode_binary(c(1, 2, 1, NA), yes = 1, no = 2)
#> [1]  1  0  1 NA

# When `no` is omitted, everything that isn't `yes` becomes 0
recode_binary(c(1, 2, 9, NA), yes = 1)
#> [1]  1  0  0 NA

# With `no` specified, unrecognised codes (9) become NA with a warning
recode_binary(c(1, 2, 9, NA), yes = 1, no = 2)
#> Warning: Some values matched neither `yes` nor `no`; leaving them as NA.
#> [1]  1  0 NA NA
```
