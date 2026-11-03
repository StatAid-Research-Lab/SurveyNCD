# Simulated adult NCD survey (STEPS-style)

A simulated nationally representative-style survey of adults aged 18-69,
drawn from a known synthetic population by stratified two-stage cluster
sampling. It mimics the structure of WHO STEPS and DHS microdata
(strata, primary sampling units, unequal sampling weights, raw response
codes with "don't know" answers) so that every function in the package
can be demonstrated. **The data are entirely synthetic**; regions are
fictitious and no estimate describes any real country.

## Usage

``` r
ncd_survey
```

## Format

A data frame with 2,400 rows (one adult per household) and 18 variables:

- hh_id:

  Household identifier (links to `child_anthro`).

- region:

  Region (6 fictitious regions, "Region A" to "Region F").

- residence:

  "Urban" or "Rural".

- stratum:

  Sampling stratum (region x residence, 12 strata).

- psu:

  Primary sampling unit (enumeration area), 120 in total.

- wt:

  Sampling weight, normalised to mean 1 (as in DHS).

- sex:

  "Female" or "Male".

- age:

  Age in completed years (18-69).

- wealth_score:

  Continuous household wealth index (higher = richer).

- wealth_quintile:

  Weighted wealth quintile, 1 (poorest) to 5 (richest).

- bmi:

  Body mass index (kg/m^2).

- htn_raw, dm_raw, arth_raw, asthma_raw, angina_raw, stroke_raw:

  Raw answers to "Has a doctor or health worker ever told you that you
  have hypertension / diabetes / arthritis / asthma / angina or heart
  disease / stroke?", coded 1 = yes, 2 = no, 9 = don't know.

- dep_raw:

  Raw answer for depression, coded as text: "Yes", "No", "Don't know".

## Source

Simulated; see `data-raw/simulate_survey.R` in
<https://github.com/StatAid-Research-Lab/SurveyNCD>.

## Details

The population has 6 regions of unequal size, each divided into urban
and rural enumeration areas (12 strata). Ten enumeration areas were
selected by simple random sampling in every stratum and 20 households in
each, so small regions and urban areas are over-sampled and the weights
vary about 15-fold. The code that generates the population and the
sample is in `data-raw/` in the package source repository.

## See also

[`child_anthro`](https://github.com/StatAid-Research-Lab/SurveyNCD/reference/child_anthro.md)

## Examples

``` r
head(ncd_survey)
#>   hh_id   region residence          stratum psu       wt    sex age
#> 1   908 Region A     Urban Region A - Urban   1 1.287859   Male  26
#> 2   932 Region A     Urban Region A - Urban   1 1.287859   Male  25
#> 3   936 Region A     Urban Region A - Urban   1 1.287859   Male  35
#> 4   937 Region A     Urban Region A - Urban   1 1.287859   Male  28
#> 5   938 Region A     Urban Region A - Urban   1 1.287859 Female  41
#> 6   939 Region A     Urban Region A - Urban   1 1.287859   Male  38
#>   wealth_score wealth_quintile  bmi htn_raw dm_raw arth_raw asthma_raw
#> 1        0.926               4 17.3       2      2        2          2
#> 2       -0.162               2 25.8       2      9        2          2
#> 3       -0.477               2 20.7       2      2        2          2
#> 4        1.607               5 24.4       2      2        2          2
#> 5        0.353               3 24.8       2      2        2          2
#> 6        1.297               4 25.5       1      2        2          2
#>   angina_raw stroke_raw    dep_raw
#> 1          2          2         No
#> 2          2          9         No
#> 3          2          2         No
#> 4          2          2         No
#> 5          2          2 Don't know
#> 6          2          2         No
ncd_survey$htn <- recode_binary(ncd_survey$htn_raw, yes = 1, no = 2)
#> Warning: Some values matched neither `yes` nor `no`; leaving them as NA.
```
