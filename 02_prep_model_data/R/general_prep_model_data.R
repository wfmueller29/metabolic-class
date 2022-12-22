# Author: William Mueller
# Purpose: The purpose of this file is to prep the datasets that were used for
# the previous glucose paper so they can be modeled
# We also removed outliers based upon outcome velocity
# We are trying to generalize the trajectories pipeline to other datasets

library(tidyverse)
library(helphlme)

# load in config
config <- yaml::read_yaml("yaml/default.yaml")

# load in data using file path ------------------------------------------------
datasets <- yaml::read_yaml("yaml/test.yaml")

get_extension <- function(datasets) {
  datasets <- lapply(datasets, function(dataset) {
    data_path <- file.path(dataset$path)
    ext <- tools::file_ext(data_path)
    dataset$ext <- ext
    dataset
  })
}

datasets <- get_extension(datasets)

read_data <- function(datasets) {
  datasets <- lapply(datasets, function(dataset) {
    if (dataset$ext == "RDATA") {
      dataset$data <- read_rdata(dataset$path)
    } else if (dataset$ext == "csv") {
      dataset$data <- read.csv(dataset$path)
    }
    dataset
  })
}

read_rdata <- function(fileName) {
  # loads an RData file, and returns it
  load(fileName)
  get(ls()[ls() != "fileName"])
}

datasets <- read_data(datasets)


# convert all variables to correct type ---------------------------------------

convert_variables <- function(datasets) {
  datasets <- lapply(datasets, function(dataset) {
    dataset <- convert_numeric(dataset)
    dataset <- convert_age(dataset)
    dataset <- convert_dummy(dataset)
    dataset <- convert_factor(dataset)
    dataset
  })
  datasets
}

convert_numeric <- function(dataset) {
  numeric_cols <- c(dataset$numeric)

  dataset$data[, numeric_cols] <- lapply(numeric_cols, function(col) {
    as.numeric(dataset$data[, col])
  })

  dataset
}

convert_factor <- function(dataset) {
  factor_cols <- c(dataset$factor)

  dataset$data[, factor_cols] <- lapply(factor_cols, function(col) {
    as.factor(dataset$data[, col])
  })

  dataset
}

convert_dummy <- function(dataset) {
  dummy_cols <- c(dataset$dummy)

  dataset$data <- fastDummies::dummy_cols(dataset$data, dummy_cols)
  dataset
}

convert_age <- function(dataset) {
  age_cols <- c(dataset$age_var)
  age_cols2 <- paste0(age_cols, "2")

  dataset$data[, age_cols2] <- lapply(age_cols, function(col) {
    col2 <- dataset$data[, col] * dataset$data[, col]
  })

  dataset
}

datasets <- convert_variables(datasets)

# filter out cases that have NA in the outcome variable

filter_na <- function(dataset) {
  outcome_col <- dataset$outcome

  df <- dataset$data

  dataset$data <- df[!is.na(df[, outcome_col]), ]

  dataset
}

datasets <- lapply(datasets, filter_na)

# calculate percent change from baseline --------------------------------------


source("R/source/percent_change_baseline.R")

percent_change_datasets <- list()

for (dataset in datasets) {
  if (dataset$percent_change_baseline$execute) {
    percent_change_dataset <- dataset
    percent_change_dataset$data <- percent_change_baseline(
      df = dataset$data,
      var = dataset$outcome,
      age_var = dataset$percent_change_baseline$age_var,
      id = dataset$id,
      target = dataset$percent_change_baseline$target,
      lower = dataset$percent_change_baseline$lower,
      upper = dataset$percent_change_baseline$upper,
      keep_before = dataset$percent_change_baseline$keep_before
    )
    percent_change_dataset$outcome <- paste0(
      dataset$outcome,
      "_percent_change_baseline"
    )

    percent_change_dataset$data_mod <- "percent_change_calculated"

    percent_change_datasets <- c(
      percent_change_datasets,
      list(percent_change_dataset)
    )
  }
}

datasets <- c(datasets, percent_change_datasets)

# remove outliers base upon velocity ------------------------------------------

source("R/source/remove_velocity_outliers.R")

remove_velocity_datasets <- list()

for (dataset in datasets) {
  original <- is.null(dataset$data_mod)
  # we only want to remove velocity outliers from the original dataset because
  # if we were to do this for already modified datasets we would produce a
  # Medusa head of datasets that would complicate our analysis exponentially.
  if (dataset$remove_velocity_outliers$execute & original) {
    remove_velocity_dataset <- dataset
    remove_velocity_dataset$data <- remove_velocity_outliers(
      df = dataset$data,
      var = dataset$outcome,
      age_var = dataset$remove_velocity_outliers$age_var,
      id = dataset$id,
      threshold = dataset$remove_velocity_outliers$threshold
    )

    remove_velocity_dataset$data_mod <- c(
      dataset$data_mod,
      "velocity_outliers_removed"
    )

    remove_velocity_datasets <- c(
      remove_velocity_datasets,
      list(remove_velocity_dataset)
    )
  }
}

datasets <- c(datasets, remove_velocity_datasets)

for (i in seq_along(datasets)) {
  age_vars <- datasets[[i]]$age_var
  age_vars2 <- paste0(age_vars, "2")
  age_vars <- c(age_vars, age_vars2)
  datasets[[i]]$data <- helphlme::prep_hlme(
    df = datasets[[i]]$data,
    vars = age_vars,
    center = config$center,
    scale = config$scale
  )
}

# sample datasets based upon 3 month time interval ----------------------------

source("R/source/sample_monthwise.R")

for (i in seq_along(datasets)) {
  if (!is.null(datasets[[i]]$sample)) {
    datasets[[i]]$data <- sample_monthwise(
      data = datasets[[i]]$data,
      age_var = paste0(datasets[[i]]$sample$age_var, "_ns"),
      interval = datasets[[i]]$sample$interval,
      id = datasets[[i]]$id
    )
  }
}

# create data_id --------------------------------------------------------------
for (i in seq_along(datasets)) {

  # if no data mod, dataset is considered OG
  if (is.null(datasets[[i]]$data_mod)) {
    datasets[[i]]$data_mod <- "og"
  } else {
    datasets[[i]]$data_mod <- datasets[[i]]$data_mod
  }

  # create data name which combines name, outcome, and data mod

  data_id <- paste(
    datasets[[i]]$name,
    datasets[[i]]$outcome,
    datasets[[i]]$data_mod,
    sep = "_"
  )

  datasets[[i]]$data_id <- data_id
}

# save datasets as R object list, individual R objects, and csv's -------------
save(datasets, file = "output/datasets.RDATA")

i <- 1
for (dataset in datasets) {
  data_mod <- dataset$data_mod
  file_name <- paste(dataset$outcome,
    data_mod,
    i,
    sep = "_"
  )
  path_rdata <- file.path(
    "output",
    "individual_rdata",
    paste0(
      file_name,
      ".RDATA"
    )
  )
  path_csv <- file.path(
    "output",
    "individual_csv",
    paste0(
      file_name,
      ".csv"
    )
  )
  save(dataset, file = path_rdata)
  write.csv(dataset$data, file = path_csv)
  i <- 1 + i
}
