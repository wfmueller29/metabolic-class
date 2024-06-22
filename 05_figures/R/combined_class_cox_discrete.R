# Combined Class Cox Discrete

combine_census <- function(censuses, ids, outcomes) {
  # Select probability of class membership and id's
  censuses_bare <- mapply(function(census, id, outcome) {
    # get prob column names
    probs <- names(census)[grepl("^prob", names(census))]
    class <- names(census)[grepl("^new_class$", names(census))]
    census <- census[, c(id, probs, class)]
    names(census)[names(census) == "new_class"] <- paste0("new_class_", outcome)
    census
  }, census = censuses, id = ids, outcome = outcomes)

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

  list(census = census, id = merged_census_id)
}


cox_combine <- function(model_name_vector,
                        final_model_object,
                        covariates,
                        age_death,
                        censor) {
  # rename inputs
  final_models <- final_model_object

  model_index <- final_models$model_name %in% model_name_vector
  censuses <- final_models[model_index, ]$census
  ids <- final_models[model_index, "subject"]
  outcomes <- final_models[model_index, "oc"]

  merged_census <- combine_census(
    censuses = censuses,
    ids = ids,
    outcomes = outcomes
  )

  data <- merged_census$census

  class_names <- names(data)[grepl("^new_class", names(data))]
  prob_names <- names(data)[grepl("^prob", names(data))]
  class_form_add <- paste(class_names, collapse = "+")
  prob_form_add <- paste(prob_names, collapse = "+")
  class_form_interact <- paste(class_names, collapse = "*")
  surv_obj <- survival::Surv(time = data$le_wk, event = data$dead_censor)
  form1 <- as.formula(paste("surv_obj ~", class_form_add, "+", covariates))
  form2 <- as.formula(paste("surv_obj ~", prob_form_add, "+", covariates))
  forms <- list(form1, form2)
  cox_combined <- lapply(forms, survival::coxph, data)

  cox_combined
}
