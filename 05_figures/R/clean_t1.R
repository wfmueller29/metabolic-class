source("R/chi_test.R")
source("R/t1.R")

clean_t1 <- function(census,
                     columns,
                     include_n = TRUE,
                     surv = TRUE,
                     total = TRUE) {

  # create t1
  df_table <- create_count_columns(census, columns, total = include_n, surv = surv)
  t1 <- t1(census, columns, total = include_n, surv = surv)

  total <- rowSums(df_table)

  t1 <- t1 %>%
    select(ends_with("_final"))

  # add total column
  if (total) {
    t1$total <-  total
    if (surv) {
      t1[grepl(rownames(t1), pattern = "surv"), "total"] <- NA
    }
  }

  # get chi squared results for t1
  chi_result <- chi_test(census, columns)
  chi_tests <-  chi_result$tests

  # create named list of pvals with column name
  pvals <- list()
  for (col in columns) {
    pvals[[col]] <- chi_tests[[col]]$p.value
  }

  t1_rownames <- rownames(t1)
  for (col in columns) {
    matches <- grepl(col, t1_rownames)
    t1$pval[matches] <- pvals[[col]]
  }

  # return cleaned t1
  t1

}
