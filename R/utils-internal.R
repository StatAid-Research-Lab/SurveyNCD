# Internal helpers shared across SurveyNCD functions. Not exported.

.check_design <- function(design, arg = "design") {
  if (!inherits(design, "survey.design") && !inherits(design, "svyrep.design")) {
    stop("`", arg, "` must be a survey design object created by survey::svydesign(), ",
         "survey::svrepdesign(), srvyr::as_survey_design() or one of dhs_design(), ",
         "mics_design(), steps_design().", call. = FALSE)
  }
  invisible(design)
}

.check_vars <- function(design, vars, what = "Column") {
  miss <- setdiff(vars, names(design$variables))
  if (length(miss) > 0) {
    stop(what, "(s) not found in the design data: ", paste(miss, collapse = ", "),
         call. = FALSE)
  }
  invisible(vars)
}

.check_binary <- function(x, name) {
  if (is.logical(x)) x <- as.numeric(x)
  if (!is.numeric(x)) {
    stop("`", name, "` must be numeric 0/1 (or logical). Use recode_binary() first.",
         call. = FALSE)
  }
  bad <- setdiff(unique(x[!is.na(x)]), c(0, 1))
  if (length(bad) > 0) {
    stop("`", name, "` must contain only 0, 1 or NA. Found: ",
         paste(utils::head(bad, 5), collapse = ", "), call. = FALSE)
  }
  x
}

# Positive design weights (0 for rows outside a domain created by subset())
.design_weights <- function(design) {
  w <- stats::weights(design)
  if (is.matrix(w)) w <- design$pweights   # replicate designs: sampling weights
  as.numeric(w)
}

# Add or replace a column in the design's data
.set_var <- function(design, name, value) {
  design$variables[[name]] <- value
  design
}

.formula <- function(var) stats::as.formula(paste0("~`", var, "`"))

# Split a design into domains defined by one or more grouping variables.
# Domains are formed with `[` on the design, which keeps the full design for
# variance estimation (the same mechanism as survey::subset()).
.domains <- function(design, by) {
  if (is.null(by) || length(by) == 0) {
    return(list(list(key = NULL, design = design)))
  }
  .check_vars(design, by, "Grouping column")
  vars <- design$variables
  keys <- unique(vars[, by, drop = FALSE])
  keys <- keys[stats::complete.cases(keys), , drop = FALSE]
  keys <- keys[do.call(order, unname(as.list(keys))), , drop = FALSE]
  rownames(keys) <- NULL
  lapply(seq_len(nrow(keys)), function(i) {
    k <- keys[i, , drop = FALSE]
    sel <- rep(TRUE, nrow(vars))
    for (b in by) sel <- sel & !is.na(vars[[b]]) & vars[[b]] == k[[b]]
    list(key = k, design = design[sel, ])
  })
}

.bind_key <- function(key, df) {
  if (is.null(key)) return(df)
  key <- key[rep(1, nrow(df)), , drop = FALSE]
  rownames(key) <- NULL
  cbind(key, df)
}

# Tie-aware weighted fractional rank (Lerman & Yitzhaki 1989): the mid-point of
# each respondent's interval of the cumulative weight distribution; respondents
# tied on x share the mid-point of their tied group's interval.
.frac_rank <- function(x, w) {
  o <- order(x)
  xs <- x[o]; ws <- w[o]
  hi <- cumsum(ws); lo <- hi - ws
  r_sorted <- (stats::ave(lo, xs, FUN = min) + stats::ave(hi, xs, FUN = max)) / 2 / sum(ws)
  r <- numeric(length(x))
  r[o] <- r_sorted
  r
}

.lonely_adjust <- function() options(survey.lonely.psu = "adjust")
