# Reproduce the analysis from the CLEANED data onward (modeling -> figures).
#
# Assumes you have already run, IN ORDER:
#   01_installer.R   - install package dependencies
#   run/02_hydrate_data.R - provision raw data from the master (hydrate("raw"))
#   03_preprocess.R  - run all cleaning stages (00a / 00b / 00c)
# Cleaning is therefore NOT repeated here.

# Train  ----------------------------------------------------------------------
yaml_files <- c(
  "inputs/train/slam_c1-c10_age_all_bwfatgluc.yaml",
  "inputs/train/slam_c1-c10_age_b6_bwfatgluc.yaml",
  "inputs/train/slam_c1-c10_age_fb6_bwfatgluc.yaml",
  "inputs/train/slam_c1-c10_age_fhet3_bwfatgluc.yaml",
  "inputs/train/slam_c1-c10_age_mb6_bwfatgluc.yaml",
  "inputs/train/slam_c1-c10_age_mhet3_bwfatgluc.yaml",
  "inputs/train/slam_c1-c10_age_het3_bwfatgluc.yaml",
  "inputs/train/slam_c1-c10_age_het3_bw.yaml",
  "inputs/train/itp_c10c11c13c16_age_controls_bw.yaml",
  "inputs/train/itp_genotyped.yaml",
  "inputs/train/itp_genotyped_F.yaml",
  "inputs/train/itp_genotyped_M.yaml",
  "inputs/train/itp_genotyped_treat.yaml",
  "inputs/train/itp_genotyped_treat_F.yaml",
  "inputs/train/itp_genotyped_treat_M.yaml"
)

for (yaml in yaml_files) {
  cat("Running:", yaml, "\n")
  ecode <- system2("Rscript", args = c("helpers/train.R", yaml))
  if (ecode != 0) stop(paste("Error in:", yaml))
}

# Validate  -------------------------------------------------------------------
yaml_files <- c(
  "inputs/validate/slam_c1-c10_x_slam_c16-c18.yaml",
  "inputs/validate/slam_c1-c10_x_slam_c16-c18_het3_bw.yaml"
)

for (yaml in yaml_files) {
  cat("Running:", yaml, "\n")
  ecode <- system2("Rscript", args = c("helpers/validate.R", yaml))
  if (ecode != 0) stop(paste("Error in:", yaml))
}

# Predict ---------------------------------------------------------------------
yaml_files <- c(
  "inputs/predict/itp_controls_p_treatment.yaml"
)

for (yaml in yaml_files) {
  cat("Running:", yaml, "\n")
  ecode <- system2("Rscript", args = c("helpers/predict.R", yaml))
  if (ecode != 0) stop(paste("Error in:", yaml))
}

# Treatment Response ----------------------------------------------------------
rmarkdown::render("pipeline/99_treatment_response/treatment_response.Rmd")

# Figures are now a SEPARATE step -- run/05_render_figures.R (generates the
# pub-ready figure components via figures/R/pub_ready_figs.R, then renders
# primary + sup figures). Run it after this script.
