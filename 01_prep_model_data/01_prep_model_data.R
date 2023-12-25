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

if (length(args) == 0) {
  args[[1]] <- "input/test_local.yaml"
  warning("No input file provided, using: ", args[[1]])
}

config <- yaml::read_yaml(args[[1]])

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

source("R/harmonize.R")

harmonized_datasets <- lapply(datasets, function(dataset) {
  if (isTRUE(dataset$harmonize$execute)) {
    data_harmonized <- harmonize(
      data = dataset$data,
      formula = dataset$harmonize$formula,
      outcome = dataset$outcome,
      variable = dataset$harmonize$variable
    )

    dataset$data <- data_harmonized

    return(dataset)
  } else {
    return(NULL)
  }
})

datasets <- harmonized_datasets


# check if there is overlap in unique ID's for each dataset -------------------
unique_id_list <- lapply(datasets, function(dataset) {
  id <- dataset$id
  data <- dataset$data
  unique_ids <- unique(data[[id]])
})


# these are the id's that are common to all outcomes. This way we can exclude
# the same ids from the training set for all outcome
shared_unique_id <- Reduce(dplyr::intersect, unique_id_list)

# keep ID's that have all outcomes --------------------------------------------
new_datasets <- lapply(datasets, function(dataset) {
  data <- dataset$data
  id <- dataset$id
  missing_data <- data[!data$id %in% shared_unique_id, ]
  data <- data[data$id %in% shared_unique_id, ]
  dataset$data <- data
  dataset$missing_data <- missing_data
  dataset
})

# Get orphaned ID numbers ------------------------------------------------------

orphaned_ids <- lapply(datasets, function(dataset) {
  id <- dataset$id
  data <- dataset$missing_data
  orphaned_ids <- unique(data[[id]])
  orphaned_ids
})

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
  test_data <- datasets[[i]]$test_data
  if (!is.null(test_data)) {
    datasets[[i]]$test_data <- helphlme::prep_hlme(
      df = datasets[[i]]$test_data,
      vars = age_vars,
      center = config$center,
      scale = config$scale
    )
  }
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
