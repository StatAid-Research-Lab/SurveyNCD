# ==============================================================================
# Pipeline: MICS 2025 64-District Child Anthropometric Failure & Inequality
# Protocol: Subnational Inequalities in Composite Anthropometric Failure
# Package: SurveyNCD v0.1.0
# Author: Sujon Mia & Md. Atiqul Islam (StatAid Research Lab)
# ==============================================================================

suppressPackageStartupMessages({
  library(SurveyNCD)
  library(survey)
  library(haven)
  library(dplyr)
  library(sf)
  library(ggplot2)
})

cat("=====================================================================\n")
cat("Starting MICS 2025 64-District Anthropometric Analysis Pipeline\n")
cat("=====================================================================\n\n")

# ---- 1. File Paths -----------------------------------------------------------
ch_path  <- "E:/DATASETS/MICS-2026/Bangladesh MICS7 Datasets/Bangladesh MICS7 Datasets/Bangladesh MICS7 SPSS Datasets/ch.sav"
hh_path  <- "E:/DATASETS/MICS-2026/Bangladesh MICS7 Datasets/Bangladesh MICS7 Datasets/Bangladesh MICS7 SPSS Datasets/hh.sav"
shp_path <- "E:/DATASETS/gadm41_BGD_shp/gadm41_BGD_2.shp"

# Verify file existence
stopifnot(file.exists(ch_path))
stopifnot(file.exists(shp_path))

# ---- 2. Read Relevant Columns from ch.sav ------------------------------------
cat("Step 1: Reading Under-5 child dataset (ch.sav)...\n")
ch_cols <- c(
  "HH1", "HH2", "HH7", "HH7A", "stratum", "chweight",
  "CAGE", "HL4", "HAZ2", "WHZ2", "WAZ2",
  "wscore", "windex5"
)

raw_ch <- haven::read_sav(ch_path, col_select = dplyr::all_of(ch_cols))
cat("Total under-5 records loaded:", nrow(raw_ch), "\n\n")

# ---- 3. Anthropometric Cleaning & WHO Implausibility Flagging ----------------
cat("Step 2: Cleaning anthropometric z-scores using SurveyNCD::who_anthro_score()...\n")

raw_ch$stunt_cat <- who_anthro_score(
  raw_ch[["HAZ2"]], indicator = "stunting", scaled_by_100 = FALSE, remove_implausible = TRUE
)
raw_ch$waste_cat <- who_anthro_score(
  raw_ch[["WHZ2"]], indicator = "wasting", scaled_by_100 = FALSE, remove_implausible = TRUE
)
raw_ch$under_cat <- who_anthro_score(
  raw_ch[["WAZ2"]], indicator = "underweight", scaled_by_100 = FALSE, remove_implausible = TRUE
)

# Standard binary failure indicators (1 = Failure, 0 = Normal)
raw_ch$is_stunted     <- as.numeric(raw_ch$stunt_cat %in% c("Severe stunting", "Moderate stunting"))
raw_ch$is_wasted      <- as.numeric(raw_ch$waste_cat %in% c("Severe wasting", "Moderate wasting"))
raw_ch$is_underweight <- as.numeric(raw_ch$under_cat %in% c("Severe underweight", "Moderate underweight"))

# Set to NA if original score was implausible / missing
raw_ch$is_stunted[is.na(raw_ch$stunt_cat)] <- NA
raw_ch$is_wasted[is.na(raw_ch$waste_cat)]   <- NA
raw_ch$is_underweight[is.na(raw_ch$under_cat)] <- NA

# ---- 4. Construct Svedberg & Nandy CIAF Model --------------------------------
cat("Step 3: Constructing Svedberg & Nandy Composite Index of Anthropometric Failure (CIAF)...\n")

raw_ch$is_ciaf <- as.numeric(
  raw_ch$is_stunted == 1 | raw_ch$is_wasted == 1 | raw_ch$is_underweight == 1
)
all_na <- is.na(raw_ch$is_stunted) & is.na(raw_ch$is_wasted) & is.na(raw_ch$is_underweight)
raw_ch$is_ciaf[all_na] <- NA

