# Purpose: Function to plot other metabolic outcomes by class
# Author: William Mueller

plot_other <- function(census, t1, other_df, oc, age_var, title, xlab, ylab) {
  lej <- create_legend(t1)

  other_plot <- create_other_plot_df(census, other_df)

  plot <- ggplot(
    data = other_plot,
    aes(
      x = eval(as.symbol(age_var)),
      y = eval(as.symbol(oc)),
      color = factor(new_class)
    )
  ) +
    geom_point(alpha = .1) +
    geom_smooth(
      method = "gam",
      formula = y ~ s(x, bs = "cs"),
      span = .7,
      inherit.aes = TRUE
    ) +
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

  plot
}

create_other_plot_df <- function(census, other_df) {
  census <- census %>%
    select(idno, new_class)

  other_plot_data <- other_df %>%
    left_join(census, by = "idno") %>%
    filter(!is.na(new_class))

  other_plot_data
}

plot_other_apply <- function(final_models, model_name) {
  x <- final_models
  other_df <- x[x$model_name == model_name, ]$dfs[[1]]
  other_name <- x[x$model_name == model_name, ]$oc_name
  oc <- x[x$model_name == model_name, ]$oc
  plots <- lapply(seq_len(nrow(x)), function(i) {
    plot_other(
      census = x$census[[i]],
      t1 = x$t1_raw[[i]],
      other_df = other_df,
      oc = oc,
      age_var = x$age_var[[i]],
      title = paste(
        other_name,
        "across",
        x$age_var_name[[i]],
        "by",
        x$oc_name[[i]],
        "Class",
        sep = " "
      ),
      xlab = paste(x$age_var_name[[i]], x$age_var_units[[i]], sep = " "),
      ylab = paste(x$oc_name[[i]], x$oc_name_units[[i]], sep = " ")
    )
  })
  plots
}
