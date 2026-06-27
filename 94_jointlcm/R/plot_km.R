plot_km_classes <- function(data,
                            time,
                            event,
                            class,
                            title = NULL,
                            x_label = "Time",
                            y_label = "Survival probability",
                            class_label = "Class",
                            risk_table = TRUE,
                            pval = TRUE,
                            conf_int = FALSE,
                            censor = TRUE,
                            palette = NULL) {
  # Create temporary clean dataframe
  km_data <- data.frame(
    time = data[[deparse(substitute(time))]],
    event = data[[deparse(substitute(event))]],
    class = factor(data[[deparse(substitute(class))]])
  )

  km_data <- km_data[complete.cases(km_data), ]

  # Fit Kaplan-Meier model
  km_fit <- survfit(
    Surv(time, event) ~ class,
    data = km_data
  )

  # Plot
  ggsurvplot(
    km_fit,
    data = km_data,
    risk.table = risk_table,
    pval = pval,
    conf.int = conf_int,
    censor = censor,
    palette = palette,
    title = title,
    xlab = x_label,
    ylab = y_label,
    legend.title = class_label,
    legend.labs = levels(km_data$class),
    ggtheme = theme_classic(base_size = 14),
    risk.table.theme = theme_classic(base_size = 12)
  )
}
