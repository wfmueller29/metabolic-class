# Purpose: To plot Sensitivity, Specificity, PPV, and NPV for each missing
# data simulation
# Author: William Mueller

plot_interval <- function(interval_df,
                          title = "",
                          ylab = "",
                          xlab = "",
                          subtitle = "") {
  interval_df <- pivot_longer(interval_df, cols = Sensitivity:NPV) %>%
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
                          title = "",
                          ylab = "",
                          xlab = "",
                          subtitle = "") {
  threshold_df <- pivot_longer(threshold_df, cols = Sensitivity:NPV) %>%
    filter(class == "all")

  ggplot(data = threshold_df, mapping = aes(x = upper_bound, y = value)) +
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
                          title = "",
                          ylab = "",
                          xlab = "",
                          subtitle = "") {
  sample_df <- pivot_longer(sample_df, cols = Sensitivity:NPV) %>%
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
