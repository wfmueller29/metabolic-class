plot_concord_lp <- function(data, x, y, color, se) {
  width <- 0.9
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
      width = 3, size = 1,
      position = ggplot2::position_dodge2(
        width = width,
        preserve = "single",
        padding = 0
      )
    ) +
    ggplot2::geom_line(
      stat = "identity",
      size = 1,
      position = ggplot2::position_dodge2(
        width = width,
        preserve = "single",
        padding = 0
      )
    )
}
