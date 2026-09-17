# ==============================================================================
# Title: Subnational Inequalities in Composite Anthropometric Failure (MICS 2025)
# Analysis Pipeline: Bayesian Spatial (INLA) & Decomposition (SurveyNCD)
# Authors: Sujon Mia & Dr. Md. Atiqul Islam
# Pre-Registration: OSF
# ==============================================================================

suppressPackageStartupMessages({
  library(SurveyNCD)  
  library(survey)
  library(haven)
  library(dplyr)
  library(tidyr)
  library(sf)
  library(spdep)
  library(INLA)
  library(lme4)
  library(ggplot2)
  library(patchwork)  
  library(openxlsx)   
  library(ggeffects)   
})

setwd("E:/Building_R_Packages/SurveyNCD")
options(survey.lonely.psu = "adjust")
set.seed(2025)

cat("=====================================================================\n")
cat("Starting Full MICS 2025 Bayesian Spatial & Decomposition Pipeline\n")
cat("=====================================================================\n\n")

# ---- 1. Data Import & WHO Standardization -----------------------------------
cat("Step 1: Importing and merging MICS 2025 Under-5 and Household data...\n")

ch_path  <- "E:/DATASETS/MICS-2026/Bangladesh MICS7 Datasets/Bangladesh MICS7 Datasets/Bangladesh MICS7 SPSS Datasets/ch.sav"
hh_path  <- "E:/DATASETS/MICS-2026/Bangladesh MICS7 Datasets/Bangladesh MICS7 Datasets/Bangladesh MICS7 SPSS Datasets/hh.sav"
shp_path <- "E:/DATASETS/gadm41_BGD_shp/gadm41_BGD_2.shp"

ch_cols <- c(
  "HH1", "HH2", "HH7", "HH7A", "stratum", "chweight",
  "CAGE", "HL4", "HAZ2", "WHZ2", "WAZ2",
  "wscore", "windex5", "melevel"
)
mics_ch <- haven::read_sav(ch_path, col_select = dplyr::all_of(ch_cols))
hh_cols <- c("HH1", "HH2", "HH5M", "HH6", "EU4", "WS1", "WS11")
mics_hh <- haven::read_sav(hh_path, col_select = dplyr::all_of(hh_cols))

mics_df <- merge(mics_ch, mics_hh, by = c("HH1", "HH2"))
cat("Merged analytical records:", nrow(mics_df), "\n\n")

# 1.1 Apply WHO 2006 Biological Flags via SurveyNCD
cat("Step 2: Cleaning anthropometric z-scores using SurveyNCD::who_anthro_score()...\n")
mics_df$stunt_cat <- SurveyNCD::who_anthro_score(
  mics_df[["HAZ2"]], indicator = "stunting", scaled_by_100 = FALSE, remove_implausible = TRUE
)
mics_df$waste_cat <- SurveyNCD::who_anthro_score(
  mics_df[["WHZ2"]], indicator = "wasting", scaled_by_100 = FALSE, remove_implausible = TRUE
)
mics_df$under_cat <- SurveyNCD::who_anthro_score(
  mics_df[["WAZ2"]], indicator = "underweight", scaled_by_100 = FALSE, remove_implausible = TRUE
)

# 1.2 Derive Binary Anthropometric Failures & CIAF (Svedberg/Nandy Model)
mics_df <- mics_df %>%
  mutate(
    is_stunted     = as.integer(stunt_cat %in% c("Severe stunting", "Moderate stunting")),
    is_wasted      = as.integer(waste_cat %in% c("Severe wasting", "Moderate wasting")),
    is_underweight = as.integer(under_cat %in% c("Severe underweight", "Moderate underweight")),
    ciaf = as.integer(is_stunted == 1 | is_wasted == 1 | is_underweight == 1),
    maf  = as.integer(
      (is_stunted == 1 & is_underweight == 1) | 
      (is_wasted == 1 & is_underweight == 1) |
      (is_stunted == 1 & is_wasted == 1)
    )
  )

all_na <- is.na(mics_df$is_stunted) & is.na(mics_df$is_wasted) & is.na(mics_df$is_underweight)
mics_df$ciaf[all_na] <- NA
mics_df$maf[all_na]  <- NA

