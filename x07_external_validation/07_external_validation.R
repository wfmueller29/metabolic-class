# Externally Validate
# This will run everything in order

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  args[[1]] <- "../x07_external_validation/input/slam_age_all.yaml"
  warning("No input file provided, using: ", args[[1]])
}

args[[1]] <- normalizePath(args[[1]])
cat("This is our input file:", args[[1]], "\n")

# 01 -------------------------------------------------------------------------

setwd("../01_prep_model_data")
config <- yaml::read_yaml(args[[1]])
system2("Rscript", args = c("01_prep_model_data.R", args[[1]]))
setwd("../x07_external_validation")

# 04 -------------------------------------------------------------------------

input_04 <- normalizePath(
  paste0(file.path("../01_prep_model_data/output", config$out_tag), ".yaml")
)

setwd("../04_prediction_data")
system2("Rscript", args = c("create_prediction_data.R", input_04))
setwd("../x07_external_validation")

# 05 --------------------------------------------------------------------------
# for the case when we are not running with RStudio
if (!exists("params")) {
  params <- list()
  params$input_path <- "../04_prediction_data/output/external_validation.yaml"
  # params$input_path <- "../04_prediction_data/output/all.yaml"
  # params$input_path <- "../04_prediction_data/output/all_relative_age.yaml"
  # params$input_path <- "../04_prediction_data/output/test_relative_age.yaml"
}

input <- yaml::read_yaml(file = params$input_path)

# read in final models
model <- yaml::read_yaml(config$model$path)

# load datasets ---------------------------------------------------------------
load(input$datasets_path)
load(model$final_models_path)
config <- yaml::read_yaml(input$config_path)


# load in main_cat_surv
main_cat_surv <- read.csv(file = config$survival_dataset$path)
main_cat_surv <- as.data.frame(main_cat_surv)

final_models$dfs <- lapply(final_models$data, function(name) {
  datasets[[name]]$data
})


