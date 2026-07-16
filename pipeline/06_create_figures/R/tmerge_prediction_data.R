# this file is for tmerging prediction data

tmerge_prediction_data <- function(data,
                                   id,
                                   age,
                                   age_death,
                                   dead_censor,
                                   outcomes) {
  print(nrow(data))
  if (nrow(data) == 0) {
    warning("Cannot perform surv_tmerge, 0 nrows in data")
    return(data)
  }

  tmerged_data <- SLAM::surv_tmerge(
    data = data,
    id = id,
    age = age,
    age_death = age_death,
    dead_censor = dead_censor,
    outcomes = outcomes
  )

  prob_cols <- names(tmerged_data)[grepl("^prob", names(tmerged_data))]
  prob_cols_drop <- sapply(prob_cols, function(name) {
    all(tmerged_data[[name]] == 1)
  })
  prob_cols <- prob_cols[!prob_cols_drop]

  tmerged_data
}
