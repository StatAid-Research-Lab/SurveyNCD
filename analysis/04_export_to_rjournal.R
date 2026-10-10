# Copy figures and tables from analysis/output/ into rjournal/ for the article.
# Run from the package source root after run_all.R:  Rscript analysis/04_export_to_rjournal.R
figs <- c("workflow", "mm_by_wealth", "concentration_indices", "region_map",
          "shap_summary", "simulation_coverage")
dir.create("rjournal/figures", showWarnings = FALSE, recursive = TRUE)
dir.create("rjournal/tables",  showWarnings = FALSE, recursive = TRUE)
for (f in figs) file.copy(file.path("analysis/output/figures", paste0("fig_", f, ".pdf")),
                          "rjournal/figures", overwrite = TRUE)
size <- c(tab_simulation = "\\scriptsize\\setlength{\\tabcolsep}{3pt}",
          tab_validation_rineq = "\\scriptsize\\setlength{\\tabcolsep}{3pt}",
          tab_anthropometry = "\\footnotesize\\setlength{\\tabcolsep}{3pt}")
tabs <- c("tab_dataset", "tab_condition_prevalence", "tab_multimorbidity", "tab_anthropometry",
          "tab_concentration_indices", "tab_validation_rineq", "tab_validation_ties", "tab_simulation")
for (t in tabs) {
  s <- paste(readLines(file.path("analysis/output/tables", paste0(t, ".tex"))), collapse = "\n")
  s <- sub("\\begin{table}", "\\begin{table}[htbp]", s, fixed = TRUE)
  s <- sub("\\centering", paste0("\\centering\n", if (t %in% names(size)) size[[t]] else "\\small"), s, fixed = TRUE)
  s <- sub("\\begin{tabular}[t]", "\\begin{adjustbox}{max width=\\linewidth}\n\\begin{tabular}", s, fixed = TRUE)
  s <- sub("\\end{tabular}", "\\end{tabular}\n\\end{adjustbox}", s, fixed = TRUE)
  writeLines(s, file.path("rjournal/tables", paste0(t, ".tex")))
}
message("Copied ", length(figs), " figures and ", length(tabs), " tables to rjournal/.")
