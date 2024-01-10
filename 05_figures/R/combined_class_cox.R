# This file is going to combine metabolic classes to create one mortality
# prediction


# we are going to merge the census of the models specificied by each model
# list in the yaml configuration file.
combine_census <- function(model_name_vector,
                           final_model_object,
                           dead_censor,
                           age_death,
                           covariates) {
  # rename inputs
  final_models <- final_model_object

  # get list of censuses
  model_index <- final_models$model_name %in% model_name_vector
  censuses <- final_models[model_index, ]$census
  ids <- final_models[model_index, "subject"]

  # Select probability of class membership and id's
  censuses_bare <- mapply(function(census, id) {
    # get prob column names
    probs <- names(census)[grepl("^prob", names(census))]
    census <- census[, c(id, probs)]
  }, census = censuses, id = ids)

  xy_list <- mapply(function(census, id) {
    list(census = census, id = id)
  }, census = censuses_bare, id = ids, SIMPLIFY = FALSE)

  merged_census <- Reduce(function(x, y) {
    census <- merge(x = x$census, y = y$census, by.x = x$id, by.y = y$id)
    id <- x$id
    list(census = census, id = id)
  }, xy_list)

  merged_census_id <- merged_census$id
  merged_census <- merged_census$census
  merged_census <- merged_census[complete.cases(merged_census), ]

  censuses <- mapply(function(census, id) {
    census <- census[, !grepl("^prob", colnames(census))]
    census <- merge(census, merged_census, by.x = id, by.y = merged_census_id)
    census
  }, census = censuses, id = ids, SIMPLIFY = FALSE)

  # remove outcome specific names from the census
  censuses <- lapply(censuses, function(census) {
    census[, !names(census) %in% c("class", "Class", "new_class")]
  })

  # check if all censuses are equal (because they should be)
  check <- lapply(censuses, function(census) {
    all.equal(census, censuses[[1]])
  })
  check <- do.call(all.equal, check)
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
                              covariates,
                              age_death,
                              censor) {
  merged_census <- combine_census(
    model_name_vector,
    final_model_object,
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
