# Purpose: Create mixed effects model for metabolic class determined by one
# outcome across other outcomes
# Author: William Mueller
#

model_other <- function(census,
                        other_df,
                        fixcovs,
                        outcome,
                        age_var,
                        class,
                        subject) {
  new_df <- create_other_plot_df(census, other_df)

  # Keep fixcov if there are more than one value for the factor
  keep_fixcovs <- lapply(fixcovs, function(fixcov) {
    l <- length(unique(new_df[[fixcov]]))
    if (l == 1) {
      FALSE
    } else {
      TRUE
    }
  })

  fixcovs <- fixcovs[as.logical(keep_fixcovs)]

  age_var2 <- paste0(age_var, "2")
  if (length(unique(new_df[[class]])) == 1) {
    class_term0 <- paste(age_var, age_var2, sep = " + ")
    class_term1 <- paste(age_var, age_var2, sep = " + ")
  } else {
    class_term0 <- paste(age_var, age_var2, class, sep = " + ")
    class_term1 <- paste("(", age_var, "+", age_var2, ")", "*", class)
  }
  raneff <- paste("(", age_var, "+", age_var2, "|", subject, ")", sep = " ")
  fixeff0 <- paste(outcome, "~", class_term0)
  fixeff1 <- paste(outcome, "~", class_term1)
  interact <- paste("+", "(", age_var, "+", age_var2, ")", "*", sep = " ")
  if (length(fixcovs) > 0) {
    fixeff0.5 <- paste(fixeff0, paste(fixcovs, sep = " * "), sep = " + ")
    fixeff2 <- paste(fixeff1, paste(fixcovs, sep = " * "), sep = " + ")
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
  model_list <- lapply(formula_list, lmer, data = new_df)

  model_list
}


model_other_apply <- function(final_models, model_name, fixcovs, class) {
  x <- final_models
  other_df <- x[x$model_name == model_name, ]$dfs[[1]]
  outcome <- x[x$model_name == model_name, ]$oc
  models <- lapply(seq_len(nrow(x)), function(i) {
    model_other(
      census = x$census[[i]],
      other_df = other_df,
      fixcovs = fixcovs,
      outcome = outcome,
      age_var = x$age_var[[i]],
      class = class,
      subject = x$subject[[i]]
    )
  })
  models
  
}

