# Purpose: Create cox models to see if class predicts mortality, after
# controlling for sex and strain
# Author: William Mueller

model_cox <- function(census, var, covariates, age_death, censor) {

  # Trying to deal with the case when length class == 1 (not sure how this will
  # work)
  len_var <- length(unique(census[[var]]))
  if (len_var == 1) census[[var]] <- as.numeric(census[[var]])

  keep_covariates <- lapply(covariates, function(cov) {
    l <- length(unique(census[[cov]]))
    if (l == 1) {
      FALSE
    } else {
      TRUE
    }
  })

  covariates <- covariates[as.logical(keep_covariates)]

  if (length(covariates) == 0) {
    rhs1 <- var
    rhs2 <- var
    rhs3 <- var
  } else {
    rhs1 <- var
    rhs2 <- paste(var, "+", paste(covariates, sep = " + "))
    rhs3 <- paste(var, "+", paste(covariates, sep = " * "))
  }


  f_list <- list(rhs1, rhs2, rhs3)
  model_list <- lapply(f_list, function(form) {
    form <- paste("surv_object", form, sep = " ~ ")
    form <- as.formula(form)
    surv_object <- Surv(time = census[[age_death]], event = census[[censor]])
    coxph(form, data = census)
    coxph
  })

  model_list
}
