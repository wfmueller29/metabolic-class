
.filter_window <- function(data, age_var, start, end, window_size, step) {
  upper_bound <- start + window_size
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
    lower_bound <- lower_bound + step
  }

  sampled_data_list
}

.filter_window_across <- function(data,
                                  age_var,
                                  start,
                                  end, window_size_vector, step) {
  new_datasets <- list()
  for (window_size in window_size_vector) {
    new_dataset <- .filter_window(
      data,
      age_var,
      start,
      end,
      window_size,
      step
    )

    new_datasets <- c(new_datasets, new_dataset)
  }
  new_datasets
}

.filter_window_across_apply <- function(data_list,
                                        age_var,
                                        start,
                                        end,
                                        window_size_vector,
                                        step) {
  sampled_data_list <- lapply(data_list,
    .filter_window_across,
    age_var = age_var,
    start = start,
    end = end,
    window_size_vector = window_size_vector,
    step = step
  )

  sampled_data_list
}

filter_window <- function(data_list,
                          age_var,
                          start,
                          end,
                          window_size_vector,
                          step) {
  .filter_window_across_apply(
    data_list,
    age_var,
    start,
    end,
    window_size_vector,
    step
  )
}

# make these for datasets -----------------------------------------------------

.filter_window_across_dataset <- function(dataset) {

  data <- dataset$data
  age_var <- dataset$prediction_data$filter_window$age_var
  end <- dataset$prediction_data$filter_window$end
  start <- dataset$prediction_data$filter_window$start
  window_size_vector <- dataset$prediction_data$filter_window$window_size_vector
  step <- dataset$prediction_data$filter_window$step

  dataset$prediction_data$data$filter_window_data <- .filter_window_across(
    data,
    age_var,
    start,
    end,
    window_size_vector,
    step
  )

  dataset
}

.filter_window_across_dataset_apply <- function(datasets) {
  datasets <- lapply(datasets, .filter_window_across_dataset)

  datasets
}

filter_window_dataset <- function(datasets) {
  datasets <- .filter_window_across_dataset_apply(datasets)

  datasets
}
