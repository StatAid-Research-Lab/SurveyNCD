# Worked analysis of the simulated survey using every exported SurveyNCD function.
# Run from the package root:  Rscript analysis/01_worked_example.R
source("analysis/00_helpers.R")
source("data-raw/simulate_survey.R")
set.seed(2026)
truth <- population_truth(simulate_population(seed = 20261010))
truth_key <- c(htn = "hypertension", dm = "diabetes", arth = "arthritis", asthma = "asthma",
               angina = "angina", stroke = "stroke", dep = "depression")

# ---------------------------------------------------------------- 1. clean
d <- ncd_survey
items <- c(htn = "htn_raw", dm = "dm_raw", arth = "arth_raw",
           asthma = "asthma_raw", angina = "angina_raw", stroke = "stroke_raw")
for (k in names(items)) {
  d[[k]] <- suppressWarnings(recode_binary(d[[items[[k]]]], yes = 1, no = 2))
}
d$dep <- suppressWarnings(recode_binary(d$dep_raw, yes = "Yes", no = "No"))
conds <- c(names(items), "dep")
labels <- c(htn = "Hypertension", dm = "Diabetes", arth = "Arthritis",
            asthma = "Asthma", angina = "Angina / heart disease",
            stroke = "Stroke", dep = "Depression")

# FCI reference list: which FCI conditions are covered by the survey items
fci <- fci_items()
covered <- c(1, 3, 5, 9, 11, 13)          # arthritis, asthma, angina, stroke, diabetes, depression
tab_fci <- data.frame(
  `FCI item` = fci,
  `In simulated survey` = ifelse(seq_along(fci) %in% covered, "Yes", "No"),
  check.names = FALSE
)
save_tab(tab_fci, "tab_fci_coverage",
         "The 18 Functional Comorbidity Index conditions returned by fci\\_items() and those collected in the simulated survey (hypertension is collected but is not an FCI item).")

# ---------------------------------------------------------------- 2. score
scored <- multimorbidity_index(d, conditions = conds, na_action = "na")
n_missing <- sum(is.na(scored$mm_n_conditions))

des <- svydesign(ids = ~psu, strata = ~stratum, weights = ~wt,
                 data = scored, nest = TRUE)

# ------------------------------------------- Table: condition prevalence
cond_rows <- lapply(conds, function(k) {
  f <- stats::as.formula(paste0("~", k))
  dd <- subset(des, !is.na(get(k)))
  p <- svyciprop(f, dd, method = "logit"); ci <- attr(p, "ci")
  nv <- mean(scored[[k]], na.rm = TRUE)
  data.frame(Condition = labels[[k]],
             `Don't know (n)` = sum(is.na(scored[[k]])),
             `Design-based % (95% CI)` = fmt_ci(as.numeric(p), ci[1], ci[2]),
             `Unweighted %` = pct(nv),
             `Population truth %` = pct(truth$condition_prevalence[[truth_key[[k]]]]),
             `Design effect` = round(deff(svymean(f, dd, na.rm = TRUE, deff = "replace"))[1], 2),
             check.names = FALSE)
})
tab_cond <- do.call(rbind, cond_rows); rownames(tab_cond) <- NULL
save_tab(tab_cond, "tab_condition_prevalence",
         "Self-reported prevalence of each condition in the simulated survey: design-based estimates (strata, clusters, weights; logit 95\\% CI), unweighted sample percentages, the true value in the simulated population, and the design effect.",
         align = "lrrrrr")

# ------------------------------------------- Table: multimorbidity by group
mp <- function(by = NULL) suppressMessages(
  mm_prevalence(scored, ids = "psu", strata = "stratum", weights = "wt", by = by))
overall <- mp()
groups <- list(Sex = "sex", Residence = "residence", `Wealth quintile` = "wealth_quintile",
               Region = "region")
rows <- list(data.frame(Characteristic = "All adults", Group = "", overall))
for (g in names(groups)) {
  r <- mp(groups[[g]])
  lev <- as.character(r[[groups[[g]]]])
  if (g == "Wealth quintile") lev <- c("Q1 (poorest)", "Q2", "Q3", "Q4", "Q5 (richest)")
  rows[[g]] <- data.frame(Characteristic = g, Group = lev, r[, -1])
}
mm <- do.call(rbind, rows); rownames(mm) <- NULL
tab_mm <- data.frame(
  Characteristic = ifelse(duplicated(mm$Characteristic), "", mm$Characteristic),
  Group = mm$Group, n = mm$n,
  `Multimorbidity % (95% CI)` = fmt_ci(mm$prevalence, mm$prevalence_lower, mm$prevalence_upper),
  `Mean conditions (SE)` = sprintf("%.2f (%.3f)", mm$mean_conditions, mm$mean_conditions_se),
  check.names = FALSE)
