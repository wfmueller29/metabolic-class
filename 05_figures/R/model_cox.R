# Purpose: Create cox models to see if class predicts mortality, after
# controlling for sex and strain
# Author: William Mueller

model_cox <- function(census, formulas, age_death, censor) {
  # Trying to deal with the case when length class == 1 (not sure how this will
  # work)

  f_list <- formulas
  model_list <- lapply(f_list, function(form) {
    form <- paste("surv_object", form)
    form <- as.formula(form)
    surv_object <- survival::Surv(time = census[[age_death]],
                                  event = census[[censor]])
    survival::coxph(form, data = census)
  })

  model_list
}
