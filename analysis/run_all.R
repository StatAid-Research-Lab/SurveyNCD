# Reproduce every table and figure in the SurveyNCD papers.
# From the package source root:   Rscript analysis/run_all.R
# Requirements: SurveyNCD (>= 0.2.0), survey, ggplot2, knitr, sf, xgboost, rineq
# Runtime: about 6 minutes on one core (the simulation study is cached in
# analysis/output/simulation_results_1000.rds; delete it to recompute).
t0 <- Sys.time()
source("analysis/01_worked_example.R")
source("analysis/02_validation.R")
source("analysis/03_simulation_study.R")
source("analysis/04_export_to_rjournal.R")
message(sprintf("All analyses finished in %.1f minutes.",
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))
