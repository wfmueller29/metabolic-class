# This file is going to combine metabolic classes to create one mortality
# prediction


# we are going to merge the census of the models specificied by each model
# list in the yaml configuration file.
combine_census <- function(model_name_vector,
                           final_model_object,
                           datasets_object,
                           dead_censor,
                           age_death,
                           covariates) {

  # things we can parameterize, but not doing it today
  fixcov <- covariates


  # rename inputs
  final_models <- final_model_object
  datasets <- datasets_object

  # get list of censuses
  model_index <- final_models$model_name %in% model_name_vector
  censuses <- final_models[model_index, ]$census

  # get datasets for models specified by model_name_vect so we can get their
  # id's
  dataset_names <- stringr::str_split(model_name_vector, "\\|", simplify = TRUE)[, 1]
  dataset_index <- names(datasets) %in% dataset_names
  datasets <- datasets[dataset_index]

  # get ids of datasets
  ids <- lapply(datasets, function(dataset) dataset$id)
  ids_unique <- unique(unlist(ids))

  if (length(ids_unique) != 1) stop("ID's for each census do not match")

  # Select probability of class membership and id's
  censuses_bare <- lapply(censuses, function(census) {

    # get prob column names
    probs <- names(census)[grepl("^prob", names(census))]
    census <- census[, c(ids_unique, probs)]
  })

  # merge census into one dataframe
  merged_census <- censuses_bare %>%
    purrr::reduce(dplyr::left_join, by = ids_unique)

  # filter out NA's in merge census
  merged_census <- merged_census[complete.cases(merged_census), ]

  # add merged census back to original census
  censuses <- lapply(censuses, function(census) {
    census <- census %>%
      dplyr::select(-rsample::starts_with("prob"))

    census <- merged_census %>%
      dplyr::left_join(census, by = ids_unique)
  })

  # remove outcome specific names from the census
  censuses <- lapply(censuses, function(census) {
    census[, !names(census) %in% c("class", "Class", "new_class")]
  })

  # check if all censuses are equal (because they should be)
  check <- do.call(all.equal, censuses)
  if (!isTRUE(check)) {
    print(check)
    stop("Not all censuses are equal \n")
  }

  census <- censuses[[1]]

  census
}


# Next we are going to construct the cox model.

cox_merged_class <- function(merged_census,
                             covariates,
                             age_death,
                             censor) {
  # make var from merged_census
  vars <- names(merged_census)[grepl("^prob", names(merged_census))]
  var <- paste(vars, collapse = " + ")

  cox_model <- model_cox(
    census = merged_census,
    var = var,
    covariates = covariates,
    age_death = age_death,
    censor = censor
  )

  cox_model
}

cox_combine_class <- function(model_name_vector,
                              final_model_object,
                              datasets_object,
                              covariates,
                              age_death,
                              censor) {
  merged_census <- combine_census(
    model_name_vector,
    final_model_object,
    datasets_object,
    covariates,
    age_death,
    censor
  )

  if (nrow(merged_census) == 0) {
    warning("There are no observations that intersect the censuses of interest")
    warning("cox_combine_class will output an NA value")
    return(NA)
  }

  cox_model <- cox_merged_class(
    merged_census = merged_census,
    covariates = covariates,
    age_death = age_death,
    censor = censor
  )

  cox_model
}
