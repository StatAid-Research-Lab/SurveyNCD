# Monte Carlo study: repeated samples from the known simulated population.
# Run from the package root:  Rscript analysis/03_simulation_study.R [reps]
# Default 1000 replicates (about 5 minutes on one core); results cached.
source("analysis/00_helpers.R")
source("data-raw/simulate_survey.R")

args <- commandArgs(trailingOnly = TRUE)
REPS <- if (length(args)) as.integer(args[1]) else 1000L
cache <- file.path(out_dir, sprintf("simulation_results_%d.rds", REPS))

pop   <- simulate_population(seed = 20261010)
truth <- population_truth(pop)
# true stunting concentration index (children, ranked by household wealth)
ch <- pop$children; o <- order(ch$wealth_score); y <- as.numeric(ch$haz[o] < -2)
N <- length(y); R <- (seq_len(N) - 0.5) / N
truth$ci_stunting <- 2 / mean(y) * mean((y - mean(y)) * (R - mean(R)))

one_rep <- function(i) {
  hh <- draw_sample(pop, seed = 10000 + i)
  dd <- make_public_datasets(pop, hh, seed = 20000 + i)
  a <- dd$ncd_survey; k <- dd$child_anthro
  for (v in c("htn_raw", "dm_raw", "arth_raw", "asthma_raw", "angina_raw", "stroke_raw"))
    a[[sub("_raw", "", v)]] <- suppressWarnings(recode_binary(a[[v]], yes = 1, no = 2))
  a$dep <- suppressWarnings(recode_binary(a$dep_raw, yes = "Yes", no = "No"))
  sc <- multimorbidity_index(a, c("htn", "dm", "arth", "asthma", "angina", "stroke", "dep"), na_action = "na")
  sc <- sc[!is.na(sc$mm_n_conditions), ]; sc$one <- 1
  st <- who_anthro_score(k$hw70, "stunting")
  k$stunted <- as.numeric(st %in% levels(st)[1:2]); k <- k[!is.na(st), ]; k$one <- 1

  mk <- function(dat, m) switch(m,
    design       = svydesign(ids = ~psu, strata = ~stratum, weights = ~wt, data = dat, nest = TRUE),
    weights_only = svydesign(ids = ~1, weights = ~wt, data = dat),
    naive        = svydesign(ids = ~1, weights = ~one, data = dat))
  out <- list()
  for (m in c("design", "weights_only", "naive")) {
    p <- switch(m,
      design       = suppressMessages(mm_prevalence(sc, ids = "psu", strata = "stratum", weights = "wt")),
      weights_only = suppressMessages(mm_prevalence(sc, weights = "wt")),
      naive        = suppressMessages(mm_prevalence(sc, weights = "one")))
    cA <- survey_concentration_index(mk(sc, m), outcome = mm_n_conditions, wealth = wealth_score)
    kd <- mk(k, m)
    sp <- svyciprop(~stunted, kd, method = "logit"); spci <- attr(sp, "ci")
    cK <- survey_concentration_index(kd, outcome = stunted, wealth = wealth_score)
    out[[m]] <- data.frame(rep = i, method = m,
      estimand = c("Multimorbidity prevalence", "CI: number of conditions",
                   "Stunting prevalence", "CI: stunting"),
      est = c(p$prevalence, cA$Concentration_Index, as.numeric(sp), cK$Concentration_Index),
      se  = c(p$prevalence_se, cA$Standard_Error, as.numeric(SE(sp)), cK$Standard_Error),
      lo  = c(p$prevalence_lower, cA$Lower_CI, spci[1], cK$Lower_CI),
      hi  = c(p$prevalence_upper, cA$Upper_CI, spci[2], cK$Upper_CI))
  }
  do.call(rbind, out)
}

if (file.exists(cache)) {
  res <- readRDS(cache)
} else {
  t0 <- Sys.time()
  res <- do.call(rbind, lapply(seq_len(REPS), one_rep))
  attr(res, "runtime_min") <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
  saveRDS(res, cache)
}

