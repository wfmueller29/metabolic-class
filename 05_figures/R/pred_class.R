# Purpose: To predict the classes of simulated data given our latent class
# models. The simulated data is made from subsets of the origin modelling data
#
# Author: William Mueller

# Function that will predict given a single model and single data.frame
predict_class <- function(newdata,
                          model) {
  model$call[[1]] <- "hlme"

  prediction <- tryCatch(
    {
      lcmm::predictClass(
        model = model,
        newdata = newdata
      )
    },
    error = function(cond) {
      browser()
      errormsg <- conditionMessage(cond)
      if (errormsg == "the leading minor of order 3 is not positive") {
        warning("predictClass error, likely due to lack of repeated measures")
        warning("returning NULL")
        message("Here's the original error message:")
        message(conditionMessage(cond))
        return(NULL)
      } else {
        stop(cond)
      }
    }
  )

  prediction
}

# Function that will predict given a single model, but a list of prediction
# data.frames
predict_class_newdata_list <- function(newdata_list, model) {
  if (!is.list(newdata_list)) {
    warning("newdata_list is not a list; returning NA")
    return(NA)
  }
  subset_predictions <- lapply(newdata_list, function(newdata) {
    # check if there is actually data in the newdata
    if (nrow(newdata) >= 2) {
      class_result <- predict_class(
        newdata = newdata,
        model = model
      )
    } else {
      col_names <- names(model$pprob)
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

predict_class_model_list <- function(nested_newdata_list, model_list, names) {
  pred_result <- lapply(seq_along(model_list), function(i) {
    print(i)
    predict_class_newdata_list(
      newdata_list = nested_newdata_list[[i]],
      model = model_list[[i]]
    )
  })

  names(pred_result) <- names

  pred_result
}
