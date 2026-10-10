# Validation of survey_concentration_index() against independent calculations.
# Run from the package root:  Rscript analysis/02_validation.R
# Requires the 'rineq' package (CRAN) for the external comparison.
source("analysis/00_helpers.R")
set.seed(99)

d <- ncd_survey
for (v in c("htn_raw", "dm_raw", "arth_raw", "asthma_raw", "angina_raw", "stroke_raw"))
  d[[sub("_raw", "", v)]] <- suppressWarnings(recode_binary(d[[v]], yes = 1, no = 2))
d$dep <- suppressWarnings(recode_binary(d$dep_raw, yes = "Yes", no = "No"))
s <- multimorbidity_index(d, c("htn", "dm", "arth", "asthma", "angina", "stroke", "dep"), na_action = "na")
s <- s[!is.na(s$mm_n_conditions), ]
s$multimorbid <- as.numeric(s$mm_category == "Multimorbid")
# wealth_score has tied values (rounded to 3 decimals); a tie-free copy for exact comparison
s$wealth_untied <- s$wealth_score + rank(s$wealth_score, ties.method = "first") * 1e-9
des <- svydesign(ids = ~psu, strata = ~stratum, weights = ~wt, data = s, nest = TRUE)
rep_des <- as.svrepdesign(des, type = "bootstrap", replicates = 500)

ci_plain <- function(y, x, w) {           # weighted CI, mid-rank for ties
  o <- order(x); y <- y[o]; w <- w[o]; x <- x[o]
  hi <- cumsum(w); lo <- hi - w
  R <- (stats::ave(lo, x, FUN = min) + stats::ave(hi, x, FUN = max)) / 2 / sum(w)
  mu <- stats::weighted.mean(y, w)
  2 / mu * sum(w * (y - mu) * (R - stats::weighted.mean(R, w))) / sum(w)
}

outcomes <- c(Hypertension = "htn", Diabetes = "dm", Depression = "dep",
              `Number of conditions` = "mm_n_conditions", Multimorbidity = "multimorbid")
has_rineq <- requireNamespace("rineq", quietly = TRUE)
val <- do.call(rbind, lapply(names(outcomes), function(nm) {
  v <- outcomes[[nm]]
  r <- eval(substitute(survey_concentration_index(des, outcome = V, wealth = wealth_score),
                       list(V = as.name(v))))
  bt <- withReplicates(rep_des, function(w, data) ci_plain(data[[v]], data$wealth_score, w))
  ri <- if (has_rineq) rineq::ci(x = s$wealth_score, y = s[[v]], wt = s$wt, type = "CI") else NULL
  # same comparison after breaking ties (rineq ranks tied values by row order)
  r_u  <- eval(substitute(survey_concentration_index(des, outcome = V, wealth = wealth_untied),
                          list(V = as.name(v))))
  ri_u <- if (has_rineq) rineq::ci(x = s$wealth_untied, y = s[[v]], wt = s$wt, type = "CI") else NULL
  data.frame(
    Outcome = nm,
    `SurveyNCD CI` = f3(r$Concentration_Index),
    `rineq CI` = if (has_rineq) f3(ri$concentration_index) else NA,
    `Abs. diff. (ties)` = if (has_rineq) formatC(abs(r$Concentration_Index - ri$concentration_index), format = "e", digits = 1) else NA,
    `Abs. diff. (no ties)` = if (has_rineq) formatC(abs(r_u$Concentration_Index - ri_u$concentration_index), format = "e", digits = 1) else NA,
    `SE: SurveyNCD (design)` = f3(r$Standard_Error),
    `SE: bootstrap (design)` = f3(as.numeric(SE(bt))),
    `SE: rineq (iid)` = if (has_rineq) f3(sqrt(ri$variance)) else NA,
    check.names = FALSE)
}))
save_tab(val, "tab_validation_rineq",
         sprintf("Concentration index (adults with complete answers on all seven conditions, n = 2054) from survey\\_concentration\\_index() compared with rineq::ci() (version %s) and with a 500-replicate design bootstrap that re-computes the fractional ranks in every replicate. The wealth score has %d tied values; rineq ranks ties by row order while SurveyNCD gives tied respondents a common mid-rank, which explains the small differences; with ties broken the two agree to rounding error. rineq's standard error assumes independent observations and ignores strata and clusters.",
                 if (has_rineq) as.character(utils::packageVersion("rineq")) else "n/a",
                 sum(duplicated(s$wealth_score))),
         align = "lrrrrrrr")

# Tie handling: quintile ranking, 50 random row orders
shuffle_ci <- function(fun_lib) {
  vapply(1:50, function(i) {
    ss <- s[sample(nrow(s)), ]
    dd <- svydesign(ids = ~psu, strata = ~stratum, weights = ~wt, data = ss, nest = TRUE)
    fun_lib(dd)
  }, numeric(1))
}
set.seed(99)
new_vals <- shuffle_ci(function(dd) survey_concentration_index(dd, outcome = mm_n_conditions, wealth = wealth_quintile)$Concentration_Index)
# v0.1.0 ranked tied respondents by their position in the data. Reproduced here
# (frac_rank = (cumsum(w) - w/2) / sum(w) after a stable sort by wealth) so the
# comparison runs without the old package; it was checked against v0.1.0 itself.
ci_v010 <- function(dd) {
  x <- dd$variables$wealth_quintile; y <- dd$variables$mm_n_conditions; w <- weights(dd)
  o <- order(x); y <- y[o]; w <- w[o]
  R <- (cumsum(w) - 0.5 * w) / sum(w); mu <- weighted.mean(y, w)
  2 / mu * sum(w * (y - mu) * (R - weighted.mean(R, w))) / sum(w)
}
set.seed(99)
old_vals <- shuffle_ci(ci_v010)
tie_tab <- data.frame(
  Version = c(if (!is.null(old_vals)) "0.1.0 (row-order ranks)", "0.2.0 (mid-ranks for ties)"),
  `Min CI` = f3(c(if (!is.null(old_vals)) min(old_vals), min(new_vals))),
  `Max CI` = f3(c(if (!is.null(old_vals)) max(old_vals), max(new_vals))),
  `Range` = formatC(c(if (!is.null(old_vals)) diff(range(old_vals)), diff(range(new_vals))), format = "g", digits = 2),
  `Reference (mid-rank)` = f3(ci_plain(s$mm_n_conditions, s$wealth_quintile, s$wt)),
  check.names = FALSE)
save_tab(tie_tab, "tab_validation_ties",
         "Concentration index of the number of conditions ranked by wealth quintile (five tied groups), over 50 random row orders of the same data.",
         align = "lrrrr")
message("Validation done.")
