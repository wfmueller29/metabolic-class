# sample the number or proportion of measurements by grouping variable

# loop through sample_loop for list of subsets
sample_loop <- function(data, n) {
  names <- lapply(n, paste, collapse = "_")
  filter_list <- lapply(n, sample_measures, data = data)
  names(filter_list) <- names
  filter_list
}

sample_group_n <- function(x, size) {
  if (size >= length(x)) {
    samp <- sample(x = size, size = size)
  } else {
    samp <- sample(x = x, size = size)
  }
  samp
}

sample_group_p <- function(x, p) {
  sample_size <- round(x * p, digits = 0)
  samp <- sample(x = x, size = sample_size)
  samp
}

sample_measures <- function(data, n) {
  group <- names(n)
  n <- unname(n)
  dt <- data.table::as.data.table(data)
  if (n >= 1) {
    dt <- dt[, .SD[sample_group_n(1:.N, n)], by = group]
  }

  if (n < 1 & n > 0) {
    dt <- dt[, .SD[sample_group_p(1:.N, p = n)], by = group]
  }
  data <- as.data.frame(dt)

  data
}
