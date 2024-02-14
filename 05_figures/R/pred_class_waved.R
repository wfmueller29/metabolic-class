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
