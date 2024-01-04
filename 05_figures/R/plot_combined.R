# Purpose: Function to plot other metabolic outcomes by class
# Author: William Mueller

create_combined_df <- function(census, census_id, outcome_df, outcome_id) {
  census <- census[, c(census_id, "new_class")]
  combined_df <- merge(outcome_df, census, by.x = outcome_id, by.y = census_id)
  combined_df
}

plot_combined <- function(census, t1, outcome_df, outcome, age, census_id, outcome_id, title, xlab, ylab) {
  lej <- create_legend(t1)

  combined_df <- create_combined_df(census, census_id, outcome_df, outcome_id)

  plot <- ggplot2::ggplot(
    data = combined_df,
    ggplot2::aes(
      x = eval(as.symbol(age)),
      y = eval(as.symbol(outcome)),
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

  plot
}


plot_combined_across <- function(final_models, model_name) {
  final_models_row <- final_models[final_models$model_name == model_name, ]
  outcome_df <- final_models_row$dfs[[1]]
  other_name <- final_models_row$oc_name
  outcome <- final_models_row$oc
  outcome_id <- final_models_row$subject
  plots <- lapply(seq_len(nrow(final_models)), function(i) {
    plot_combined(
      census = final_models$census[[i]],
      t1 = final_models$t1_raw[[i]],
      outcome_df = outcome_df,
      outcome = outcome,
      age = final_models$age_var[[i]],
      census_id = final_models$subject[[i]],
      outcome_id = outcome_id,
      title = paste(
        other_name,
        "across",
        final_models$age_var_name[[i]],
        "by",
        final_models$oc_name[[i]],
        "Class",
        sep = " "
      ),
      xlab = paste(final_models$age_var_name[[i]],
                   final_models$age_var_units[[i]], sep = " "),
      ylab = paste(final_models$oc_name[[i]],
                   final_models$oc_name_units[[i]], sep = " ")
    )
  })
  plots
}
