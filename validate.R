# This script will call the external validate file
# Externally Validate
# This will run everything in order

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  args[[1]] <- "x01_external_validation/input/slam_age_all.yaml"
  warning("No input file provided, using: ", args[[1]])
}

args[[1]] <- normalizePath(args[[1]])
cat("This is our input file:", args[[1]], "\n")

# 01 -------------------------------------------------------------------------

setwd("01_prep_model_data")
config <- yaml::read_yaml(args[[1]])
system2("Rscript", args = c("01_prep_model_data.R", args[[1]]))
setwd("..")

# 04 -------------------------------------------------------------------------

input_04 <- normalizePath(
  paste0(file.path("03_model_select/output", config$out_tag), ".yaml")
)

setwd("04_create_census")
system2("Rscript", args = c("create_census.R", input_04))
setwd("..")

# 05 -------------------------------------------------------------------------

input_05 <- normalizePath(
  paste0(file.path("04_create_census/output", config$out_tag), ".yaml")
)

setwd("05_prediction_data")
system2("Rscript", args = c("create_prediction_data.R", input_05))
setwd("..")

# 06 -------------------------------------------------------------------------

input_06 <- normalizePath(
  paste0(file.path("05_prediction_data/output", config$out_tag), ".yaml")
)

setwd("06_create_figures")
output_dir <- normalizePath(file.path("output", config$out_tag))
rmarkdown::render("06_create_figures.Rmd",
  output_dir = output_dir, params = list(input_path = input_06)
)
setwd("..")

# 07 --------------------------------------------------------------------------
input_07 <- normalizePath(
  paste0(file.path("06_create_figures/output", config$out_tag), ".yaml")
)

setwd("07_display_figures")
output_dir <- normalizePath(file.path("output", config$out_tag))
rmarkdown::render("07_display_figures.Rmd",
  output_dir = output_dir, params = list(input_path = input_07)
)
setwd("..")

beepr::beep()
