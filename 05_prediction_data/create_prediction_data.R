# Purpose: To create simulated data from the orginal datasets to test
# predictablilty of the models
# Author: William Mueller

library(tidyverse)


# take command line arguments for output tag ----------------------------------
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  input_path <- "../04_create_census/output/test_local.yaml"
  warning("Using default input file: ", input_path)
} else {
  input_path <- args[[1]]
}

input <- yaml::read_yaml(file = input_path)

# load in datasets and config -------------------------------------------------
load(input$datasets_path)

# create df_list --------------------------------------------------------------

df_list <- list()

for (i in seq_along(datasets)) {
  dataset <- datasets[[i]]
  df_list[[i]] <- data.frame(dataset$data)
  names(df_list)[[i]] <- dataset$data_id
}

# filter by cumulative time window --------------------------------------------

source("R/filter_utils.R")
source("R/filter_cumulative.R")

datasets <- filter_cumulative_dataset(datasets)
datasets <- filter_cumulative_dataset(datasets, test_data = TRUE)

# filter by time window -------------------------------------------------------

source("R/filter_window.R")

datasets <- filter_window_dataset(datasets)
datasets <- filter_window_dataset(datasets, test_data = TRUE)

# filter by time interval -----------------------------------------------------

# Filter by time interval
source("R/filter_interval.R")

datasets <- filter_interval_dataset(datasets)
datasets <- filter_interval_dataset(datasets, test_data = TRUE)


# Decrease sample frequency ---------------------------------------------------
source("R/resample_frequency.R")

datasets <- resample_frequency_dataset(datasets)

# save our datasets -----------------------------------------------------------
config <- yaml::read_yaml(file = input$config_path)

output_dir_path <- file.path("output", config$out_tag)
dir.create(output_dir_path)
output_dir_path <- normalizePath(output_dir_path)
datasets_path <- file.path(output_dir_path, "datasets.RDATA")

save(datasets, file = datasets_path)

# create output file ----------------------------------------------------------
input_path <- normalizePath(input_path)

output_list <- list(
  data_time = format(Sys.time()),
  working_directory = getwd(),
  config_path = input$config_path,
  input_path = input_path,
  output_dir_path = output_dir_path,
  datasets_path = datasets_path,
  models_path = input$models_path,
  cf_path = input$cf_path,
  final_models_path = input$final_models_path,
  csv_path = input$csv_path
)

output_list_path <- paste0(file.path("output", config$out_tag), ".yaml")
yaml::write_yaml(x = output_list, file = output_list_path)
