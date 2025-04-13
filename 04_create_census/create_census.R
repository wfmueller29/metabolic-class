# Create census

library(consoler)
# for the case when we are not running with RStudio
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  # input_path <- "../03_model_select/output/test_local.yaml"
  # input_path <- "../01_prep_model_data/output/xslam_c16-c18.yaml"
  input_path <- "../01_prep_model_data/output/20250410_slam_c1-c10_x_slam_c16-c18.yaml"
  # input_path <- "../01_prep_model_data/output/mb6.yaml"
  warning("Using default input file: ", input_path)
} else {
  input_path <- args[[1]]
}

input <- yaml::read_yaml(file = input_path)

# load in datasets and config -------------------------------------------------
config <- yaml::read_yaml(file = input$config_path)

# fill in if validation -------------------------------------------------------
# notice if doing external validation, parts of "input" are empty
# we are going to fill those using paths from our validation file that
# has run them already
if (!isFALSE(config$external_validate)) {
  validation_output <- yaml::read_yaml(config$external_validate)
  validation_input <- yaml::read_yaml(validation_output$input_path)

  input$models_path <- validation_input$models_path
  input$cf_path <- validation_input$cf_path
  input$final_models_path <- validation_input$final_models_path
  input$csv_path <- validation_input$csv_path
}
load(input$cf_path)
load(input$datasets_path)
load(input$final_models_path)

