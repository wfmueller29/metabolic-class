# Purpose: Extract Accuracy and Confidence Interval from List of
# Bootstrapped Results
# Author: William Mueller


extract_accuracy_ci <- function(accuracy_df) {
  data <- accuracy_df
  data$accuracy <- lapply(data$boot_accuracy, function(boot) {
    boot$t0
  })

  data$accuracy <- unlist(data$accuracy, recursive = FALSE)

  data$ci <- lapply(data$boot_accuracy, function(boot) {
    # boot.ci will bug if population value is 0 or 1
    if ((boot$t0 != 1) & (boot$t0 != 0)) {
      ci <- boot::boot.ci(boot)
      ci <- ci$normal
    } else {
      ci <- NA
    }
    ci
  })

  data$lower_ci <- lapply(data$ci, function(ci) {
    if (!is.na(ci)) {
      lower_ci <- ci[[2]]
    } else {
      lower_ci <- NA
    }

    lower_ci
  })

  data$lower_ci <- unlist(data$lower_ci, recursive = FALSE)

  data$upper_ci <- lapply(data$ci, function(ci) {
      if (!is.na(ci)) {
        upper_ci <- ci[[3]]
      } else {
        upper_ci <- NA
      }

      upper_ci
    })

  data$upper_ci <- unlist(data$upper_ci, recursive = FALSE)

  data
}
