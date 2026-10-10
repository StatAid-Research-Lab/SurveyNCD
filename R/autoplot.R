#' Plot SurveyNCD results with ggplot2
#'
#' `autoplot()` methods for the results of [survey_prevalence()],
#' [mm_prevalence()], [survey_concentration_index()],
#' [survey_concentration_curve()] and [mm_patterns()]. Each returns a
#' `ggplot` object that can be modified with the usual \pkg{ggplot2} layers.
#'
#' @param object A result object from one of the functions above.
#' @param ... Not used.
#' @return A `ggplot` object.
#' @examples
#' d <- ncd_survey
#' d$htn <- recode_binary(d$htn_raw, yes = 1, no = 2)
#' d$dm  <- recode_binary(d$dm_raw,  yes = 1, no = 2)
#' des <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~wt,
#'                          data = d, nest = TRUE)
#' ggplot2::autoplot(survey_prevalence(des, c("htn", "dm"), by = "residence"))
#' ggplot2::autoplot(survey_concentration_curve(des, dm, wealth_score))
#' @name autoplot.surveyncd
#' @importFrom rlang .data
NULL

.pal3 <- c("#2a78d6", "#eb6834", "#1baf7a")
.pct <- function(x) paste0(round(100 * x), "%")
.theme_sncd <- function() {
  ggplot2::theme_minimal() +
    ggplot2::theme(plot.background = ggplot2::element_rect(fill = "white", colour = NA),
                   panel.grid.minor = ggplot2::element_blank())
}

#' @rdname autoplot.surveyncd
#' @exportS3Method ggplot2::autoplot
autoplot.surveyncd_prevalence <- function(object, ...) {
  by <- attr(object, "by")
  df <- as.data.frame(object)
  if (is.null(by)) {
    p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$estimate, y = .data$indicator)) +
      ggplot2::geom_pointrange(ggplot2::aes(xmin = .data$lower, xmax = .data$upper),
                               colour = .pal3[1])
  } else {
    df$group <- interaction(df[by], sep = " / ", drop = TRUE)
    p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$estimate, y = .data$group)) +
      ggplot2::geom_pointrange(ggplot2::aes(xmin = .data$lower, xmax = .data$upper),
                               colour = .pal3[1]) +
      ggplot2::facet_wrap(~indicator, scales = "free_x")
  }
  p + ggplot2::scale_x_continuous(labels = .pct) +
    ggplot2::labs(x = "Design-based prevalence (95% CI)", y = NULL) +
    (.theme_sncd())
}

#' @rdname autoplot.surveyncd
#' @exportS3Method ggplot2::autoplot
autoplot.surveyncd_mm_prevalence <- function(object, ...) {
  by <- attr(object, "by")
  df <- as.data.frame(object)
  df$group <- if (is.null(by)) "All" else interaction(df[by], sep = " / ", drop = TRUE)
  ggplot2::ggplot(df, ggplot2::aes(x = .data$prevalence, y = .data$group)) +
    ggplot2::geom_pointrange(ggplot2::aes(xmin = .data$prevalence_lower,
                                          xmax = .data$prevalence_upper), colour = .pal3[1]) +
    ggplot2::scale_x_continuous(labels = .pct) +
    ggplot2::labs(x = "Multimorbidity prevalence (95% CI)", y = NULL) +
    (.theme_sncd())
}

#' @rdname autoplot.surveyncd
#' @exportS3Method ggplot2::autoplot
autoplot.surveyncd_ci <- function(object, ...) {
  df <- as.data.frame(object)
  keys <- setdiff(names(df), c("Concentration_Index", "Standard_Error", "Lower_CI", "Upper_CI",
                               "p_value", "Outcome_Mean", "n", "Type"))
  df$group <- if (length(keys) == 0) "All" else interaction(df[keys], sep = " / ", drop = TRUE)
  ggplot2::ggplot(df, ggplot2::aes(x = .data$Concentration_Index, y = .data$group)) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey50") +
    ggplot2::geom_pointrange(ggplot2::aes(xmin = .data$Lower_CI, xmax = .data$Upper_CI),
                             colour = .pal3[1]) +
    ggplot2::labs(x = paste0("Concentration index (", df$Type[1], ", 95% CI)"), y = NULL) +
    (.theme_sncd())
}

#' @rdname autoplot.surveyncd
#' @exportS3Method ggplot2::autoplot
autoplot.surveyncd_curve <- function(object, ...) {
  by <- attr(object, "by")
  df <- as.data.frame(object)
  df$group <- if (is.null(by)) "All" else interaction(df[by], sep = " / ", drop = TRUE)
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$cum_population, y = .data$cum_outcome)) +
    ggplot2::geom_abline(slope = 1, intercept = 0, colour = "grey50", linetype = "dashed")
  if (is.null(by)) {
    p <- p + ggplot2::geom_line(colour = .pal3[1], linewidth = 0.8)
  } else {
    p <- p + ggplot2::geom_line(ggplot2::aes(colour = .data$group), linewidth = 0.8)
  }
  p + ggplot2::coord_equal() +
    ggplot2::scale_x_continuous(labels = .pct) + ggplot2::scale_y_continuous(labels = .pct) +
    ggplot2::labs(x = "Cumulative population, poorest to richest",
                  y = "Cumulative share of outcome", colour = NULL) +
    (.theme_sncd())
}

#' @rdname autoplot.surveyncd
#' @exportS3Method ggplot2::autoplot
autoplot.surveyncd_patterns <- function(object, ...) {
  df <- as.data.frame(object)
  df$combination <- factor(df$combination, rev(df$combination))
  ggplot2::ggplot(df, ggplot2::aes(x = .data$prevalence, y = .data$combination)) +
    ggplot2::geom_col(fill = .pal3[1], width = 0.6) +
    ggplot2::geom_errorbar(ggplot2::aes(xmin = .data$lower, xmax = .data$upper), width = 0.2,
                           orientation = "y", colour = "grey30") +
    ggplot2::scale_x_continuous(labels = .pct) +
    ggplot2::labs(x = "Prevalence of combination (95% CI)", y = NULL) +
    (.theme_sncd())
}
