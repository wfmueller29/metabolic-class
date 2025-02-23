# This file is going to combine metabolic classes to create one mortality
# prediction
surv_tmerge <- function(data, id, age, age_death, dead_censor, outcomes) {
  data_baseline <- data[order(data[[id]], data[[age]]), , drop = FALSE]
  data_baseline <- data_baseline[!duplicated(data_baseline[[id]]), ,
    drop = FALSE
  ]
  cl_tmerge1 <- rlang::call2("tmerge",
    data1 = as.symbol("data_baseline"),
    data2 = as.symbol("data_baseline"),
    id = as.symbol(id),
    tstart = as.symbol(age),
    tstop = as.symbol(age_death),
    .ns = "survival"
  )
  data1 <- eval(cl_tmerge1)

  # Second tmerge --------------------------------------------------------------
  args <- lapply(c(outcomes, age), function(outcome) {
    call("tdc", as.symbol(age), as.symbol(outcome))
  })
  args <- c(args, call("event", as.symbol(age_death), as.symbol(dead_censor)))
  # name args
  names(args) <- c(outcomes, "age", dead_censor)
  # Create call
  cl_tmerge2 <- rlang::call2("tmerge",
    data1 = as.symbol("data1"),
    data2 = as.symbol("data"),
    id = as.symbol(id),
    !!!args,
    .ns = "survival"
  )
  data2 <- eval(cl_tmerge2)

  return(data2)
}

surv_cox <- function(data,
                     covariates,
                     time,
                     time2 = NULL,
                     death,
                     tt = NULL,
                     type = c("right", "left", "interval", "counting", "interval2", "mstate")) {
  if (is.null(time2)) {
    surv_object <- survival::Surv(
      time = data[[time]],
      event = data[[death]],
      type = type
    )
  } else {
    surv_object <- survival::Surv(
      time = data[[time]],
      time2 = data[[time2]],
      event = data[[death]]
    )
  }
  cox.form <- stats::as.formula(paste0("surv_object", deparse1(covariates)))

  if (is.null(tt)) {
    fit <- survival::coxph(cox.form, data = data)
  } else {
    fit <- survival::coxph(cox.form, data = data, tt = tt)
  }
  return(fit)
}


combine_data <- function(data, ids, age_vars, outcomes, census, census_id) {
  data <- mapply(
    function(data, outcome, age_var, id) {
      data <- data[, c(outcome, age_var, id)]
      list(data = data, id = id, age_var = age_var)
    },
    data = data, outcome = outcomes, age_var = age_vars, id = ids,
    SIMPLIFY = FALSE
  )

  merged_data <- Reduce(function(x, y) {
    data <- merge(
      x = x$data, y = y$data,
      by.x = c(x$id, x$age_var), by.y = c(y$id, y$age_var), all = TRUE
    )
    list(data = data, id = x$id, age_var = x$age_var)
  }, data)

  merged_data$data <- merge(
    x = merged_data$data, y = census,
    by.x = merged_data$id, by.y = census_id
  )

  merged_data
}

tmerge_prediction_data <- function(data, id, age, age_death, outcomes) {
  print(nrow(data))
  if (nrow(data) == 0) {
    warning("Cannot perform surv_tmerge, 0 nrows in data")
    return(data)
  }

  tmerged_data <- surv_tmerge(
    data = data,
    id = id,
    age = age,
    age_death = age_death,
    outcomes = outcomes
  )

  prob_cols <- names(tmerged_data)[grepl("^prob", names(tmerged_data))]
  prob_cols_drop <- sapply(prob_cols, function(name) {
    all(tmerged_data[[name]] == 1)
  })
  prob_cols <- prob_cols[!prob_cols_drop]

  tmerged_data[, prob_cols] <- lapply(tmerged_data[, prob_cols],
    log,
    base = 1.1
  )

  tmerged_data
}

combine_census <- function(censuses, ids, outcomes) {
  # Select probability of class membership and id's
  censuses_bare <- mapply(function(census, id, outcome) {
    # get prob column names
    probs <- names(census)[grepl("^prob", names(census))]
    class <- names(census)[grepl("^new_class$", names(census))]
    census <- census[, c(id, probs, class)]
    names(census)[names(census) == "new_class"] <- paste0("new_class_", outcome)
    census
  }, census = censuses, id = ids, outcome = outcomes, SIMPLIFY = FALSE)

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

create_combined_cox <- function(data,
                                id,
                                age,
                                age_death,
                                death_censor,
                                outcomes,
                                covariates) {
  # WARNING: We probably do not need tmerge here, something throwing warnings
  tmerged_data <- surv_tmerge(
    data = data,
    id = id,
    age = age,
    age_death = age_death,
    dead_censor = death_censor,
    outcomes = outcomes
  )

  new_class_cols <- names(tmerged_data)[grepl("^new_class", names(tmerged_data))]
  new_class_cols_drop <- sapply(new_class_cols, function(name) {
    all(tmerged_data[[name]] == 1)
  })
  new_class_cols <- new_class_cols[!new_class_cols_drop]

  prob_cols <- names(tmerged_data)[grepl("^prob", names(tmerged_data))]
  prob_cols_drop <- sapply(prob_cols, function(name) {
    all(tmerged_data[[name]] == 1)
  })
  prob_cols <- prob_cols[!prob_cols_drop]

  keep_new_class_cols <- sapply(new_class_cols, function(col) {
    number_unique <- length(unique(data[[col]]))
    if (number_unique == 1) {
      return(FALSE)
    } else {
      return(TRUE)
    }
  })

  # drop new_class_cols that only have one value, otherwise contrast error
  new_class_cols <- new_class_cols[keep_new_class_cols]

  # drop any prob_cols from outcomes
  outcomes <- outcomes[!outcomes %in% prob_cols]

  if (!is.null(covariates)) {
    cov_form <- paste0("~", "(", covariates, ")")
    form1 <- paste0(cov_form, "+", paste(new_class_cols, collapse = "+"))
    form2 <- paste0(cov_form, "+", paste(prob_cols, collapse = "+"))
    form3 <- paste0(
      cov_form, "*",
      "(", paste(prob_cols, collapse = "+"), ")"
    )
  } else {
    cov_form <- "~"
    form1 <- paste0(cov_form, paste(new_class_cols, collapse = "+"))
    form2 <- paste0(cov_form, paste(prob_cols, collapse = "+"))
    form3 <- paste0(
      cov_form,
      "(", paste(prob_cols, collapse = "+"), ")"
    )
  }

  forms <- list(form1, form2, form3)
  forms <- lapply(forms, as.formula)

  cox_outputs <- mapply(surv_cox, covariates = forms, MoreArgs = list(
    data = tmerged_data,
    time = "tstart",
    time2 = "tstop",
    death = dead_censor,
  ), SIMPLIFY = FALSE)

  cox_outputs
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
  census_id <- merged_census$id
  census <- merged_census$census

  if (nrow(census) == 0) {
    warning("There are no observations that intersect the censuses of interest")
    warning("cox_combine_class will output an NA value")
    return(NA)
  }

  data <- final_models[model_index, "dfs"]
  age_vars <- final_models[model_index, "age_var"]
  age_vars <- paste0(age_vars, "_ns")

  merged_data <- combine_data(
    data = data, ids = ids, age_vars = age_vars, outcomes = outcomes,
    census = census, census_id = census_id
  )

  cox_model <- create_combined_cox(
    data = merged_data$data,
    id = merged_data$id,
    age = merged_data$age_var,
    age_death = age_death,
    death_censor = censor,
    outcomes = outcomes,
    covariates = covariates
  )

  cox_model
}
