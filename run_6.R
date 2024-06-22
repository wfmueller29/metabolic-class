# This will run just the 06_display_figures
# this is for running 4-5

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  args[[1]] <- "01_prep_model_data/input/test_local.yaml"
  warning("No input file provided, using: ", args[[1]])
}

args[[1]] <- normalizePath(args[[1]])
cat("This is our input file:", args[[1]], "\n")
config <- yaml::read_yaml(args[[1]])

# 06 --------------------------------------------------------------------------
input_06 <- normalizePath(
  paste0(file.path("05_figures/output", config$out_tag), ".yaml")
)

setwd("06_display_figures")
output_dir <- normalizePath(file.path("output", config$out_tag))
rmarkdown::render("06_display_figures.Rmd",
  output_dir = output_dir, params = list(input_path = input_06)
)
setwd("..")
