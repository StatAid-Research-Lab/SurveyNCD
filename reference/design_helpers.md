# Build a survey design from DHS, MICS or STEPS microdata

Thin wrappers around
[`survey::svydesign()`](https://rdrr.io/pkg/survey/man/svydesign.html)
that use each programme's standard variable names, so the design
(clusters, strata, weights) is specified correctly in one line.

## Usage

``` r
dhs_design(
  data,
  psu = "v021",
  strata = "v023",
  weight = "v005",
  weight_scale = 1e+06,
  ...
)

mics_design(
  data,
  weight,
  psu = "HH1",
  strata = "stratum",
  weight_scale = 1,
  ...
)

steps_design(
  data,
  weight,
  psu = "psu",
  strata = "stratum",
  weight_scale = 1,
  ...
)
```

## Arguments

- data:

  A data frame of survey microdata.

- psu, strata, weight:

  Names of the cluster, stratum and weight columns. Set `strata = NULL`
  for an unstratified design.

- weight_scale:

  Number the weight is divided by (1e6 for raw DHS weights; 1 if the
  weight has already been rescaled).

- ...:

  Further arguments passed to
  [`survey::svydesign()`](https://rdrr.io/pkg/survey/man/svydesign.html).

## Value

A `survey.design2` object.

## Details

- **DHS**: the Guide to DHS Statistics identifies the primary sampling
  unit as `v021` (`hv021`/`mv021` in household and men's files), the
  strata as `v023` (`hv023`/`mv023`) and the weight as `v005`
  (`hv005`/`mv005`) divided by 1,000,000. Check the survey report
  (Appendix A) where strata were not consistently defined.

- **MICS**: clusters are `HH1` and strata `stratum`; the weight depends
  on the file (`hhweight`, `wmweight`, `mnweight`, `chweight`,
  `fsweight`), so it must be given.

- **STEPS**: clusters are usually `psu` and strata `stratum`; the weight
  depends on the step analysed (`wstep1`, `wstep2`, `wstep3`), so it
  must be given. A design built with the stepssurvey package can be
  passed to SurveyNCD functions directly instead.

All three set `nest = TRUE`, because cluster numbers are typically
reused across strata, and drop rows with a missing or non-positive
weight with a message.

## References

ICF. Guide to DHS Statistics: Analyzing DHS data.
<https://dhsprogram.com/data/Guide-to-DHS-Statistics/Analyzing_DHS_Data.htm>

## Examples

``` r
# A toy individual-recode extract with DHS variable names
set.seed(1)
ir <- data.frame(
  v021 = rep(1:20, each = 10),
  v023 = rep(1:4, each = 50),
  v005 = round(runif(200, 5e5, 2e6)),
  htn  = rbinom(200, 1, 0.2)
)
des <- dhs_design(ir)
survey_prevalence(des, "htn")
#>   indicator   n  estimate         se     lower     upper    deff
#> 1       htn 200 0.1850791 0.03221461 0.1261875 0.2631776 1.36926

# MICS and STEPS: same idea, weight column chosen for the file or step
names(ir) <- c("HH1", "stratum", "wmweight", "htn")
ir$wmweight <- ir$wmweight / 1e6
mics_design(ir, weight = "wmweight")
#> Stratified 1 - level Cluster Sampling design (with replacement)
#> With (20) clusters.
#> survey::svydesign(ids = stats::as.formula(paste0("~`", psu, "`")), 
#>     strata = if (is.null(strata)) NULL else stats::as.formula(paste0("~`", 
#>         strata, "`")), weights = ~.surveyncd_weight, data = data, 
#>     nest = TRUE, ...)
```
