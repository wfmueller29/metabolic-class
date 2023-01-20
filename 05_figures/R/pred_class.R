# Purpose: To predict the classes of simulated data given our latent class
# models. The simulated data is made from subsets of the origin modelling data
#
# Author: William Mueller

# Function that will predict given a single model and single data.frame
predict_class <- function(newdata,
                          model,
                          vars,
                          center,
                          scale,
                          ref_data = NULL) {
  newdata <- helphlme::prep_hlme(
    df = newdata,
    vars = vars,
    center = center,
    scale = scale,
    ref_data = ref_data
  )
  model$call[[1]] <- "hlme"

  prediction <- lcmm::predictClass(
    model = model,
    newdata = newdata
  )

  prediction
}

# Function that will predict given a single model, but a list of prediction
# data.frames
predict_class_newdata_list <- function(newdata_list,
                                       model,
                                       vars,
                                       center,
                                       scale,
                                       ref_data = NULL) {
  subset_predictions <- lapply(newdata_list, function(newdata) {
    # check if there is actually data in the newdata
    if (nrow(newdata) >= 1) {
      class_result <- predict_class(
        newdata = newdata,
        model = model,
        vars = vars,
        center = center,
        scale = scale,
        ref_data = ref_data
      )
    } else {
      # if there is no data in newdata make class_result be null
      class_result <- NA
    }

    class_result
  })

  # check if NA in subset_predictions and remove that data
  keep <- !is.na(subset_predictions)
  subset_predictions <- subset_predictions[keep]

  names(subset_predictions) <- names(newdata_list)[keep]

  subset_predictions
}

predict_class_model_list <- function(nested_newdata_list,
                                     model_list,
                                     vars_list,
                                     center,
                                     scale,
                                     ref_data_list,
                                     names = NULL) {
  pred_result <- lapply(seq_along(model_list), function(i) {
                          print(i)
    predict_class_newdata_list(
      newdata_list = nested_newdata_list[[i]],
      model = model_list[[i]],
      vars = vars_list[[i]],
      center = center,
      scale = scale,
      ref_data = ref_data_list[[i]]
    )
  })

  names(pred_result) <- names

  pred_result
}