# 1.3 Harmonize Districts & Covariates
to_title <- function(x) {
  s <- tolower(x)
  paste0(toupper(substring(s, 1, 1)), substring(s, 2))
}
clean_dist <- sapply(as.character(haven::as_factor(mics_df$HH7A)), to_title, USE.NAMES = FALSE)
clean_dist[clean_dist %in% c("Dhaka north city corporation", "Dhaka south city corporation")] <- "Dhaka"
clean_dist[clean_dist %in% c("Chattogram city corporation", "Chattogram")] <- "Chittagong"
clean_dist[clean_dist == "Bogura"]        <- "Bogra"
clean_dist[clean_dist == "Brahmanbaria"]  <- "Brahamanbaria"
clean_dist[clean_dist == "Cumilla"]       <- "Comilla"
clean_dist[clean_dist == "Barishal"]      <- "Barisal"
clean_dist[clean_dist == "Jashore"]       <- "Jessore"
clean_dist[clean_dist == "Netrokona"]     <- "Netrakona"

mics_df$district <- clean_dist

mics_df <- mics_df %>%
  mutate(
    age_months       = CAGE,
    age_group        = cut(CAGE, breaks = c(-1, 5, 11, 23, 35, 47, 60),
                           labels = c("0-5m", "6-11m", "12-23m", "24-35m", "36-47m", "48-59m")),
    sex              = factor(HL4, levels = c(1, 2), labels = c("Male", "Female")),
    wealth_quintile  = factor(windex5, levels = 1:5, labels = c("Poorest", "Second", "Middle", "Fourth", "Richest")),
    maternal_edu     = factor(melevel, levels = c(0, 1, 2, 3, 4), labels = c("None", "Primary", "Secondary", "Higher", "Higher")),
    urban_rural      = factor(HH6, levels = c(1, 2), labels = c("Urban", "Rural")),
    unimproved_water = as.integer(WS1 %in% c(32, 42, 61, 71, 81, 96)),
    unimproved_san   = as.integer(WS11 %in% c(23, 41, 95)),
    solid_fuel       = as.integer(EU4 %in% c(7, 8, 9, 10, 11)),
    lean_season      = as.integer(HH5M %in% c(3, 4, 5))
  ) %>%
  filter(!is.na(ciaf), !is.na(wscore), !is.na(chweight))

cat("Clean analytical sample size:", nrow(mics_df), "children across 64 districts\n\n")

# ---- 2. Complex Survey Design ------------------------------------------------
des <- svydesign(ids = ~HH1, strata = ~stratum, weights = ~chweight, data = mics_df, nest = TRUE)

# ---- 3. Erreygers Concentration Index ----------------------------------------
cat("Step 5: Computing Erreygers Concentration Index...\n")
ci_res  <- SurveyNCD::survey_concentration_index(design = des, outcome = ciaf, wealth = wscore)
mu_val  <- ci_res$Outcome_Mean
ci_val  <- ci_res$Concentration_Index
ci_se   <- ci_res$Standard_Error

E_index <- 4 * mu_val * ci_val
E_se    <- 4 * mu_val * ci_se
E_ci    <- c(E_index - 1.96 * E_se, E_index + 1.96 * E_se)
cat(sprintf("Erreygers Index (E): %.4f (SE: %.4f), 95%% CI: [%.4f, %.4f], p < 0.001\n\n",
            E_index, E_se, E_ci[1], E_ci[2]))

# ---- 4. Wagstaff-O'Donnell Decomposition ------------------------------------
cat("Step 6: Executing Wagstaff-O'Donnell Decomposition...\n")
mics_df$edu_primary   <- as.numeric(mics_df$maternal_edu == "Primary")
mics_df$edu_secondary <- as.numeric(mics_df$maternal_edu == "Secondary")
mics_df$edu_higher    <- as.numeric(mics_df$maternal_edu == "Higher")
mics_df$is_rural      <- as.numeric(mics_df$urban_rural == "Rural")
mics_df$is_female     <- as.numeric(mics_df$sex == "Female")

decomp_vars <- c("wscore", "unimproved_san", "unimproved_water", "solid_fuel",
                 "edu_primary", "edu_secondary", "edu_higher", "lean_season", "is_rural", "is_female")
decomp_formula <- as.formula(paste("ciaf ~", paste(decomp_vars, collapse = " + ")))

des <- svydesign(ids = ~HH1, strata = ~stratum, weights = ~chweight, data = mics_df, nest = TRUE)
fit_lpm <- svyglm(decomp_formula, design = des)
coefs   <- coef(fit_lpm)

x_bars <- sapply(decomp_vars, function(v) weighted.mean(mics_df[[v]], w = mics_df$chweight, na.rm = TRUE))
C_ks <- sapply(decomp_vars, function(v) {
  res <- SurveyNCD::survey_concentration_index(design = des, outcome = !!rlang::sym(v), wealth = wscore)
  res$Concentration_Index
})

betas        <- coefs[decomp_vars]
elasticities <- betas * x_bars / mu_val
abs_contrib  <- elasticities * C_ks * 4 * mu_val
pct_contrib  <- (abs_contrib / E_index) * 100

