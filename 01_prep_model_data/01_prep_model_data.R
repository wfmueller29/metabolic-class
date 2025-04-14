# Author: William Mueller
# Purpose: The purpose of this file is to prep the datasets that were used for
# the previous glucose paper so they can be modeled
# We also removed outliers based upon outcome velocity
# We are trying to generalize the trajectories pipeline to other datasets

library(tidyverse)
library(helphlme)
library(rsample)
set.seed(365)

# load in config using file path ----------------------------------------------
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  # args[[1]] <- "input/test_local.yaml"
  # args[[1]] <- "input/slam_age_mb6.yaml"
  # args[[1]] <- "input/slam_age_all.yaml"
  # args[[1]] <- "input/slam_all_only_bw.yaml"
  # args[[1]] <- "input/itp_bw.yaml"
  # args[[1]] <- "../inputs/validate/slam_c1-c10_x_slam_c16-c18.yaml"
  args[[1]] <- "../inputs/predict/slam_c1-c10_x_slam_c16-c18.yaml"
  # args[[1]] <- "../x01_external_validation/input/slam_age_all.yaml"
  # args[[1]] <- "../x01_external_validation/input/slam_c16-c18.yaml"
  warning("No input file provided, using: ", args[[1]])
}

input_path <- args[[1]]
input_path <- normalizePath(input_path)

config <- yaml::read_yaml(input_path)

# update config ---------------------------------------------------------------

# Fill prediction_data and meta_dataset info foin each dataset
config$datasets <- lapply(config$datasets, function(dataset) {
  dataset$prediction_data <- config$prediction_data
  dataset <- c(dataset, config$meta_dataset)
})

# create validation and predict bools -----------------------------------------

bool_external_validate <- is.character(config$external_validate)
if (bool_external_validate) {
  if (file.exists(config$external_validate)) {
    bool_external_validate <- file.exists(config$external_validate)
  } else {
    stop("external_validate should either be a path to an output yaml or FALSE")
  }
}
bool_predict <- is.character(config$predict)
if (bool_predict) {
  if (file.exists(config$predict)) {
    bool_predict <- file.exists(config$predict)
  } else {
    stop("predict should either be a path to an output yaml or FALSE")
  }
}

# Read in yaml if external_validate -------------------------------------------

# if validation, make validation data og data and input datasets test data
if (bool_external_validate || bool_predict) {
  if (bool_external_validate) {
    file <- config$external_validate
  } else if (bool_predict) {
    file <- config$predict
  }
  validation_output <- yaml::read_yaml(file)
  validation_config <- yaml::read_yaml(validation_output$config_path)

  validation_config$datasets <- lapply(
    validation_config$datasets,
    function(dataset) {
      dataset$prediction_data <- validation_config$prediction_data
      dataset <- c(dataset, validation_config$meta_dataset)
    }
  )

  datasets <- validation_config$datasets
  validation_datasets <- config$datasets
} else {
  datasets <- config$datasets
}

# Input datasets --------------------------------------------------------------

get_extension <- function(datasets) {
  datasets <- lapply(datasets, function(dataset) {
    data_path <- file.path(dataset$path)
    print(data_path)
    ext <- tools::file_ext(data_path)
    dataset$ext <- ext
    dataset
  })
}

datasets <- get_extension(datasets)
if (bool_external_validate || bool_predict) {
  validation_datasets <- get_extension(validation_datasets)
}

