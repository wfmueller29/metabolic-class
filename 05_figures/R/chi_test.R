# Purpose: Perform chi-squared test on columns from a census
# Author: William Mueller
chi_test <- function(census, columns) {
  
  # Create t1 table from census with total = FALSE and surv = FALSE
  t1 <- t1(census, columns, total = FALSE, surv = FALSE)
  
  if (!is.na(t1)) {
    result <- create_chi_test(t1, columns)
  } else {
    cat("T1 was NA \n")
    result <- NA
  }
  result

}

create_chi_test <- function(t1, columns) {
  # We only want first column of counts from t1
  l <- length(t1) / 3
  # Take transpose and subsets only count rows
  t1 <- data.frame(t(t1))[1:l, ]
  # make sure those count rows are numeric
  t1 <- data.frame(apply(t1, 2, as.numeric))

  # select columns that we would like to do chi_test on
  test_dfs <- list()
  for (col in columns) {
    test_dfs[[col]] <- t1 %>%
      select(starts_with(col))
  }

  # apply chi_test
  tests <- lapply(test_dfs, function(df) {
    chisq.test(data.matrix(df))
  })

  # return test and dataframe used for test
  list(tests = tests, dfs = test_dfs)
    
}