# Purpose: To plot the observed values of a dataframe by class
# Author William Mueller

# need to source for create legend function
source("R/traj_plot.R")

traj_obs <- function(main,
                     df,
                     t1,
                     age_var,
                     y_var,
                     id_var,
                     title = " ",
                     xlab = " ",
                     ylab = " ") {
  ## Create legend
  lej <- create_legend(t1)

  # age_var_ns
  age_var <- paste0(age_var, "_ns")

  ## join main and df
  main_obs <- merge(x = main, y = df, by = id_var)

  p <- ggplot2::ggplot(
    data = main_obs,
    mapping = ggplot2::aes(
      x = eval(as.symbol((age_var))),
      y = eval(as.symbol(y_var)),
      color = factor(new_class)
    )
  ) +
    ggplot2::geom_point(alpha = .1) +
    ggplot2::geom_smooth(
      method = "gam",
      formula = y ~ s(x, bs = "cs"),
      span = .7,
      inherit.aes = TRUE
    ) +
    ggplot2::scale_color_manual(values = lej$col) +
    ggplot2::labs(
      color = "Class",
      y = ylab,
      x = xlab,
      title = title
    ) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        face = "bold",
        color = "black",
        size = 16,
        hjust = .5
      ),
      plot.margin = ggplot2::unit(c(10, 4, 25, 2), "pt")
    )

  return(p)
}
