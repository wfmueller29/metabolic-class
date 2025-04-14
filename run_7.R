# This will run just the 07_display_figures
# this is for running 6

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  args[[1]] <- "01_prep_model_data/input/test_local.yaml"
  warning("No input file provided, using: ", args[[1]])
}

args[[1]] <- normalizePath(args[[1]])
cat("This is our input file:", args[[1]], "\n")
config <- yaml::read_yaml(args[[1]])

# 07 --------------------------------------------------------------------------
input_07 <- normalizePath(
  paste0(file.path("07_create_figures/output", config$out_tag), ".yaml")
)

setwd("07_display_figures")
output_dir <- normalizePath(file.path("output", config$out_tag))
rmarkdown::render("07_display_figures.Rmd",
  output_dir = output_dir, params = list(input_path = input_07)
)
setwd("..")

beepr::beep()