save_tab(tab_mm, "tab_multimorbidity",
         sprintf("Design-based prevalence of multimorbidity (two or more of seven self-reported conditions) and mean number of conditions, from mm\\_prevalence(). %d of %d respondents with any `don't know' answer were excluded. True population values: multimorbidity %s\\%%, mean %.2f conditions.", n_missing, nrow(scored), pct(truth$multimorbidity), truth$mean_conditions),
         align = "llrrr")
utils::write.csv(mm, file.path(out_dir, "tables", "mm_prevalence_raw.csv"), row.names = FALSE)

# Figure: multimorbidity by wealth quintile and residence (two-way via subsets)
by_res <- do.call(rbind, lapply(c("Urban", "Rural"), function(r) {
  x <- suppressMessages(mm_prevalence(scored[scored$residence == r, ], ids = "psu",
                                      strata = "stratum", weights = "wt", by = "wealth_quintile"))
  cbind(residence = r, x)
}))
by_all <- cbind(residence = "All", mp("wealth_quintile"))
fig_df <- rbind(by_all, by_res)
fig_df$residence <- factor(fig_df$residence, c("All", "Urban", "Rural"))
p1 <- ggplot(fig_df, aes(factor(wealth_quintile), prevalence, colour = residence)) +
  geom_pointrange(aes(ymin = prevalence_lower, ymax = prevalence_upper),
                  position = position_dodge(width = 0.55), size = 0.35, linewidth = 0.6) +
  scale_colour_manual(values = unname(pal)) +
  scale_y_continuous(labels = function(x) paste0(100 * x, "%"), limits = c(0, NA)) +
  scale_x_discrete(labels = c("Q1\npoorest", "Q2", "Q3", "Q4", "Q5\nrichest")) +
  labs(x = "Wealth quintile", y = "Multimorbidity prevalence",
       caption = "Points: design-based estimates; bars: logit 95% CIs (simulated data). Urban/rural estimates use subsets of the data.") +
  theme_paper()
save_fig(p1, "fig_mm_by_wealth")

# ------------------------------------------- Children: anthropometry
ch <- child_anthro
ch$stunt <- who_anthro_score(ch$hw70, "stunting")
ch$under <- who_anthro_score(ch$hw71, "underweight")
ch$waste <- who_anthro_score(ch$hw72, "wasting")
flag_codes <- function(x) sum(x %in% c(9996, 9997, 9998, 9999, 999))
implaus <- function(x, lo, hi) sum(!x %in% c(9996, 9997, 9998, 9999, 999) & (x / 100 < lo | x / 100 > hi))
cdes <- svydesign(ids = ~psu, strata = ~stratum, weights = ~wt, data = ch, nest = TRUE)
anthro_row <- function(var, raw, ind, lo, hi) {
  cat_tab <- svymean(stats::as.formula(paste0("~", var)), subset(cdes, !is.na(ch[[var]])), na.rm = TRUE)
  est <- as.numeric(cat_tab); se <- as.numeric(SE(cat_tab))
  any_lvl <- est[1] + est[2]
  ind01 <- as.numeric(ch[[var]] %in% levels(ch[[var]])[1:2]); ind01[is.na(ch[[var]])] <- NA
  cdes2 <- update(cdes, z = ind01)
  p <- svyciprop(~z, subset(cdes2, !is.na(z)), method = "logit"); ci <- attr(p, "ci")
  data.frame(Indicator = ind,
             `DHS flag codes (n)` = flag_codes(raw),
             `Implausible removed (n)` = implaus(raw, lo, hi),
             `Analysed (n)` = sum(!is.na(ch[[var]])),
             `Severe %` = pct(est[1]), `Moderate %` = pct(est[2]),
             `Moderate or severe % (95% CI)` = fmt_ci(as.numeric(p), ci[1], ci[2]),
             check.names = FALSE)
}
tab_anthro <- rbind(
  anthro_row("stunt", ch$hw70, "Stunting (HAZ < -2)", -6, 6),
  anthro_row("under", ch$hw71, "Underweight (WAZ < -2)", -6, 5),
  anthro_row("waste", ch$hw72, "Wasting (WHZ < -2)", -5, 5))
