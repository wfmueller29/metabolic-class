# Purpose: To plot the observed values of a dataframe by class
# Author William Mueller

# need to source for create legend function
source("R/traj_plot.R")

traj_obs <- function(main,
                     df,
                     t1,
                     age_var,
                     y_var,
                     title = " ",
                     xlab = " ",
                     ylab = " ") {
  ## Create legend
  lej <- create_legend(t1)

  # age_var_ns
  age_var <- paste0(age_var, "_ns")

  ## make id character
  df <- df %>%
    select(-sex, -strain)

  ## join main and df
  main_obs <- main %>%
    left_join(df, by = "idno")

  p <- ggplot(
    data = main_obs,
    mapping = aes(
      x = eval(as.symbol((age_var))),
      y = eval(as.symbol(y_var)),
      color = factor(new_class)
    )
  ) +
    geom_point(alpha = .1) +
    geom_smooth(method = "gam",
                formula = y ~ s(x, bs = "cs"),
                span = .7,
                inherit.aes = TRUE) +
    scale_color_manual(values = lej$col) +
    labs(
      color = "Class",
      y = ylab,
      x = xlab,
      title = title
    ) +
    theme(
      plot.title = element_text(
        face = "bold",
        color = "black",
        size = 16,
        hjust = .5
      ),
      plot.margin = unit(c(10, 4, 25, 2), "pt")
    )

  return(p)
}
