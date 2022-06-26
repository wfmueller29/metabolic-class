# Purpose: To plot the bootstrapped accuracy with error bars for each model
# Author: WIlliam mueller
plot_boot_accuracy_interval <- function(accuracy_interval_df,
                                        xlab = "",
                                        ylab = "",
                                        title = "") {
  uni_accuracy <- length(unique(accuracy_interval_df$accuracy))
  if (uni_accuracy != 1) {
    comparisons <- interval_comparisons(accuracy_interval_df)

    plot <- ggplot(
      data = accuracy_interval_df,
      mapping = aes(x = data_name, y = as.numeric(accuracy))
    ) +
      geom_bar(stat = "identity") +
      geom_errorbar(aes(x = data_name, ymin = lower_ci, ymax = upper_ci),
        stat = "identity",
        width = 0.4
      ) +
      geom_signif(
        comparisons = comparisons, annotations = "*", margin_top = .1,
        step_increase = .35
      ) + 
    labs(
      y = ylab,
      x = xlab,
      title = title
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
    plot <- ggplot(
      data = accuracy_threshold_df,
      mapping = aes(
        x = upper_bound,
        y = accuracy,
        color = factor(lower_bound)
      )
    ) +
      geom_line(stat = "identity") +
      geom_point(stat = "identity") +
      geom_errorbar(aes(x = upper_bound, ymin = lower_ci, ymax = upper_ci),
        stat = "identity",
        width = 4
      ) +
      labs(
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
    plot <- ggplot(
      data = accuracy_sample_df,
      mapping = aes(x = sample_per_id, y = accuracy)
    ) +
      geom_line(stat = "identity") +
      geom_point(stat = "identity") +
      geom_errorbar(aes(x = sample_per_id, ymin = lower_ci, ymax = upper_ci),
        stat = "identity",
        width = .2
      ) +
      labs(
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