read_data <- function(datasets) {
  datasets <- lapply(datasets, function(dataset) {
    print(dataset$path)
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
if (bool_external_validate || bool_predict) {
  validation_datasets <- read_data(validation_datasets)
}

# drop all variables we are not using -----------------------------------------

drop_unused_vars <- function(datasets) {
  lapply(datasets, function(dataset) {
    keep_vars <- c(
      dataset$id,
      dataset$harmonize$variable,
      dataset$covariates,
      dataset$covariates_dummy,
      dataset$age_var,
      dataset$outcome
    )
    dataset$data <- dataset$data[, keep_vars]
    dataset
  })
}

datasets <- drop_unused_vars(datasets)

if (bool_external_validate || bool_predict) {
  validation_datasets <- drop_unused_vars(validation_datasets)
  test <- lapply(seq_along(datasets), function(i) {
    data <- datasets[[i]]$data
    val_data <- validation_datasets[[i]]$data
    length(names(data)) == length(names(val_data))
  })
  if (all(as.vector(test))) {
    message("Number of columns in training data = validation data")
  } else {
    stop("Mismatched number of columns in training and validation data")
  }
}

# convert all variables to correct type ---------------------------------------

convert_variables <- function(datasets) {
  datasets <- lapply(datasets, function(dataset) {
    dataset <- convert_factor(dataset)
    dataset <- convert_numeric(dataset)
    dataset
  })
  datasets
}

convert_numeric <- function(dataset) {
  numeric_cols <- c(dataset$id, dataset$outcome, dataset$age_var)

  dataset$data[, numeric_cols] <- lapply(numeric_cols, function(col) {
    as.numeric(dataset$data[, col])
  })

  dataset
}

convert_factor <- function(dataset) {
  factor_cols <- c(dataset$harmonize$variable)

  dataset$data[, factor_cols] <- lapply(factor_cols, function(col) {
    as.factor(dataset$data[, col])
  })

  dataset
}

datasets <- convert_variables(datasets)

if (bool_external_validate || bool_predict) {
  validation_datasets <- convert_variables(validation_datasets)
}

# filter out cases that have NA in the outcome variable -----------------------

filter_na <- function(dataset) {
  outcome_col <- dataset$outcome

  df <- dataset$data

  dataset$data <- df[!is.na(df[, outcome_col]), ]

  dataset
}

datasets <- lapply(datasets, filter_na)
if (bool_external_validate || bool_predict) {
  validation_datasets <- lapply(validation_datasets, filter_na)
}


# test if age => age_death ----------------------------------------------------
merge_surv_data <- function(dataset, surv) {
  data <- dataset$data
  data <- merge(data, surv, by = dataset$id, all.x = TRUE)
  data
}

surv <- read.csv(config$survival_dataset$path)
surv_data <- lapply(datasets, merge_surv_data, surv)
# we do not need to do this for predict because there should be no surivival
# data for predict
if (bool_external_validate) {
  # remember, we swapped datasets and validation_datasets above
  surv <- read.csv(validation_config$survival_dataset$path)
  surv_data <- lapply(datasets, merge_surv_data, surv)
  surv_validation <- read.csv(config$survival_dataset$path)
  surv_data_validation <- lapply(
    validation_datasets, merge_surv_data,
    surv_validation
  )
  surv_data <- c(surv_data, surv_data_validation)
}

tests <- lapply(surv_data, function(data) {
  age_death <- config$survival_dataset$age_death
  age <- config$meta_dataset$age_var[[1]]
  all(data[, age_death] > data[, age])
})
test <- all(unlist(tests))

if (!isTRUE(test)) {
  stop("Age of observation is >= age death, age < age_death is required")
}

# harmonize the datasets ------------------------------------------------------

source("R/harmonize.R")

harmonize_apply <- function(datasets) {
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
      return(dataset)
    }
  })
  harmonized_datasets
}

harmonize_apply_validate <- function(datasets, validation_datasets) {
  harmonized_datasets <- lapply(seq_along(datasets), function(i) {
    if (isTRUE(datasets[[i]]$harmonize$execute)) {
      validation_data <- validation_datasets[[i]]$data
      validation_data$validate <- 1
      data <- datasets[[i]]$data
      data$validate <- 0
      combined_data <- rbind(data, validation_data)
      data_harmonized <- harmonize(
        data = combined_data,
        formula = validation_datasets[[i]]$harmonize$formula,
        outcome = validation_datasets[[i]]$outcome,
        variable = validation_datasets[[i]]$harmonize$variable
      )

      data_harmonized <- data_harmonized[data_harmonized$validate == 1, ]

      validation_datasets[[i]]$data <- data_harmonized

      return(validation_datasets[[i]])
    } else {
      return(validation_datasets[[i]])
    }
  })
  harmonized_datasets
}

