# Purpose: Create mixed effects model for metabolic class determined by one
# outcome across other outcomes
# Author: William Mueller
#

model_combined <- function(census,
                           outcome_df,
                           fixcovs,
                           outcome,
                           age_vars,
                           class,
                           census_id,
                           outcome_id) {
  combined_df <- create_combined_df(census, census_id, outcome_df, outcome_id)

  if (nrow(combined_df) == 0) {
    return("No overlapping subjects")
  }

  if (length(unique(combined_df[[outcome_id]])) < 2) {
    return("Need more than one subject to model")
  }

  # Keep fixcov if there are more than one value for the factor
  keep_fixcovs <- lapply(fixcovs, function(fixcov) {
    l <- length(unique(combined_df[[fixcov]]))
    if (l == 1) {
      keep <- FALSE
    } else {
      keep <- TRUE
    }
    keep
  })

  fixcovs <- fixcovs[as.logical(keep_fixcovs)]

  age_vars <- paste0(age_vars, "_ns")

  age_sum <- paste(age_vars, collapse = " + ")
  class_term0 <- age_sum
  class_term1 <- age_sum
  if (length(unique(combined_df[[class]])) != 1) {
    class_term0 <- paste(age_sum, class, sep = " + ")
    class_term1 <- paste0("(", age_sum, ")", " * ", class)
  }
  raneff <- paste0("(", age_sum, " | ", census_id, ")")
  fixeff0 <- paste(outcome, "~", class_term0)
  fixeff1 <- paste(outcome, "~", class_term1)
  interact <- paste0("+ ", "(", age_sum, ")", " * ")
  if (length(fixcovs) > 0) {
    fixeff0.5 <- paste(fixeff0, paste(fixcovs, collapse = " * "), sep = " + ")
    fixeff2 <- paste(fixeff1, paste(fixcovs, collapse = " * "), sep = " + ")
    fixeff3 <- paste(fixeff1,
      interact,
      paste(fixcovs, collapse = " * "),
      sep = " "
    )
  } else {
    fixeff0.5 <- fixeff0
    fixeff2 <- fixeff1
    fixeff3 <- fixeff1
  }

  fixeff_list <- list(fixeff0, fixeff0.5, fixeff1, fixeff2, fixeff3)
  formula_list <- lapply(fixeff_list, paste, "+", raneff)
  formula_list <- lapply(formula_list, as.formula)
  model_list <- lapply(formula_list, lme4::lmer, data = combined_df)

  model_list
}


model_combined_across <- function(final_models, datasets,
                                  model_name, fixcovs, class) {
  final_models_row <- final_models[final_models$model_name == model_name, ]
  outcome_df <- final_models_row$dfs[[1]]
  outcome_id <- final_models_row$subject
  outcome <- final_models_row$oc
  dataset_index <- final_models_row$dataset_index
  age_vars <- datasets[[dataset_index]]$age_var
  fixcovs <- final_models_row$fixcov[[1]]
  models <- lapply(seq_len(nrow(final_models)), function(i) {
    model_combined(
      census = final_models$census[[i]],
      outcome_df = outcome_df,
      fixcovs = fixcovs,
      outcome = outcome,
      age_vars = age_vars,
      class = class,
      census_id = final_models$subject[[i]],
      outcome_id = outcome_id
    )
  })
  models
}
