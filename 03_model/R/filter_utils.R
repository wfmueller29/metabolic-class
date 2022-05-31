# unlist looped filter list
unlist_filter_list <- function(df_list) {
  df_list <- unlist(df_list, recursive = FALSE)
  new_names <- lapply(names(df_list),
    gsub,
    pattern = "\\.",
    replacement = "_"
  )
  names(df_list) <- new_names
  df_list
}

# named character vector to list of named characters
named_vector_list <- function(x) {
  x <- as.list(x)
  names <- names(x)
  named_char_list <- list()
  for (i in seq_along(x)) {
    named_char_list[[i]] <- x[[i]]
    names(named_char_list[[i]]) <- names[[i]]
  }
  named_char_list
}

# combine ambersand args
combine_amper <- function(filter_call1, filter_call2) {
  call <- call(
    "&", as.call(substitute(filter_call1)),
    as.call(substitute(filter_call2))
  )
}

# tests------------------------------------------------------------------------
# test named_vector_list
should_output <- list(c(sex = "M"), c(stain = "HET3"))
output <- named_vector_list(c(sex = "M", strain = "HET3"))
test <- identical(should_output, output)
if (test) stop("named_vector_list is broken")
