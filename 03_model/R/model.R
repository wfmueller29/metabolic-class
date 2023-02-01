# Author: William Mueller
# Purpose: To run the mdoels for the metabolic class analysis on biowulf in
# parallel

library(helphlme)
library(callframe)
library(tidyverse)
library(future)

# load in data
load("../02_prep_model_data/output/df_list.RDATA")
load("../02_prep_model_data/output/datasets.RDATA")

# take command line arguments for parameter file ------------------------------
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  params <- list(
    default_yaml = "yaml/default.yaml",
    config_yaml = "yaml/test.yaml"
  )
} else {
  params <- list(
    default_yaml = "yaml/default.yaml",
    config_yaml = args[[1]]
  )
}


# ----read in config file------------------------------------------------------
# Read in default and config yaml files
default_yaml <- yaml::read_yaml(file = params$default_yaml)
config_yaml <- yaml::read_yaml(file = params$config_yaml)

# Create config by replacing defautl_yaml with config_yaml Values

# make config the default yaml
config <- default_yaml

# if there are values in config_yaml add them to config
in_config <- names(default_yaml) %in% names(config_yaml)
config[in_config] <- config_yaml

# filter for each sex and strain
source("R/source/filter_utils.R")
source("R/source/filter_group.R")

if (!is.null(config$filters)) {
  datasets <- lapply(datasets, function(dataset) {
    dataset$data <- filter_group(dataset$data, subsets = unlist(config$filters))
    dataset
  })
}

# sample df
if (!is.null(config$sample_n)) {
  df_list <- lapply(df_list, sample_df, "idno", config$sample_n)
  datasets <- lapply(datasets, function(dataset) {
    dataset$data <- sample_df(
      df = dataset$data,
      id = dataset$id,
      n = config$sample_n
    )
    dataset
  })
}

# create call frame -----------------------------------------------------------
cf_all <- data.frame()
for (dataset in datasets) {
  cf <- make_cf(
    `data|oc` = paste0(dataset$data_id, "|", dataset$outcome),
    fixed = dataset$model$fixed,
    random = dataset$model$random,
    idiag = config$idiag,
    nwg = config$nwg,
    ng = 1:config$ng_max,
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

if (config$test) {
  cf <- cf[1:10, ]
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
