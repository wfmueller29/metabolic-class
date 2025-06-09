# This file will create prediction for external data

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  # args[[1]] <- "inputs/predict/slam_c1-c10_p_slam_c16-c18.yaml"
  args[[1]] <- "inputs/predict/itp_controls_p_treatment.yaml"
  warning("No input file provided, using: ", args[[1]])
}

args[[1]] <- normalizePath(args[[1]])
cat("This is our input file:", args[[1]], "\n")

# 01 -------------------------------------------------------------------------

setwd("01_prep_model_data")
config <- yaml::read_yaml(args[[1]])
exit_code <- system2("Rscript", args = c("01_prep_model_data.R", args[[1]]))
if (exit_code != 0) stop("Error was thrown from system2 command")
setwd("..")

# 04 -------------------------------------------------------------------------

input_04 <- normalizePath(
  paste0(file.path("01_prep_model_data/output", config$out_tag), ".yaml")
)

setwd("04_create_census")
exit_code <- system2("Rscript", args = c("create_census.R", input_04))
if (exit_code != 0) stop("Error was thrown from system2 command")
setwd("..")

beepr::beep()
