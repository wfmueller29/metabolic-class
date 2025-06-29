# Reproduce figures

# Run 3-7  --------------------------------------------------------------------
yaml_files <- c(
  "inputs/train/slam_c1-c10_age_all_bwfatgluc.yaml",
  "inputs/train/slam_c1-c10_age_fb6_bwfatgluc.yaml",
  "inputs/train/slam_c1-c10_age_fhet3_bwfatgluc.yaml",
  "inputs/train/slam_c1-c10_age_mb6_bwfatgluc.yaml",
  "inputs/train/slam_c1-c10_age_mhet3_bwfatgluc.yaml",
  "inputs/train/slam_c1-c10_age_het3_bwfatgluc.yaml",
  "inputs/train/slam_c1-c10_age_het3_bw.yaml",
  "inputs/train/itp_c10c11c13c16_age_controls_bw.yaml",
  "inputs/validate/slam_c1-c10_x_slam_c16-c18.yaml",
  "inputs/validate/slam_c1-c10_x_slam_c16-c18_het3_bw.yaml"
)

for (yaml in yaml_files) {
  cat("Running:", yaml, "\n")
  ecode <- system2("Rscript", args = c("run_7.R", yaml))
  if (ecode != 0) stop(paste("Error in:", yaml))
}

# Treatment Response ----------------------------------------------------------
rmarkdown::render("99_treatment_response/treatment_response.Rmd")

# Figures ---------------------------------------------------------------------
rmarkdown::render("figures/primary_figures.Rmd",
  output_format = "pdf_document",
  output_dir = "figures/output",
  output_file = "Primary Figures.pdf"
)
rmarkdown::render("figures/sup_figures.Rmd",
  output_format = "pdf_document",
  output_dir = "figures/output",
  output_file = "Supplemental Material.pdf"
)
