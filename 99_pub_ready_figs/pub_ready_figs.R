# =============================================================================
# 99_pub_ready_figs -- publication styling for the figure deck
#
# WHAT THIS STAGE IS FOR
#   Stage 07 saves its plots as ggplot OBJECTS (plot_list.RDATA,
#   validation_list.RDATA). This stage loads those objects, applies the
#   publication styling, and writes one PNG per panel. figures/figure_spec.R
#   then references those PNGs by path.
#
#   Style MUST be applied here. By the time a panel reaches the deck it is a
#   PNG and its appearance is fixed -- fonts, axes and colours are pixels.
#
# WHAT IT DELIBERATELY DOES NOT DO
#   No figure numbers, no panel letters, no composition. A component does not
#   know which figure it lands in; that is figure_spec.R's job. Outputs are
#   named semantically (bw_by_fat) so they survive renumbering.
#
# PANEL NAMING -- <outcome>_by_<class system>
#   Stage 07 builds new_figure1_plot_list as c(obs_plots, kap_plots,
#   unique_plots) with outcomes ordered bw, fat, gluc, giving 12 positions:
#
#     1  bw_by_bw       observed BW,  coloured by BW class    (diagonal)
#     2  fat_by_fat     observed FM,  coloured by FM class    (diagonal)
#     3  gluc_by_gluc   observed FBG, coloured by FBG class   (diagonal)
#     4  km_bw          Kaplan-Meier by BW class
#     5  km_fat         Kaplan-Meier by FM class
#     6  km_gluc        Kaplan-Meier by FBG class
#     7  fat_by_bw      FM  coloured by BW class
#     8  bw_by_fat      BW  coloured by FM class
#     9  bw_by_gluc     BW  coloured by FBG class
#     10 gluc_by_bw     FBG coloured by BW class
#     11 gluc_by_fat    FBG coloured by FM class
#     12 fat_by_gluc    FM  coloured by FBG class
#
#   NOTE: position 10 used to be lost. It was assigned the name "glucfat" and
#   then immediately overwritten by position 11 under the same name, so one
#   panel was never written at all. It is figure 1D, so that bug is fixed here
#   by giving every position a distinct name.
#
# STYLING RULES
#   The y-axis title comes from the OUTCOME plotted, not the class system:
#     bw -> "Body weight (g)"   fat -> "Fat mass (g)"   gluc -> "Blood glucose (mg/dL)"
#   The three diagonal panels (outcome == class system) get a BOLD y title;
#   cross-reference panels get plain. Axis ranges are fixed per outcome so
#   panels stay comparable across cohorts.
#
# OUTPUTS  (output/<env>/...)
#   define_class/<name>.png       one per panel, legend removed
#   define_class/legend_<n>.png   the three class legends, for placement
#   validation/<name>.png         validation curves
# =============================================================================

library(consoler)
library(cowplot)
library(ggplot2)

# ---- panel definitions ------------------------------------------------------
# position in new_figure1_plot_list -> name, outcome, and whether it is a
# diagonal (own-class) panel. Order matches the plot list.
PANELS <- list(
  list(i = 1,  name = "bw_by_bw",     outcome = "bw",   diagonal = TRUE),
  list(i = 2,  name = "fat_by_fat",   outcome = "fat",  diagonal = TRUE),
  list(i = 3,  name = "gluc_by_gluc", outcome = "gluc", diagonal = TRUE),
  list(i = 4,  name = "km_bw",        outcome = "km",   diagonal = FALSE),
  list(i = 5,  name = "km_fat",       outcome = "km",   diagonal = FALSE),
  list(i = 6,  name = "km_gluc",      outcome = "km",   diagonal = FALSE),
  list(i = 7,  name = "fat_by_bw",    outcome = "fat",  diagonal = FALSE),
  list(i = 8,  name = "bw_by_fat",    outcome = "bw",   diagonal = FALSE),
  list(i = 9,  name = "bw_by_gluc",   outcome = "bw",   diagonal = FALSE),
  list(i = 10, name = "gluc_by_bw",   outcome = "gluc", diagonal = FALSE),
  list(i = 11, name = "gluc_by_fat",  outcome = "gluc", diagonal = FALSE),
  list(i = 12, name = "fat_by_gluc",  outcome = "fat",  diagonal = FALSE)
)

Y_LABEL  <- c(bw = "Body weight (g)",
              fat = "Fat mass (g)",
              gluc = "Blood glucose (mg/dL)")

Y_LIMITS <- list(bw = c(0, 70), fat = c(0, 25), gluc = c(0, 275))

# ---- canonical axis labels --------------------------------------------------
# ONE vocabulary for the whole paper, enforced here because this is the last
# point at which a plot is still a ggplot OBJECT -- after this it is a PNG and
# the text is pixels. Stage 07 is deliberately left untouched: its labels come
# from each config's oc_name/oc_units and vary ("Body Weight", "Body fat",
# "Glucose (mg/dL)", ...). Rather than chase every config, every label is
# normalised here on the way out.
#
#   anything mentioning fat        -> "Fat mass (g)"
#   anything mentioning glucose    -> "Blood glucose (mg/dL)"
#   anything mentioning body weight-> "Body weight (g)"
#
# Matching is case-insensitive and ignores existing units, so "Body Fat",
# "body fat (g)", "Fat", "Fat Mass" all collapse to the same string. Labels
# that match none of these (e.g. "Survival", "Concordance", "Age (weeks)")
# are left exactly as they are.
#
# TO ADD OR CHANGE A TERM: edit CANON below. It applies to every panel this
# stage writes, existing and future -- do not special-case labels elsewhere.
CANON <- list(
  list(pattern = "fat|\\bfm\\b",            label = "Fat mass (g)"),
  list(pattern = "gluc|\\bfbg\\b",          label = "Blood glucose (mg/dL)"),
  list(pattern = "body ?wei?gh?t|^bw\\b",   label = "Body weight (g)")
)