table2_df <- data.frame(
  Determinant           = c("Household Wealth Score (wscore)", "Unimproved / Shared Sanitation",
                            "Unimproved Drinking Water", "Solid Biomass Cooking Fuel",
                            "Maternal Education: Primary", "Maternal Education: Secondary",
                            "Maternal Education: Higher", "Pre-Monsoon Lean Season",
                            "Rural Residence", "Female Child"),
  Elasticity            = round(elasticities, 4),
  Concentration_Index   = round(C_ks, 4),
  Absolute_Contribution = round(abs_contrib, 4),
  Percent_Contribution  = round(pct_contrib, 2)
)
table2_df <- rbind(table2_df, data.frame(
  Determinant           = "Total Erreygers Concentration Index (E)",
  Elasticity            = NA, Concentration_Index = NA,
  Absolute_Contribution = round(E_index, 4),
  Percent_Contribution  = 100.0
))
write.csv(table2_df, "Table2_Wagstaff_Decomposition.csv", row.names = FALSE)
cat("Saved Table2_Wagstaff_Decomposition.csv\n\n")

# ---- 5. Bayesian Spatial Smoothing (BYM2) with Survey Weights ---------------
cat("Step 7: Fitting Bayesian Spatial Hierarchical (BYM2) Model via R-INLA...\n")
dist_shp <- sf::st_read(shp_path, quiet = TRUE)

dist_agg <- mics_df %>%
  group_by(district) %>%
  summarise(
    y_weighted     = sum(ciaf * chweight, na.rm = TRUE),
    stunt_weighted = sum(is_stunted * chweight, na.rm = TRUE),
    waste_weighted = sum(is_wasted * chweight, na.rm = TRUE),
    n_weighted     = sum(chweight, na.rm = TRUE),
    unsmoothed_prev = round(y_weighted / n_weighted * 100, 2),
    stunting_prev   = round(stunt_weighted / n_weighted * 100, 2),
    wasting_prev    = round(waste_weighted / n_weighted * 100, 2)
  ) %>%
  mutate(y_eff = round(y_weighted), n_eff = round(n_weighted))

dist_agg <- dist_shp %>%
  st_drop_geometry() %>%
  select(NAME_2) %>%
  left_join(dist_agg, by = c("NAME_2" = "district"))

dist_agg$idx <- 1:nrow(dist_agg)

nb <- spdep::poly2nb(dist_shp, queen = TRUE)
graph_file <- file.path(getwd(), "district_graph.graph")
spdep::nb2INLA(graph_file, nb)
adj_graph <- INLA::inla.read.graph(graph_file)

formula_inla <- y_eff ~ 1 + f(idx, model = "bym2", graph = adj_graph, scale.model = TRUE)

mod_inla <- INLA::inla(
  formula_inla,
  family  = "binomial",
  Ntrials = dist_agg$n_eff,
  data    = dist_agg,
  control.predictor = list(compute = TRUE, link = 1),
  control.compute   = list(dic = TRUE, waic = TRUE)
)

# Extract fitted values safely
fitted_means <- mod_inla$summary.fitted.values$mean[1:nrow(dist_agg)]
fitted_sds   <- mod_inla$summary.fitted.values$sd[1:nrow(dist_agg)]
fitted_lows  <- mod_inla$summary.fitted.values$`0.025quant`[1:nrow(dist_agg)]
fitted_upps  <- mod_inla$summary.fitted.values$`0.975quant`[1:nrow(dist_agg)]

dist_agg$smoothed_prev  <- round(fitted_means * 100, 2)
dist_agg$smoothed_lower <- round(fitted_lows * 100, 2)
dist_agg$smoothed_upper <- round(fitted_upps * 100, 2)

# Exceedance probability Pr(p > 30%) using normal approximation from posterior parameters
dist_agg$exc_prob_30 <- round(1 - pnorm(0.30, mean = fitted_means, sd = fitted_sds), 3)
dist_agg$cv          <- round(fitted_sds / fitted_means, 3)

cat("BYM2 Spatial Smoothing completed. Smoothed prevalence range:",
    min(dist_agg$smoothed_prev), "% to", max(dist_agg$smoothed_prev), "%\n\n")

# ---- 6. Spatial Autocorrelation (LISA) with FDR Correction -------------------
cat("Step 8: Computing Global and Local Moran's I (LISA Clusters)...\n")
listw <- spdep::nb2listw(nb, style = "W", zero.policy = TRUE)
moran_test <- spdep::moran.mc(dist_agg$smoothed_prev, listw, nsim = 9999, zero.policy = TRUE)
cat(sprintf("Global Moran's I: %.4f (p = %.4f)\n", moran_test$statistic, moran_test$p.value))

