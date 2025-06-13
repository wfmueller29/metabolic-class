# This is where we are going to put all of the data subsetting, such as
# removing outliers, and subsetting by sex and strain. The logic here is to
# greatly simplify the modelling pipeline

library(tidyverse)
library(consoler)

# load in config using file path ----------------------------------------------
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  args[[1]] <- "input/slam_c1-c10.yaml"
}

datasets <- yaml::read_yaml(args[[1]])

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

read_rdata <- function(file_name) {
  # loads an RData file, and returns it
  load(file_name)
  get(ls()[ls() != "file_name"])
}

datasets <- read_data(datasets)


# convert all variables to correct type ---------------------------------------

convert_variables <- function(datasets) {
  datasets <- lapply(datasets, function(dataset) {
    dataset <- convert_numeric(dataset)
    dataset <- convert_age(dataset)
    dataset <- convert_dummy(dataset)
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

convert_dummy <- function(dataset) {
  dummy_cols <- c(dataset$dummy)

  dataset$data <- fastDummies::dummy_cols(dataset$data, dummy_cols)
  dataset
}

convert_age <- function(dataset) {
  age_cols <- c(dataset$age_var)
  age_cols2 <- paste0(age_cols, "2")

  dataset$data[, age_cols2] <- lapply(age_cols, function(col) {
    dataset$data[, col] * dataset$data[, col]
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

# generate idno if ID column not coercible to numeric -------------------------

for (i in seq_along(datasets)) {
  if (!is.null(datasets[[i]]$generate_idno)) {
    if (datasets[[i]]$generate_idno) {
      id <- datasets[[i]]$id
      data <- datasets[[i]]$data
      census <- unique(data[, id])
      census <- as.data.frame(census)
      names(census) <- id
      census$idno <- seq_along(census[, 1])
      data <- merge(data, census, by = id)
      datasets[[i]]$data <- data
      datasets[[i]]$id <- "idno"
    }
  }
}

# log transform the outcome variable ------------------------------------------
datasets <- lapply(datasets, function(dataset) {
  log_outcome_name <- paste0("log_", dataset$outcome)
  dataset$data[[log_outcome_name]] <- log(dataset$data[[dataset$outcome]])
  dataset
})

# sample datasets based upon 3 month time interval ----------------------------

source("R/sample_monthwise.R")

for (i in seq_along(datasets)) {
  if (!is.null(datasets[[i]]$sample_monthwise)) {
    if (datasets[[i]]$sample_monthwise$execute) {
      datasets[[i]]$data <- sample_monthwise(
        data = datasets[[i]]$data,
        age_var = paste0(datasets[[i]]$sample_monthwise$age_var),
        interval = datasets[[i]]$sample_monthwise$interval,
        id = datasets[[i]]$id
      )
    }
  }
}

# resample datasets by subsets of the data ------------------------------------

source("R/filter_group.R")
sample_subsets_datasets <- list()
dataset_overwrite <- list()

for (dataset in datasets) {
  if (isTRUE(dataset$sample_subsets$execute)) {
    subsets <- lapply(dataset$sample_subsets$subsets,
      unlist,
      use.names = TRUE
    )

    sampled_data <- filter_loop(dataset$data, subsets = subsets)

    new_datasets <- list()

    subset_names <- names(sampled_data)
    names(subsets) <- subset_names
    for (subset in subset_names) {
      new_datasets[[subset]] <- dataset
      old_data_mod <- dataset$data_mod
      new_datasets[[subset]]$data_subset <- subsets[[subset]]
      new_datasets[[subset]]$labels$data_name <- paste(
        new_datasets[[subset]]$labels$data_name,
        paste(subsets[[subset]], collapse = " "),
        sep = " "
      )

      new_datasets[[subset]]$data <- sampled_data[[subset]]
    }

    new_datasets <- unname(new_datasets)
    sample_subsets_datasets <- c(sample_subsets_datasets, new_datasets)
    dataset_overwrite <- c(dataset_overwrite, sample_subsets_datasets)
  } else {
    dataset_overwrite <- c(dataset_overwrite, list(dataset))
  }
}

datasets <- c(datasets, dataset_overwrite)


# calculate percent change from baseline --------------------------------------

source("R/percent_change_baseline.R")

percent_change_datasets <- list()

for (dataset in datasets) {
  if (isTRUE(dataset$percent_change_baseline$execute)) {
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

    percent_change_dataset$labels$data_name <- paste(
      percent_change_dataset$labels$data_name,
      "% Change",
      sep = " "
    )

    percent_change_dataset$labels$oc_name <- paste(
      percent_change_dataset$labels$oc_name,
      "% Change",
      sep = " "
    )

    percent_change_dataset$labels$oc_units <- "(%)"

    percent_change_datasets <- c(
      percent_change_datasets,
      list(percent_change_dataset)
    )
  }
}

datasets <- c(datasets, percent_change_datasets)

# remove outliers base upon velocity ------------------------------------------

source("R/remove_velocity_outliers.R")

remove_velocity_datasets <- list()

for (dataset in datasets) {
  original <- is.null(dataset$data_mod)
  # we only want to remove velocity outliers from the original dataset because
  # if we were to do this for already modified datasets we would produce a
  # Medusa head of datasets that would complicate our analysis exponentially.
  if (isTRUE(dataset$remove_velocity_outliers$execute) && original) {
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

    remove_velocity_dataset$labels$data_name <- paste(
      remove_velocity_dataset$labels$data_name,
      "Velocity Outliers Removed",
      sep = " "
    )


    remove_velocity_datasets <- c(
      remove_velocity_datasets,
      list(remove_velocity_dataset)
    )
  }
}

datasets <- c(datasets, remove_velocity_datasets)

# -----------------------------------------------------------------------------
# down sample age at to see how classes separate with limited data late in life
# we will only down sample the original dataset

source("R/filter_interval.R")

sample_age_interval_datasets <- list()
for (dataset in datasets) {
  # to check if there are any commands about sampling age intervals
  if (!is.null(dataset$sample_age_interval)) {
    # to check if the dataset is an original, if not we are not sample age
    original <- is.null(dataset$data_mod)

    # get the intervals we want to sample
    intervals <- lapply(dataset$sample_age_interval$intervals,
      unlist,
      use.names = TRUE
    )

    # check if we want to execute info in the sample_age_interval
    # also check if the datsaet is an original
    if (dataset$sample_age_interval$execute && original) {
      sampled_data <- filter_interval_loop(
        dataset$data,
        intervals
      )


      new_datasets <- list()
      for (interval in intervals) {
        new_datasets[[interval]] <- dataset
        new_datasets[[interval]]$data_mod <- paste("sample",
          names(interval),
          interval,
          sep = "_"
        )
        new_datasets[[interval]]$labels$data_name <- paste(
          new_datasets[[interval]]$labels$data_name,
          "Sample",
          names(interval),
          interval,
          sep = " "
        )

        new_datasets[[interval]]$data <- sampled_data[[interval]]
      }

      new_datasets <- unname(new_datasets)

      sample_age_interval_datasets <- c(
        sample_age_interval_datasets,
        new_datasets
      )
    }
  }
}

datasets <- c(datasets, sample_age_interval_datasets)

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

  if (!is.null(datasets[[i]]$data_subset)) {
    data_subset_name <- paste(datasets[[i]]$data_subset, collapse = "_")
    data_id <- paste(data_id, data_subset_name, sep = "_")
  }

  datasets[[i]]$data_id <- data_id
  names(datasets)[[i]] <- data_id
}

# save all datsets as csv files in output/data --------------------------------
output_name <- basename(args[[1]])
output_name <- strsplit(x = output_name, split = "\\.")[[1]][[1]]
file_path <- file.path("output", output_name, "data")
if (dir.exists(file_path)) {
  files <- list.files(file_path)
  files <- file.path(file_path, files)
  file.remove(files)
} else {
  dir.create(file_path, recursive = TRUE)
}

for (dataset_name in names(datasets)) {
  file_name <- file.path(file_path, dataset_name)
  file_name <- paste0(file_name, ".csv")
  data <- datasets[[dataset_name]]$data
  write.csv(data, file = file_name)
}


# create output file ----------------------------------------------------------
file_names <- names(datasets)
file_names <- paste0(file_names, ".csv")
file_names <- list(file_names)
names(file_names) <- file.path(getwd(), "output", "data", output_name)

output_name <- basename(args[[1]])
output_path <- file.path("output", output_name)
yaml::write_yaml(x = file_names, file = output_path)
