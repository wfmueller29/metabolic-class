# Create filter interval for datasets
filter_interval_dataset <- function(datasets, test_data = FALSE) {
  datasets <- lapply(datasets, function(dataset) {
    if (isFALSE(test_data)) {
      intervals <- dataset$prediction_data$filter_interval$intervals
      intervals <- lapply(intervals, unlist, use.names = TRUE)
      data <- dataset$data
      dataset$prediction_data$data$filter_interval_data <-
        filter_interval_loop(data, intervals)
    } else if (isTRUE(test_data)) {
      data <- dataset$test_data
      if (is.null(data)) {
        dataset$prediction_test_data$data$filter_interval_data  <- NA
      } else {
        intervals <- dataset$prediction_data$filter_interval$intervals
        intervals <- lapply(intervals, unlist, use.names = TRUE)
        dataset$prediction_test_data$data$filter_interval_data <-
          filter_interval_loop(data, intervals)
      }
    } else {
      stop("test_data argument must be a boolean value")
    }
    dataset
  })
}
# loop through filter_interval for list of intervals
filter_interval_loop <- function(data, intervals) {
  names <- lapply(intervals, paste, collapse = "_")
  filter_list <- lapply(intervals, filter_interval, data = data)
  names(filter_list) <- names
  filter_list
}
# Filter an Interval in a dataset
filter_interval <- function(data, intervals) {
  dt <- data.table::as.data.table(data)
  intervals <- named_vector_list(intervals)
  filter_calls <- lapply(intervals, filter_interval_call)
  if (length(filter_calls) > 1) {
    filter_calls <- do.call(combine_amper, filter_calls)
  } else {
    filter_calls <- filter_calls[[1]]
  }
  dt <- dt[eval(filter_calls), ]
  data <- as.data.frame(dt)
  data
}

# Create call to filter an interval
filter_interval_call <- function(interval) {
  col <- names(interval)
  interval <- unname(interval)
  # trim whitespace
  interval <- gsub(pattern = " ", replacement = "", interval)
  # get first and last character
  first <- substr(interval, 1, 1)
  last <- substr(interval, nchar(interval), nchar(interval))
  # get value of first interval
  lower_bound <- get_bound(which = "lower", interval = interval)
  upper_bound <- get_bound(which = "upper", interval = interval)
  # if [] or ()
  if (first == "(") {
    fun_low <- ">"
  } else if (first == "[") {
    fun_low <- ">="
  } else {
    stop("Incorrect lower bound, must be ( or [")
  }

  if (last == ")") {
    fun_high <- "<"
  } else if (last == "]") {
    fun_high <- "<="
  } else {
    stop("Incorecct upper bound, must be ) or ]")
  }
  # create calls
  lower_call <- call(name = fun_low, as.symbol(col), lower_bound)
  upper_call <- call(name = fun_high, as.symbol(col), upper_bound)

  filter_interval_call <- call("&", lower_call, upper_call)
  filter_interval_call
}

get_bound <- function(which, interval) {
  if (which == "lower") pattern <- ".*,"
  if (which == "upper") pattern <- ",.*"
  subset_interval <- regexpr(pattern = pattern, text = interval)
  subset_interval <- regmatches(interval, subset_interval)
  subset_interval <- substr(subset_interval, 2, nchar(subset_interval) - 1)
  subset_interval <- as.numeric(subset_interval)
  subset_interval
}


# tests------------------------------------------------------------------------
# test filter interval call
output <- filter_interval_call(c(sex = "( -213, Inf ]"))
should_output <- quote(sex > -213 & sex <= Inf)
if (!(output == should_output)) cat("filter_interval_call() not working")
