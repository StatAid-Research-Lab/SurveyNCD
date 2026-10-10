# Creates data/ncd_survey.rda and data/child_anthro.rda.
# Run from the package root:  Rscript data-raw/make_datasets.R
source("data-raw/simulate_survey.R")
pop  <- simulate_population(seed = 20261010)
hh_s <- draw_sample(pop, ea_per_stratum = 10, hh_per_ea = 20, seed = 1)
out  <- make_public_datasets(pop, hh_s, seed = 2)
ncd_survey   <- out$ncd_survey
child_anthro <- out$child_anthro
save(ncd_survey,   file = "data/ncd_survey.rda",   compress = "xz")
save(child_anthro, file = "data/child_anthro.rda", compress = "xz")
message("ncd_survey: ", nrow(ncd_survey), " rows; child_anthro: ",
        nrow(child_anthro), " rows")