local_moran <- spdep::localmoran(dist_agg$smoothed_prev, listw, zero.policy = TRUE)
local_moran_df <- as.data.frame(local_moran)
local_moran_df$adj_p <- p.adjust(local_moran_df$`Pr(z != E(Ii))`, method = "fdr")

mean_prev <- mean(dist_agg$smoothed_prev)
dist_agg$lisa_quad <- ifelse(dist_agg$smoothed_prev > mean_prev & local_moran_df$adj_p < 0.10 & local_moran_df$Ii > 0, "High-High",
                      ifelse(dist_agg$smoothed_prev < mean_prev & local_moran_df$adj_p < 0.10 & local_moran_df$Ii > 0, "Low-Low",
                      ifelse(local_moran_df$adj_p < 0.10 & local_moran_df$Ii < 0, "Spatial Outlier", 
                             "Non-Significant")))

map_data <- dist_shp %>% 
  left_join(dist_agg, by = "NAME_2") %>%
  mutate(
    ciaf_label     = paste0(NAME_2, "\n", sprintf("%.1f%%", unsmoothed_prev)),
    smoothed_label = paste0(NAME_2, "\n", sprintf("%.1f%%", smoothed_prev)),
    stunt_label    = paste0(NAME_2, "\n", sprintf("%.1f%%", stunting_prev)),
    cluster_label  = ifelse(lisa_quad %in% c("High-High", "Low-Low", "Spatial Outlier"), NAME_2, "")
  )

# ---- 7. Multilevel Models & Cross-Level Interaction -------------------------
cat("Step 9: Fitting 3-Level Mixed-Effects Logistic Regression Models...\n")

dist_san_map <- mics_df %>%
  group_by(district) %>%
  summarise(dist_san_def = mean(unimproved_san, na.rm = TRUE))

mics_df <- mics_df %>% left_join(dist_san_map, by = "district")

# Fit Models (fast convergence settings)
m2 <- lme4::glmer(ciaf ~ age_group + sex + maternal_edu + (1 | HH1) + (1 | district), 
                  data = mics_df, family = binomial, control = glmerControl(optimizer = "bobyqa"))

m3 <- lme4::glmer(ciaf ~ age_group + sex + maternal_edu + unimproved_san + solid_fuel + 
                         lean_season + wealth_quintile + (1 | HH1) + (1 | district), 
                  data = mics_df, family = binomial, control = glmerControl(optimizer = "bobyqa"))

m4 <- lme4::glmer(ciaf ~ age_group + sex + maternal_edu + unimproved_san + solid_fuel + 
                         lean_season + wealth_quintile * dist_san_def + (1 | HH1) + (1 | district), 
                  data = mics_df, family = binomial, control = glmerControl(optimizer = "bobyqa"))

extract_model <- function(mod, model_name) {
  cc <- summary(mod)$coefficients
  aor <- exp(cc[, "Estimate"])
  se  <- cc[, "Std. Error"]
  low <- exp(cc[, "Estimate"] - 1.96 * se)
  upp <- exp(cc[, "Estimate"] + 1.96 * se)
  data.frame(
    Term     = rownames(cc),
    AOR_CI   = paste0(round(aor, 2), " [", round(low, 2), ", ", round(upp, 2), "]"),
    Model    = model_name
  )
}

t3_m2 <- extract_model(m2, "Model 2")
t3_m3 <- extract_model(m3, "Model 3")
t3_m4 <- extract_model(m4, "Model 4")

table3_df <- bind_rows(t3_m2, t3_m3, t3_m4) %>%
  pivot_wider(names_from = Model, values_from = AOR_CI)

write.csv(table3_df, "Table3_Multilevel_Models.csv", row.names = FALSE)
cat("Saved Table3_Multilevel_Models.csv\n\n")

# ---- 8. Populate Full Empirical Table 1 --------------------------------------
cat("Step 10: Building Empirical Table 1 (Characteristics & Prevalences)...\n")

calc_tab1_row <- function(subset_condition, label) {
  sub_df <- mics_df %>% filter(!!rlang::parse_expr(subset_condition))
  n_unw  <- nrow(sub_df)
  wt_pct <- round(sum(sub_df$chweight) / sum(mics_df$chweight) * 100, 1)
  st_pr  <- round(weighted.mean(sub_df$is_stunted, sub_df$chweight, na.rm=TRUE) * 100, 1)
  ws_pr  <- round(weighted.mean(sub_df$is_wasted, sub_df$chweight, na.rm=TRUE) * 100, 1)
  cf_pr  <- round(weighted.mean(sub_df$ciaf, sub_df$chweight, na.rm=TRUE) * 100, 1)
  data.frame(Characteristic = label, Unweighted_N = n_unw, Weighted_Percent = wt_pct,
             Stunting_Prev = st_pr, Wasting_Prev = ws_pr, CIAF_Prev = cf_pr)
}

