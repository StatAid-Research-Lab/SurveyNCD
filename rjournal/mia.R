# Reproduces every result, table and figure in
# "SurveyNCD: Design-Based Multimorbidity, Health-Inequality and Child-Growth
#  Indicators from Complex Population Surveys" (Mia, The R Journal, submitted).
#
# Run from the top level of the submission folder (the folder that contains
# analysis/ and data-raw/):     Rscript mia.R
# Requires SurveyNCD >= 0.2.0 from CRAN, plus survey, ggplot2, knitr, sf,
# xgboost and rineq. Runtime: about 6 minutes on one core; the 1,000-sample
# simulation is cached in analysis/output/simulation_results_1000.rds
# (delete that file to recompute it from scratch).

stopifnot(utils::packageVersion("SurveyNCD") >= "0.2.0")

## ---- Code shown in the article (Section "A worked analysis") -------------
library("SurveyNCD")
library("survey")
options(survey.lonely.psu = "adjust")

d <- ncd_survey
d$htn <- recode_binary(d$htn_raw, yes = 1, no = 2)
d$dep <- recode_binary(d$dep_raw, yes = "Yes", no = "No")
table(raw = d$dep_raw, clean = d$dep, useNA = "ifany")

for (v in c("dm", "arth", "asthma", "angina", "stroke"))
  d[[v]] <- recode_binary(d[[paste0(v, "_raw")]], yes = 1, no = 2)
conds <- c("htn", "dm", "arth", "asthma", "angina", "stroke", "dep")
scored <- multimorbidity_index(d, conditions = conds, na_action = "na")
table(scored$mm_category, useNA = "ifany")

mm_prevalence(scored, ids = "psu", strata = "stratum", weights = "wt")

des <- svydesign(ids = ~psu, strata = ~stratum, weights = ~wt,
                 data = scored, nest = TRUE)
survey_concentration_index(des, outcome = dm, wealth = wealth_score)

ch <- child_anthro
ch$stunting <- who_anthro_score(ch$hw70, indicator = "stunting")
table(ch$stunting, useNA = "ifany")

## ---- All tables and figures ------------------------------------------------
source("analysis/run_all.R")