# Severe Triple Failure (Group D: Stunted + Wasted + Underweight simultaneously)
raw_ch$is_triple <- as.numeric(
  raw_ch$is_stunted == 1 & raw_ch$is_wasted == 1 & raw_ch$is_underweight == 1
)

# Multiple Anthropometric Failures (>= 2 concurrent deficits)
raw_ch$fail_count <- raw_ch$is_stunted + raw_ch$is_wasted + raw_ch$is_underweight
raw_ch$is_multiple <- as.numeric(raw_ch$fail_count >= 2)

# ---- 5. Harmonize District Names to Match GADM Shapefile ---------------------
cat("Step 4: Harmonizing MICS 67 strata down to 64 GADM Districts...\n")
dist_factor <- haven::as_factor(raw_ch[["HH7A"]])
dist_name   <- as.character(dist_factor)

to_title <- function(x) {
  s <- tolower(x)
  paste0(toupper(substring(s, 1, 1)), substring(s, 2))
}

clean_dist <- sapply(dist_name, to_title, USE.NAMES = FALSE)

# Merge City Corporations back into their parent districts
clean_dist[clean_dist %in% c("Dhaka north city corporation", "Dhaka south city corporation")] <- "Dhaka"
clean_dist[clean_dist == "Chattogram city corporation"] <- "Chittagong"
clean_dist[clean_dist == "Chattogram"]                  <- "Chittagong"
clean_dist[clean_dist == "Bogura"]                      <- "Bogra"
clean_dist[clean_dist == "Brahmanbaria"]                <- "Brahamanbaria"
clean_dist[clean_dist == "Cumilla"]                     <- "Comilla"
clean_dist[clean_dist == "Barishal"]                    <- "Barisal"
clean_dist[clean_dist == "Jashore"]                     <- "Jessore"
clean_dist[clean_dist == "Netrokona"]                   <- "Netrakona"

raw_ch$district <- clean_dist

# Complete cases for anthropometry & sampling weight
clean_df <- raw_ch %>%
  filter(!is.na(chweight), !is.na(is_ciaf), !is.na(wscore))

cat("Valid analytical sample size:", nrow(clean_df), "children across 64 districts\n\n")

# ---- 6. Complex Survey Design ------------------------------------------------
options(survey.lonely.psu = "adjust")
des <- survey::svydesign(
  ids     = ~HH1,
  strata  = ~stratum,
  weights = ~chweight,
  data    = clean_df,
  nest    = TRUE
)

# ---- 7. National Weighted Prevalences ----------------------------------------
calc_prev <- function(var_formula) {
  est <- survey::svyciprop(var_formula, des, method = "logit")
  ci  <- attr(est, "ci")
  data.frame(
    Prevalence    = round(as.numeric(est) * 100, 2),
    Lower_95_CI   = round(ci[1] * 100, 2),
    Upper_95_CI   = round(ci[2] * 100, 2),
    SE            = round(as.numeric(survey::SE(est)) * 100, 3)
  )
}

prev_stunt  <- calc_prev(~is_stunted)
prev_waste  <- calc_prev(~is_wasted)
prev_under  <- calc_prev(~is_underweight)
prev_ciaf   <- calc_prev(~is_ciaf)
prev_triple <- calc_prev(~is_triple)
prev_multi  <- calc_prev(~is_multiple)

national_table <- data.frame(
  Indicator   = c("Stunting (HAZ < -2)", "Wasting (WHZ < -2)", "Underweight (WAZ < -2)",
                  "Composite Index of Anthropometric Failure (CIAF)",
                  "Severe Triple Failure (Stunted + Wasted + Underweight)",
                  "Multiple Anthropometric Failures (>=2)"),
  Prevalence  = c(prev_stunt$Prevalence, prev_waste$Prevalence, prev_under$Prevalence,
                  prev_ciaf$Prevalence, prev_triple$Prevalence, prev_multi$Prevalence),
  Lower_CI    = c(prev_stunt$Lower_95_CI, prev_waste$Lower_95_CI, prev_under$Lower_95_CI,
                  prev_ciaf$Lower_95_CI, prev_triple$Lower_95_CI, prev_multi$Lower_95_CI),
  Upper_CI    = c(prev_stunt$Upper_95_CI, prev_waste$Upper_95_CI, prev_under$Upper_95_CI,
                  prev_ciaf$Upper_95_CI, prev_triple$Upper_95_CI, prev_multi$Upper_95_CI)
)

