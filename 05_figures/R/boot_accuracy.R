# Purpose to bootstrap accuracy
# William Mueller

# for make_new_df function we must source
source("R/pred_table.R")

boot_accuracy <- function(pred_df,
                          og_df,
                          subject,
                          parallel = "no",
                          ncpus = getOption("boot.ncpus", 1L)) {
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
    unique_og <- length(unique(data$class.og))
    unique_pred <- length(unique(data$class.pred))
    if (unique_og == 1) {
      warning("Truth data has only one level")
      message("f1 stat is meaningless in this case")
      message("returning NA")
      return(NA)
    }
    data$class_og_factor <- factor(as.character(data$class.og),
      levels = as.character(sort(unique(data$class.og))),
      labels = as.character(sort(unique(data$class.og)))
    )
    data$class_pred_factor <- factor(as.character(data$class.pred),
      levels = as.character(sort(unique(data$class.og))),
      labels = as.character(sort(unique(data$class.og)))
    )


    f1 <- yardstick::f_meas_vec(
      truth = data$class_og_factor,
      estimate = data$class_pred_factor,
      estimator = "macro"
    )
    if (unique_og != unique_pred) {
      warning("Some levels had no predicted events")
      message("f1 was calculated excluding those levels")
      message("f1 will be multiplied by the fraction of missing levels.")
      message("original f1 = ", f1)
      f1 <- f1 * (unique_pred / unique_og)
      message("rebalanced f1 = ", f1)
    }
    # f1 <- MLmetrics::F1_Score(y_true = data$class.og, y_pred = data$class.pred)
    # f1 <- f1_score(predicted = data$class.pred, expected = data$class.og)
    f1
  }, R = 100, parallel = parallel, ncpus = ncpus)

  bootobj
}


boot_accuracy_list <- function(pred_df_list, og_df, subject, parallel = "no",
                               ncpus = getOption("boot.ncpus", 1L)) {
  lapply(pred_df_list, boot_accuracy,
    og_df, subject,
    parallel = parallel, ncpus = ncpus
  )
}
