# use mixed effects models to determine fixed effects structure ---------------
# I think this is too complex for our pipeline to handle and also diminishes 
# the interpretability of the classes. Thus I am archiving this function
# Also note that this function does not fully work either and has not yet
# successfully been incorporated into the greater modelling pipeline. 

for (dataset in datasets) {
  dataset <- datasets[[1]] # delete
  if (dataset$model$generate_fixed) {
    fixcov <- dataset$model$fixcov
    fixcov_form <- paste(fixcov, collapse = " * ")
    age_vars <- dataset$age_var
    outcome <- dataset$outcome
    id <- dataset$id
    models <- list()
    for (age_var in age_vars) {
      age_form <- paste(age_var, paste0(age_var, "2"), sep = " + ")
      fixed_effects <- paste0("(", age_form, ")", " * ", "(", fixcov_form, ")")
      random_effects <- paste0("(", age_form, "|", id, ")") 
      form <- paste0(outcome, " ~ ", fixed_effects, " + ", random_effects)
      form <- as.formula(form)
      control <- buildmer::buildmerControl()
      model <- buildmer::buildmer(
        formula = form,
        data = dataset$data,
        buildmerControl = control
      )
      
      models <- c(models, model)
    }
    
    fixed_list <- list()
    for (model in models) {
      fixed <- as.character(model@model@call$formula[[3]][2])
      fixed <- paste("~ ", fixed)
      fixed_list <- c(fixed_list, fixed)
    }
    
  }
}
