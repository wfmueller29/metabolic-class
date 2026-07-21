# Reproduce entire analysis

# Run timing ------------------------------------------------------------------
# Each step's start/end/duration is appended to run_records/run_log.csv AS THE
# RUN PROCEEDS -- timing has to be captured during the run, since nothing at the
# end can reconstruct when each step began. session_info.R summarizes this into a
# timestamped run_timing record. This raw log is rewritten fresh each run (and is
# gitignored), but is appended to incrementally, so it survives a step failing
# partway through.
dir.create("run_records", showWarnings = FALSE)
RUN_LOG <- file.path("run_records", "run_log.csv")
writeLines("step,start,end,minutes,status", RUN_LOG)

run_step <- function(label, expr) {
  cat("\n>>>>> ", label, "  (", format(Sys.time()), ")\n", sep = "")
  t0 <- Sys.time()
  status <- tryCatch({ expr; "OK" },
                     error = function(e) paste0("FAILED: ", conditionMessage(e)))
  t1 <- Sys.time()
  mins <- as.numeric(difftime(t1, t0, units = "mins"))
  cat(sprintf('"%s","%s","%s",%.2f,"%s"\n',
              label, format(t0), format(t1), mins, status),
      file = RUN_LOG, append = TRUE)
  cat(sprintf("      -> %s (%.1f min)\n", status, mins))
  if (!identical(status, "OK")) stop("Error in: ", label, " -- ", status)
  invisible(TRUE)
}

# Preprocess  -----------------------------------------------------------------
run_step("preprocess", {
  ecode <- system2("Rscript", args = c("preprocess.R"))
  if (ecode != 0) stop("exit code ", ecode)
})

# Train  ----------------------------------------------------------------------
yaml_files <- c(
  "inputs/train/slam_c1-c10_age_all_bwfatgluc.yaml",
  "inputs/train/slam_c1-c10_age_all_bwadipositygluc.yaml",
  "inputs/train/slam_c1-c10_age_fb6_bwfatgluc.yaml",
  "inputs/train/slam_c1-c10_age_fhet3_bwfatgluc.yaml",
  "inputs/train/slam_c1-c10_age_mb6_bwfatgluc.yaml",
  "inputs/train/slam_c1-c10_age_mhet3_bwfatgluc.yaml",
  "inputs/train/itp_c10c11c13c16_age_controls_bw.yaml",
  "inputs/train/itp_genotyped.yaml",
  "inputs/train/itp_genotyped_F.yaml",
  "inputs/train/itp_genotyped_M.yaml",
  "inputs/train/itp_genotyped_treat.yaml",
  "inputs/train/itp_genotyped_treat_F.yaml",
  "inputs/train/itp_genotyped_treat_M.yaml"
)

for (yaml in yaml_files) {
  run_step(paste("train:", basename(yaml)), {
    ecode <- system2("Rscript", args = c("train.R", yaml))
    if (ecode != 0) stop("exit code ", ecode)
  })
}

# Validate  -------------------------------------------------------------------
yaml_files <- c(
  "inputs/validate/slam_c1-c10_x_slam_c16-c18.yaml",
  "inputs/validate/slam_c1-c10_x_slam_c16-c18_het3_bw.yaml"
)

for (yaml in yaml_files) {
  run_step(paste("validate:", basename(yaml)), {
    ecode <- system2("Rscript", args = c("validate.R", yaml))
    if (ecode != 0) stop("exit code ", ecode)
  })
}

# Predict ---------------------------------------------------------------------
yaml_files <- c(
  "inputs/predict/itp_controls_p_treatment.yaml"
)

for (yaml in yaml_files) {
  run_step(paste("predict:", basename(yaml)), {
    ecode <- system2("Rscript", args = c("predict.R", yaml))
    if (ecode != 0) stop("exit code ", ecode)
  })
}

# Treatment Response ----------------------------------------------------------
run_step("treatment_response", {
  rmarkdown::render("99_treatment_response/treatment_response.Rmd")
})

# Figures ---------------------------------------------------------------------
run_step("figures: primary", {
  rmarkdown::render("figures/primary_figures.Rmd",
    output_format = "pdf_document",
    output_dir = "figures/output",
    output_file = "Primary Figures.pdf"
  )
})
run_step("figures: supplemental", {
  rmarkdown::render("figures/sup_figures.Rmd",
    output_format = "pdf_document",
    output_dir = "figures/output",
    output_file = "Supplemental Material.pdf"
  )
})

# Session info ----------------------------------------------------------------
# Record the environment that produced this run (R build, architecture, BLAS,
# package versions + in-house commit SHAs) and summarize run_records/run_log.csv into
# run_timing.txt. renv pins packages but cannot pin the numerical stack, and LCMM
# class assignments are sensitive to it -- so this is the provenance record that
# ties results to the environment that made them.
# A failure here must not invalidate a completed run, so it only warns.
# (If an earlier step fails, run `Rscript session_info.R` by hand -- run_records/run_log.csv
#  is written incrementally and will contain everything up to the failure.)
ecode <- system2("Rscript", args = c("session_info.R"))
if (ecode != 0) warning("session_info.R failed -- no environment record written")
