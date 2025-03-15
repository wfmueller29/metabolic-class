plot_cumulative_concord_lp <- function(data, outcome,
                                       lower_bound, upper_bound, se,
                                       ylab, xlab, title, legend_title) {
  ggplot2::ggplot(
    data = data,
    mapping = ggplot2::aes(
      x = as.numeric(.data[[upper_bound]]),
      y = as.numeric(.data[[outcome]]),
      color = factor(.data[[lower_bound]])
    )
  ) +
    ggplot2::geom_line(stat = "identity") +
    ggplot2::geom_errorbar(
      ggplot2::aes(
        x = .data[[upper_bound]],
        ymin = .data[[outcome]] - 1.96 * .data[[se]],
        ymax = .data[[outcome]] + 1.96 * .data[[se]]
      ),
      stat = "identity",
      width = 2
    ) +
    ggplot2::labs(
      y = ylab,
      x = xlab,
      title = title,
      color = legend_title
    )
}

plot_window_concord_lp <- function(data, outcome,
                                   window_size, midpoint, se,
                                   ylab, xlab, title, legend_title) {
  ggplot2::ggplot(
    data = data,
    mapping = ggplot2::aes(
      x = as.numeric(.data[[midpoint]]),
      y = as.numeric(.data[[outcome]]),
      color = factor(.data[[window_size]])
    )
  ) +
    ggplot2::geom_errorbar(
      ggplot2::aes(
        x = .data[[midpoint]],
        ymin = .data[[outcome]] - 1.96 * .data[[se]],
        ymax = .data[[outcome]] + 1.96 * .data[[se]]
      ),
      stat = "identity",
      width = 2, size = 1,
      position = ggplot2::position_dodge2(width = 0.9, preserve = "single", padding = 0)
    ) +
    ggplot2::geom_line(
      stat = "identity",
      size = 1,
      position = ggplot2::position_dodge2(width = 0.9, preserve = "single", padding = 0)
    ) +
    ggplot2::labs(
      y = ylab,
      x = xlab,
      title = title,
      color = legend_title
    )
}

plot_concord_lp <- function(data, x, y, color, se,
                            ylab, xlab, title, legend_title) {
  ggplot2::ggplot(
    data = data,
    mapping = ggplot2::aes(
      x = as.numeric(.data[[x]]),
      y = as.numeric(.data[[y]]),
      color = factor(.data[[color]])
    )
  ) +
    ggplot2::geom_errorbar(
      ggplot2::aes(
        x = .data[[x]],
        ymin = .data[[y]] - 1.96 * .data[[se]],
        ymax = .data[[y]] + 1.96 * .data[[se]]
      ),
      stat = "identity",
      width = 2, size = 1,
      position = ggplot2::position_dodge2(
        width = 0.9,
        preserve = "single",
        padding = 0
      )
    ) +
    ggplot2::geom_line(
      stat = "identity",
      size = 1,
      position = ggplot2::position_dodge2(
        width = 0.9,
        preserve = "single",
        padding = 0
      )
    ) +
    ggplot2::labs(
      y = ylab,
      x = xlab,
      title = title,
      color = legend_title
    )
}
