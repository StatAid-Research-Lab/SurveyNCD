# Shared helpers for the SurveyNCD paper analyses (tables and figures).
suppressPackageStartupMessages({
  library(SurveyNCD)
  library(survey)
  library(ggplot2)
})
options(survey.lonely.psu = "adjust", width = 100)

out_dir <- file.path("analysis", "output")
dir.create(file.path(out_dir, "tables"),  recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(out_dir, "figures"), recursive = TRUE, showWarnings = FALSE)

# Validated categorical slots 1-3 (pass all-pairs CVD checks) + text inks
pal <- c(blue = "#2a78d6", orange = "#eb6834", aqua = "#1baf7a")
ink <- c(primary = "#0b0b0b", secondary = "#52514e", grid = "#e4e3df")

theme_paper <- function(base_size = 10) {
  theme_minimal(base_size = base_size) +
    theme(
      text             = element_text(colour = ink[["primary"]]),
      axis.text        = element_text(colour = ink[["secondary"]]),
      panel.grid.major = element_line(colour = ink[["grid"]], linewidth = 0.3),
      panel.grid.minor = element_blank(),
      legend.position  = "top",
      legend.title     = element_blank(),
      strip.text       = element_text(face = "bold", hjust = 0),
      plot.title       = element_text(face = "bold", size = base_size + 1),
      plot.caption     = element_text(colour = ink[["secondary"]], hjust = 0)
    )
}

save_fig <- function(p, name, width = 6.5, height = 3.8) {
  ggsave(file.path(out_dir, "figures", paste0(name, ".pdf")), p,
         width = width, height = height, device = grDevices::pdf)
  ggsave(file.path(out_dir, "figures", paste0(name, ".png")), p,
         width = width, height = height, dpi = 300, bg = "white")
  invisible(p)
}

# Write a table as CSV, Markdown and LaTeX (booktabs)
save_tab <- function(df, name, caption, digits = 3, align = NULL) {
  utils::write.csv(df, file.path(out_dir, "tables", paste0(name, ".csv")),
                   row.names = FALSE)
  md <- knitr::kable(df, format = "pipe", digits = digits, align = align,
                     caption = caption)
  writeLines(md, file.path(out_dir, "tables", paste0(name, ".md")))
  tex <- knitr::kable(df, format = "latex", booktabs = TRUE, digits = digits,
                      align = align, caption = caption, label = name,
                      linesep = "", escape = TRUE)
  writeLines(tex, file.path(out_dir, "tables", paste0(name, ".tex")))
  invisible(df)
}

pct <- function(x, d = 1) formatC(100 * x, format = "f", digits = d)
fmt_ci <- function(est, lo, hi, d = 1) sprintf("%s (%s, %s)", pct(est, d), pct(lo, d), pct(hi, d))
f3 <- function(x) formatC(x, format = "f", digits = 3)
