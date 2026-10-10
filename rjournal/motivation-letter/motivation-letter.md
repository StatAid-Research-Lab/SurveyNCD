---
output: pdf_document
fontsize: 12pt
---

\thispagestyle{empty}
\today

Editor
The R Journal
\bigskip

Dear Editor,
\bigskip

Please consider the article "SurveyNCD: Design-Based Multimorbidity, Health-Inequality and Child-Growth Indicators from Complex Population Surveys" for publication in The R Journal as a contributed research article.

The article describes the CRAN package **SurveyNCD**. It turns the self-reported chronic-condition answers collected by WHO STEPS, Demographic and Health Surveys and Multiple Indicator Cluster Surveys into design-based estimates of multimorbidity prevalence, wealth-related concentration indices and child undernutrition. All variance estimation is delegated to the **survey** package.

We believe the article will interest R Journal readers for three reasons.

1. It addresses a gap between general survey software and comorbidity packages. Existing comorbidity packages work with ICD-coded clinical or claims data, while population surveys record self-reported answers under complex designs; the article explains the methods and design decisions needed to connect the two.
2. It is transparent about overlap with existing packages (**rineq**, **healthequal**, **anthro**) and positions the package as a workflow built on **survey** rather than a set of new estimators.
3. It is fully reproducible and validated. The package ships simulated datasets drawn from a known population, so results can be checked against the truth. The article validates the concentration index against **rineq** and a design bootstrap, documents a correction to the handling of tied ranks, and reports a 1,000-sample simulation of bias and confidence-interval coverage. All code runs in about six minutes.

The manuscript has not been published or submitted elsewhere. The package (version 0.2.0) is available on CRAN and is developed openly at https://github.com/StatAid-Research-Lab/SurveyNCD.

\bigskip
\bigskip

Regards,




Sujon Mia
StatAid Research Lab
Department of Statistics, Jagannath University
Dhaka, Bangladesh
sujonsgc@gmail.com
ORCID: 0009-0001-1032-2818
