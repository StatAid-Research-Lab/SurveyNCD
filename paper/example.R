# Reproducible example for the SurveyNCD paper (simulated STEPS-style data).
# Requires: SurveyNCD (>= 0.1.0), survey
library(SurveyNCD)
library(survey)

set.seed(2026)
n_region <- 3; psu_per_region <- 20; per_psu <- 25
sim <- data.frame(
  region = rep(paste0("R", 1:n_region), each = psu_per_region * per_psu),
  psu    = rep(seq_len(n_region * psu_per_region), each = per_psu)
)
n <- nrow(sim)
psu_effect <- rnorm(n_region * psu_per_region, 0, 0.5)[sim$psu]
sim$sex    <- sample(c("Female", "Male"), n, replace = TRUE)
sim$wealth <- rnorm(n) + 0.5 * psu_effect            # continuous wealth score
sim$wt     <- round(runif(n, 0.5, 3), 3)             # sampling weight
lp <- function(b0) plogis(b0 - 0.30 * sim$wealth + 0.4 * psu_effect)
raw <- function(p) {                                 # STEPS coding: 1 yes, 2 no, 9 don't know
  y <- ifelse(rbinom(n, 1, p) == 1, 1, 2)
  y[runif(n) < 0.03] <- 9
  y
}
sim$htn_raw <- raw(lp(-1.4)); sim$dm_raw <- raw(lp(-2.2)); sim$arth_raw <- raw(lp(-1.8))

# 1. Clean raw codes (9 = "don't know" becomes NA, with a warning)
sim$htn  <- recode_binary(sim$htn_raw,  yes = 1, no = 2)
sim$dm   <- recode_binary(sim$dm_raw,   yes = 1, no = 2)
sim$arth <- recode_binary(sim$arth_raw, yes = 1, no = 2)

# 2. Individual-level score; respondents with any missing condition -> NA
scored <- multimorbidity_index(sim, conditions = c("htn", "dm", "arth"),
                               na_action = "na")

# 3. Design-weighted population estimates (strata, PSUs, weights)
mm_prevalence(scored, ids = "psu", strata = "region", weights = "wt")
mm_prevalence(scored, ids = "psu", strata = "region", weights = "wt", by = "sex")

# 4. Wealth-related inequality in condition count
design <- svydesign(ids = ~psu, strata = ~region, weights = ~wt,
                    data = scored, nest = TRUE)
survey_concentration_index(design, outcome = mm_n_conditions, wealth = wealth)

# Naive (design-ignoring) prevalence for contrast
mean(scored$mm_category == "Multimorbid", na.rm = TRUE)
