# create table1
#
# Author: William Mueller

library(tidyverse)

t1 <- function(df, columns, total = TRUE, surv = TRUE) {
  df_table <- create_count_columns(df, columns, total, surv)

  df_freq <- create_freq_column(df_table)

  df_final <- create_count_columns(df_table, df_freq)

  # return df_final
  df_final
}

create_count_columns <- function(df, columns, total = TRUE, surv = TRUE) {
  df_main <- df

  df_table <- df_main %>%
    group_by(class) %>%
    summarise(n = n()) %>%
    select(class, n, everything())

  df_list_count_by_class <- lapply(
    columns,
    count_column_by_class,
    df = df, group = "class"
  )

  surv <- survfit(
    data = df_main,
    Surv(time = age_wk_death, event = dead_nat) ~ factor(class)
  )
  df_surv <- surv_median(surv) %>%
    rename(
      class = strata,
      median_surv = median
    ) %>%
    select(-lower, -upper)

  df_surv$class <- sort(unique(df_main$class))

  dfs <- c(list(df_table), df_list_count_by_class, list(df_surv))

  df_table <- dfs %>%
    reduce(left_join, by = "class")

  df_table <- df_table %>%
    t() %>%
    data.frame() %>%
    round() %>%
    janitor::row_to_names(1)

  df_table[is.na(df_table)] <- 0


  names(df_table) <- paste0("class_", names(df_table))

  df_table
}

count_column_by_class <- function(df, group, column) {
  df <- eval(call("group_by", df, as.symbol(group)))
  df <- eval(call("count", df, as.symbol(column)))
  df <- df %>%
    ungroup()
  spread_call <- call("spread", as.symbol("df"),
    key = as.symbol(column),
    value = as.symbol("n"),
    sep = "_"
  )
  df_count <- eval(spread_call)
  df_count
}

create_freq_column <- function(df_table) {
  # sum rows to create total column
  df_table$total <- rowSums(df_table[, ])
  # set survival columns to NA
  df_table[grepl(rownames(df_table), pattern = "surv"), "total"] <- NA

  # create new cols that are the frequency of the n columns
  new_cols <- do.call(cbind, lapply(1:(length(df_table) - 1), function(i) {
    round(df_table[[i]] / df_table$total * 100, 1)
  })) %>%
    data.frame()

  names(new_cols) <- paste0(names(df_table[, -length(df_table)]), "_freq")
}

create_combo_column <- function(df_table, df_freq) {
  # bind freq columns to original table
  df_table <- cbind(df_table, df_freq)
  # number of columns of dataframe
  l <- length(df_table)
  # number of classes
  x <- (length(df_table) - 1) / 2
  for (i in 1:x) {
    df_table[, i + l] <- paste0(
      as.character(df_table[, i]),
      " (",
      df_table[, i + x + 1],
      "%)"
    )
  }

  df_table <- as.data.frame(
    sapply(df_table,
      gsub,
      pattern = "(NA%)",
      replacement = "weeks"
    ),
    row.names = rownames(df_table)
  )
}
