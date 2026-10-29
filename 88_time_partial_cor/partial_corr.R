# Create a partial correlation analysis
library(consoler)
library(ppcor)
library(qgraph)
library(gridExtra)
library(grid)
library(consoler)


source("R/run_partial_correlation.R")

# fat -------------------------------------------------------------------------
keep_vars_fat <- c(
  "Lifespan" = "le_wk",
  "Female" = "sex_F",
  "B6" = "strain_B6",
  "Early-peak BW" = "prob1",
  "Early-peak FM" = "prob4",
  "Decline FBG" = "prob7"
)

early_fat_results <- run_partial_correlation(
  census_path = paste0(
    "../06_create_figures/output/",
    "slam_c1-c10_age_all_bwfatgluc/",
    "interval_data/(0, 57.50).csv"
  ),
  analysis_name = "early_fat",
  keep_vars = keep_vars_fat,
  output_dir = "output",
  minimum = 0.05,
  network_title = "Partial Correlation Network FM Early Life",
  table_title = "Partial Correlation Coefficients FM Early Life"
)

mid_fat_results <- run_partial_correlation(
  census_path = paste0(
    "../06_create_figures/output/",
    "slam_c1-c10_age_all_bwfatgluc/",
    "interval_data/[57.50,86.25).csv"
  ),
  analysis_name = "mid_fat",
  keep_vars = keep_vars_fat,
  output_dir = "output",
  minimum = 0.05,
  network_title = "Partial Correlation Network FM Mid Life",
  table_title = "Partial Correlation Coefficients FM Mid Life"
)

mid_late_fat_results <- run_partial_correlation(
  census_path = paste0(
    "../06_create_figures/output/",
    "slam_c1-c10_age_all_bwfatgluc/",
    "interval_data/[57.50,103.50].csv"
  ),
  analysis_name = "mid_late_fat",
  keep_vars = keep_vars_fat,
  output_dir = "output",
  minimum = 0.05,
  network_title = "Partial Correlation Network FM Mid+Late Life",
  table_title = "Partial Correlation Coefficients FM Mid+Late Life"
)

late_fat_results <- run_partial_correlation(
  census_path = paste0(
    "../06_create_figures/output/",
    "slam_c1-c10_age_all_bwfatgluc/",
    "interval_data/[86.25,103.50).csv"
  ),
  analysis_name = "late_fat",
  keep_vars = keep_vars_fat,
  output_dir = "output",
  minimum = 0.05,
  network_title = "Partial Correlation Network FM Late Life",
  table_title = "Partial Correlation Coefficients FM Late Life"
)


end_fat_results <- run_partial_correlation(
  census_path = paste0(
    "../06_create_figures/output/",
    "slam_c1-c10_age_all_bwfatgluc/",
    "interval_data/[103.50,Inf).csv"
  ),
  analysis_name = "end_fat",
  keep_vars = keep_vars_fat,
  output_dir = "output",
  minimum = 0.05,
  network_title = "Partial Correlation Network FM End of Life",
  table_title = "Partial Correlation Coefficients FM End of Life"
)


# adiposity -------------------------------------------------------------------------
keep_vars_adiposity <- c(
  "Lifespan" = "le_wk",
  "Female" = "sex_F",
  "B6" = "strain_B6",
  "Early-peak BW" = "prob1",
  "Early-peak Adiposity" = "prob4",
  "Decline FBG" = "prob7"
)

early_adiposity_results <- run_partial_correlation(
  census_path = paste0(
    "../06_create_figures/output/",
    "slam_c1-c10_age_all_bwadipositygluc/",
    "interval_data/(0, 57.50).csv"
  ),
  analysis_name = "early_adiposity",
  keep_vars = keep_vars_adiposity,
  output_dir = "output",
  minimum = 0.05,
  network_title = "Partial Correlation Network Adiposity Early Life",
  table_title = "Partial Correlation Coefficients Adiposity Early Life"
)

mid_adiposity_results <- run_partial_correlation(
  census_path = paste0(
    "../06_create_figures/output/",
    "slam_c1-c10_age_all_bwadipositygluc/",
    "interval_data/[57.50,86.25).csv"
  ),
  analysis_name = "mid_adiposity",
  keep_vars = keep_vars_adiposity,
  output_dir = "output",
  minimum = 0.05,
  network_title = "Partial Correlation Network Adiposity Mid Life",
  table_title = "Partial Correlation Coefficients Adiposity Mid Life"
)

mid_late_adiposity_results <- run_partial_correlation(
  census_path = paste0(
    "../06_create_figures/output/",
    "slam_c1-c10_age_all_bwadipositygluc/",
    "interval_data/[57.50,103.50].csv"
  ),
  analysis_name = "mid_late_adiposity",
  keep_vars = keep_vars_adiposity,
  output_dir = "output",
  minimum = 0.05,
  network_title = "Partial Correlation Network Adiposity Mid+Late Life",
  table_title = "Partial Correlation Coefficients Adiposity Mid+Late Life"
)

late_adiposity_results <- run_partial_correlation(
  census_path = paste0(
    "../06_create_figures/output/",
    "slam_c1-c10_age_all_bwadipositygluc/",
    "interval_data/[86.25,103.50).csv"
  ),
  analysis_name = "late_adiposity",
  keep_vars = keep_vars_adiposity,
  output_dir = "output",
  minimum = 0.05,
  network_title = "Partial Correlation Network Adiposity Late Life",
  table_title = "Partial Correlation Coefficients Adiposity Late Life"
)


end_adiposity_results <- run_partial_correlation(
  census_path = paste0(
    "../06_create_figures/output/",
    "slam_c1-c10_age_all_bwadipositygluc/",
    "interval_data/[103.50,Inf).csv"
  ),
  analysis_name = "end_adiposity",
  keep_vars = keep_vars_adiposity,
  output_dir = "output",
  minimum = 0.05,
  network_title = "Partial Correlation Network Adiposity End of Life",
  table_title = "Partial Correlation Coefficients Adiposity End of Life"
)
