# Purpose: To plot subsetted prediction statistics
# Author: William Mueller

name_interval <- function(interval_df) {
  interval_df <- interval_df %>%
    mutate(data_name = ifelse(dataset == "(0, 57.50)", "Early Life",
      ifelse(dataset == "[57.50,86.25)", "Midlife",
        ifelse(dataset == "[86.25,103.50)", "Late life",
          ifelse(dataset == "[103.50,Inf)", "Oldest in Life",
            ifelse(dataset == "[57.50,103.50]", "Midlife and Late life",
                   dataset)
          )
        )
      )
    )) %>%
    mutate(data_name = factor(data_name, levels = c(
      "Early Life",
      "Midlife",
      "Late life",
      "Midlife and Late life",
      "Oldest in Life"
    )))

    interval_df
}

name_new_interval <- function(new_interval_df) {
  splits <- str_split_fixed(new_interval_df$dataset,
                            pattern = "\\[|,|\\]",
                            n = Inf)
  new_interval_df$upper_bound <- as.numeric(splits[,3])
  new_interval_df$lower_bound <- as.numeric(splits[,2])
  new_interval_df$window_size <- new_interval_df$upper_bound - 
    new_interval_df$lower_bound

  new_interval_df

}

name_threshold <- function(threshold_df) {
  splits <- str_split_fixed(threshold_df$dataset,
                            pattern = "\\(|\\[|,|\\)|\\]",
                            n = Inf)
  threshold_df$upper_bound <- as.numeric(splits[,3])
  threshold_df$lower_bound <- as.numeric(splits[,2])

  threshold_df
}

name_sample <- function(sample_df) {
  sample_df <- sample_df %>%
    mutate(sample_per_id = as.numeric(dataset))
}

name_window <- function(window_df) {
  splits <- str_split_fixed(window_df$dataset,
                            pattern = "\\[|,|\\]",
                            n = Inf)
  window_df$upper_bound <- as.numeric(splits[,3])
  window_df$lower_bound <- as.numeric(splits[,2])

  window_df
}

name_sample <- function(sample_df) {
  sample_df <- sample_df %>%
    mutate(sample_per_id = as.numeric(dataset))
}