write.csv(national_table, "E:/Building_R_Packages/SurveyNCD/Table1_National_Prevalence_MICS2025.csv", row.names = FALSE)

# ---- 8. Erreygers-Corrected Concentration Indices ----------------------------
calc_erreygers <- function(indicator_name, var_sym) {
  ci_out  <- survey_concentration_index(des, outcome = {{var_sym}}, wealth = wscore)
  mu      <- ci_out$Outcome_Mean
  ci_val  <- ci_out$Concentration_Index
  se_val  <- ci_out$Standard_Error
  
  E_index <- 4 * mu * ci_val
  E_se    <- 4 * mu * se_val
  E_lower <- E_index - 1.96 * E_se
  E_upper <- E_index + 1.96 * E_se
  p_val   <- 2 * (1 - pnorm(abs(E_index / E_se)))
  
  data.frame(
    Indicator            = indicator_name,
    Weighted_Mean        = round(mu, 4),
    Standard_CI          = round(ci_val, 4),
    Erreygers_Index      = round(E_index, 4),
    Erreygers_SE         = round(E_se, 4),
    Erreygers_Lower_95   = round(E_lower, 4),
    Erreygers_Upper_95   = round(E_upper, 4),
    p_value              = ifelse(p_val < 0.001, "< 0.001", round(p_val, 4)),
    Inequality_Direction = ifelse(E_index < 0, "Pro-Poor", "Pro-Rich")
  )
}

eq_stunt  <- calc_erreygers("Stunting (HAZ < -2)", is_stunted)
eq_waste  <- calc_erreygers("Wasting (WHZ < -2)", is_wasted)
eq_under  <- calc_erreygers("Underweight (WAZ < -2)", is_underweight)
eq_ciaf   <- calc_erreygers("Overall CIAF Failure", is_ciaf)
eq_triple <- calc_erreygers("Triple Failure (Group D)", is_triple)

inequality_table <- rbind(eq_stunt, eq_waste, eq_under, eq_ciaf, eq_triple)
write.csv(inequality_table, "E:/Building_R_Packages/SurveyNCD/Table2_Erreygers_Inequality_MICS2025.csv", row.names = FALSE)

# ---- 9. 64-District Estimation & Geographic League Table ---------------------
cat("Step 8: Computing 64-District League Table...\n")

district_summary <- clean_df %>%
  group_by(district) %>%
  summarise(
    n_unweighted   = n(),
    stunting_prev  = round(weighted.mean(is_stunted, chweight, na.rm = TRUE) * 100, 1),
    wasting_prev   = round(weighted.mean(is_wasted, chweight, na.rm = TRUE) * 100, 1),
    underwt_prev   = round(weighted.mean(is_underweight, chweight, na.rm = TRUE) * 100, 1),
    ciaf_prev      = round(weighted.mean(is_ciaf, chweight, na.rm = TRUE) * 100, 1),
    triple_prev    = round(weighted.mean(is_triple, chweight, na.rm = TRUE) * 100, 1)
  ) %>%
  arrange(desc(ciaf_prev))

write.csv(district_summary, "E:/Building_R_Packages/SurveyNCD/TableS1_64District_Prevalence_League.csv", row.names = FALSE)

# ---- 10. High-Resolution Spatial Choropleth Maps with District Labels & Scales -
cat("Step 9: Rendering enhanced 64-District Maps with District Names & Values...\n")
bgd_shp <- sf::st_read(shp_path, quiet = TRUE)

map_data <- bgd_shp %>%
  left_join(district_summary, by = c("NAME_2" = "district"))

