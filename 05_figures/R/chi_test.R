# Purpose: Perform chi-squared test on columns from a census
# Author: William Mueller
chi_test <- function(census, columns, age_death, event) {
  # Create t1 table from census with total = FALSE and surv = FALSE
  t1 <- t1(census, columns, age_death = age_death, event = event)

  if (class(t1) == "data.frame") {
    result <- create_chi_test(t1, columns)
  } else if (is.na(t1)) {
    cat("T1 was NA \n")
    result <- NA
  } else {
    cat("T1 is not NA or a data.frame \n")
    stop("T1 is not NA or a data.frame")
  }

  result
}

create_chi_test <- function(t1, columns, age_death, event) {
  browser()
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
    if (l != 1) {
      chisq.test(data.matrix(df))
    } else {
      NA
    }
  })

  # return test and dataframe used for test
  list(tests = tests, dfs = test_dfs)
}
