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

  formula <- paste(outcome, formula, collapse = " ")
  formula <- paste0(formula, " + (1|", variable, ")")

  formula <- as.formula(formula)
  model <- lme4::lmer(
    formula = formula,
    data = data
  )
  random_intercept <- lme4::ranef(model)
  random_intercept_variable <- random_intercept[[variable]]
  random_intercept_variable <- tibble::rownames_to_column(
    random_intercept_variable,
    variable
  )
  random_intercept_variable <- as.data.frame(random_intercept_variable)

  data <- base::merge(data, random_intercept_variable, by = variable)

  save_outcome <- paste0(outcome, "_before_harm")
  data[, save_outcome] <- data[, outcome]
  data[, outcome] <- data[, outcome] - data[, "(Intercept)"]

  data
}
