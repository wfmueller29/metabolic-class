# =============================================================================
# run_06_07.R -- run ONLY stages 06 then 07 for one config, using the
# reconstructed 05 yaml (from .A/make_05_yamls.R) + William's canonical data.
#
# Mirrors train.R's 06/07 blocks exactly. 06 reads the 05 yaml, writes its own
# 06 yaml; 07 reads that. Skips 01-05 (William's outputs are already in place).
#
# Usage (from repo root, renv active):
#   Rscript .A/run_06_07.R slam_c1-c10_age_all_bwfatgluc
# =============================================================================

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) stop("usage: Rscript .A/run_06_07.R <config_tag>")
tag  <- args[[1]]
repo <- normalizePath(".")

step <- function(label, expr) {
  cat("\n>>>>>", label, "(", format(Sys.time()), ")\n"); t0 <- Sys.time()
  force(expr)
  cat("     ->", label, "done (",
      round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), "min )\n")
}

# 06 -------------------------------------------------------------------------
step(paste("06 create_figures:", tag), {
  input_06 <- normalizePath(file.path("05_prediction_data/output", paste0(tag, ".yaml")))
  setwd(file.path(repo, "06_create_figures"))
  outdir <- file.path("output", tag); dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
  rmarkdown::render("06_create_figures.Rmd",
    output_dir = normalizePath(outdir), params = list(input_path = input_06))
  setwd(repo)
})

# 07 -------------------------------------------------------------------------
step(paste("07 display_figures:", tag), {
  input_07 <- normalizePath(file.path("06_create_figures/output", paste0(tag, ".yaml")))
  setwd(file.path(repo, "07_display_figures"))
  outdir <- file.path("output", tag); dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
  rmarkdown::render("07_display_figures.Rmd",
    output_dir = normalizePath(outdir), params = list(input_path = input_07))
  setwd(repo)
})

cat("\n=== DONE. 07 output: 07_display_figures/output/", tag, "/ ===\n", sep = "")