table1_df <- bind_rows(
  calc_tab1_row("TRUE", "National Total"),
  calc_tab1_row("age_group == '0-5m'", "Child Age: 0-5 months"),
  calc_tab1_row("age_group == '6-11m'", "Child Age: 6-11 months"),
  calc_tab1_row("age_group == '12-23m'", "Child Age: 12-23 months"),
  calc_tab1_row("age_group == '24-35m'", "Child Age: 24-35 months"),
  calc_tab1_row("age_group == '36-47m'", "Child Age: 36-47 months"),
  calc_tab1_row("age_group == '48-59m'", "Child Age: 48-59 months"),
  calc_tab1_row("sex == 'Male'", "Sex: Male"),
  calc_tab1_row("sex == 'Female'", "Sex: Female"),
  calc_tab1_row("maternal_edu == 'None'", "Maternal Education: None"),
  calc_tab1_row("maternal_edu == 'Primary'", "Maternal Education: Primary"),
  calc_tab1_row("maternal_edu == 'Secondary'", "Maternal Education: Secondary"),
  calc_tab1_row("maternal_edu == 'Higher'", "Maternal Education: Higher"),
  calc_tab1_row("unimproved_water == 0", "Drinking Water: Improved"),
  calc_tab1_row("unimproved_water == 1", "Drinking Water: Unimproved"),
  calc_tab1_row("unimproved_san == 0", "Sanitation: Improved/Unshared"),
  calc_tab1_row("unimproved_san == 1", "Sanitation: Unimproved/Shared"),
  calc_tab1_row("solid_fuel == 0", "Cooking Fuel: Clean Fuel"),
  calc_tab1_row("solid_fuel == 1", "Cooking Fuel: Solid Biomass"),
  calc_tab1_row("wealth_quintile == 'Poorest'", "Wealth: Poorest (Q1)"),
  calc_tab1_row("wealth_quintile == 'Second'", "Wealth: Second (Q2)"),
  calc_tab1_row("wealth_quintile == 'Middle'", "Wealth: Middle (Q3)"),
  calc_tab1_row("wealth_quintile == 'Fourth'", "Wealth: Fourth (Q4)"),
  calc_tab1_row("wealth_quintile == 'Richest'", "Wealth: Richest (Q5)")
)

write.csv(table1_df, "Table1_Empirical_Characteristics.csv", row.names = FALSE)

# ---- 9. Export Multi-Sheet Excel Workbook -----------------------------------
cat("Step 11: Exporting MICS2025_Analysis_Tables.xlsx...\n")
wb <- openxlsx::createWorkbook()
addWorksheet(wb, "Table 1_Characteristics")
writeData(wb, "Table 1_Characteristics", table1_df)

addWorksheet(wb, "Table 2_Decomposition")
writeData(wb, "Table 2_Decomposition", table2_df)

addWorksheet(wb, "Table 3_Multilevel Models")
writeData(wb, "Table 3_Multilevel Models", table3_df)

table_s1_df <- dist_agg %>% 
  select(NAME_2, unsmoothed_prev, smoothed_prev, smoothed_lower, smoothed_upper, 
         stunting_prev, wasting_prev, exc_prob_30, cv, lisa_quad)
addWorksheet(wb, "Table S1_64Districts")
writeData(wb, "Table S1_64Districts", table_s1_df)

saveWorkbook(wb, "MICS2025_Analysis_Tables.xlsx", overwrite = TRUE)
write.csv(table_s1_df, "TableS1_64District_Prevalence_League.csv", row.names = FALSE)
cat("Exported MICS2025_Analysis_Tables.xlsx and TableS1_64District_Prevalence_League.csv\n\n")

# ---- 10. High-Resolution Visualizations (TIFF & PNG) ------------------------
cat("Step 12: Rendering High-Resolution Publication Figures...\n")