canonical_label <- function(lab) {
  if (is.null(lab) || !is.character(lab) || !nzchar(lab)) return(lab)
  l <- tolower(trimws(lab))
  for (rule in CANON) if (grepl(rule$pattern, l)) return(rule$label)
  lab
}

# Apply to the axis titles of a ggplot, leaving everything else alone.
normalise_labels <- function(g) {
  if (!inherits(g, "gg")) return(g)
  if (!is.null(g$labels$y)) g$labels$y <- canonical_label(g$labels$y)
  if (!is.null(g$labels$x)) g$labels$x <- canonical_label(g$labels$x)
  g
}

# ---- stage 07 workspaces ----------------------------------------------------
OUTCOME_ENVS <- list(
  all_env   = "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/outcome/plot_list.RDATA",
  fb6_env   = "../07_display_figures/output/slam_c1-c10_age_fb6_bwfatgluc/outcome/plot_list.RDATA",
  fhet3_env = "../07_display_figures/output/slam_c1-c10_age_fhet3_bwfatgluc/outcome/plot_list.RDATA",
  mb6_env   = "../07_display_figures/output/slam_c1-c10_age_mb6_bwfatgluc/outcome/plot_list.RDATA",
  mhet3_env = "../07_display_figures/output/slam_c1-c10_age_mhet3_bwfatgluc/outcome/plot_list.RDATA"
)

VALIDATION_ENVS <- list(
  all_env      = "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/validation/validation_list.RDATA",
  held_out_env = "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/validation/validation_list.RDATA"
)

save_png <- function(plot, dir, name, width = 4, height = 5, dpi = 300) {
  # every panel leaves this stage with canonical axis labels -- no exceptions
  plot <- normalise_labels(plot)
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  ggplot2::ggsave(filename = file.path(dir, paste0(name, ".png")),
                  plot = plot, width = width, height = height, dpi = dpi)
}

# ---- define-class panels ----------------------------------------------------
for (env_name in names(OUTCOME_ENVS)) {
  path <- OUTCOME_ENVS[[env_name]]
  if (!file.exists(path)) {
    message("SKIP ", env_name, " -- not found: ", path)
    next
  }
  e <- new.env()
  load(path, envir = e)
  plots   <- e$new_figure1_plot_list
  out_dir <- file.path("output", env_name, "define_class")

  for (p in PANELS) {
    if (p$i > length(plots)) {
      message("SKIP ", env_name, "/", p$name,
              " -- plot list has only ", length(plots), " entries")
      next
    }
    g <- plots[[p$i]]

    if (p$outcome != "km") {
      face <- if (p$diagonal) "bold" else "plain"
      g <- g +
        ggplot2::ylab(Y_LABEL[[p$outcome]]) +
        ggplot2::coord_cartesian(ylim = Y_LIMITS[[p$outcome]]) +
        ggplot2::theme(axis.title.y = ggplot2::element_text(face = face))
    }

    save_png(g + ggplot2::theme(legend.position = "none"), out_dir, p$name)
  }

  # the three class legends, exported separately for placement
  legends <- e$save_figtabs$legends_only
  if (!is.null(legends)) {
    for (k in seq_along(legends)) {
      lg <- tryCatch(cowplot::ggdraw(legends[[k]]), error = function(...) NULL)
      if (!is.null(lg)) save_png(lg, out_dir, paste0("legend_", k), width = 3, height = 3)
    }
  }
}

# ---- validation panels ------------------------------------------------------
VALIDATION_PANELS <- list(
  list(i = 1, name = "window_coef",    kind = "coef"),
  list(i = 2, name = "window_concord", kind = "concord"),
  list(i = 3, name = "cum_coef",       kind = "coef"),
  list(i = 4, name = "cum_concord",    kind = "concord")
)

for (env_name in names(VALIDATION_ENVS)) {
  path <- VALIDATION_ENVS[[env_name]]
  if (!file.exists(path)) {
    message("SKIP ", env_name, " validation -- not found: ", path)
    next
  }
  e <- new.env()
  load(path, envir = e)
  out_dir <- file.path("output", env_name, "validation")

  for (p in VALIDATION_PANELS) {
    if (p$i > length(e$p)) next
    g <- e$p[[p$i]]
    g <- if (p$kind == "coef") {
      g + ggplot2::coord_cartesian(ylim = c(-1, 3)) +
        ggplot2::geom_hline(yintercept = 1, linetype = "dotted", colour = "gray40") +
        ggplot2::ylab("Linear Predictor") + ggplot2::xlab("Upper Bound Age (weeks)")
    } else {
      g + ggplot2::coord_cartesian(ylim = c(0.4, 0.8)) +
        ggplot2::geom_hline(yintercept = 0.5, linetype = "dotted", colour = "red") +
        ggplot2::ylab("Concordance") + ggplot2::xlab("Upper Bound Age (weeks)")
    }
    save_png(g + ggplot2::theme(legend.position = "none"), out_dir, p$name)
  }
}

message("99_pub_ready_figs: done")
