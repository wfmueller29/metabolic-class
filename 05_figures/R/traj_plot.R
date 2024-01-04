get_abr_freq <- function(df, row_name, class_no, n) {
  split <- unlist(strsplit(row_name, split = "_"))
  abr <- split[length(split)]
  freq <- round(as.numeric(df[row_name, 1:class_no]) / n * 100)

  list(row_name = row_name, abr = abr, freq = freq)
}

create_legend <- function(df) {
  class_no <- (length(df)) / 3
  n <- as.numeric(df["n", 1:class_no])

  row_names <- rownames(df)[-c(1, length(rownames(df)))]
  abr_freq <- lapply(
    row_names, get_abr_freq,
    df = df, class_no = class_no, n = n
  )

  med_surv <- as.numeric(df["median_surv", 1:class_no])
  legend <- vector()
  col <- vector()
  for (i in 1:class_no) {
    abr_freq_i <- lapply(abr_freq, function(abr_freq) {
      paste(abr_freq$freq[[i]], abr_freq$abr, sep = "%")
    })
    abr_freq_i <- paste(unlist(abr_freq_i), collapse = ", ")
    legend[i] <- paste0(
      "Class ", i, ":",
      " n=", n[i], ", ",
      abr_freq_i,
      ", MLE=", med_surv[i], " weeks"
    )
    col[i] <- mega_pal[as.numeric(i)]
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
  par(mar = c(4, 4, 2, 2), mgp = c(2, 1, 0))

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