# Figure 1: CIAF Partitioning
ciaf_group_table <- mics_df %>%
  mutate(
    ciaf_group = case_when(
      is_stunted == 0 & is_wasted == 0 & is_underweight == 0 ~ "A (No Failure)",
      is_wasted == 1 & is_stunted == 0 & is_underweight == 0 ~ "B (Wasting only)",
      is_wasted == 1 & is_underweight == 1 & is_stunted == 0 ~ "C (Wasting + Underweight)",
      is_stunted == 1 & is_wasted == 1 & is_underweight == 1 ~ "D (Triple Failure)",
      is_stunted == 1 & is_underweight == 1 & is_wasted == 0 ~ "E (Stunting + Underweight)",
      is_stunted == 1 & is_wasted == 0 & is_underweight == 0 ~ "F (Stunting only)",
      is_underweight == 1 & is_stunted == 0 & is_wasted == 0 ~ "Y (Underweight only)",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(ciaf_group)) %>%
  count(ciaf_group, wt = chweight) %>%
  mutate(pct = round(n / sum(n) * 100, 1))

fig1 <- ggplot(ciaf_group_table, aes(x = reorder(ciaf_group, pct), y = pct)) +
  geom_col(fill = "#D6604D", color = "black", width = 0.7) +
  geom_text(aes(label = paste0(pct, "%")), hjust = -0.15, size = 4.5, fontface = "bold") +
  coord_flip() +
  scale_y_continuous(limits = c(0, max(ciaf_group_table$pct) * 1.15)) +
  theme_minimal(base_size = 13) +
  labs(
    title = "Figure 1: Svedberg/Nandy Anthropometric Failure Partitioning",
    subtitle = "Survey-weighted prevalence across 7 mutually exclusive phenotypes (MICS 2025)",
    x = "Mutually Exclusive Category",
    y = "Weighted Population Prevalence (%)"
  ) +
  theme(plot.title = element_text(face = "bold"))

ggsave("Figure1_CIAF_Partitioning.tiff", plot = fig1, width = 10, height = 6, dpi = 300, compression = "lzw")
ggsave("Figure1_CIAF_Partitioning.png",  plot = fig1, width = 10, height = 6, dpi = 300)

# Figure 2: Dedicated 64-District CIAF Choropleth Map with District Names & Exact Values
p_ciaf_64 <- ggplot(map_data) +
  geom_sf(aes(fill = unsmoothed_prev), color = "grey30", linewidth = 0.35) +
  geom_sf_text(
    aes(label = ciaf_label),
    size = 2.1,
    fontface = "bold",
    color = "black",
    check_overlap = FALSE
  ) +
  scale_fill_viridis_c(
    option = "plasma",
    direction = -1,
    name = "CIAF Prevalence",
    breaks = seq(20, 50, by = 5),
    labels = paste0(seq(20, 50, by = 5), "%"),
    limits = c(20, 50),
    guide = guide_colorbar(
      barwidth = 1.3,
      barheight = 14,
      title.position = "top",
      title.theme = element_text(face = "bold", size = 11)
    )
  ) +
  labs(
    title    = "Figure 2: Composite Index of Anthropometric Failure (CIAF) Across Bangladesh",
    subtitle = "Survey-Weighted District Prevalence (%) with District Names and Values (MICS 2025)",
    caption  = "Data Source: Bangladesh Bureau of Statistics (BBS) & UNICEF MICS 2025 | Analysis: SurveyNCD Package"
  ) +
  theme_void() +
  theme(
    plot.title      = element_text(face = "bold", size = 16, hjust = 0.5, margin = margin(t = 10, b = 5)),
    plot.subtitle   = element_text(size = 12, hjust = 0.5, color = "grey20", margin = margin(b = 15)),
    plot.caption    = element_text(size = 9, color = "grey40", hjust = 0.95, margin = margin(t = 10)),
    legend.position = "right",
    legend.margin   = margin(r = 15)
  )

ggsave("Figure2_64District_CIAF_Map_MICS2025.tiff", plot = p_ciaf_64, width = 11, height = 13, dpi = 300, compression = "lzw")
ggsave("Figure2_64District_CIAF_Map_MICS2025.png",  plot = p_ciaf_64, width = 11, height = 13, dpi = 300)

# Figure 2B: Dedicated 64-District Stunting Map with District Names & Exact Values
p_stunt_64 <- ggplot(map_data) +
  geom_sf(aes(fill = stunting_prev), color = "grey30", linewidth = 0.35) +
  geom_sf_text(
    aes(label = stunt_label),
    size = 2.1,
    fontface = "bold",
    color = "black",
    check_overlap = FALSE
  ) +
  scale_fill_viridis_c(
    option = "viridis",
    direction = -1,
    name = "Stunting Prevalence",
    breaks = seq(10, 40, by = 5),
    labels = paste0(seq(10, 40, by = 5), "%"),
    limits = c(10, 40),
    guide = guide_colorbar(
      barwidth = 1.3,
      barheight = 14,
      title.position = "top",
      title.theme = element_text(face = "bold", size = 11)
    )
  ) +
  labs(
    title    = "Figure 2B: Under-5 Child Stunting (HAZ < -2) Across Bangladesh",
    subtitle = "Survey-Weighted District Prevalence (%) with District Names and Values (MICS 2025)",
    caption  = "Data Source: Bangladesh Bureau of Statistics (BBS) & UNICEF MICS 2025 | Analysis: SurveyNCD Package"
  ) +
  theme_void() +
  theme(
    plot.title      = element_text(face = "bold", size = 16, hjust = 0.5, margin = margin(t = 10, b = 5)),
    plot.subtitle   = element_text(size = 12, hjust = 0.5, color = "grey20", margin = margin(b = 15)),
    plot.caption    = element_text(size = 9, color = "grey40", hjust = 0.95, margin = margin(t = 10)),
    legend.position = "right",
    legend.margin   = margin(r = 15)
  )

ggsave("Figure2B_64District_Stunting_Map_MICS2025.tiff", plot = p_stunt_64, width = 11, height = 13, dpi = 300, compression = "lzw")
ggsave("Figure2B_64District_Stunting_Map_MICS2025.png",  plot = p_stunt_64, width = 11, height = 13, dpi = 300)

# Figure 2 Atlas: 4-Panel Bayesian Geospatial Atlas (with Percentage-Formatted Scales)
panel_a <- ggplot(map_data) + 
  geom_sf(aes(fill = unsmoothed_prev), color = "grey40", linewidth = 0.2) + 
  scale_fill_viridis_c(
    option = "plasma", direction = -1, name = "Prevalence",
    breaks = seq(25, 50, by = 5), labels = paste0(seq(25, 50, by = 5), "%")
  ) + 
  ggtitle("A: Unsmoothed Survey Prevalence (%)") + theme_void() + theme(plot.title = element_text(face = "bold", size = 11))

panel_b <- ggplot(map_data) + 
  geom_sf(aes(fill = smoothed_prev), color = "grey40", linewidth = 0.2) + 
  scale_fill_viridis_c(
    option = "plasma", direction = -1, name = "Prevalence",
    breaks = seq(25, 50, by = 5), labels = paste0(seq(25, 50, by = 5), "%")
  ) + 
  ggtitle("B: BYM2 Spatial-Smoothed Prevalence (%)") + theme_void() + theme(plot.title = element_text(face = "bold", size = 11))

panel_c <- ggplot(map_data) + 
  geom_sf(aes(fill = exc_prob_30), color = "grey40", linewidth = 0.2) + 
  scale_fill_viridis_c(
    option = "magma", name = "Probability",
    breaks = seq(0, 1, by = 0.2), labels = paste0(seq(0, 100, by = 20), "%")
  ) + 
  ggtitle("C: Exceedance Prob Pr(p > 30%)") + theme_void() + theme(plot.title = element_text(face = "bold", size = 11))

panel_d <- ggplot(map_data) + 
  geom_sf(aes(fill = cv), color = "grey40", linewidth = 0.2) + 
  scale_fill_viridis_c(
    option = "cividis", name = "CV",
    breaks = seq(0.04, 0.16, by = 0.04), labels = paste0(seq(4, 16, by = 4), "%")
  ) + 
  ggtitle("D: Coefficient of Variation (GATHER)") + theme_void() + theme(plot.title = element_text(face = "bold", size = 11))

fig2_atlas <- (panel_a | panel_b) / (panel_c | panel_d) +
  plot_annotation(
    title = "Figure 2: 4-Panel Bayesian Geospatial Atlas of Child Malnutrition (MICS 2025)",
    subtitle = "Design-weighted empirical vs. BYM2 model-smoothed estimates, exceedance probabilities, and uncertainty",
    theme = theme(plot.title = element_text(face = "bold", size = 14),
                  plot.subtitle = element_text(size = 11))
  )

ggsave("Figure2_Geospatial_Atlas.tiff", plot = fig2_atlas, width = 12, height = 12, dpi = 300, compression = "lzw")
ggsave("Figure2_Geospatial_Atlas.png",  plot = fig2_atlas, width = 12, height = 12, dpi = 300)

# Figure 3: LISA Clusters with Hotspot District Names
fig3 <- ggplot(map_data) + 
  geom_sf(aes(fill = lisa_quad), color = "grey40", linewidth = 0.25) + 
  geom_sf_text(
    aes(label = cluster_label),
    size = 2.4,
    fontface = "bold",
    color = "black",
    check_overlap = TRUE
  ) +
  scale_fill_manual(
    values = c("High-High" = "#D73027", "Low-Low" = "#4575B4", "Spatial Outlier" = "#FDAE61", "Non-Significant" = "grey85"),
    name = "LISA Cluster"
  ) +
  theme_void() + 
  labs(
    title = "Figure 3: Spatial Clusters of Child Anthropometric Failure in Bangladesh",
    subtitle = "Local Indicators of Spatial Association (LISA) with FDR Adjustment (MICS 2025)",
    caption = "Data Source: BBS & UNICEF MICS 2025 | Analysis: SurveyNCD Package"
  ) +
  theme(
    plot.title    = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, margin = margin(b = 10)),
    legend.position = "right"
  )

