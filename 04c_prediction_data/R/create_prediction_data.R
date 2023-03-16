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

# Filter by sex and strain ----------------------------------------------------
source("R/source/filter_utils.R")
source("R/source/filter_group.R")

subsets <- lapply(config$subsets, unlist, use.names = TRUE)

df_subset_list <- lapply(df_list, filter_loop, subsets = subsets)
# df_subset_list <- unlist_filter_list(df_subset_list)

# filter by cumulative time window --------------------------------------------

source("R/source/filter_cumulative.R")
df_cumulative_list <- filter_cumulative(data_list = df_list,
                       age_var = "age_wk_ns",
                       start_vector = c(0, 25, 50),
                       end = 165,
                       step = 25)

# filter by time window -------------------------------------------------------

source("R/source/filter_window.R")
df_window_list <- filter_window(data_list = df_list,
                                age_var = "age_wk_ns",
                                start = 0,
                                end = 165,
                                window_size_vector = c(25, 50),
                                step = 10)

# filter by time interval -----------------------------------------------------
intervals <- lapply(config$intervals, unlist, use.names = TRUE)

# Filter by time interval
source("R/source/filter_interval.R")
df_interval_list <- lapply(df_list,
  filter_interval_loop,
  intervals = intervals
)
# df_interval_list <- unlist_filter_list(df_interval_list)

# old way of filtering time window --------------------------------------------

windows <- lapply(config$windows, unlist, use.names = TRUE)

# Filter by time interval
source("R/source/filter_interval.R")
df_windows_list <- lapply(df_list,
  filter_interval_loop,
  intervals = windows
)
# df_interval_list <- unlist_filter_list(df_interval_list)


# filter by measurement sample ------------------------------------------------

ns <- lapply(config$samples, unlist, use.names = TRUE)

# Filter by measurement sample
source("R/source/sample_measures.R")
df_sample_list <- lapply(df_list,
  sample_loop,
  n = ns
)
# df_sample_list <- unlist_filter_list(df_sample_list)


# threshold filtering ---------------------------------------------------------

# Threshold timepoint
threshold <- lapply(config$threshold, unlist, use.names = TRUE)

# Filter by time interval
source("R/source/filter_interval.R")
df_threshold_list <- lapply(df_list,
  filter_interval_loop,
  intervals = threshold
)


dfs_prediction <- list(
  main = df_list,
  subset = df_subset_list,
  interval = df_interval_list,
  window = df_windows_list,
  threshold = df_threshold_list,
  sample = df_sample_list
)

# save our prediction dataframe -----------------------------------------------
save(dfs_prediction, file = "output/dfs_prediction.RDATA")
