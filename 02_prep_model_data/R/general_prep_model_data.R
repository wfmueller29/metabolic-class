# Author: William Mueller
# Purpose: The purpose of this file is to prep the datasets that were used for
# the previous glucose paper so they can be modeled
# We also removed outliers based upon outcome velocity
# We are trying to generalize the trajectories pipeline to other datasets

library(tidyverse)
library(helphlme)
library(rsample)

# load in config using file path ----------------------------------------------
args <- commandArgs(trailingOnly = TRUE)

args <- "yaml/slam_age_all.yaml" # delete

if (length(args) == 0) {
  config <- yaml::read_yaml("yaml/test_local.yaml")
} else {
  config <- yaml::read_yaml(args[[1]])
}

datasets <- yaml::read_yaml(config$dataset)

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

# harmonize the datasets for cohort -------------------------------------------

source("R/source/harmonize.R")

harmonized_datasets <- list()

for (dataset in datasets) {
  if (dataset$harmonize$execute) {
    data_harmonized <- harmonize(
      data = dataset$data,
      formula = dataset$harmonize$formula,
      outcome = dataset$outcome,
      variable = dataset$harmonize$variable
    )

    dataset$data <- data_harmonized

    harmonized_datasets <- c(harmonized_datasets, list(dataset))
  }
}

datasets <- harmonized_datasets

# sample datasets based upon 3 month time interval ----------------------------

source("R/source/sample_monthwise.R")

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

source("R/source/filter_group.R")
sample_subsets_datasets <- list()
dataset_overwrite <- list()

for (dataset in datasets) {
  if (!is.null(dataset$sample_subsets)) {
    if (dataset$sample_subsets$execute) {
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
  } else {
    dataset_overwrite <- c(dataset_overwrite, list(dataset))
  }
}

datasets <- dataset_overwrite

# check if there is overlap in unique ID's for each dataset -------------------
unique_id_list <- list()
for (i in seq_along(datasets)) {
  execute <- datasets[[i]]$train_test$execute
  id <- datasets[[i]]$id
  data <- datasets[[i]]$data
  if (execute) {
    unique_id_list[[i]] <- unique(data$id)
  } else {
    unique_id_list[[i]] <- NULL
  }
}

# these are the id's that are common to all outcomes. This way we can exclude
# the same ids from the training set for all outcome
shared_unique_id <- Reduce(dplyr::intersect, unique_id_list)

# keep ID's that have all outcomes --------------------------------------------
new_datasets <- list()
for (dataset in datasets) {
  data <- dataset$data
  id <- dataset$id
  missing_data <- data[!data$id %in% shared_unique_id, ]
  data <- data[data$id %in% shared_unique_id, ]
  dataset$data <- data
  dataset$missing_data <- missing_data
  new_datasets <- c(new_datasets, list(dataset))
}

# Get orphaned ID numbers ------------------------------------------------------

orphaned_ids <- list()

for (dataset in new_datasets) {
  id <- dataset$id
  data <- dataset$missing_data
  new_orphaned_ids <- unique(data[[id]])
  orphaned_ids <- c(orphaned_ids, new_orphaned_ids)
}

orphaned_ids <- as.vector(orphaned_ids)

datasets <- new_datasets

# training testing split ------------------------------------------------------
# I need to figure a way to ensure that each dataset has the same subjects
# removed from the training and testing sets

train_test_datasets <- list()
i <- 1

for (dataset in datasets) {
  # check if train_test is part of dataset commands
  if (!is.null(dataset$train_test)) {
    # to ensure that we want to excute train test split
    if (dataset$train_test$execute) {
      # first we need to make one categorical variable that encompasses all
      # groups
      cat_vars <- dataset$train_test$sample_by
      data <- dataset$data
      new_name <- paste(cat_vars, collapse = "-")
      new_col <- apply(data[, cat_vars], 1, paste, collapse = "-")
      data[, new_name] <- new_col
      dataset$data <- data

      # now we need to create a split determined by the split variable in the
      # yaml file. This will split so that we have representative proportions
      # of the original dataset in the initial split.

      # we are adding this counter so that we have coherant train and test
      # ids across outcome variables
      if (i == 1) {
        split_data <- rsample::group_initial_split(
          data = dataset$data,
          prop = dataset$train_test$split,
          strata = new_name,
          group = dataset$train_test$id
        )

        train_data <- rsample::training(split_data)
        test_data <- rsample::testing(split_data)

        # get ID's from previous train test
        train_id <- train_data[[dataset$id]]
        test_id <- test_data[[dataset$id]]
      } else {
        id_name <- dataset$id
        train_data <- data[data[[id_name]] %in% train_id, ]
        test_data <- data[data[[id_name]] %in% test_id, ]
      }

      i <- i + 1

      dataset$data <- train_data
      dataset$test_data <- test_data

      dataset$data_mod <- "train_test"

      train_test_datasets <- c(train_test_datasets, list(dataset))
    } else {
      train_data <- dataset$data
    }
  }
}

datasets <- c(datasets, train_test_datasets)

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

source("R/source/filter_interval.R")

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
    if (dataset$sample_age_interval$execute & original) {
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


# use prep_hlme to center and scale the data ----------------------------------

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

# ensure all data is a data.frame object --------------------------------------
for (i in seq_along(datasets)) {
  datasets[[i]]$data <- as.data.frame(datasets[[i]]$data)
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

  if (!is.null(datasets[[i]]$data_subset)) {
    data_subset_name <- paste(datasets[[i]]$data_subset, collapse = "_")
    data_id <- paste(data_id, data_subset_name, sep = "_")
  }

  datasets[[i]]$data_id <- data_id
  names(datasets)[[i]] <- data_id
}

# save datasets as R object list, individual R objects, and csv's -------------
path <- file.path("output", config$out_tag)
dir.create(path)
dir.create(file.path(path, "rdata"))
dir.create(file.path(path, "csv"))
save(datasets, file = file.path(path, "datasets.RDATA"))
save(config, file = file.path(path, "config.RDATA"))

i <- 1
for (dataset in datasets) {
  data_mod <- dataset$data_mod
  file_name <- paste(
    i,
    dataset$outcome,
    data_mod,
    sep = "_"
  )
  path_rdata <- file.path(
    path,
    "rdata",
    paste0(
      file_name,
      ".RDATA"
    )
  )
  path_csv <- file.path(
    path,
    "csv",
    paste0(
      file_name,
      ".csv"
    )
  )
  save(dataset, file = path_rdata)
  write.csv(dataset$data, file = path_csv)
  i <- 1 + i
}
