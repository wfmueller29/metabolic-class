# Purpose: Extract Accuracy and Confidence Interval from List of
# Bootstrapped Results
# Author: William Mueller


extract_accuracy_ci <- function(accuracy_df) {
  data <- accuracy_df

  # filter out NA in boot_accuracy
  data <- data[!is.na(data$boot_accuracy), ]

  data$accuracy <- lapply(data$boot_accuracy, function(boot) {
    boot$t0
  })

  data$accuracy <- unlist(data$accuracy, recursive = FALSE)

  data$ci <- lapply(data$boot_accuracy, function(boot) {
    # boot.ci will bug if population value is 0 or 1
    if (is.na(boot$t0)) {
      warning("The bootstrapped statistic is NA; returning NA")
      return(NA)
    }
    if ((boot$t0 != 1) && (boot$t0 != 0)) {
      ci <- boot::boot.ci(boot, type = "norm")
      ci <- ci$normal
    } else {
      ci <- NA
    }
    ci
  })

  data$lower_ci <- lapply(data$ci, function(ci) {
    if ("matrix" %in% class(ci)) {
      lower_ci <- ci[[2]]
    } else if (is.na(ci)) {
      lower_ci <- NA
    } else {
      stop("CI is not of class Matrix and is not NA")
    }

    lower_ci
  })

  data$lower_ci <- unlist(data$lower_ci, recursive = FALSE)

  data$upper_ci <- lapply(data$ci, function(ci) {
    if ("matrix" %in% class(ci)) {
      upper_ci <- ci[[3]]
    } else if (is.na(ci)) {
      upper_ci <- NA
    } else {
      stop("CI is not of class Matrix and is not NA")
    }

    upper_ci
  })

  data$upper_ci <- unlist(data$upper_ci, recursive = FALSE)

  data
}