if (!isFALSE(config$external_validate)) {
  # overwrite train_test_models because we are using og models as our training
  # model in external validation

  # values we need to overwrite
  data_mod <- final_models$data_mod
  model_name <- final_models$model_name
  data <- final_models$data
  data_id <- final_models$data_id
  dataset_index <- final_models$dataset_index

  og_models <- final_models[final_models$data_mod == "og", ]
  final_models <- rbind(og_models, og_models)
  if (!all(final_models$data_mod == "og")) {
    stop("All our models for external validation are not based off original
         dataset")
  }

  final_models$data_mod <- data_mod
  final_models$model_name <- model_name
  final_models$data <- data
  final_models$data_id <- data_id
  final_models$dataset_index <- dataset_index
}

# load in main_cat_surv
main_cat_surv <- read.csv(file = config$survival_dataset$path)
main_cat_surv <- as.data.frame(main_cat_surv)

final_models$dfs <- lapply(final_models$data, function(name) {
  datasets[[name]]$data
})


# create census for complete and train datasets -------------------------------
# will number classes so that all classes of list given to function
# are labelled uniquely
make_census <- function(cf_row, dataset) {
  model <- unlist(cf_row$final_model, recursive = FALSE)
  class_df <- model$pprob

  data <- dataset$data
  id <- dataset$id

  # add class_df to main
  census <- data[!duplicated(data[[id]]), ]
  census_cols <- dataset[c("id", "covariates", "covariates_dummy")]
  census_cols <- c(census_cols, dataset$harmonize$variable)
  census_cols <- unlist(census_cols, use.names = FALSE)
  census <- census[, census_cols]
  census <- merge(x = census, y = class_df, by = id)

  # add survival information to census
  surv_id <- config$survival_dataset$id

  census <- merge(x = census, y = main_cat_surv, by.x = id, by.y = surv_id)

  census
}


final_models$census <- lapply(seq_len(nrow(final_models)), function(i) {
  cf_row <- final_models[i, ]
  dataset <- datasets[[cf_row$dataset_index]]
  make_census(cf_row, dataset)
})


# create combined census ------------------------------------------------------
source("../06_create_figures/R/combine_census.R")

train_test_index <- (final_models$data_mod == "train_test")
train_test_names <- final_models[train_test_index, "model_name"]
rest_names <- final_models[!train_test_index, "model_name"]

model_name_list <- list(rest_names, train_test_names)

column <- list(rep(NA, times = length(final_models)))
for (model_name_vector in model_name_list) {
  model_index <- final_models$model_name %in% model_name_vector
  censuses <- final_models[model_index, ]$census
  ids <- final_models[model_index, "subject"]
  outcomes <- final_models[model_index, "oc"]


  merged_census <- combine_census(
    censuses = censuses,
    ids = ids,
    outcomes = outcomes
  )

  column[model_index] <- list(merged_census$census)
}
final_models$combined_census <- column

# create test census ----------------------------------------------------------
make_test_census <- function(cf_row, dataset) {
  if (is.null(dataset$test_data)) {
    return(NA)
  }
  data <- dataset$test_data
  id <- dataset$id

  # create census from data
  census <- data[!duplicated(data[[id]]), ]
  harmonize_vars <- dataset$harmonize$variable
  census_cols <- dataset[c("id", "covariates", "covariates_dummy")]
  census_cols <- unlist(census_cols, use.names = FALSE)
  census_cols <- c(census_cols, harmonize_vars)

  census <- census[, census_cols, drop = FALSE]
  # add survival information to census
  surv_id <- config$survival_dataset$id

  census <- merge(x = census, y = main_cat_surv, by.x = id, by.y = surv_id)

  census
}


final_models$test_census <- lapply(seq_len(nrow(final_models)), function(i) {
  cf_row <- final_models[i, ]
  dataset <- datasets[[cf_row$dataset_index]]
  make_test_census(cf_row, dataset)
})


# create combined test census -------------------------------------------------
source("../06_create_figures/R/pred_class.R")
test_data <- lapply(datasets[train_test_index], `[[`, "test_data")
models <- final_models[train_test_index, "final_model"]
outcomes <- final_models[train_test_index, "oc"]
ids <- final_models[train_test_index, "subject"]

predicted_class <- mapply(predict_class,
  newdata = test_data, model = models,
  SIMPLIFY = FALSE
)

test_census <- final_models[train_test_index, "test_census"]

test_census_pred <- mapply(merge,
  x = test_census,
  y = predicted_class,
  by = config$meta_dataset$id, SIMPLIFY = FALSE
)

reorder_class <- function(censuses) {
  i <- 0
  for (j in seq_along(censuses)) {
    # generate new_class
    census <- censuses[[j]]
    census$new_class <- as.character(census$class + i)

    # Create new prob based off of new_class
    probs_index <- grepl("^prob", names(census))
    probs <- names(census)[grepl("^prob", names(census))]
    probs <- stringr::str_split(probs, pattern = "prob", simplify = TRUE)[, 2]
    new_probs <- as.numeric(probs) + i
    new_probs <- paste0("prob", new_probs)
    names(census)[probs_index] <- new_probs

    uni_class <- length(unique(census$class))
    i <- uni_class + i

    censuses[[j]] <- census
  }

  censuses
}

test_census_pred <- reorder_class(test_census_pred)

combined_test_census <- combine_census(
  censuses = test_census_pred,
  outcomes = outcomes,
  ids = ids
)$census

column <- as.list(rep(NA, nrow(final_models)))
column[train_test_index] <- combined_test_census
final_models$combined_test_census <- column

# create single combined censuses ---------------------------------------------
combined_complete_census <- final_models[!train_test_index, "combined_census"]
combined_complete_census <- combined_complete_census[[1]]

combined_train_census <- final_models[train_test_index, "combined_census"]
combined_train_census <- combined_train_census[[1]]

# save combined censuses as csv -----------------------------------------------
config_path <- input$config_path
config <- yaml::read_yaml(file = config_path)

output_path <- file.path("output", config$out_tag)
dir.create(output_path)
output_path <- normalizePath(output_path)

final_models_path <- file.path(output_path, "final_models.RDATA")

save(final_models, file = final_models_path)

combined_complete_census_path <- file.path(output_path, "complete_census.csv")
write.csv(combined_complete_census, combined_complete_census_path)

combined_train_census_path <- file.path(output_path, "train_census.csv")
write.csv(combined_train_census, combined_train_census_path)

combined_test_census_path <- file.path(output_path, "test_census.csv")
write.csv(combined_test_census, combined_test_census_path)

# create output file ----------------------------------------------------------
output_list <- list(
  data_time = format(Sys.time()),
  working_directory = getwd(),
  config_path = config_path,
  input_path = params$input_path,
  output_dir_path = output_path,
  datasets_path = input$datasets_path,
  validation_config_path = input$validation_config_path,
  models_path = input$models_path,
  cf_path = input$cf_path,
  final_models_path = final_models_path,
  csv_path = input$csv_path,
  complete_cenus_path = combined_complete_census_path,
  train_cenus_path = combined_train_census_path,
  test_cenus_path = combined_test_census_path
)

output_list_path <- paste0(file.path("output", config$out_tag), ".yaml")
yaml::write_yaml(x = output_list, file = output_list_path)
