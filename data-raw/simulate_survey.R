# Simulation of a STEPS/DHS-style population and a stratified two-stage
# cluster sample drawn from it. Used to create the example datasets shipped
# with SurveyNCD (`ncd_survey`, `child_anthro`) and for the simulation study
# in the accompanying papers. Base R only.
#
# Population: 6 regions of unequal size, each split into urban and rural
# enumeration areas (EAs, the clusters). One adult (18-69 y) per household;
# children under 5 nested in households. Health outcomes depend on age, sex,
# BMI, household wealth and an EA-level random effect, so outcomes are
# clustered and socially patterned.
#
# Design: stratification by region x residence (12 strata); 10 EAs drawn by
# simple random sampling in every stratum (equal allocation, so small regions
# and urban areas are over-sampled); 20 households drawn by SRS in each
# selected EA. Inclusion probabilities are exact, so design weights are exact.

simulate_population <- function(seed = 20261010) {
  set.seed(seed)
  regions <- data.frame(
    region  = paste("Region", LETTERS[1:6]),
    n_ea    = c(300, 220, 160, 120, 90, 60),
    reg_eff = c(0.30, 0.10, 0.00, -0.10, -0.25, -0.40),
    stringsAsFactors = FALSE
  )

  # ---- enumeration areas -------------------------------------------------
  ea <- do.call(rbind, lapply(seq_len(nrow(regions)), function(r) {
    n_u <- round(0.30 * regions$n_ea[r])
    data.frame(
      region    = regions$region[r],
      reg_eff   = regions$reg_eff[r],
      residence = rep(c("Urban", "Rural"), c(n_u, regions$n_ea[r] - n_u)),
      stringsAsFactors = FALSE
    )
  }))
  ea$ea_id   <- seq_len(nrow(ea))
  ea$stratum <- paste(ea$region, ea$residence, sep = " - ")
  ea$n_hh    <- 80L + stats::rpois(nrow(ea), 70)
  ea$u_wealth <- stats::rnorm(nrow(ea), 0, 0.6)  # EA-level wealth effect
  ea$u_health <- stats::rnorm(nrow(ea), 0, 0.5)  # EA-level health effect

  # ---- households / adults ------------------------------------------------
  hh <- ea[rep(seq_len(nrow(ea)), ea$n_hh), ]
  n  <- nrow(hh)
  hh$hh_id <- seq_len(n)
  urban    <- as.numeric(hh$residence == "Urban")
  hh$sex   <- ifelse(stats::runif(n) < 0.5, "Female", "Male")
  female   <- as.numeric(hh$sex == "Female")
  hh$age   <- pmin(69L, 18L + as.integer(stats::rexp(n, 1 / 17)))
  hh$wealth_score <- round(0.9 * urban + hh$reg_eff + hh$u_wealth +
                             stats::rnorm(n), 3)
  hh$bmi <- round(21.5 + 1.1 * hh$wealth_score + 1.2 * urban +
                    0.04 * (hh$age - 40) + stats::rnorm(n, 0, 3.2), 1)

  a10 <- (hh$age - 45) / 10
  b4  <- (hh$bmi - 22) / 4
  w   <- hh$wealth_score
  u   <- hh$u_health
  lp <- list(
    hypertension = -1.45 + 0.55 * a10 + 0.20 * w + 0.35 * b4 + u,
    diabetes     = -2.55 + 0.50 * a10 + 0.35 * w + 0.35 * b4 + u,
    arthritis    = -2.10 + 0.50 * a10 - 0.25 * w + 0.15 * b4 + 0.45 * female + u,
    asthma       = -3.00 + 0.15 * a10 - 0.30 * w + 0.5 * u,
    angina       = -3.30 + 0.60 * a10 + 0.10 * w + 0.15 * b4 + u,
    stroke       = -4.20 + 0.70 * a10 + 0.5 * u,
    depression   = -2.80 + 0.10 * a10 - 0.35 * w + 0.30 * female + 0.5 * u
  )
  for (k in names(lp)) hh[[k]] <- stats::rbinom(n, 1, stats::plogis(lp[[k]]))

  # ---- children under 5 ---------------------------------------------------
  n_kids <- pmin(3L, stats::rpois(n, 0.45))
  ch <- hh[rep(seq_len(n), n_kids),
           c("hh_id", "ea_id", "region", "residence", "stratum",
             "wealth_score", "u_wealth")]
  m <- nrow(ch)
  ch$child_id   <- seq_len(m)
  ch$sex        <- ifelse(stats::runif(m) < 0.5, "Female", "Male")
  ch$age_months <- sample(0:59, m, replace = TRUE)
  u_ch <- stats::rnorm(max(ea$ea_id), 0, 0.35)[ch$ea_id]
  ch$haz <- -1.35 + 0.38 * ch$wealth_score - 0.012 * (ch$age_months - 30) +
    u_ch + stats::rnorm(m, 0, 1.1)
  ch$whz <- -0.55 + 0.15 * ch$wealth_score + 0.5 * u_ch + stats::rnorm(m, 0, 1.0)
  ch$waz <- 0.55 * ch$haz + 0.65 * ch$whz + stats::rnorm(m, 0, 0.35)

  list(households = hh, children = ch, ea = ea)
}

