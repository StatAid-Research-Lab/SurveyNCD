# The 18 conditions of the Functional Comorbidity Index

Returns the standard condition list for the Functional Comorbidity
Index.

## Usage

``` r
fci_items()
```

## Value

A character vector of the 18 FCI condition descriptions.

## References

Groll, D. L., To, T., Bombardier, C., & Wright, J. G. (2005). The
development of a comorbidity index with physical function as the
outcome. *Journal of Clinical Epidemiology*, 58(6), 595-602.
[doi:10.1016/j.jclinepi.2004.10.018](https://doi.org/10.1016/j.jclinepi.2004.10.018)

## Examples

``` r
fci_items()
#>  [1] "Arthritis (rheumatoid and osteoarthritis)"                       
#>  [2] "Osteoporosis"                                                    
#>  [3] "Asthma"                                                          
#>  [4] "Chronic obstructive pulmonary disease (COPD), ARDS, or emphysema"
#>  [5] "Angina"                                                          
#>  [6] "Congestive heart failure (or heart disease)"                     
#>  [7] "Heart attack (myocardial infarction)"                            
#>  [8] "Neurological disease (e.g. Parkinson's, multiple sclerosis)"     
#>  [9] "Stroke or transient ischemic attack (TIA)"                       
#> [10] "Peripheral vascular disease"                                     
#> [11] "Diabetes, type I or type II"                                     
#> [12] "Upper gastrointestinal disease (ulcer, hernia, reflux)"          
#> [13] "Depression"                                                      
#> [14] "Anxiety or panic disorders"                                      
#> [15] "Visual impairment (e.g. cataracts, glaucoma)"                    
#> [16] "Hearing impairment"                                              
#> [17] "Degenerative disc disease"                                       
#> [18] "Obesity"                                                         
length(fci_items())  # 18
#> [1] 18
```
