# Purpose: The purpose of this function is to create a spaghetti plot
# for the metabolic class data
# Author: William Mueller

plot_spag <- function(data, x, y, id, title = " ", xlab = " ", ylab = " ") {
  x <- paste0(x, "_ns")
  ggplot2::ggplot(
    data = data,
    mapping = ggplot2::aes_string(
      x = x,
      y = y,
      group = id
    )
  ) +
    #    ggplot2::geom_point() +
    ggplot2::geom_line() +
    ggplot2::geom_smooth(
      data = data,
      mapping = ggplot2::aes_string(
        x = x,
        y = y,
        group = NULL
      ) 
    ) +
    labs(title = title, 
         x = xlab,
         y = ylab)
}
