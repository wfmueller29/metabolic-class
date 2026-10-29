# Reproduce entire analysis

# Preprocess  -----------------------------------------------------------------
ecode <- system2("Rscript", args = c("preprocess.R"))
if (ecode != 0) stop("Error in: preprocess.R")

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
  cat("Running:", yaml, "\n")
  ecode <- system2("Rscript", args = c("train.R", yaml))
  if (ecode != 0) stop(paste("Error in:", yaml))
}

# Validate  -------------------------------------------------------------------
yaml_files <- c(
  "inputs/validate/slam_c1-c10_x_slam_c16-c18.yaml",
  "inputs/validate/slam_c1-c10_x_slam_c16-c18_het3_bw.yaml"
)

for (yaml in yaml_files) {
  cat("Running:", yaml, "\n")
  ecode <- system2("Rscript", args = c("validate.R", yaml))
  if (ecode != 0) stop(paste("Error in:", yaml))
}

# Predict ---------------------------------------------------------------------
yaml_files <- c(
  "inputs/predict/itp_controls_p_treatment.yaml"
)

for (yaml in yaml_files) {
  cat("Running:", yaml, "\n")
  ecode <- system2("Rscript", args = c("predict.R", yaml))
  if (ecode != 0) stop(paste("Error in:", yaml))
}

# Downstream analyses ---------------------------------------------------------
analyses <- list(
  list(tag = "90_med_max_le",          dir = "90_med_max_le",          script = "med_max_le.R",           type = "source"),
  list(tag = "91_partial_correlation", dir = "91_partial_correlation", script = "partial_corr.R",         type = "source"),
  list(tag = "92_overlap_analysis",    dir = "92_overlap_analysis",    script = "overlap.R",              type = "source"),
  list(tag = "93_strain_analysis",     dir = "93_strain_analysis",     script = "strain_analysis.R",      type = "source"),
  list(tag = "94_jointlcm",            dir = "94_jointlcm",            script = "jointlcm.R",             type = "source"),
  list(tag = "95_healthcard_cod",      dir = "95_healthcard_cod/R",    script = "healthcard_cod.rmd",     type = "render"),
  list(tag = "96_similarity_slam_itp", dir = "96_similarity_slam_itp", script = "similarity_table.R",     type = "source"),
  list(tag = "97_treatment_response",  dir = "97_treatment_response",  script = "treatment_response.Rmd", type = "render"),
  list(tag = "98_prep_census",         dir = "98_itp_genotype",        script = "prep_census.R",          type = "source"),
  list(tag = "98_trajectory",          dir = "98_itp_genotype",        script = "trajectory.R",           type = "source"),
  list(tag = "98_geno_demographics",   dir = "98_itp_genotype",        script = "itp_geno_demographics_table.R", type = "source")
)

repo_root <- getwd()
for (a in analyses) {
  cat("Running:", a$tag, "\n")
  args <- if (identical(a$type, "render")) {
    c("-e", sprintf('rmarkdown::render("%s")', a$script))
  } else {
    a$script
  }
  setwd(file.path(repo_root, a$dir))
  ecode <- tryCatch(system2("Rscript", args = args), finally = setwd(repo_root))
  if (ecode != 0) stop(paste("Error in:", a$tag))
}

# Figures ---------------------------------------------------------------------
if (!dir.exists("figures/output")) dir.create("figures/output", recursive = TRUE)

setwd("99_pub_ready_figs/")
ecode <- system2("Rscript", "pub_ready_figs.R")
if (ecode != 0) stop(paste("Error in pub_ready_figs.R"))
setwd("..")

rmarkdown::render("figures/final_figure_deck.Rmd")
