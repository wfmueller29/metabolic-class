# Purpose: To plot the bootstrapped accuracy with error bars for each model
# Author: WIlliam mueller
#
plot_boot_accuracy_interval <- function(accuracy_interval_df,
                                        xlab = "",
                                        ylab = "",
                                        title = "") {
  if (nrow(accuracy_interval_df) == 0) {
    plot <- NA
    warning("accuracy_interval_df has 0 rows so cannot plot; returning NA")
    return(plot)
  }
  # if accuracy is constant we do no want to plot. This covers case where all
  # predictions are completely accurate
  uni_accuracy <- length(unique(accuracy_interval_df$accuracy))

  # if there are some NA's we want to remove those for the sake of running
  # without errors
  data <- accuracy_interval_df
  data <- data[!is.na(data$ci), ]
  accuracy_interval_df <- data

  if (uni_accuracy != 1) {
    comparisons <- interval_comparisons(accuracy_interval_df)

    plot <- ggplot2::ggplot(
      data = accuracy_interval_df,
      mapping = ggplot2::aes(x = data_name, y = as.numeric(accuracy))
    ) +
      ggplot2::geom_bar(stat = "identity") +
      ggplot2::geom_errorbar(
        ggplot2::aes(x = data_name, ymin = lower_ci, ymax = upper_ci),
        stat = "identity",
        width = 0.4
      ) +
      ggplot2::geom_signif(
        comparisons = comparisons, annotations = "*", margin_top = .1,
        step_increase = .35
      ) +
      ggplot2::labs(
        y = ylab,
        x = xlab,
        title = title
      )
  } else {
    plot <- NA
  }
  plot
}

plot_boot_accuracy_window <- function(accuracy_window_df,
                                      xlab = "",
                                      ylab = "",
                                      title = "",
                                      legend_title = "Window Size") {
  uni_accuracy <- length(unique(accuracy_window_df$accuracy))
  if (uni_accuracy != 1) {
    plot <- ggplot2::ggplot(
      data = accuracy_window_df,
      mapping = ggplot2::aes(
        x = average,
        y = as.numeric(accuracy),
        color = factor(window_size)
      )
    ) +
      ggplot2::geom_line(stat = "identity") +
      ggplot2::geom_errorbar(
        ggplot2::aes(x = upper_bound, ymin = lower_ci, ymax = upper_ci),
        stat = "identity",
        width = 0.4
      ) +
      ggplot2::labs(
        y = ylab,
        x = xlab,
        title = title,
        color = legend_title
      )
  } else {
    plot <- NA
  }
  plot
}

plot_boot_accuracy_threshold <- function(accuracy_threshold_df,
                                         xlab = "",
                                         ylab = "",
                                         title = "",
                                         legend_title = "") {
  uni_accuracy <- length(unique(accuracy_threshold_df$accuracy))

  if (uni_accuracy != 1) {
    plot <- ggplot2::ggplot(
      data = accuracy_threshold_df,
      mapping = ggplot2::aes(
        x = upper_bound,
        y = accuracy,
        color = factor(lower_bound)
      )
    ) +
      ggplot2::geom_line(stat = "identity") +
      ggplot2::geom_point(stat = "identity") +
      ggplot2::geom_errorbar(
        ggplot2::aes(x = upper_bound, ymin = lower_ci, ymax = upper_ci),
        stat = "identity",
        width = 4
      ) +
      ggplot2::labs(
        y = ylab,
        x = xlab,
        title = title,
        color = legend_title
      )
  } else {
    plot <- NA
  }
  plot
}

plot_boot_accuracy_sample <- function(accuracy_sample_df,
                                      xlab = "",
                                      ylab = "",
                                      title = "") {
  uni_accuracy <- length(unique(accuracy_sample_df$accuracy))

  if (uni_accuracy != 1) {
    plot <- ggplot2::ggplot(
      data = accuracy_sample_df,
      mapping = ggplot2::aes(x = sample_per_id, y = accuracy)
    ) +
      ggplot2::geom_line(stat = "identity") +
      ggplot2::geom_point(stat = "identity") +
      ggplot2::geom_errorbar(
        ggplot2::aes(x = sample_per_id, ymin = lower_ci, ymax = upper_ci),
        stat = "identity",
        width = .2
      ) +
      ggplot2::labs(
        y = ylab,
        x = xlab,
        title = title
      )
  } else {
    plot <- NA
  }
  plot
}

interval_comparisons <- function(accuracy_interval_df) {
  accuracy_df <- accuracy_interval_df
  variables <- as.character(unique(accuracy_df$data_name))
  comparisons <- combn(variables, m = 2, simplify = FALSE)

  sig <- vector()
  for (i in seq_along(comparisons)) {
    comparison <- comparisons[[i]]
    a_lower <- accuracy_df[accuracy_df$data_name == comparison[[1]], ]$lower_ci
    a_upper <- accuracy_df[accuracy_df$data_name == comparison[[1]], ]$upper_ci
    b_lower <- accuracy_df[accuracy_df$data_name == comparison[[2]], ]$lower_ci
    b_upper <- accuracy_df[accuracy_df$data_name == comparison[[2]], ]$upper_ci

    if ((a_lower >= b_upper) | (b_lower >= a_upper)) {
      test <- TRUE
    } else {
      test <- FALSE
    }
    sig[[i]] <- test
  }

  new_comparisons <- comparisons[sig]
}


# Archive old function

plot_boot_accuracy_interval_old <- function(accuracy_interval_df,
                                            xlab = "",
                                            ylab = "",
                                            title = "") {
  uni_accuracy <- length(unique(accuracy_interval_df$accuracy))
  if (uni_accuracy != 1) {
    comparisons <- interval_comparisons(accuracy_interval_df)

    plot <- ggplot2::ggplot(
      data = accuracy_interval_df,
      mapping = ggplot2::aes(x = data_name, y = as.numeric(accuracy))
    ) +
      ggplot2::geom_bar(stat = "identity") +
      ggplot2::geom_errorbar(
        ggplot2::aes(x = data_name, ymin = lower_ci, ymax = upper_ci),
        stat = "identity",
        width = 0.4
      ) +
      ggplot2::geom_signif(
        comparisons = comparisons, annotations = "*", margin_top = .1,
        step_increase = .35
      ) +
      ggplot2::labs(
        y = ylab,
        x = xlab,
        title = title
      )
  } else {
    plot <- NA
  }
  plot
}
