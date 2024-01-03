source("R/chi_test.R")
source("R/t1.R")

clean_t1 <- function(census,
                     columns,
                     age_death,
                     event) {
  # create t1
  df_table <- create_count_columns(census,
    columns,
    age_death = age_death,
    event = event
  )
  t1 <- t1(census, columns, age_death = age_death, event = event)

  if (class(t1) == "data.frame") {
    clean_t1 <- create_clean_t1(
      df_table,
      t1,
      census,
      columns,
      age_death,
      event
    )
  } else if (is.na(t1)) {
    cat("T1 was NA \n")
    clean_t1 <- NA
  } else {
    cat("T1 is not NA or a data.frame \n")
    stop("T1 is not NA or a data.frame")
  }

  clean_t1
}

create_clean_t1 <- function(df_table,
                            t1,
                            census,
                            columns,
                            age_death,
                            event) {
  total <- rowSums(df_table)

  t1 <- t1[, grepl("_final", colnames(t1)), drop = FALSE]

  # add total column
  t1$total <- total
  t1[grepl(rownames(t1), pattern = "surv"), "total"] <- NA

  # get chi squared results for t1
  chi_result <- chi_test(census, columns, age_death, event)
  chi_tests <- chi_result$tests

  # create named list of pvals with column name
  pvals <- list()

  for (col in columns) {
    if (class(chi_tests[[col]]) == "htest") {
      pvals[[col]] <- chi_tests[[col]]$p.value
    } else if (is.na(chi_tests[[col]])) {
      pvals[[col]] <- NA
    } else {
      stop("chi_tests is not of class htest and is not NA")
    }
  }

  t1_rownames <- rownames(t1)
  for (col in columns) {
    matches <- grepl(col, t1_rownames)
    t1$pval[matches] <- pvals[[col]]
  }

  # return cleaned t1
  t1
}
