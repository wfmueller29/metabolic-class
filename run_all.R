# This will run everything in order

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  args[[1]] <- "01_prep_model_data/input/test_local.yaml"
  warning("No input file provided, using: ", args[[1]])
}

args[[1]] <- normalizePath(args[[1]])

setwd("01_prep_model_data")
config <- yaml::read_yaml(args[[1]])
system2("Rscript", args = c("01_prep_model_data.R", args[[1]]))
setwd("..")

input_02 <- normalizePath(
  paste0(file.path("01_prep_model_data/output", config$out_tag), ".yaml")
)

setwd("02_model")
system2("Rscript", args = c("model.R", input_02))
setwd("..")
