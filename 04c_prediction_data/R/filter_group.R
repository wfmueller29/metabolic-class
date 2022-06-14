# This R script has functions that filter by group
# Author: William Mueller

source("R/filter_utils.R")

# loop through filter_group for list of subsets
filter_loop <- function(data, subsets) {
  names <- lapply(subsets, paste, collapse = "_")
  filter_list <- lapply(subsets, filter_group, data = data)
  names(filter_list) <- names
  filter_list
}
# here subsets is a named vector where the name is column and val is the column
# value we would like to subset
filter_group <- function(data, subsets) {
  dt <- data.table::as.data.table(data)
  subsets <- named_vector_list(subsets)
  filter_calls <- lapply(subsets, filter_call)
  if (length(filter_calls) > 1) {
    filter_calls <- do.call(combine_amper, filter_calls)
  } else {
    filter_calls <- filter_calls[[1]]
  }

  dt <- dt[eval(filter_calls), ]
  data <- as.data.frame(dt)
  data
}

filter_call <- function(subset) {
  col <- names(subset)
  val <- unname(subset)
  filter_call <- call("==", as.symbol(col), val)
  filter_call
}

# test-------------------------------------------------------------------------
# test filter call
test <- quote(sex == "M") == filter_call(subset = c(sex = "M"))
if (!test) stop("filter_call is broken")

