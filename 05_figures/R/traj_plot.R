create_legend <- function(df) {
  l <- (length(df)) / 3
  n <- as.numeric(df["n", 1:l])
  sex_name <- rownames(df)[grepl("sex", rownames(df))][1]
  sex_abr <- unlist(strsplit(sex_name, split = "_"))[[2]]
  sex_freq <- round(as.numeric(df[sex_name, 1:l]) / n * 100)
  strain_name <- rownames(df)[grepl("strain", rownames(df))][1]
  strain_abr <- unlist(strsplit(strain_name, split = "_"))[[2]]
  strain_freq <- round(as.numeric(df[strain_name, 1:l]) / n * 100)
  med_surv <- as.numeric(df["median_surv", 1:l])
  legend <- vector()
  col <- vector()
  for (i in 1:l) {
    name <- unlist(str_split(names(df)[i], "_"))[2]
    legend[i] <- paste0(
      "Class ",
      name,
      ":",
      " n=",
      n[i],
      ", ",
      sex_freq[i],
      "%",
      sex_abr,
      ", ",
      strain_freq[i],
      "%",
      strain_abr,
      ", MLE=",
      med_surv[i],
      " weeks"
    )
    col[i] <- mega_pal[as.numeric(name)]
  }
  return(list(legend = legend, col = col))
}

traj_plot <- function(df,
                      mo,
                      t1,
                      age_var,
                      fixcov,
                      y_var,
                      title = " ",
                      xlab = " ",
                      ylab = " ") {
  ## Create legend using create_legend function
  lej <- create_legend(t1)

  ## Create Prediction DF using lcpred
  pred <- helphlme::create_pred_df(
    df = df,
    age_vars = c(age_var, paste0(age_var, 2)),
    fixcov = fixcov
  )

  # Determine ymax by maximum predicted value
  predY <- lcmm::predictY(mo, pred, var.time = paste0(age_var, "_ns"))
  ymax <- max(predY$pred)

  # Determine ymin by either taking minimum predicted value or
  # minimum absoluate value
  abs_min <- min(df[[y_var]])
  pred_min <- min(predY$pred)
  if (pred_min <= abs_min) {
    ymin <- abs_min
  } else {
    ymin <- pred_min
  }

  ## Determine legend position
  if (age_var == "age_wk") {
    lej_pos <- "topright"
  } else {
    lej_pos <- "topleft"
  }
  ## Set graphical parameters
  par(
    mar = c(4, 4, 2, 2),
    mgp = c(2, 1, 0)
  )

  ## Create Plot
  helphlme::plot_hlme(
    df = pred,
    model = mo,
    age = age_var,
    lwd = 3,
    lty = c(1, 1),
    main = title,
    xlab = xlab,
    ylab = ylab,
    cex = .7,
    ylim = c(ymin, 1.1 * ymax),
    legend = NULL,
    col = lej$col
  )
  legend(
    x = lej_pos,
    legend = lej$legend,
    col = lej$col,
    horiz = FALSE,
    lwd = 3,
    lty = c(1, 1),
    cex = .85,
    bty = "n"
  )
}