harmonized_datasets <- harmonize_apply(datasets)
if (bool_external_validate || bool_predict) {
  harmonized_validation_datasets <- harmonize_apply_validate(
    datasets,
    validation_datasets
  )
}

datasets <- harmonized_datasets
if (bool_external_validate || bool_predict) {
  validation_datasets <- harmonized_validation_datasets
}

# Make sure all datasets have the same ids ------------------------------------
id_intersect <- function(datasets) {
  # check if there is overlap in unique ID's for each dataset

  unique_id_list <- lapply(datasets, function(dataset) {
    id <- dataset$id
    data <- dataset$data
    unique_ids <- unique(data[[id]])
  })


  # these are the id's that are common to all outcomes. This way we can exclude
  # the same ids from the training set for all outcome
  shared_unique_id <- Reduce(dplyr::intersect, unique_id_list)

  # keep ID's that have all outcomes
  new_datasets <- lapply(datasets, function(dataset) {
    data <- dataset$data
    id <- dataset$id
    missing_data <- data[!data$id %in% shared_unique_id, ]
    data <- data[data$id %in% shared_unique_id, ]
    dataset$data <- data
    dataset$missing_data <- missing_data
    dataset
  })
  new_datasets
}

datasets <- id_intersect(datasets)
if (bool_external_validate || bool_predict) {
  validation_datasets <- id_intersect(validation_datasets)
}

# Get orphaned ID numbers ------------------------------------------------------

orphaned_ids <- function(datasets) {
  orphaned_ids <- lapply(datasets, function(dataset) {
    id <- dataset$id
    data <- dataset$missing_data
    orphaned_ids <- unique(data[[id]])
    orphaned_ids
  })

  orphaned_ids <- as.vector(orphaned_ids)
  orphaned_ids
}

datasets_orphans <- orphaned_ids(datasets)
if (bool_external_validate || bool_predict) {
  validation_datasets_orphans <- orphaned_ids(validation_datasets)
}

# training testing split ------------------------------------------------------

# create strata variable when doing train_test split
create_strata_vars <- function(dataset) {
  cat_vars <- dataset$train_test$sample_by
  data <- dataset$data
  new_col <- apply(data[, cat_vars, drop = FALSE], 1, paste, collapse = "-")
  data[, "sample_by"] <- new_col
  dataset$data <- data

  dataset
}

datasets <- lapply(datasets, create_strata_vars)
if (bool_external_validate || bool_predict) {
  validation_datasets <- lapply(validation_datasets, create_strata_vars)
}

# create determine training ids and testing ids
get_train_test_id <- function(datasets) {
  split_data <- rsample::group_initial_split(
    data = datasets[[1]]$data,
    prop = datasets[[1]]$train_test$split,
    strata = "sample_by",
    group = datasets[[1]]$id
  )

  train_data <- rsample::training(split_data)
  test_data <- rsample::testing(split_data)

  # get ID's from previous train test
  train_id <- train_data[[datasets[[1]]$id]]
  test_id <- test_data[[datasets[[1]]$id]]

  return(list(train_id = train_id, test_id = test_id))
}

train_test_ids <- get_train_test_id(datasets)
train_ids <- train_test_ids$train_id
test_ids <- train_test_ids$test_id

# use train and test ids to make train and test datasets
create_train_test <- function(dataset, train_id, test_id) {
  data <- dataset$data
  id_name <- dataset$id
  train_data <- data[data[[id_name]] %in% train_id, ]
  test_data <- data[data[[id_name]] %in% test_id, ]


  dataset$data <- train_data
  dataset$test_data <- test_data

  dataset$data_mod <- "train_test"

  dataset
}

create_train_test_validate <- function(dataset, validation_dataset) {
  dataset$test_data <- validation_dataset$data
  dataset$data_mod <- "train_test"
  dataset
}