# Create text labels: District Name + Exact Prevalence Value
map_data <- map_data %>%
  mutate(
    ciaf_label   = paste0(NAME_2, "\n", ciaf_prev, "%"),
    stunt_label  = paste0(NAME_2, "\n", stunting_prev, "%")
  )

# Figure 2: Total CIAF Map with District Names & Values
p_ciaf <- ggplot(map_data) +
  geom_sf(aes(fill = ciaf_prev), color = "grey30", linewidth = 0.35) +
  geom_sf_text(
    aes(label = ciaf_label),
    size = 2.0,
    fontface = "bold",
    color = "black",
    check_overlap = FALSE
  ) +
  scale_fill_viridis_c(
    option = "plasma",
    direction = -1,
    name = "CIAF Prevalence (%)",
    breaks = seq(20, 50, by = 5),
    labels = paste0(seq(20, 50, by = 5), "%"),
    limits = c(20, 50),
    guide = guide_colorbar(
      barwidth = 1.2,
      barheight = 14,
      title.position = "top",
      title.theme = element_text(face = "bold", size = 11)
    )
  ) +
  labs(
    title    = "Composite Index of Anthropometric Failure (CIAF) Across Bangladesh",
    subtitle = "Design-Weighted Prevalence with District Names & Values (MICS 2025)",
    caption  = "Data Source: BBS & UNICEF Bangladesh MICS 2025 | Analysis: SurveyNCD Package"
  ) +
  theme_void() +
  theme(
    plot.title      = element_text(face = "bold", size = 16, hjust = 0.5, margin = margin(t = 10, b = 5)),
    plot.subtitle   = element_text(size = 12, hjust = 0.5, color = "grey20", margin = margin(b = 15)),
    plot.caption    = element_text(size = 9, color = "grey40", hjust = 0.95, margin = margin(t = 10)),
    legend.position = "right",
    legend.margin   = margin(r = 15)
  )

ggsave("E:/Building_R_Packages/SurveyNCD/Figure2_64District_CIAF_Map_MICS2025.png", p_ciaf, width = 11, height = 13, dpi = 300)
cat("Exported: Figure2_64District_CIAF_Map_MICS2025.png\n")

# Figure 2B: Stunting Map with District Names & Values
p_stunt <- ggplot(map_data) +
  geom_sf(aes(fill = stunting_prev), color = "grey30", linewidth = 0.35) +
  geom_sf_text(
    aes(label = stunt_label),
    size = 2.0,
    fontface = "bold",
    color = "black",
    check_overlap = FALSE
  ) +
  scale_fill_viridis_c(
    option = "viridis",
    direction = -1,
    name = "Stunting Prevalence (%)",
    breaks = seq(10, 40, by = 5),
    labels = paste0(seq(10, 40, by = 5), "%"),
    limits = c(10, 40),
    guide = guide_colorbar(
      barwidth = 1.2,
      barheight = 14,
      title.position = "top",
      title.theme = element_text(face = "bold", size = 11)
    )
  ) +
  labs(
    title    = "Child Stunting (HAZ < -2) Across Bangladesh",
    subtitle = "Design-Weighted Prevalence with District Names & Values (MICS 2025)",
    caption  = "Data Source: BBS & UNICEF Bangladesh MICS 2025 | Analysis: SurveyNCD Package"
  ) +
  theme_void() +
  theme(
    plot.title      = element_text(face = "bold", size = 16, hjust = 0.5, margin = margin(t = 10, b = 5)),
    plot.subtitle   = element_text(size = 12, hjust = 0.5, color = "grey20", margin = margin(b = 15)),
    plot.caption    = element_text(size = 9, color = "grey40", hjust = 0.95, margin = margin(t = 10)),
    legend.position = "right",
    legend.margin   = margin(r = 15)
  )

ggsave("E:/Building_R_Packages/SurveyNCD/Figure2B_64District_Stunting_Map_MICS2025.png", p_stunt, width = 11, height = 13, dpi = 300)
cat("Exported: Figure2B_64District_Stunting_Map_MICS2025.png\n")

cat("\n=====================================================================\n")
cat("Pipeline Completed Successfully! All Enhanced Figures and Tables Saved.\n")
cat("=====================================================================\n")
