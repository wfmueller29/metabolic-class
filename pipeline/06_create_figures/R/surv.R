kap_plot_cox <- function(df, var, age_death, event, covariates = NULL) {
  cselect <- length(unique(df[[var]])) - 1
  cox_form <- as.formula(paste0("surv_object ~ ", var, covariates))
  surv_object <- survival::Surv(time = df[[age_death]], event = df[[event]])
  fit <- survival::coxph(cox_form, data = df)
  cph_summary <- summary(fit)
  hr_list <- list()
  for (i in 1:cselect) {
    value <- format(
      round(cph_summary$conf.int[, "exp(coef)"][i], 2),
      nsmall = 2
    )
    le <- format(round(cph_summary$conf.int[, "lower .95"][i], 2), nsmall = 2)
    ue <- format(round(cph_summary$conf.int[, "upper .95"][i], 2), nsmall = 2)
    pval <- cph_summary$coefficients[, "Pr(>|z|)"][i]

    if (pval < .001) {
      hr <- paste0("HR = ", value, " (", le, ", ", ue, ")***")
    } else if (pval < .005) {
      hr <- paste0("HR = ", value, " (", le, ", ", ue, ")**")
    } else if (pval < 0.050) {
      hr <- paste0("HR = ", value, " (", le, ", ", ue, ")*")
    } else {
      hr <- paste0("HR = ", value, " (", le, ", ", ue, ")")
    }
    hr_list[[i]] <- hr
  }
  names(hr_list) <- rownames(cph_summary$conf.int)

  hr_list <- lapply(names(hr_list), function(name) {
    el <- paste(name, hr_list[[name]], sep = " ")
    el
  })
  hr <- paste(as.vector(hr_list), collapse = "\n")
  surv_results <- list(hr, pval, cph_summary, fit)


  return(surv_results)
}

kap_plot_all <- function(df,
                         var,
                         age_death,
                         event,
                         ptitle = " ",
                         subtitle = " ") {
  pal_names <- as.numeric(sort(unique(df[[var]])))
  pal <- rep(palette(), 20)[pal_names]
  df[[var]] <- factor(df[[var]])
  if (length(unique(df[[var]])) == 1) {
    hr1 <- NULL
  } else {
    hr1 <- kap_plot_cox(df, var, age_death = age_death, event = event)
  }
  surv_object <- survival::Surv(time = df[[age_death]], event = df[[event]])
  formula <- as.formula(paste0("surv_object ~ ", var))
  fit1 <- survminer::surv_fit(formula, data = df)
  p <- survminer::ggsurvplot(fit1,
    data = df,
    conf.int = FALSE,
    pval = hr1[[1]],
    xlab = "Age (Weeks) ",
    ylab = "Survival Probability",
    legend.labs = pal_names,
    surv.median.line = "hv",
    legend.title = "Class",
    legend = "right",
    size = 2,
    title = ptitle,
    #             font.title = c(12, "bold", "black"),
    ggtheme = ggplot2::theme(
      plot.title = ggplot2::element_text(
        face = "bold",
        color = "black",
        size = 16,
        hjust = .5
      ),
      plot.margin = ggplot2::unit(c(2, 4, 25, 2), "pt")
    ),
    pval.size = 3.5,
    subtitle = subtitle,
    font.subtitle = c(8),
    risk.table = FALSE,
    cumevents = FALSE,
    cumcensor = FALSE,
    palette = pal
  )
  p


  return(p)
}
