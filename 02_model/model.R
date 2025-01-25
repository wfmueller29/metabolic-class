# Author: William Mueller
# Purpose: To run the mdoels for the metabolic class analysis on biowulf in
# parallel

library(helphlme)
library(callframe)
library(tidyverse)
library(future)
set.seed(365)

# take command line arguments for output tag ----------------------------------
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  input_path <- "../01_prep_model_data/output/test_local.yaml"
  warning("Using default input file: ", input_path)
} else {
  input_path <- args[[1]]
}

input <- yaml::read_yaml(file = input_path)

# load in datasets and config -------------------------------------------------
load(input$datasets_path)
config <- yaml::read_yaml(file = input$config_path)


# filter for each sex and strain
source("R/filter_group.R")

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

source("R/sample_ubiquitous.R")

if (!is.null(config$sample_n) && !isFALSE(config$sample_n)) {
  # check if there are train_test datasets
  ubiquitous_sample <- create_ubiquitous_sample(
    datasets,
    size = config$sample_n
  )

  # sample all datasets based upon train_test_sample
  datasets <- lapply(datasets, function(dataset) {
    id_name <- dataset$id
    index <- dataset$data[, id_name] %in% ubiquitous_sample
    dataset$data <- dataset$data[index, ]
    dataset$unique_ids <- ubiquitous_sample
    dataset
  })

  # check that the unique ids for each train_test dataset are all equal
  ubiquitous_ids <- lapply(datasets, function(dataset) {
    unique_ids <- unique(dataset$data[, dataset$id])
    unique_ids <- sort(unique_ids)
    unique_ids
  })

  all_equal <- sapply(ubiquitous_ids, function(ids) {
    all.equal(ids, ubiquitous_ids[[1]])
  })
  all_equal <- all(all_equal)

  if (!isTRUE(all_equal)) {
    stop("Train_test ids are not equal across datasets")
  } else {
    print("Train_test ids appear to be equal across datasets")
  }
}

# create dataset id number ----------------------------------------------------

datasets <- lapply(seq_len(length(datasets)), function(i) {
  datasets[[i]]$dataset_index <- i
  datasets[[i]]
})

expand.grid
# create call frame -----------------------------------------------------------
create_callframe <- function(dataset) {
  cf <- expand.grid(
    list(
      dataset_index = dataset$dataset_index,
      data = dataset$data_id,
      fixed = dataset$model$fixed,
      random = dataset$model$random,
      idiag = dataset$model$idiag,
      nwg = dataset$model$nwg,
      ng = seq_len(dataset$model$ng_max),
      subject = dataset$id
    ),
    stringsAsFactors = FALSE
  )

  cf$mixture <- dataset$model$mixture
  cf$fixed <- paste0(dataset$outcome, cf[["fixed"]], sep = " ")

  cf
}

cfs <- lapply(datasets, create_callframe)
cf <- do.call(what = rbind, args = cfs)

## ----pmap_cf----------------------------------------------------------------
# if biowulf is in config file, allow for asyncronous eval
if (!is.null(config$plan)) {
  if (config$plan == "cluster") {
    ncpus <- future::availableCores()
    cl <- future::makeClusterPSOCK(ncpus)
    future::plan(cluster, workers = cl)
  } else {
    if (is.null(config$ncpus)) {
      future::plan(config$plan)
    } else {
      future::plan(config$plan, workers = config$ncpus)
    }
  }
} else {
  future::plan("default")
}

# create object variables for data because they are in list and need to be
# in global env for pmap function

for (dataset in datasets) {
  assign(x = dataset$data_id, value = dataset$data, envir = .GlobalEnv)
}

models <- callframe::pmap_cf(cf,
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
future::plan(sequential)

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

input_yaml_path <- normalizePath(input_path)
out_path <- file.path("output", out_dir)
dir.create(out_path)
out_path <- normalizePath(out_path)

# Create file paths
datasets_path <- normalizePath(file.path(out_path, "datasets.RDATA"))
models_path <- normalizePath(file.path(out_path, "models.RDATA"))
cf_path <- normalizePath(file.path(out_path, "cf.RDATA"))

# save objects
save(datasets, file = datasets_path)
save(models, file = models_path)
save(cf, file = cf_path)

# create output file ----------------------------------------------------------

output_list <- list(
  data_time = format(Sys.time()),
  working_directory = getwd(),
  config_path = input$config_path,
  input_yaml_path = input_yaml_path,
  output_dir_path = out_path,
  datasets_path = datasets_path,
  models_path = models_path,
  cf_path = cf_path
)

output_list_path <- paste0(file.path("output", config$out_tag), ".yaml")
yaml::write_yaml(x = output_list, file = output_list_path)
