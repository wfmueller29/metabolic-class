# This will run everything in order

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  args[[1]] <- "01_prep_model_data/input/test_local.yaml"
  warning("No input file provided, using: ", args[[1]])
}

args[[1]] <- normalizePath(args[[1]])
cat("This is our input file:", args[[1]], "\n")

# 01 -------------------------------------------------------------------------

setwd("01_prep_model_data")
config <- yaml::read_yaml(args[[1]])
system2("Rscript", args = c("01_prep_model_data.R", args[[1]]))
setwd("..")

# 02 -------------------------------------------------------------------------

input_02 <- normalizePath(
  paste0(file.path("01_prep_model_data/output", config$out_tag), ".yaml")
)

setwd("02_model")
system2("Rscript", args = c("model.R", input_02))
setwd("..")

# 03 -------------------------------------------------------------------------

input_03 <- normalizePath(
  paste0(file.path("02_model/output", config$out_tag), ".yaml")
)

setwd("03_model_select")
output_dir <- normalizePath(file.path("output", config$out_tag))
rmarkdown::render("03_model_select.Rmd",
  output_dir = output_dir, params = list(input_path = input_03)
)
setwd("..")

# 04 -------------------------------------------------------------------------

input_04 <- normalizePath(
  paste0(file.path("03_model_select/output", config$out_tag), ".yaml")
)

setwd("04_prediction_data")
system2("Rscript", args = c("create_prediction_data.R", input_04))
setwd("..")

# 05 -------------------------------------------------------------------------

input_05 <- normalizePath(
  paste0(file.path("04_prediction_data/output", config$out_tag), ".yaml")
)

setwd("05_figures")
output_dir <- normalizePath(file.path("output", config$out_tag))
rmarkdown::render("05_figures.Rmd",
  output_dir = output_dir, params = list(input_path = input_05)
)
setwd("..")

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