tv <- c(`Multimorbidity prevalence` = truth$multimorbidity,
        `CI: number of conditions`  = truth$ci_conditions,
        `Stunting prevalence`       = truth$stunting,
        `CI: stunting`              = truth$ci_stunting)
res$truth <- tv[res$estimand]
res$cover <- res$lo <= res$truth & res$hi >= res$truth
agg <- do.call(rbind, lapply(split(res, list(res$estimand, res$method), drop = TRUE), function(z)
  data.frame(estimand = z$estimand[1], method = z$method[1], truth = z$truth[1],
             mean_est = mean(z$est), rel_bias = 100 * (mean(z$est) - z$truth[1]) / abs(z$truth[1]),
             emp_se = stats::sd(z$est), mean_se = mean(z$se),
             se_ratio = mean(z$se) / stats::sd(z$est),
             coverage = mean(z$cover), mc_se_cov = sqrt(mean(z$cover) * (1 - mean(z$cover)) / nrow(z)),
             reps = nrow(z))))
lab <- c(design = "Full design (SurveyNCD)", weights_only = "Weights only", naive = "Unweighted, iid")
agg$Method <- factor(lab[agg$method], lab)
agg$estimand <- factor(agg$estimand, names(tv))
agg <- agg[order(agg$estimand, agg$Method), ]
utils::write.csv(agg, file.path(out_dir, "tables", "simulation_summary_raw.csv"), row.names = FALSE)

tab_sim <- data.frame(
  Estimand = ifelse(duplicated(agg$estimand), "", as.character(agg$estimand)),
  Method = as.character(agg$Method),
  `True value` = ifelse(duplicated(agg$estimand), "", sprintf("%.4f", agg$truth)),
  `Mean estimate` = sprintf("%.4f", agg$mean_est),
  `Rel. bias %` = sprintf("%.1f", agg$rel_bias),
  `Empirical SE` = sprintf("%.4f", agg$emp_se),
  `Mean model SE` = sprintf("%.4f", agg$mean_se),
  `SE ratio` = sprintf("%.2f", agg$se_ratio),
  `Coverage %` = sprintf("%.1f", 100 * agg$coverage),
  check.names = FALSE)
save_tab(tab_sim, "tab_simulation",
         sprintf("Monte Carlo evaluation over %d independent samples drawn with the same stratified two-stage design from one simulated population (142,133 adults; 64,169 children). Coverage of nominal 95\\%% intervals (Monte Carlo SE about 0.7 points). SE ratio = mean estimated SE / empirical SE.", REPS),
         align = "llrrrrrrr")

p5 <- ggplot(agg, aes(100 * coverage, estimand, colour = Method)) +
  annotate("rect", xmin = 100 * (0.95 - 1.96 * sqrt(0.95 * 0.05 / REPS)),
           xmax = 100 * (0.95 + 1.96 * sqrt(0.95 * 0.05 / REPS)),
           ymin = -Inf, ymax = Inf, fill = ink[["grid"]], alpha = 0.8) +
  geom_vline(xintercept = 95, colour = ink[["secondary"]], linewidth = 0.4) +
  geom_point(aes(group = factor(Method, rev(levels(Method)))), position = position_dodge(width = 0.6), size = 2.6) +
  scale_colour_manual(values = unname(pal)) +
  scale_y_discrete(limits = rev(levels(agg$estimand))) +
  labs(x = "Coverage of nominal 95% confidence intervals (%)", y = NULL,
       caption = sprintf("%d simulated samples. Grey band: Monte Carlo range expected if coverage were exactly 95%%.", REPS)) +
  guides(colour = guide_legend(nrow = 1)) +
  theme_paper()
save_fig(p5, "fig_simulation_coverage", height = 3.4)
writeLines(sprintf("replicates=%d runtime_minutes=%.2f", REPS, attr(res, "runtime_min")),
           file.path(out_dir, "simulation_runtime.txt"))
message("Simulation study done.")
