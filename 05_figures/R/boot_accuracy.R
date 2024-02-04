# Purpose to bootstrap accuracy
# William Mueller

# for make_new_df function we must source
source("R/pred_table.R")

f1_score <- function(predicted, expected) {
  predicted <- factor(as.character(predicted),
    levels = unique(as.character(expected))
  )
  expected <- as.factor(expected)
  cm <- as.matrix(table(expected, predicted))

  precision <- diag(cm) / colSums(cm)
  recall <- diag(cm) / rowSums(cm)
  f1 <- ifelse(precision + recall == 0,
    0, 2 * precision * recall / (precision + recall)
  )

  mean(f1)
}

boot_accuracy <- function(pred_df, og_df, subject) {
  if (nrow(pred_df) == 0) {
    warning("pred_df has 0 rows, cannot make_new_df, returning NA")
    return(NA)
  }

  new_df <- make_new_df(pred_df, og_df, subject)

  if (nrow(new_df) == 0) {
    cat("No overlap for prediction")
    return(NA)
  }

  bootobj <- boot::boot(data = new_df, statistic = function(data, indices) {
    data <- data[indices, ]
    f1 <- f1_score(predicted = data$class.pred, expected = data$class.og)
    f1
  }, R = 2000)

  bootobj
}


boot_accuracy_list <- function(pred_df_list, og_df, subject) {
  lapply(pred_df_list, boot_accuracy, og_df, subject)
}