# DHS-style coding of child z-scores: multiplied by 100, with flag codes
dhs_code_z <- function(z, p_9996 = 0.008, p_9998 = 0.010, p_extreme = 0.004) {
  x <- round(z * 100)
  r <- stats::runif(length(x))
  x[r < p_extreme] <- sample(c(-720, -650, 640, 710), sum(r < p_extreme),
                             replace = TRUE)            # biologically implausible
  x[r >= p_extreme & r < p_extreme + p_9996] <- 9996    # height out of range
  x[r >= p_extreme + p_9996 & r < p_extreme + p_9996 + p_9998] <- 9998  # missing
  as.integer(x)
}

# STEPS-style raw coding: 1 = yes, 2 = no, 9 = don't know
steps_code <- function(y, p_dk) {
  out <- ifelse(y == 1, 1L, 2L)
  out[stats::runif(length(y)) < p_dk] <- 9L
  out
}

weighted_quintile <- function(x, w) {
  o  <- order(x)
  cw <- cumsum(w[o]) / sum(w)
  q  <- integer(length(x))
  q[o] <- pmin(5L, 1L + floor(cw * 5 - 1e-12))
  q
}

draw_sample <- function(pop, ea_per_stratum = 10, hh_per_ea = 20, seed = 1) {
  set.seed(seed)
  ea <- pop$ea
  M_h <- table(ea$stratum)
  sel <- unlist(lapply(split(ea$ea_id, ea$stratum),
                       function(ids) ids[sample.int(length(ids), ea_per_stratum)]))
  ea_s <- ea[ea$ea_id %in% sel, ]
  hh <- pop$households
  hh_s <- do.call(rbind, lapply(split(hh[hh$ea_id %in% sel, ], hh$ea_id[hh$ea_id %in% sel]),
                                function(d) d[sample.int(nrow(d), hh_per_ea), ]))
  pi1 <- ea_per_stratum / as.numeric(M_h[hh_s$stratum])
  pi2 <- hh_per_ea / hh_s$n_hh
  hh_s$design_weight <- 1 / (pi1 * pi2)
  hh_s <- hh_s[order(hh_s$hh_id), ]
  rownames(hh_s) <- NULL
  hh_s
}

# Turn a sample of households into the two public-style datasets
make_public_datasets <- function(pop, hh_s, seed = 2) {
  set.seed(seed)
  n <- nrow(hh_s)
  wt <- hh_s$design_weight / mean(hh_s$design_weight)   # normalised, DHS-style
  psu <- match(hh_s$ea_id, sort(unique(hh_s$ea_id)))
  q <- weighted_quintile(hh_s$wealth_score, wt)

  adults <- data.frame(
    hh_id           = hh_s$hh_id,
    region          = hh_s$region,
    residence       = hh_s$residence,
    stratum         = hh_s$stratum,
    psu             = psu,
    wt              = round(wt, 6),
    sex             = hh_s$sex,
    age             = hh_s$age,
    wealth_score    = hh_s$wealth_score,
    wealth_quintile = q,
    bmi             = hh_s$bmi,
    htn_raw         = steps_code(hh_s$hypertension, 0.04),
    dm_raw          = steps_code(hh_s$diabetes,     0.03),
    arth_raw        = steps_code(hh_s$arthritis,    0.02),
    asthma_raw      = steps_code(hh_s$asthma,       0.01),
    angina_raw      = steps_code(hh_s$angina,       0.02),
    stroke_raw      = steps_code(hh_s$stroke,       0.01),
    dep_raw         = c("No", "Yes")[hh_s$depression + 1],
    stringsAsFactors = FALSE
  )
  dk <- stats::runif(n) < 0.03
  adults$dep_raw[dk] <- "Don't know"

  ch <- pop$children[pop$children$hh_id %in% hh_s$hh_id, ]
  idx <- match(ch$hh_id, hh_s$hh_id)
  children <- data.frame(
    child_id        = seq_len(nrow(ch)),
    hh_id           = ch$hh_id,
    region          = ch$region,
    residence       = ch$residence,
    stratum         = ch$stratum,
    psu             = psu[idx],
    wt              = round(wt[idx], 6),
    sex             = ch$sex,
    age_months      = ch$age_months,
    wealth_score    = ch$wealth_score,
    wealth_quintile = q[idx],
    hw70            = dhs_code_z(ch$haz),
    hw71            = dhs_code_z(ch$waz),
    hw72            = dhs_code_z(ch$whz),
    stringsAsFactors = FALSE
  )
  list(ncd_survey = adults, child_anthro = children)
}

# True finite-population values used to judge the estimators
population_truth <- function(pop) {
  hh <- pop$households
  cond <- c("hypertension", "diabetes", "arthritis", "asthma", "angina",
            "stroke", "depression")
  k <- rowSums(hh[, cond])
  o <- order(hh$wealth_score)
  y <- k[o]; N <- length(y)
  R <- (seq_len(N) - 0.5) / N
  ci <- 2 / mean(y) * mean((y - mean(y)) * (R - mean(R)))
  list(
    condition_prevalence = colMeans(hh[, cond]),
    multimorbidity       = mean(k >= 2),
    mean_conditions      = mean(k),
    ci_conditions        = ci,
    stunting             = mean(pop$children$haz < -2),
    N_adults             = N,
    N_children           = nrow(pop$children)
  )
}
