# These are functions to create sample of id's so that sampling across the
# train test datasets are identical. Such that the ids sampled for one
# train_test dataset will be the same for all other train test datasets


check_ubiquitous_sample <- function(unique_ids_list, ubiquitous_sample) {
  # check that the sample is in all unique train_test idnos
  for (id_list in unique_ids_list) {
    inclusion_check <- ubiquitous_sample %in% id_list
    inclusion_check <- all(inclusion_check)
    if (!inclusion_check) {
      stop("id sample is not complete across train_test datasets")
    } else {
      print("id sample appears to be complete across train_test datasets")
    }
  }
}

create_ubiquitous_sample <- function(datasets, size) {
  ids <- lapply(datasets, function(dataset) {
    id_name <- dataset$id
    ids <- dataset$data[, id_name]
    ids
  })

  unique_ids <- lapply(ids, unique)

  ubiquitous_ids <- Reduce(intersect, unique_ids)

  ubiquitous_sample <- sample(x = ubiquitous_ids, size = size)

  check_ubiquitous_sample(unique_ids, ubiquitous_sample)

  ubiquitous_sample
}
