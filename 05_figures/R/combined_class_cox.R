# This file is going to combine metabolic classes to create one mortality
# prediction


# we are going to merge the census of the models specificied by each model
# list in the yaml configuration file.

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

  cox_model <- cox_merged_class(
    merged_census = merged_census,
    covariates = covariates,
    age_death = age_death,
    censor = censor
  )

  cox_model
}
