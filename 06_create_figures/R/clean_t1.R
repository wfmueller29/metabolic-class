source("R/chi_test.R")
source("R/t1.R")

clean_t1 <- function(census,
                     columns,
                     age_death,
                     event,
                     chi_tests) {
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
      event,
      chi_tests
    )
  } else if (is.na(t1)) {
    cat("T1 was NA \n")
    clean_t1 <- NA
  } else {
    cat("T1 is not NA or a data.frame \n")
    stop("T1 is not NA or a data.frame")
  }

  mle_ci <- create_mle(
    data = census,
    age_death = age_death,
    event = event,
    ci = TRUE
  )
  mle_ci$total <- NA
  mle_ci$pval <- NA
  clean_t1 <- clean_t1[-nrow(clean_t1), ]
  clean_t1 <- rbind(clean_t1, mle_ci)

  clean_t1
}

create_clean_t1 <- function(df_table,
                            t1,
                            census,
                            columns,
                            age_death,
                            event,
                            chi_tests) {
  total <- rowSums(df_table)

  t1 <- t1[, grepl("_final", colnames(t1)), drop = FALSE]

  # add total column
  t1$total <- total
  t1[grepl(rownames(t1), pattern = "surv"), "total"] <- NA

  # get chi squared results for t1
  chi_result <- chi_test(census, columns, age_death, event)
  print(all.equal(chi_result, chi_tests))
  if (!all.equal(chi_result, chi_tests)) {
    stop("Our chi squared tests are not the same; something went wrong")
  } else {
    chi_results <- chi_tests
  }
  chi_tests <- chi_result$tests

  # create named list of pvals with column name
  pvals <- list()

  for (col in columns) {
    if (class(chi_tests[[col]]) == "htest") {
      pvals[[col]] <- signif(chi_tests[[col]]$p.value, 4)
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

  if (is.null(columns)) {
    t1$pval <- NA
  }

  # return cleaned t1
  t1
}

create_mle <- function(data,
                       age_death,
                       event,
                       ci = FALSE) {
  df_main <- data

  obj <- survival::Surv(time = df_main[[age_death]], event = df_main[[event]])
  surv_fit <- survival::survfit(data = df_main, obj ~ factor(new_class))

  df_surv <- survminer::surv_median(surv_fit)
  df_surv$median <- round(df_surv$median, 0)
  if (ci) {
    df_surv$median <- paste0(
      df_surv$median,
      " (", round(df_surv$lower, 0), ", ", round(df_surv$upper, 0), ")"
    )
  }
  names(df_surv)[names(df_surv) == "strata"] <- "new_class"
  names(df_surv)[names(df_surv) == "median"] <- "median_surv"
  df_surv <- df_surv[, !(colnames(df_surv) == c("lower", "upper"))]

  df_surv$new_class <- sort(unique(df_main$new_class))

  rownames(df_surv) <- paste0("class_", df_surv[, 1], "_final")
  df_surv <- df_surv[, -1, drop = FALSE]
  df_surv <- as.data.frame(t(df_surv))

  df_surv
}