ggsave("Figure3_LISA_Map.tiff", plot = fig3, width = 9, height = 11, dpi = 300, compression = "lzw")
ggsave("Figure3_LISA_Map.png",  plot = fig3, width = 9, height = 11, dpi = 300)

# Figure 4: Concentration Curves
get_cc_data <- function(design, outcome_var, wealth_var) {
  df <- design$variables[!is.na(design$variables[[outcome_var]]) & !is.na(design$variables[[wealth_var]]), ]
  df <- df[order(df[[wealth_var]]), ]
  df$cum_pop     <- cumsum(df$chweight) / sum(df$chweight)
  df$cum_outcome <- cumsum(df[[outcome_var]] * df$chweight) / sum(df[[outcome_var]] * df$chweight)
  data.frame(cum_pop = df$cum_pop, cum_outcome = df$cum_outcome, Outcome = outcome_var)
}

cc_stunting <- get_cc_data(des, "is_stunted", "wscore")
cc_wasting  <- get_cc_data(des, "is_wasted", "wscore")
cc_ciaf     <- get_cc_data(des, "ciaf", "wscore")
cc_maf      <- get_cc_data(des, "maf", "wscore")

cc_df <- bind_rows(cc_stunting, cc_wasting, cc_ciaf, cc_maf) %>%
  mutate(
    Outcome = factor(Outcome, 
                     levels = c("is_stunted", "is_wasted", "ciaf", "maf"),
                     labels = c("Stunting", "Wasting", "Overall CIAF", "Multiple Concurrent Failure"))
  )

