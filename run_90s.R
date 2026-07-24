# run_90s.R -- run the 90-99 downstream analyses sequentially, on their own.
#
#   Rscript run_90s.R
#
# Mirrors the analyses block in reproduce.R, but stands alone: it assumes 01-07
# have already produced their outputs (or William's frozen 01-05 + a local 06/07
# run are in place). 99_pub_ready_figs runs LAST -- it reads the PNGs/objects the
# earlier stages and 07 produced.
#
# Each stage runs as its OWN Rscript process. That Rscript is launched from the
# REPO ROOT (so the root .Rprofile activates renv) and setwd()s into the stage
# dir itself -- launching Rscript from inside the stage dir would miss renv and
# fail with "no package called ...". Stages are isolated from each other, so one
# crash cannot corrupt another's environment.
#
# Continue-on-failure: a stage that errors is logged and the run continues, with
# a PASS/FAIL summary at the end and a non-zero exit if anything failed. Some
# stages legitimately fail without the right inputs (e.g. 93_strain_analysis and
# 96_similarity need strain-pooled runs; 95/98 need hand-dropped raw files) --
# this lets the rest proceed instead of halting on the first gap.

analyses <- list(
  list(tag = "90_med_max_le",          dir = "90_med_max_le",          script = "med_max_le.R",           type = "source"),
  list(tag = "91_partial_correlation", dir = "91_partial_correlation", script = "partial_corr.R",         type = "source"),
  list(tag = "92_overlap_analysis",    dir = "92_overlap_analysis",    script = "overlap.R",              type = "source"),
  list(tag = "93_strain_analysis",     dir = "93_strain_analysis",     script = "strain_analysis.R",      type = "source"),
  # 94_jointlcm is deliberately SKIPPED here. It re-fits Jointlcmm (joint latent
  # class) models, which are optimizer/OS-sensitive and would drift from the
  # published S4 figure on a different machine. The canonical joint-LCM result
  # was produced on Billy's machine with his seeding; use that output rather than
  # re-running it here.
  # list(tag = "94_jointlcm",          dir = "94_jointlcm",            script = "jointlcm.R",             type = "source"),
  list(tag = "95_healthcard_cod",      dir = "95_healthcard_cod/R",    script = "healthcard_cod.rmd",     type = "render"),
  list(tag = "96_similarity_slam_itp", dir = "96_similarity_slam_itp", script = "similarity_table.R",     type = "source"),
  list(tag = "97_treatment_response",  dir = "97_treatment_response",  script = "treatment_response.Rmd", type = "render"),
  list(tag = "98_prep_census",         dir = "98_itp_genotype",        script = "prep_census.R",          type = "source"),
  list(tag = "98_trajectory",          dir = "98_itp_genotype",        script = "trajectory.R",           type = "source"),
  # S9C class-demographics table. Reads the censuses prep_census.R wrote into
  # output/; independent of trajectory.R. Feeds figure_spec's itp_geno_demographics.png.
  list(tag = "98_geno_demographics",   dir = "98_itp_genotype",        script = "itp_geno_demographics_table.R", type = "source"),
  list(tag = "99_pub_ready_figs",      dir = "99_pub_ready_figs",      script = "pub_ready_figs.R",       type = "source")
)

# Launch one stage in its own Rscript, started at the repo root (renv), then
# setwd() into the stage dir. Returns the process exit code.
run_stage <- function(a) {
  expr <- if (identical(a$type, "render")) {
    sprintf("setwd('%s'); rmarkdown::render('%s')", a$dir, a$script)
  } else {
    sprintf("setwd('%s'); source('%s')", a$dir, a$script)
  }
  system2("Rscript", args = c("-e", shQuote(expr)))
}

failed <- character(0)
for (a in analyses) {
  cat("\n>>>>> ", a$tag, "  (", format(Sys.time()), ")\n", sep = "")
  code <- tryCatch(run_stage(a), error = function(e) { message(conditionMessage(e)); 1L })
  if (identical(code, 0L)) {
    cat("      -> PASS: ", a$tag, "\n", sep = "")
  } else {
    cat("      -> FAIL: ", a$tag, " (exit ", code, ")\n", sep = "")
    failed <- c(failed, a$tag)
  }
}

cat("\n", strrep("=", 60), "\n", sep = "")
if (length(failed)) {
  cat(length(failed), " of ", length(analyses), " stages FAILED:\n", sep = "")
  cat(paste0("  ", failed), sep = "\n"); cat("\n")
  quit(status = 1)
} else {
  cat("all ", length(analyses), " stages PASSED\n", sep = "")
}
