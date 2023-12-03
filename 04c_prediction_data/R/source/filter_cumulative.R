.filter_cumulative <- function(data, age_var, start, end, step) {
  upper_bound <- start + step
  lower_bound <- start
  sampled_data_list <- list()
  while (upper_bound <= end) {
    keep <- (data[[age_var]] > lower_bound) & (data[[age_var]] < upper_bound)
    data_new <- data[keep, ]
    if (nrow(data_new) > 0) {
      new_name <- paste0("[", lower_bound, ", ", upper_bound, "]")
      new_names <- c(names(sampled_data_list), new_name)
      sampled_data_list <- c(sampled_data_list, list(data_new))
      names(sampled_data_list) <- new_names
    } else {
      sampled_data_list <- sampled_data_list
    }
    upper_bound <- upper_bound + step
    lower_bound <- lower_bound
  }

  sampled_data_list
}

.filter_cumulative_across <- function(data, age_var, start_vector, end, step) {
  new_datasets <- list()
  for (start in start_vector) {
    new_dataset <- .filter_cumulative(data, age_var, start, end, step)
    new_datasets <- c(new_datasets, new_dataset)
  }
  new_datasets
}

.filter_cumulative_across_apply <- function(data_list,
                                            age_var,
                                            start_vector,
                                            end,
                                            step) {
  sampled_data_list <- lapply(data_list,
    .filter_cumulative_across,
    age_var = age_var,
    start_vector = start_vector,
    end = end,
    step = step
  )

  sampled_data_list
}

filter_cumulative <- function(data_list, age_var, start_vector, end, step) {
  .filter_cumulative_across_apply(data_list, age_var, start_vector, end, step)
}

# make these for datasets -----------------------------------------------------

.filter_cumulative_across_dataset <- function(dataset, test_data) {
  if (isFALSE(test_data)) {
    data <- dataset$data
    age_var <- dataset$prediction_data$filter_cumulative$age_var
    start_vector <- dataset$prediction_data$filter_cumulative$start_vector
    end <- dataset$prediction_data$filter_cumulative$end
    step <- dataset$prediction_data$filter_cumulative$step
    dataset$prediction_data$data$filter_cumulative_data <-
      .filter_cumulative_across(
        data,
        age_var,
        start_vector,
        end,
        step
      )
  } else if (isTRUE(test_data)) {
    data <- dataset$test_data
    print(data)
    if (is.null(data)) {
      dataset$prediction_test_data$data$filter_cumulative_data <- NA
    } else {
      age_var <- dataset$prediction_data$filter_cumulative$age_var
      start_vector <- dataset$prediction_data$filter_cumulative$start_vector
      end <- dataset$prediction_data$filter_cumulative$end
      step <- dataset$prediction_data$filter_cumulative$step
      dataset$prediction_test_data$data$filter_cumulative_data <-
        .filter_cumulative_across(
          data,
          age_var,
          start_vector,
          end,
          step
        )
    }
  } else {
    stop("test_data argument must be a boolean value")
  }

  dataset
}

.filter_cumulative_across_dataset_apply <- function(datasets, test_data) {
  datasets <- lapply(datasets, .filter_cumulative_across_dataset, test_data)

  datasets
}

filter_cumulative_dataset <- function(datasets, test_data = FALSE) {
  datasets <- .filter_cumulative_across_dataset_apply(datasets, test_data)

  datasets
}
