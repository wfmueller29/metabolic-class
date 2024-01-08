# Purpose: To plot Sensitivity, Specificity, PPV, and NPV for each missing
# data simulation
# Author: William Mueller

plot_interval <- function(interval_df,
                          cols,
                          title = "",
                          ylab = "",
                          xlab = "",
                          subtitle = "",
                          error_bars = NULL) {
  if (length(interval_df) == 0) {
    interval_df <- NA
    warning("Dataframe is of length 0, cannot rename it; Returning NA")
    return(interval_df)
  }
  interval_df <- pivot_longer(interval_df, cols = all_of(cols)) %>%
    filter(class == "all")

  ggplot(data = interval_df, mapping = aes(x = data_name, y = value)) +
    geom_bar(position = "dodge", stat = "identity") +
    facet_wrap(name ~ ., ncol = 1) +
    labs(
      title = title,
      y = ylab,
      x = xlab,
      subtitle = subtitle
    )
}

plot_threshold <- function(threshold_df,
                           cols,
                           title = "",
                           ylab = "",
                           xlab = "",
                           subtitle = "") {
  threshold_df <- pivot_longer(threshold_df, cols = all_of(cols)) %>%
    filter(class == "all")

  ggplot(data = threshold_df, mapping = aes(
    x = upper_bound, y = value,
    color = factor(lower_bound)
  )) +
    geom_line(stat = "identity") +
    geom_point() +
    facet_wrap(name ~ ., ncol = 1) +
    labs(
      title = title,
      y = ylab,
      x = xlab,
      subtitle = subtitle
    )
}

plot_window <- function(window_df,
                           cols,
                           title = "",
                           ylab = "",
                           xlab = "",
                           subtitle = "") {
  window_df <- pivot_longer(window_df, cols = all_of(cols)) %>%
    filter(class == "all") %>%
    mutate(window_size = as.integer(upper_bound - lower_bound))

  ggplot(data = window_df, mapping = aes(
    x = upper_bound, y = value,
    color = factor(window_size)
  )) +
    geom_line(stat = "identity") +
    geom_point() +
    facet_wrap(name ~ ., ncol = 1) +
    labs(
      title = title,
      y = ylab,
      x = xlab,
      subtitle = subtitle
    )
}

plot_sample <- function(sample_df,
                        cols,
                        title = "",
                        ylab = "",
                        xlab = "",
                        subtitle = "") {
  sample_df <- pivot_longer(sample_df, cols = all_of(cols)) %>%
    filter(class == "all")

  ggplot(data = sample_df, mapping = aes(x = sample_per_id, y = value)) +
    geom_line(stat = "identity") +
    geom_point() +
    facet_wrap(name ~ ., ncol = 1) +
    labs(
      title = title,
      y = ylab,
      x = xlab,
      subtitle = subtitle
    )
}
