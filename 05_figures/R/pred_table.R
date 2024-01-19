# Purpose: To create tables with Sensititvity, Specificity, Positive Predictive
# Value, Negative Predictive Value, % Correct Class
#
# Author: William Mueller

create_pred_table <- function(pred_df, og_df, subject) {
  # new_df has predicted class, og class, idno, and tp (True Positive), dummy
  # specificying if predicted class equals og class
  new_df <- make_new_df(pred_df, og_df, subject)

  final_table <- make_final_table(new_df, og_df, pred_df, subject)
}

make_new_df <- function(pred_df, og_df, subject) {
  pred_df <- pred_df %>%
    select(!!sym(subject), class)
  og_df <- og_df %>%
    select(!!sym(subject), class)

  new_df <- pred_df %>%
    left_join(og_df, by = subject, suffix = c(".pred", ".og")) %>%
    mutate(tp = ifelse(class.pred == class.og, 1, 0)) %>%
    filter(!is.na(class.og))
}

make_final_table <- function(new_df, og_df, pred_df, subject) {
  final_table <- data.frame(row.names = c(
    "Sensitivity",
    "Specificity",
    "PPV",
    "NPV",
    "Accuracy",
    "n"
  ))
  order_classes <- sort(unique(og_df$class))
  final_table[, paste("class", order_classes, sep = "_")] <- NA

  n <- nrow(new_df)

  for (class in order_classes) {
    # total subjects predicted to be in class i
    pred_class_df <- new_df[new_df$class.pred == class, ]
    pred_class <- nrow(pred_class_df)
    # total subjects actually in class i
    og_class_df <- new_df[new_df$class.og == class, ]
    og_class <- nrow(og_class_df)
    # total subjects correctly predicted to be in class i
    tp <- sum(og_class_df$tp)

    final_table["Sensitivity", class] <- tp / og_class
    final_table["Specificity", class] <- (n - og_class - pred_class + tp) /
      (n - og_class)
    final_table["PPV", class] <- tp / pred_class
    final_table["NPV", class] <- (n - og_class - pred_class + tp) /
      (n - pred_class)
    final_table["Accuracy", class] <- (2 * tp + n - og_class - pred_class) /
      n
    final_table["n", class] <- og_class
  }

  final_table <- create_total(final_table)

  final_table
}

create_total <- function(pred_table) {
  mat <- as.data.frame(matrix(nrow = nrow(pred_table), ncol = ncol(pred_table)))

  names(mat) <- names(pred_table)

  for (i in seq_len(length(pred_table))) {
    n <- pred_table[nrow(pred_table), i]
    rest <- pred_table[1:(nrow(pred_table) - 1), i]
    vect <- n * rest
    vect <- append(vect, n)
    mat[, i] <- vect
  }

  sums <- rowSums(mat)
  n <- sums[length(sums)]
  vect <- sums / n
  vect[length(vect)] <- n
  mat <- cbind(pred_table, all = vect)

  mat
}


create_pred_table_list <- function(pred_df_list, og_df, subject) {
  table_list <- lapply(pred_df_list, function(pred_df) {
    if (nrow(pred_df) == 0) {
      warning("0 rows in our prediction dataframe, returning NA for table")
      table <- NA
    } else {
      table <- create_pred_table(
        pred_df = pred_df, og_df = og_df, subject = subject
      )
    }
    table
  })
  names(table_list) <- names(pred_df_list)
  table_list
}

create_pred_table_subset <- function(final_models, subset, subject) {
  lapply(seq_len(nrow(final_models)), function(i) {
    pred_table_list <- create_pred_table_list(
      pred_df_list = final_models[[subset]][[i]],
      og_df = final_models$census[[i]],
      subject = final_models$subject[[i]]
    )
    pred_table_list
  })
}