fig4 <- ggplot(cc_df, aes(x = cum_pop, y = cum_outcome, color = Outcome)) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "grey40", linewidth = 1) +
  geom_line(linewidth = 1.2) +
  annotate("text", x = 0.25, y = 0.30, label = "Line of Equality (45°)", angle = 45, color = "grey40", fontface = "italic") +
  theme_minimal(base_size = 12) +
  labs(
    title = "Figure 4: Concentration Curves of Child Malnutrition in Bangladesh",
    subtitle = "Curves bowed above the 45° line confirm severe pro-poor concentration (MICS 2025)",
    x = "Cumulative Share of Children (Ranked by Wealth: Poorest to Richest)",
    y = "Cumulative Share of Malnutrition Burden",
    color = "Malnutrition Phenotype"
  ) +
  scale_color_viridis_d(end = 0.85) +
  coord_equal() + 
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = c(0.75, 0.25),
    legend.background = element_rect(fill = "white", color = "grey80")
  )

ggsave("Figure4_Concentration_Curves.tiff", plot = fig4, width = 8, height = 8, dpi = 300, compression = "lzw")
ggsave("Figure4_Concentration_Curves.png",  plot = fig4, width = 8, height = 8, dpi = 300)

# -- Figure 5: Cross-Level Marginal Effects Plot --
cat("Rendering Figure 5: Marginal Interaction Effects...\n")
mydf <- tryCatch(
  ggeffects::ggpredict(m4, terms = c("wealth_quintile", "dist_san_def [quart]")),
  error = function(e) ggeffects::ggemmeans(m4, terms = c("wealth_quintile", "dist_san_def [quart]"))
)

fig5 <- plot(mydf) + 
  theme_minimal(base_size = 12) +
  labs(
    title = "Figure 5: Interaction of Household Wealth & District Sanitation Deficit",
    subtitle = "Living in sanitation-deprived districts compounds child anthropometric failure risk",
    x = "Household Wealth Quintile",
    y = "Predicted Probability of CIAF",
    color = "District Sanitation Deficit"
  ) +
  theme(plot.title = element_text(face = "bold"))

ggsave("Figure5_Interaction.tiff", plot = fig5, width = 9, height = 6, dpi = 300, compression = "lzw")
ggsave("Figure5_Interaction.png",  plot = fig5, width = 9, height = 6, dpi = 300)

cat("\n=====================================================================\n")
cat("SUCCESS! All 5 Publication Figures (.tiff & .png) and Excel Tables Created.\n")
cat("=====================================================================\n")