if (!bool_external_validate && !bool_predict) {
  train_test_datasets <- lapply(
    datasets,
    create_train_test, train_ids, test_ids
  )
} else if (bool_external_validate || bool_predict) {
  train_test_datasets <- mapply(
    create_train_test_validate,
    datasets, validation_datasets,
    SIMPLIFY = FALSE
  )
}

datasets <- c(datasets, train_test_datasets)

# use prep_hlme to center and scale the data ----------------------------------

datasets <- lapply(datasets, function(dataset) {
  prediction_data_age_vars <- lapply(dataset$prediction_data, `[[`, "age_var")
  prediction_data_age_vars <- unlist(prediction_data_age_vars)
  prep_age_vars <- unique(c(prediction_data_age_vars, dataset$age_var))
  data_scaled <- helphlme::prep_hlme(
    df = dataset$data,
    vars = prep_age_vars,
    center = config$center,
    scale = config$scale
  )
  test_data <- dataset$test_data
  if (!is.null(test_data)) {
    dataset$test_data <- helphlme::prep_hlme(
      df = dataset$test_data,
      vars = prep_age_vars,
      center = config$center,
      scale = config$scale,
      ref_data = dataset$data
    )
  }
  dataset$data <- data_scaled
  dataset
})

# Check that data and test_data were centered by same value

lapply(datasets, function(dataset) {
  if (!is.null(dataset$test_data)) {
    age_vars <- dataset$age_var
    age_vars_ns <- paste0(age_vars, "_ns")
    dif_data <- dataset$data[[age_vars[[1]]]] -
      dataset$data[[age_vars_ns[[1]]]]
    dif_test_data <- dataset$test_data[[age_vars[[1]]]] -
      dataset$test_data[[age_vars_ns[[1]]]]
    dif_data <- round(dif_data, digits = 3)
    dif_test_data <- round(dif_test_data, digits = 3)
    # Checks that all differences are equal
    x <- all(dif_test_data == dif_data[1]) && all(dif_data == dif_test_data[1])
    if (x) {
      print("We're good")
    } else {
      stop("We have not properly scaled train and test set")
    }
  } else {
    print("We're good")
  }
})


# ensure all data is a data.frame object --------------------------------------
datasets <- lapply(datasets, function(dataset) {
  dataset$data <- as.data.frame(dataset$data)
  dataset
})

# create data_id --------------------------------------------------------------
datasets <- lapply(datasets, function(dataset) {
  if (is.null(dataset$data_mod)) {
    dataset$data_mod <- "og"
  } else {
    dataset$data_mod <- dataset$data_mod
  }

  # create data name which combines name, outcome, and data mod

  data_id <- paste(
    dataset$name,
    dataset$outcome,
    dataset$data_mod,
    sep = "_"
  )

  if (!is.null(dataset$data_subset)) {
    data_subset_name <- paste(dataset$data_subset, collapse = "_")
    data_id <- paste(data_id, data_subset_name, sep = "_")
  }

  dataset$data_id <- data_id

  dataset
})

dataset_names <- lapply(datasets, function(dataset) {
  dataset$data_id
})

names(datasets) <- dataset_names

# save datasets as R object list, individual R objects, and csv's -------------
input_path <- normalizePath(input_path)
output_dir_path <- file.path("output", config$out_tag)
dir.create(output_dir_path, recursive = TRUE)
output_dir_path <- normalizePath(output_dir_path)
datasets_path <- normalizePath(file.path(output_dir_path, "datasets.RDATA"))

save(datasets, file = datasets_path)

# create output yaml ----------------------------------------------------------

output_list <- list(
  data_time = format(Sys.time()),
  working_directory = getwd(),
  config_path = input_path,
  input_yaml_path = input_path,
  output_dir_path = output_dir_path,
  datasets_path = datasets_path
)

output_yaml_path <- normalizePath(file.path("output", config$out_tag))
output_yaml_path <- paste0(output_yaml_path, ".yaml")
yaml::write_yaml(x = output_list, file = output_yaml_path)