save_tab(tab_anthro, "tab_anthropometry",
         "Child undernutrition from DHS-coded z-scores using who\\_anthro\\_score(): flag codes and biologically implausible values set to missing, then design-based prevalence.",
         align = "lrrrrrr")

# ------------------------------------------- Concentration indices
scored$multimorbid <- as.numeric(scored$mm_category == "Multimorbid")
des <- svydesign(ids = ~psu, strata = ~stratum, weights = ~wt, data = scored, nest = TRUE)
ch$stunted <- as.numeric(ch$stunt %in% levels(ch$stunt)[1:2]); ch$stunted[is.na(ch$stunt)] <- NA
ch$underweight <- as.numeric(ch$under %in% levels(ch$under)[1:2]); ch$underweight[is.na(ch$under)] <- NA
ch$wasted <- as.numeric(ch$waste %in% levels(ch$waste)[1:2]); ch$wasted[is.na(ch$waste)] <- NA
cdes <- svydesign(ids = ~psu, strata = ~stratum, weights = ~wt, data = ch, nest = TRUE)

ci_of <- function(design, var) {
  r <- eval(substitute(survey_concentration_index(design, outcome = V, wealth = wealth_score),
                       list(V = as.name(var))))
  r
}
ci_specs <- c(setNames(conds, unname(labels[conds])),
              `Number of conditions` = "mm_n_conditions", `Multimorbidity` = "multimorbid")
ci_rows <- lapply(names(ci_specs), function(nm) cbind(Outcome = nm, Group = "Adults", ci_of(des, ci_specs[[nm]])))
ci_rows <- c(ci_rows, lapply(c(Stunting = "stunted", Underweight = "underweight", Wasting = "wasted"),
                             function(v) NULL))
child_specs <- c(Stunting = "stunted", Underweight = "underweight", Wasting = "wasted")
ci_rows <- c(Filter(Negate(is.null), ci_rows),
             lapply(names(child_specs), function(nm) cbind(Outcome = nm, Group = "Children", ci_of(cdes, child_specs[[nm]]))))
ci_all <- do.call(rbind, ci_rows)
utils::write.csv(ci_all, file.path(out_dir, "tables", "concentration_indices_raw.csv"), row.names = FALSE)
tab_ci <- data.frame(
  Outcome = ci_all$Outcome, Population = ci_all$Group,
  `CI (95% CI)` = sprintf("%s (%s, %s)", f3(ci_all$Concentration_Index), f3(ci_all$Lower_CI), f3(ci_all$Upper_CI)),
  SE = f3(ci_all$Standard_Error),
  p = ifelse(ci_all$p_value < 0.001, "<0.001", sprintf("%.3f", ci_all$p_value)),
  n = ci_all$n, check.names = FALSE)
save_tab(tab_ci, "tab_concentration_indices",
         "Wealth-related concentration indices from survey\\_concentration\\_index() (ranking: continuous wealth score). Negative values: concentrated among poorer people; positive: among richer people. Design-based SEs account for strata and clusters.",
         align = "llrrrr")

ci_all$Outcome <- factor(ci_all$Outcome, rev(ci_all$Outcome))
ci_all$dir <- ifelse(ci_all$Upper_CI < 0, "Pro-poor (concentrated among poorer)",
                     ifelse(ci_all$Lower_CI > 0, "Pro-rich (concentrated among richer)", "CI includes zero"))
p2 <- ggplot(ci_all, aes(Concentration_Index, Outcome, colour = dir)) +
  geom_vline(xintercept = 0, colour = ink[["secondary"]], linewidth = 0.4) +
  geom_pointrange(aes(xmin = Lower_CI, xmax = Upper_CI), size = 0.3, linewidth = 0.6) +
  facet_grid(Group ~ ., scales = "free_y", space = "free_y") +
  scale_colour_manual(values = c("Pro-poor (concentrated among poorer)" = pal[["orange"]],
                                 "Pro-rich (concentrated among richer)" = pal[["blue"]],
                                 "CI includes zero" = ink[["secondary"]])) +
  labs(x = "Concentration index (design-based 95% CI)", y = NULL,
       caption = "Ranking variable: continuous household wealth score. Simulated data.") +
  guides(colour = guide_legend(nrow = 2)) +
  theme_paper()
