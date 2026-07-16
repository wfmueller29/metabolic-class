# Harmonize
#### ----------------------------------------
#### HARMONIZATION: Batch effect correction
#### (adapted from Jorge's clock'):
#### ----------------------------------------

# Fit a mixed effect model to determine the intercept difference
# corresponding to each cohort 1 to 10. NAs not avoided.
# ID and cohort are considered random effects (but we are only goig to substract cohort contribution).

# One model per feature as outcome,e.g.:
# bw ~ age^2 + age + sex * strain + (1|cohort) +(1|ID) # This model should have the same fixed and random structure that the one we'll use for the LCA (except for the cohort effect)

# Then subtract that random coefficient (per cohort) from values under each variable.

# Then, in the LCA we will use the new bw obtained after substracting cohort effect.


harmonize <- function(data, formula, outcome, variable) {
  save_outcome <- paste0(outcome, "_before_harm")
  data[, save_outcome] <- data[, outcome]

  formula <- paste(outcome, formula, collapse = " ")
  form_variable <- lapply(variable, function(var) {
    variable <- paste0("(1|", var, ")")
  })
  formula <- paste(formula, paste(form_variable, collapse = " + "), sep = " + ")

  formula <- as.formula(formula)
  model <- lme4::lmer(
    formula = formula,
    data = data
  )
  random_intercept <- lme4::ranef(model)
  random_intercept_variable <- lapply(variable, function(variable) {
    random_intercept[[variable]]
  })
  random_intercept_variable <- lapply(seq_along(variable), function(i) {
    df <- tibble::rownames_to_column(
      random_intercept_variable[[i]],
      variable[[i]]
    )
    names(df)[[2]] <- paste0("intercept_", names(df)[[1]])
    df
  })
  random_intercept_variable <- lapply(random_intercept_variable, as.data.frame)

  for (i in seq_along(variable)) {
    var <- variable[[i]]
    data <- base::merge(data, random_intercept_variable[[i]], by = var)
    data[, outcome] <- data[, outcome] - data[, paste0("intercept_", var)]
  }
  intercept_vars <- paste("intercept", variable, sep = "_")
  intercept_combined <- do.call(`+`, data[, intercept_vars, drop = FALSE])

  should_be_zero <- data[[outcome]] + intercept_combined - data[[save_outcome]]
  # to correct small rounding error
  should_be_zero <- round(should_be_zero, 10)
  test <- should_be_zero == 0
  if (!isTRUE(all(test))) {
    stop("There was an error in harmonization")
  }

  for (var in variable) {
    data[[outcome]] + data[[paste0("interceptk")]]
  }


  data
}
