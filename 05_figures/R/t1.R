# create table1
#
# Author: William Mueller

# library(tidyverse)

count_column_by_class <- function(df, group, column) {
  by_list <- list(df[[group]], df[[column]])
  names(by_list) <- c(group, "group_column")
  df_count <- aggregate(x = df[, 1], by = by_list, FUN = length)
  names(df_count)[names(df_count) == "x"] <- column
  df_count <- reshape(df_count,
    direction = "wide",
    timevar = "group_column",
    idvar = "new_class",
    sep = "_"
  )

  df_count
}

create_freq_column <- function(df_table) {
  # sum rows to create total column
  if (length(df_table) != 1) {
    df_table$total <- rowSums(df_table[, ])
  } else {
    df_table$total <- df_table[, 1]
  }
  # set survival columns to NA
  df_table[grepl(rownames(df_table), pattern = "surv"), "total"] <- NA

  # create new cols that are the frequency of the n columns
  new_cols <- do.call(cbind, lapply(1:(length(df_table) - 1), function(i) {
    round(df_table[[i]] / df_table$total * 100, 1)
  }))
  new_cols <- data.frame(new_cols)

  names(new_cols) <- paste0(names(df_table[, -length(df_table)]), "_freq")

  df_freq <- new_cols

  df_freq
}

create_combo_column <- function(df_table, df_freq) {
  # store column names
  col_names <- names(df_table)
  # final column names
  combo_col_names <- paste0(col_names, "_final")
  # all_col_names
  all_col_names <- c(col_names, names(df_freq), combo_col_names)
  # bind freq columns to original table
  df_table <- cbind(df_table, df_freq)
  # number of columns of dataframe
  l <- length(df_table)
  # number of classes
  x <- round((l - 1) / 2 + .1)
  for (i in 1:x) {
    df_table[, i + l] <- paste0(
      as.character(df_table[, i]),
      " (",
      df_table[, i + x],
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

  names(df_table) <- all_col_names

  df_table
}

create_count_columns <- function(df,
                                 columns,
                                 age_death,
                                 event) {
  df_main <- df

  df_total <- aggregate(df_main[, "new_class"],
    by = list(new_class = df_main[["new_class"]]),
    FUN = length
  )
  names(df_total)[names(df_total) == "x"] <- "n"

  df_list_count_by_class <- lapply(
    columns,
    count_column_by_class,
    df = df, group = "new_class"
  )

  obj <- survival::Surv(time = df_main[[age_death]], event = df_main[[event]])
  surv_fit <- survival::survfit(data = df_main, obj ~ factor(new_class))

  df_surv <- survminer::surv_median(surv_fit)
  df_surv$median <- paste0(
    df_surv$median,
    " (", df_surv$lower, ", ", df_surv$upper, ")"
  )
  names(df_surv)[names(df_surv) == "strata"] <- "new_class"
  names(df_surv)[names(df_surv) == "median"] <- "median_surv"
  df_surv <- df_surv[, !(colnames(df_surv) == c("lower", "upper"))]

  df_surv$new_class <- sort(unique(df_main$new_class))

  dfs <- df_list_count_by_class

  dfs <- c(list(df_total), dfs)

  dfs <- c(dfs, list(df_surv))

  df_table <- Reduce(function(x, y) merge(x, y, by = "new_class"), dfs)
  df_table <- data.frame(t(df_table))
  names(df_table) <- as.character(unlist(df_table[1, ]))

  # for edge case when there is one class, we need to store names and reassign
  df_table <- df_table[-1, , drop = FALSE]

  df_table[is.na(df_table)] <- 0
  names(df_table) <- paste0("class_", names(df_table))
  # seq_cols <- seq_along(df_table)
  # df_table[, seq_cols] <- lapply(df_table[, seq_cols], as.numeric)
  # df_table <- round(df_table)

  df_table
}

t1 <- function(df, columns, age_death, event) {
  # number of unique classes
  no_class <- length(unique(df$class))

  df_table <- create_count_columns(df, columns, age_death, event)
  # Drop MLE
  df_table <- df_table[-nrow(df_table), ]
  df_table <- data.frame(lapply(df_table, as.numeric),
    row.names = rownames(df_table)
  )


  df_freq <- create_freq_column(df_table)


  df_final <- create_combo_column(df_table, df_freq)

  df_mle <- create_count_columns(df, columns, age_death, event)
  # keep MLE
  df_mle <- df_mle[nrow(df_mle), ]
  df_mle2 <- df_mle
  names(df_mle2) <- paste0(names(df_mle), "_final")
  df_mle <- cbind(df_mle, df_mle2)
  df_final <- data.table::rbindlist(list(df_final, df_mle), fill =TRUE)
  df_final <- as.data.frame(df_final)

  # return df_final
  df_final
}
