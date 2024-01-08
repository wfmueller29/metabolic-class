# Purpose: To plot subsetted prediction statistics
# Author: William Mueller

name_interval <- function(interval_df) {
  if (length(interval_df) == 0) {
    warning("Dataframe is of length 0, cannot rename it; Returning empty df")
    return(interval_df)
  }

  col <- interval_df[, "dataset"]
  new_col <- ifelse(col == "(0, 57.50)", "Early Life",
    ifelse(col == "[57.50,86.25)", "Midlife",
      ifelse(col == "[86.25,103.50)", "Late life",
        ifelse(col == "[103.50,Inf)", "Oldest in Life",
          ifelse(col == "[57.50,103.50]", "Midlife and Late life",
            col
          )
        )
      )
    )
  )
  interval_df[, "data_name"] <- factor(new_col, levels = c(
    "Early Life",
    "Midlife",
    "Late life",
    "Midlife and Late life",
    "Oldest in Life"
  ))

  interval_df
}

name_new_interval <- function(new_interval_df) {
  splits <- do.call(rbind, strsplit(new_interval_df$dataset,
    split = "\\(|\\[|,|\\)|\\]"
  ))
  new_interval_df$upper_bound <- as.numeric(splits[, 3])
  new_interval_df$lower_bound <- as.numeric(splits[, 2])
  new_interval_df$window_size <- new_interval_df$upper_bound -
    new_interval_df$lower_bound
  average <- new_interval_df$lower_bound + new_interval_df$window_size / 2
  new_interval_df$average <- average

  new_interval_df
}

name_threshold <- function(threshold_df) {
  splits <- do.call(rbind, strsplit(threshold_df$dataset,
    split = "\\(|\\[|,|\\)|\\]"
  ))
  threshold_df$upper_bound <- as.numeric(splits[, 3])
  threshold_df$lower_bound <- as.numeric(splits[, 2])

  threshold_df
}

name_window <- function(window_df) {
  splits <- do.call(rbind, strsplit(window_df$dataset,
    split = "\\(|\\[|,|\\)|\\]"
  ))
  window_df$upper_bound <- as.numeric(splits[, 3])
  window_df$lower_bound <- as.numeric(splits[, 2])

  window_df
}

name_sample <- function(sample_df) {
  sample_df[, "sample_per_id"] <- as.numeric(sample_df[, "dataset"])
  sample_df
}
