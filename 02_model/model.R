# Author: William Mueller
# Purpose: To run the mdoels for the metabolic class analysis on biowulf in
# parallel

library(helphlme)
library(callframe)
library(tidyverse)
library(future)

# TODO: Read in the previous output file and determine the most effective way
# to pass output files from one script output as input

# take command line arguments for output tag ----------------------------------
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  input <- "../01_prep_model_data/output/test_local.yaml"
  warning("Using default input file: ", input)
} else {
  input <- args[[1]]
}

input <- yaml::read_yaml(file = input)

# load in datasets and config -------------------------------------------------
load(file.path(input$working_directory, input$config_path))
load(file.path(input$working_directory, input$datasets_path))

# filter for each sex and strain
source("R/source/filter_group.R")

if (!is.null(config$filters)) {
  datasets <- lapply(datasets, function(dataset) {
    dataset$data <- filter_group(
      dataset$data,
      subsets = unlist(config$filters)
    )
    dataset
  })
}

# sample df -------------------------------------------------------------------
# for datasets such as train_test we want to ensure that they have the same
# idno's removed

# we need to check if there are train_test datasets in datasets our else the
# code breaks. We also need to check if there is only one train_test dataset
# because this might break the code

# check if there are train test datasets

source("R/source/sample_train_test.R")

if (!is.null(config$sample_n) && !isFALSE(config$sample_n)) {
  # check if there are train_test datasets
  train_test_exists <- check_train_test_exists(datasets)
  if (train_test_exists) {
    train_test_sample <- create_train_test_sample(
      datasets,
      size = config$sample_n
    )
  }

  # sample datasets
  datasets <- lapply(datasets, function(dataset) {
    if (dataset$data_mod == "train_test") {
      id_name <- dataset$id
      index <- dataset$data[, id_name] %in% train_test_sample
      dataset$data <- dataset$data[index, ]
      dataset$unique_ids <- train_test_sample
    } else {
      dataset$data <- helphlme::sample_df(
        df = dataset$data,
        id = dataset$id,
        n = config$sample_n
      )
    }
    dataset
  })

  # check that the unique ids for each train_test dataset are all equal
  train_test_ids <- list()
  for (dataset in datasets) {
    if (dataset$data_mod == "train_test") {
      unique_ids <- unique(dataset$data[, dataset$id])
      unique_ids <- sort(unique_ids)
      train_test_ids <- c(train_test_ids, list(unique_ids))
    }
  }
  all_equal <- do.call(all.equal, train_test_ids)
  if (!isTRUE(all_equal)) {
    stop("Train_test ids are not equal across datasets")
  } else {
    print("Train_test ids appear to be equal across datasets")
  }
}



# create call frame -----------------------------------------------------------
cf_all <- data.frame()
for (dataset in datasets) {
  cf <- make_cf(
    `data|oc` = paste0(dataset$data_id, "|", dataset$outcome),
    fixed = dataset$model$fixed,
    random = dataset$model$random,
    idiag = dataset$model$idiag,
    nwg = dataset$model$nwg,
    ng = 1:dataset$model$ng_max,
    subject = dataset$id,
    `$age_var` = dataset$age_var
  )
  # create mixed column
  cf <- data.table::set(cf,
    i = NULL,
    j = "mixture",
    value = dataset$model$mixture
  )

  cf_all <- rbind(cf_all, cf)
}

cf <- cf_all

get_dollar <- function(cf) {
  dollar <- grepl(".*\\$.*", x = names(cf))
  dollar_nms <- names(cf)[dollar]
  dollar_nms
}


fill_dollar <- function(cf, dollar_nms) {
  nms <- dollar_nms
  nms <- paste0("\\", nms)
  for (nm in nms) {
    for (col in names(cf)) {
      data.table::set(
        cf,
        i = NULL,
        j = col,
        value = stringr::str_replace_all(cf[[col]],
          pattern = nm,
          replacement = cf[[dollar_nms]]
        )
      )
    }
  }
  cf <- data.table::setDT(cf)
}

dollar_names <- get_dollar(cf)
cf <- fill_dollar(cf, dollar_names)

# create new fixed
cf <- data.table::set(cf,
  i = NULL,
  j = "fixed",
  value = paste0(cf[["oc"]], cf[["fixed"]], sep = " ")
)

## ----pmap_cf----------------------------------------------------------------
# if biowulf is in config file, allow for asyncronous eval
if (!is.null(config$plan)) {
  if (config$plan == "cluster") {
    ncpus <- availableCores()
    cl <- makeClusterPSOCK(ncpus)
    plan(cluster, workers = cl)
  } else {
    plan(config$plan)
  }
} else {
  plan("default")
}

# create object variables for data because they are in list and need to be
# in global env for pmap function

for (dataset in datasets) {
  assign(x = dataset$data_id, value = dataset$data, envir = .GlobalEnv)
}

models <- pmap_cf(cf,
  helphlme::hlme2,
  type = c(
    data = "sym",
    fixed = "form",
    mixture = "form",
    random = "form",
    subject = "chr",
    idiag = "bool",
    nwg = "bool",
    ng = "num"
  ),
  safe_quiet = FALSE,
  pkgs = "helphlme",
  seed = TRUE
)

# This is to close background workers
plan(sequential)

# name datasets
names(datasets) <- lapply(datasets, function(dataset) {
  dataset$data_id
})


# -----save stuff -------------------------------------------------------------
# Create output directory
time <- format(Sys.time(), "%Y%m%d_%H%M%S")
if (config$tag_time) {
  out_dir <- paste(time, config$out_tag, sep = "_")
} else {
  out_dir <- paste(config$out_tag)
}
out_path <- file.path("output", out_dir)

# Create file paths
datasets_path <- file.path(out_path, "datasets.RDATA")
models_path <- file.path(out_path, "models.RDATA")
cf_path <- file.path(out_path, "cf.RDATA")
config_path <- file.path(out_path, "config.RDATA")

# save objects
dir.create(out_path)
save(datasets, file = datasets_path)
save(models, file = models_path)
save(cf, file = cf_path)
save(config, file = config_path)
