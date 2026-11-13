# =============================================================================
# source_data.R -- shared helpers for the Data S1 source-data files
#
# Every graph panel writes <name>.csv beside its PNG: the values the panel
# shows, with column names taken from the labels the published figure
# uses. figures/data_s1.R collects these into "Data S1 – Source Data.xlsx".
#
# Sourced by 99_pub_ready_figs and the 9x stages, each from its own directory:
#   source("../figures/source_data.R")
#   source("../../figures/source_data.R")   # 95, which renders from 95_healthcard_cod/R
#
# A panel whose data cannot be written is reported as "SKIP source data ...",
# or is an error under FIGS_STRICT=1, as in 99.
# =============================================================================

# ---- published class names --------------------------------------------------
# As printed in the composite figures (composite figures_revision 111226.pdf).
# Classes are numbered across the three LCMs, BW 1-3, FM 4-6, FBG 7-8, and the
# two adiposity classes are published as 9 and 10.
PUB_CLASS_DESCRIPTOR <- c("1" = "Early-peak", "2" = "Stable", "3" = "Late-peak",
                          "4" = "Early-peak", "5" = "Stable", "6" = "Late-peak",
                          "7" = "Decline", "8" = "Stable",
                          "9" = "Early-peak", "10" = "Stable")
PUB_CLASS_SYSTEM <- c("1" = "BW", "2" = "BW", "3" = "BW", "4" = "FM", "5" = "FM",
                      "6" = "FM", "7" = "FBG", "8" = "FBG",
                      "9" = "Adiposity", "10" = "Adiposity")

# "1 (Early-peak)", the legend form used in Figures 1, 5 and S1-S2
class_legend_label <- function(k) {
  d <- PUB_CLASS_DESCRIPTOR[as.character(k)]
  if (anyNA(d)) stop("no published name for class ", paste(unique(k[is.na(d)]), collapse = ", "))
  paste0(k, " (", d, ")")
}

# "Early-peak-BW", the nickname used in Figures 3, 4, S3 and S6
class_nickname <- function(k) {
  d <- PUB_CLASS_DESCRIPTOR[as.character(k)]
  s <- PUB_CLASS_SYSTEM[as.character(k)]
  if (anyNA(d)) stop("no published name for class ", paste(unique(k[is.na(d)]), collapse = ", "))
  paste0(d, "-", s)
}

# ---- writing ----------------------------------------------------------------
# One CSV per panel, in UTF-8 so labels like "≥ 5" survive. Under a C locale
# only the write switches to UTF-8. Text R read in a C locale can still come
# out escaped ("<e2><89><a5>"); data_s1.R flags that.
write_csv_panel <- function(df, dir, name) {
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  if (!l10n_info()$`UTF-8`) {
    old <- Sys.getlocale("LC_CTYPE")
    if (nzchar(suppressWarnings(Sys.setlocale("LC_CTYPE", "en_US.UTF-8")))) {
      on.exit(Sys.setlocale("LC_CTYPE", old))
    }
  }
  utils::write.csv(df, file.path(dir, paste0(name, ".csv")), row.names = FALSE,
                   na = "", fileEncoding = "UTF-8")
}

# Run one export. A failure is reported and skipped, or stops under FIGS_STRICT.
write_panel_data <- function(f, x, dir, name, ...) {
  tryCatch(f(x, dir, name, ...), error = function(e) {
    msg <- paste0("source data ", dir, "/", name, " -- ", conditionMessage(e))
    if (nzchar(Sys.getenv("FIGS_STRICT"))) stop(msg, call. = FALSE)
    message("SKIP ", msg)
  })
  invisible(NULL)
}

# Group label for each colour, read from the plot's own colour scale: the same
# text and colours ggplot draws in the legend
colour_key <- function(b) {
  sc <- b$plot$scales$get_scales("colour")
  if (is.null(sc)) stop("no colour scale")
  br <- sc$get_breaks()
  key <- data.frame(break_value = as.character(br), colour = unname(sc$map(br)),
                    class = as.character(sc$get_labels(br)))
  if (anyDuplicated(key$colour)) stop("two classes share a colour")
  if (anyNA(key$class)) stop("fewer class labels than classes")
  key
}

