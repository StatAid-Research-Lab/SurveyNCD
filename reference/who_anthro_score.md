# Calculate WHO Anthropometric Categories from DHS/MICS Data

Cleans raw DHS/MICS z-score variables (e.g., hw70, hw71, hw72), adjusts
the decimal scaling if needed, handles DHS-specific missing flags,
applies WHO biologically implausible flagging rules, and categorizes
them into WHO severity tiers.

## Usage

``` r
who_anthro_score(
  x,
  indicator = c("stunting", "wasting", "underweight"),
  scaled_by_100 = TRUE,
  remove_implausible = TRUE
)
```

## Arguments

- x:

  A numeric vector of raw DHS/MICS z-scores.

- indicator:

  The type of indicator for labeling and flagging: `"stunting"`
  (height-for-age, HAZ), `"wasting"` (weight-for-height, WHZ), or
  `"underweight"` (weight-for-age, WAZ).

- scaled_by_100:

  Logical. If `TRUE` (default), divides input values by 100 (standard
  for DHS raw recode files like `hw70`). If `FALSE`, assumes values are
  already on the standard z-score scale (like MICS or cleaned DHS data).

- remove_implausible:

  Logical. If `TRUE` (default), applies WHO child growth standard
  flagging rules to set biologically implausible values to `NA`. WHO
  flags are:

  - Stunting (HAZ): \< -6.0 or \> 6.0

  - Wasting (WHZ): \< -5.0 or \> 5.0

  - Underweight (WAZ): \< -6.0 or \> 5.0

## Value

A factor vector of WHO categories (Severe, Moderate, Normal) with the
indicator label appended.

## References

World Health Organization (2006). *WHO Child Growth Standards:
Length/height-for-age, weight-for-age, weight-for-length,
weight-for-height and body mass index-for-age: Methods and development*.
Geneva: WHO.

## Examples

``` r
# DHS-style raw z-scores (scaled by 100)
raw <- c(-310, -254, 50, 9999)
who_anthro_score(raw, indicator = "stunting")
#> [1] Severe stunting   Moderate stunting Normal stunting   <NA>             
#> Levels: Severe stunting Moderate stunting Normal stunting

# Already on standard z-score scale
who_anthro_score(c(-3.1, -2.5, 0.5), indicator = "wasting",
                 scaled_by_100 = FALSE)
#> [1] Severe wasting   Moderate wasting Normal wasting  
#> Levels: Severe wasting Moderate wasting Normal wasting
```
