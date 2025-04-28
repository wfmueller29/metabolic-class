# make all strings lowercase
clean_string <- function(string) {
  # make all strings lowercase
  string <- tolower(string)
  # remove anything inside ()
  string <- gsub("\\(.*\\)", "", string)
  # remove whitespace
  string <- unlist(lapply(string, trimws, whitespace = "[\\h\\v]"))
  # replace "" with NA
  string <- gsub(pattern = "^$", replacement = NA, string)
  # return string
  string
}

extract_parens <- function(string) {
  string <- stringr::str_extract(string, pattern = "\\((.*)\\)")
  string <- stringr::str_remove(string, pattern = "\\(")
  string <- stringr::str_remove(string, pattern = "\\)")
  string
}


split_delim <- function(string, name) {
  # split string based upon the following < + > < and > </> <, >
  string_df <- stringr::str_split_fixed(string,
    pattern = " \\+ | and |\\/|\\, ",
    n = Inf
  )
  # store as dataframe
  string_df <- as.data.frame(string_df)
  # assign names from name variable
  names(string_df) <- paste(name, seq_len(length(string_df)), sep = "_")
  # return string_df
  string_df
}

extract_parens_across <- function(string_df) {
  # apply extract parens across all columns of string_df
  parens_columns_list <- lapply(names(string_df), function(name) {
    extract_parens(string_df[[name]])
  })
  # get names based upon names of string_df
  parens_columns_df_names <- paste(names(string_df), "parens", sep = "_")
  # store as dataframe
  parens_columns_df <- as.data.frame(parens_columns_list)
  # assign names to dataframe
  names(parens_columns_df) <- parens_columns_df_names
  # combine parens_columns_df with string_df
  string_df <- cbind(string_df, parens_columns_df)
  # return string_df
  string_df
}

dvr_cod_protocol <- function(cod, name = "cod") {
  string_df <- split_delim(cod, name)
  string_df <- extract_parens_across(string_df)
  string_df_new <- apply(as.matrix(string_df), 2, clean_string)
  string_df_new <- as.data.frame(string_df_new)
  names(string_df_new) <- names(string_df)
  string_df_new
}