# Trajectory panel: every observation drawn, then the LOESS fit and its 95% CI
# (CI columns are blank when the fit is drawn without one)
trajectory_data <- function(g, y_title, group_title = "Class") {
  b <- ggplot2::ggplot_build(g)
  key <- colour_key(b)
  is_point <- vapply(g$layers, function(l) inherits(l$geom, "GeomPoint"), logical(1))
  is_smooth <- vapply(g$layers, function(l) inherits(l$geom, "GeomSmooth"), logical(1))
  if (sum(is_point) != 1 || sum(is_smooth) != 1) stop("expected one point layer and one smooth layer")
  pts <- b$data[[which(is_point)]]
  fit <- b$data[[which(is_smooth)]]
  fit_lower <- if (is.null(fit$ymin)) NA_real_ else fit$ymin
  fit_upper <- if (is.null(fit$ymax)) NA_real_ else fit$ymax
  obs <- data.frame(class = key$class[match(pts$colour, key$colour)], series = "Observed",
                    x = pts$x, y = pts$y, lower = NA_real_, upper = NA_real_)
  smo <- data.frame(class = key$class[match(fit$colour, key$colour)], series = "LOESS fit",
                    x = fit$x, y = fit$y, lower = fit_lower, upper = fit_upper)
  # rows with a missing value are not drawn, so they are not data for the panel
  obs <- obs[!is.na(obs$x) & !is.na(obs$y), ]
  out <- rbind(obs, smo)
  if (anyNA(out$class)) stop("a plotted colour matches no class")
  out <- out[order(match(out$class, key$class), out$series != "Observed", out$x), ]
  names(out) <- c(group_title, "Series", "Age (weeks)", y_title, "95% CI lower", "95% CI upper")
  out
}

# Kaplan-Meier panel: survminer's survival table, one row per step
km_data <- function(g, group_title = "Class") {
  b <- ggplot2::ggplot_build(g)
  key <- colour_key(b)
  d <- g$data
  need <- c("strata", "time", "n.risk", "n.event", "n.censor", "surv")
  if (!all(need %in% names(d))) stop("KM data lacks: ", paste(setdiff(need, names(d)), collapse = ", "))
  out <- data.frame(class = key$class[match(as.character(d$strata), key$break_value)],
                    d$time, d$n.risk, d$n.event, d$n.censor, d$surv)
  if (anyNA(out$class)) stop("a stratum matches no class")
  out <- out[order(match(out$class, key$class), out[[2]]), ]
  names(out) <- c(group_title, "Age (weeks)", "Number at risk", "Number of deaths",
                  "Number censored", "Survival probability")
  out
}

write_trajectory_data <- function(g, dir, name, y_title, group_title = "Class") {
  write_csv_panel(trajectory_data(g, y_title, group_title), dir, name)
}

write_km_data <- function(g, dir, name, group_title = "Class") {
  write_csv_panel(km_data(g, group_title), dir, name)
}

# Line or bar panel with error bars: the plotted aesthetics, read from the
# plot's own data and mapping, so a dodged error bar is reported at its true x.
# `cols` names the output columns for x, y, colour (optional), and the error
# bar's ymin and ymax, in that order.
errorbar_data <- function(g, cols) {
  is_bar <- vapply(g$layers, function(l) inherits(l$geom, "GeomErrorbar"), logical(1))
  if (sum(is_bar) != 1) stop("expected one error-bar layer")
  bar <- g$layers[[which(is_bar)]]
  d <- g$data
  if (!is.data.frame(d) || !nrow(d)) stop("plot has no data")
  eval_aes <- function(aes, mapping) {
    m <- mapping[[aes]]
    if (is.null(m)) m <- g$mapping[[aes]]
    if (is.null(m)) stop("no ", aes, " mapping")
    rlang::eval_tidy(m, d)
  }
  has_colour <- !is.null(g$mapping$colour)
  if (has_colour != (length(cols) == 5)) stop("cols does not match the colour mapping")
  out <- data.frame(x = eval_aes("x", g$mapping), y = eval_aes("y", g$mapping),
                    lower = eval_aes("ymin", bar$mapping), upper = eval_aes("ymax", bar$mapping))
  if (has_colour) {
    grp <- eval_aes("colour", g$mapping)
    lev <- if (is.factor(grp)) levels(grp) else unique(as.character(grp))
    out <- data.frame(group = as.character(grp), out)
  }
  # rows with no x or y are not drawn
  out <- out[!is.na(out$x) & !is.na(out$y), ]
  if (has_colour) {
    out <- out[order(match(out$group, lev), out$x), ]
    # groups as the legend names them, read from the plot's colour scale
    sc <- ggplot2::ggplot_build(g)$plot$scales$get_scales("colour")
    if (!is.null(sc)) {
      br <- sc$get_breaks()
      legend <- setNames(as.character(sc$get_labels(br)), as.character(br))
      if (!all(out$group %in% names(legend))) stop("a group is missing from the colour scale")
      out$group <- unname(legend[out$group])
    }
  } else {
    out <- out[order(out$x), ]
  }
  names(out) <- if (has_colour) cols[c(3, 1, 2, 4, 5)] else cols
  out
}
