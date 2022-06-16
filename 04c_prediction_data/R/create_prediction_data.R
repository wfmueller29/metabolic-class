# Purpose: To create simulated data from the orginal datasets to test
# predictablilty of the models
# Author: William Mueller

library(tidyverse)

config <- yaml::read_yaml("yaml/default.yaml")

load("../02_prep_model_data/output/df_list.RDATA")

subsets <- lapply(config$subsets, unlist, use.names = TRUE)

# Filter by sex and strain
source("R/filter_group.R")
df_subset_list <- lapply(df_list, filter_loop, subsets = subsets)
# df_subset_list <- unlist_filter_list(df_subset_list)

intervals <- lapply(config$intervals, unlist, use.names = TRUE)

# Filter by time interval
source("R/filter_interval.R")
df_interval_list <- lapply(df_list,
  filter_interval_loop,
  intervals = intervals
)
# df_interval_list <- unlist_filter_list(df_interval_list)

ns <- lapply(config$samples, unlist, use.names = TRUE)

# Filter by measurement sample
source("R/sample_measures.R")
df_sample_list <- lapply(df_list,
  sample_loop,
  n = ns
)
# df_sample_list <- unlist_filter_list(df_sample_list)

# Find threshold
threshold_intervals <- lapply(20:150, function(thresh) {
  interval <- paste0("(0,", thresh, "]")
  names(interval) <- "age_wk"
  interval
})
df_threshold_list <- lapply(df_list,
  filter_interval_loop,
  intervals = threshold_intervals
)
# df_threshold_list <- unlist_filter_list(df_threshold_list)


dfs_prediction <- list(
  main = df_list,
  subset = df_subset_list,
  interval = df_interval_list,
  threshold = df_threshold_list,
  sample = df_sample_list
)

save(dfs_prediction, file = "output/dfs_prediction.RDATA")
