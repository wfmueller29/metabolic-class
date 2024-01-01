# Purpose: To create simulated data from the orginal datasets to test
# predictablilty of the models
# Author: William Mueller

library(tidyverse)

# take command line arguments for output tag ----------------------------------
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  out_tag <- "test_local"
} else {
  out_tag <- args[[1]]
}

# load in datasets and config -------------------------------------------------
path <- file.path("..", "02_prep_model_data", "output", out_tag)
load(file.path(path, "datasets.RDATA"))

config <- yaml::read_yaml("yaml/default.yaml")


# create df_list --------------------------------------------------------------

df_list <- list()

for (i in seq_along(datasets)) {
  dataset <- datasets[[i]]
  df_list[[i]] <- data.frame(dataset$data)
  names(df_list)[[i]] <- dataset$data_id
}

# filter by cumulative time window --------------------------------------------

source("R/source/filter_utils.R")
source("R/source/filter_cumulative.R")

datasets <- filter_cumulative_dataset(datasets)
datasets <- filter_cumulative_dataset(datasets, test_data = TRUE)

# filter by time window -------------------------------------------------------

source("R/source/filter_window.R")

datasets <- filter_window_dataset(datasets)
datasets <- filter_window_dataset(datasets, test_data = TRUE)

# filter by time interval -----------------------------------------------------

# Filter by time interval
source("R/source/filter_interval.R")

datasets <- filter_interval_dataset(datasets)
datasets <- filter_interval_dataset(datasets, test_data = TRUE)


# Decrease sample frequency ---------------------------------------------------
source("R/source/resample_frequency.R")

datasets <- resample_frequency_dataset(datasets)

# save our datasets -----------------------------------------------------------

out_dir <- file.path("output", out_tag)
dir.create(out_dir)
path <- file.path(out_dir, "datasets.RDATA")
save(datasets, file = path)
