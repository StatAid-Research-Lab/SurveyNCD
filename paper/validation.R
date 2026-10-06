# Validation checks cited in the SurveyNCD paper (run with the patched, tie-aware version).
# (1) concentration index with tied wealth values; (2) SE vs bootstrap SE (ranks recomputed per replicate).
# Single simulated designs, a sanity check, not a coverage study.
suppressMessages({library(SurveyNCD); library(survey)})
options(survey.lonely.psu="adjust")

## ---- (1) Ties: DHS wealth is often a 5-level quintile --------------------
set.seed(7)
n <- 4000
d <- data.frame(psu = rep(1:200, each = 20), stratum = rep(1:4, each = 1000))
d$wscore <- rnorm(n) + rep(rnorm(200, 0, .6), each = 20)
d$quintile <- as.integer(cut(d$wscore, quantile(d$wscore, 0:5/5), include.lowest = TRUE))
d$y <- rbinom(n, 1, plogis(-0.6 - 0.35 * d$wscore))
d$wt <- runif(n, 0.5, 2.5)
des <- svydesign(ids = ~psu, strata = ~stratum, weights = ~wt, data = d, nest = TRUE)

# package result with tied ranks (quintile)
r_pkg <- survey_concentration_index(des, outcome = y, wealth = quintile)

# tie-corrected fractional rank (mid-rank of cumulative weight within tied group)
ci_tie_corrected <- function(dat, w, wealth) {
  o <- order(wealth); y <- dat$y[o]; w <- w[o]; wl <- wealth[o]
  cw <- cumsum(w); tot <- sum(w)
  lo <- cw - w
  grp_lo <- ave(lo, wl, FUN = min); grp_hi <- ave(cw, wl, FUN = max)
  R <- (grp_lo + grp_hi) / 2 / tot
  mu <- weighted.mean(y, w)
  2 / mu * sum(w * (y - mu) * (R - weighted.mean(R, w))) / sum(w)
}
cat("\n(1) TIES  quintile wealth\n")
cat("   package CI (arbitrary order within ties): ", round(r_pkg$Concentration_Index, 4), "\n")
cat("   tie-corrected CI (mid-rank per quintile):  ", round(ci_tie_corrected(d, d$wt, d$quintile), 4), "\n")
# does the package result depend on row order within ties?
shuf <- d[sample(n), ]
des2 <- svydesign(ids = ~psu, strata = ~stratum, weights = ~wt, data = shuf, nest = TRUE)
cat("   package CI after shuffling row order:       ", round(survey_concentration_index(des2, outcome = y, wealth = quintile)$Concentration_Index, 4), "\n")

## ---- (2) SE: package vs bootstrap-replicate-weights SE --------------------
des_cont <- svydesign(ids = ~psu, strata = ~stratum, weights = ~wt, data = d, nest = TRUE)
est <- survey_concentration_index(des_cont, outcome = y, wealth = wscore)
set.seed(11)
rep_des <- as.svrepdesign(des_cont, type = "bootstrap", replicates = 300)
f <- function(w, data) {
  o <- order(data$wscore); y <- data$y[o]; w <- w[o]
  R <- (cumsum(w) - 0.5 * w) / sum(w); mu <- weighted.mean(y, w)
  2 / mu * sum(w * (y - mu) * (R - weighted.mean(R, w))) / sum(w)
}
wr <- withReplicates(rep_des, f)
cat("\n(2) SE comparison, continuous wealth, clustered/stratified design\n")
cat("   package CI:", round(est$Concentration_Index, 4), " package SE:", round(est$Standard_Error, 4), "\n")
cat("   bootstrap (rank re-computed in every replicate) CI:", round(coef(wr), 4), " SE:", round(SE(wr), 4), "\n")