save_fig(p2, "fig_concentration_indices", height = 4.6)

# ------------------------------------------- Map of regional multimorbidity
reg <- mp("region")
if (requireNamespace("sf", quietly = TRUE)) {
  grid <- sf::st_make_grid(sf::st_as_sfc(sf::st_bbox(c(xmin = 0, ymin = 0, xmax = 3, ymax = 2))),
                           n = c(3, 2))
  regions_sf <- sf::st_sf(region = paste("Region", LETTERS[c(4, 5, 6, 1, 2, 3)]), geometry = grid)
  lab_df <- merge(regions_sf, reg, by = "region")
  lab_df$txt_col <- ifelse(lab_df$prevalence > 0.08, ink[["primary"]], "white")
  p3 <- suppressMessages(
    survey_map_indicator(reg, regions_sf, join_by = "region", fill_var = "prevalence",
                         palette = "cividis", legend_title = "Multimorbidity prevalence",
                         border_color = "white", border_width = 0.8) +
      ggplot2::scale_fill_viridis_c(option = "cividis", limits = c(0, 0.15),
                                    labels = function(x) paste0(100 * x, "%"),
                                    guide = ggplot2::guide_colorbar(title.position = "top",
                                      title.hjust = 0.5, barwidth = grid::unit(15, "lines"),
                                      barheight = grid::unit(0.5, "lines")),
                                    name = "Multimorbidity prevalence") +
      ggplot2::geom_sf_text(data = lab_df,
                            ggplot2::aes(label = sprintf("%s\n%s%%\n(%s-%s%%)", region, pct(prevalence),
                                                         pct(prevalence_lower, 0), pct(prevalence_upper, 0))),
                            colour = lab_df$txt_col, size = 3, fontface = "bold") +
      ggplot2::labs(caption = NULL)
  )
  save_fig(p3, "fig_region_map", width = 5.5, height = 4.2)
}

# ------------------------------------------- Exploratory ML: xgboost + SHAP
if (requireNamespace("xgboost", quietly = TRUE)) {
  scored$female <- as.numeric(scored$sex == "Female")
  scored$urban  <- as.numeric(scored$residence == "Urban")
  des_ml <- svydesign(ids = ~psu, strata = ~stratum, weights = ~wt, data = scored, nest = TRUE)
  fit <- survey_xgboost(des_ml, mm_n_conditions ~ age + bmi + wealth_score + female + urban,
                        params = list(objective = "reg:squarederror", max_depth = 3,
                                      eta = 0.05, nthread = 1),
                        nrounds = 300)
  shap <- survey_shap(fit)
  imp <- sort(colMeans(abs(shap[, colnames(shap) != "BIAS" & colnames(shap) != "(Intercept)", drop = FALSE])),
              decreasing = TRUE)
  tab_shap <- data.frame(Feature = names(imp), `Mean |SHAP|` = round(unname(imp), 4), check.names = FALSE)
  save_tab(tab_shap, "tab_shap_importance",
           sprintf("Exploratory survey-weighted gradient boosting (survey\\_xgboost(), n = %d): mean absolute SHAP value per feature for the number of conditions. Case weights only; no design-based uncertainty.", fit$n_obs),
           digits = 4, align = "lr")
  p4 <- plot_shap_summary(shap, fit$X, title = NULL, subtitle = NULL) + theme(legend.position = "right")
  save_fig(p4, "fig_shap_summary", height = 3.6)
}

# ------------------------------------------- Dataset description
desc <- data.frame(
  Item = c("Adults (households)", "Children under 5", "Strata", "Primary sampling units",
           "Weight range (normalised)", "Adults with any 'don't know' answer"),
  Value = c(nrow(ncd_survey), nrow(child_anthro), length(unique(ncd_survey$stratum)),
            length(unique(ncd_survey$psu)),
            sprintf("%.2f to %.2f", min(ncd_survey$wt), max(ncd_survey$wt)),
            sprintf("%d (%s%%)", n_missing, pct(n_missing / nrow(scored)))))
save_tab(desc, "tab_dataset", "The simulated example datasets shipped with SurveyNCD.", align = "lr")

writeLines(capture.output(sessionInfo()), file.path(out_dir, "sessionInfo_worked_example.txt"))
message("Worked example done.")
