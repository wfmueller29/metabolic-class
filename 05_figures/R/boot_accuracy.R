# Purpose to bootstrap accuracy
# William Mueller

# for make_new_df function we must source
source("R/pred_table.R")
boot_accuracy <- function(pred_df, og_df, subject) {
  new_df <- make_new_df(pred_df, og_df, subject)

  bootobj <- boot::boot(data = new_df, statistic = function(data, indices) {
    data <- data[indices, ]
    tp <- sum(data$tp)
    n <- nrow(data)
    accuracy <- tp / n
  }, R = 2000)

  bootobj
}


boot_accuracy_list <- function(pred_df_list, og_df, subject) {
  accuracy_list <- lapply(
    pred_df_list,
    boot_accuracy,
    og_df,
    subject
  )
}
