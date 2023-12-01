# These are functions to create sample of id's so that sampling across the
# train test datasets are identical. Such that the ids sampled for one
# train_test dataset will be the same for all other train test datasets

check_train_test_exists <- function(datasets) {
  all_data_mods <- lapply(datasets, function(dataset) dataset$data_mod)
  train_test_exists <- "train_test" %in% all_data_mods
  train_test_exists
}

check_complete_sample <- function(unique_train_test_ids, train_test_sample) {
  # check that the sample is in all unique train_test idnos
  for (id_list in unique_train_test_ids) {
    inclusion_check <- train_test_sample %in% id_list
    inclusion_check <- all(inclusion_check)
    if (!inclusion_check) {
      stop("id sample is not complete across train_test datasets")
    } else {
      print("id sample appears to be complete across train_test datasets")
    }
  }
}

create_train_test_sample <- function(datasets, size) {
  train_test_ids <- list()
  for (dataset in datasets) {
    id_name <- dataset$id
    if (dataset$data_mod == "train_test") {
      ids <- dataset$data[, id_name]
      train_test_ids <- c(train_test_ids, list(ids))
    }
  }

  unique_train_test_ids <- lapply(train_test_ids, unique)

  train_test_sample <- sample(
    x = unique_train_test_ids[[1]],
    size = size
  )

  check_complete_sample(unique_train_test_ids, train_test_sample)

  train_test_sample
}
