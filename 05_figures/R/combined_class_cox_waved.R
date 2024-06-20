predict_waved_class <- function(newdata,
                                model,
                                age,
                                id) {
  model$call[[1]] <- "hlme"

  newdata <- data.table::data.table(newdata)

  waved <- newdata[, wave := order(eval(as.symbol(age))), by = id]
  waved <- as.data.frame(waved)
  newdata <- as.data.frame(newdata)
  waved <- waved[order(waved$idno, waved$wave), ]

  waved_predictions <- lapply(unique(waved$wave), function(i) {
    length(unique(waved$idno))
    ids_with_wave <- unique(waved[waved$wave %in% i, id])
    waved <- waved[waved[[id]] %in% ids_with_wave, ]
    length(unique(waved$idno))

    prediction <- lcmm::predictClass(
      model = model,
      newdata = waved
    )
    prediction$wave <- i

    prediction
  })
  waved_predictions_df <- do.call(rbind, waved_predictions)

  waved_predictions <- merge(newdata, waved_predictions_df, by = c(id, "wave"))

  waved_predictions
}

# Function that will predict given a single model, but a list of prediction
# data.frames
predict_waved_class_newdata_list <- function(newdata_list, model, age, id) {
  if (!is.list(newdata_list)) {
    warning("newdata_list is not a list; returning NA")
    return(NA)
  }
  subset_predictions <- lapply(newdata_list, function(newdata) {
    # check if there is actually data in the newdata
    if (nrow(newdata) >= 2) {
      class_result <- predict_waved_class(
        newdata = newdata,
        model = model,
        age = age,
        id = id
      )
    } else {
      col_names <- names(newdata)
      class_result <- data.frame(matrix(nrow = 0, ncol = length(col_names)))
      names(class_result) <- col_names
    }

    class_result
  })

  # check if NA in subset_predictions and remove that data
  keep <- !is.na(subset_predictions)
  subset_predictions <- subset_predictions[keep]

  names(subset_predictions) <- names(newdata_list)[keep]

  subset_predictions
}

predict_waved_class_model_list <- function(nested_newdata_list,
                                           model_list,
                                           names,
                                           age_list,
                                           id_list) {
  pred_result <- lapply(seq_along(model_list), function(i) {
    print(i)
    predict_waved_class_newdata_list(
      newdata_list = nested_newdata_list[[i]],
      model = model_list[[i]],
      age = age_list[[i]],
      id = id_list[[i]]
    )
  })

  names(pred_result) <- names

  pred_result
}
