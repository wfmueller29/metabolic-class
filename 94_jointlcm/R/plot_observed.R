plot_observed_classes <- function(data,
                                  x,
                                  y,
                                  class,
                                  id = NULL,
                                  smooth_method = "loess",
                                  se = FALSE,
                                  alpha_points = 0.15,
                                  point_size = 1.5,
                                  line_size = 1.2,
                                  title = NULL,
                                  x_label = NULL,
                                  y_label = NULL,
                                  class_label = "Class") {
  p <- ggplot(
    data,
    aes(
      x = {{ x }},
      y = {{ y }},
      color = factor({{ class }})
    )
  ) +
    geom_point(
      alpha = alpha_points,
      size = point_size
    ) +
    geom_smooth(
      method = smooth_method,
      se = se,
      linewidth = line_size
    ) +
    labs(
      title = title,
      x = x_label,
      y = y_label,
      color = class_label
    ) +
    theme_classic(base_size = 14) +
    theme(
      legend.position = "right",
      plot.title = element_text(hjust = 0.5)
    )

  return(p)
}
