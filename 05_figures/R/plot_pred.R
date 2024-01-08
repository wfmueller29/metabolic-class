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
    plot <- NA
    warning("Dataframe is of length 0, cannot rename it; Returning NA")
    return(plot)
  }
  interval_df <- tidyr::pivot_longer(interval_df,
    cols = tidyselect::all_of(cols)
  ) %>%
    filter(class == "all")

  plot <- ggplot2::ggplot(
    data = interval_df,
    mapping = ggplot2::aes(x = data_name, y = value)
  ) +
    ggplot2::geom_bar(position = "dodge", stat = "identity") +
    ggplot2::facet_wrap(name ~ ., ncol = 1) +
    ggplot2::labs(
      title = title,
      y = ylab,
      x = xlab,
      subtitle = subtitle
    )

  plot
}

plot_threshold <- function(threshold_df,
                           cols,
                           title = "",
                           ylab = "",
                           xlab = "",
                           subtitle = "") {
  threshold_df <- tidyr::pivot_longer(threshold_df, cols = tidyselect::all_of(cols)) %>%
    filter(class == "all")

  ggplot2::ggplot(data = threshold_df, mapping = ggplot2::aes(
    x = upper_bound, y = value,
    color = factor(lower_bound)
  )) +
    ggplot2::geom_line(stat = "identity") +
    ggplot2::geom_point() +
    ggplot2::facet_wrap(name ~ ., ncol = 1) +
    ggplot2::labs(
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
  window_df <- tidyr::pivot_longer(window_df, cols = tidyselect::all_of(cols)) %>%
    filter(class == "all") %>%
    mutate(window_size = as.integer(upper_bound - lower_bound))

  ggplot2::ggplot(data = window_df, mapping = ggplot2::aes(
    x = upper_bound, y = value,
    color = factor(window_size)
  )) +
    ggplot2::geom_line(stat = "identity") +
    ggplot2::geom_point() +
    ggplot2::facet_wrap(name ~ ., ncol = 1) +
    ggplot2::labs(
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
  sample_df <- tidyr::pivot_longer(sample_df, cols = tidyselect::all_of(cols)) %>%
    filter(class == "all")

  ggplot(data = sample_df, mapping = ggplot2::aes(x = sample_per_id, y = value)) +
    ggplot2::geom_line(stat = "identity") +
    ggplot2::geom_point() +
    ggplot2::facet_wrap(name ~ ., ncol = 1) +
    ggplot2::labs(
      title = title,
      y = ylab,
      x = xlab,
      subtitle = subtitle
    )
}
