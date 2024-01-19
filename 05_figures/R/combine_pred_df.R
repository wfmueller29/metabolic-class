# Purpose: To combine the prediction results for a specific data simulation. In
# other word combining the tables for many different variations of subsets
# into one dataframe
# Author: William Mueller
combine_pred_df <- function(pred_df_list) {
  pred_df_list <- pred_df_list[!is.na(pred_df_list)]
  pred_df_list <- lapply(lapply(pred_df_list, t), as.data.frame)

  pred_df_list <- lapply(pred_df_list, function(data) {
    data$class <- rownames(data)
    data
  })

  pred_df_list <- lapply(names(pred_df_list), function(name) {
    data <- pred_df_list[[name]]
    data$dataset <- name
    data
  })

  pred_df <- do.call(rbind, pred_df_list)
  rownames(pred_df) <- NULL
  pred_df
}

combine_pred_df_subset <- function(final_models, subset) {
  lapply(seq_len(nrow(final_models)), function(i) {
    combine_pred_df(pred_df_list = final_models[[subset]][[i]])
  })
}
