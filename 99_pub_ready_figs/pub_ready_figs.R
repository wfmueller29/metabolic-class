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

# ---- strict mode ------------------------------------------------------------
# By default a missing input is reported and skipped, so this stage can run
# partway through a pipeline run and build whatever is ready. That tolerance is
# a liability for the final production run: a panel that fails to build would
# just come out as a MISSING line in the deck and could be scrolled past.
#
#   FIGS_STRICT=1 Rscript pub_ready_figs.R
#
# turns every skip into a hard error. Use it for the run that produces the
# submitted figures -- if it exits 0, every panel and table in the deck was
# actually built from real data.
STRICT <- nzchar(Sys.getenv("FIGS_STRICT"))
skip <- function(...) {
  if (STRICT) stop(..., call. = FALSE) else message("SKIP ", ...)
  invisible(NULL)
}

# ---- panel definitions ------------------------------------------------------
# position in new_figure1_plot_list -> name, outcome, and whether it is a
# diagonal (own-class) panel. Order matches the plot list.
# NOT every config models three outcomes. The SLAM runs use bw/fat/gluc (12
# plots), but the ITP control run models body weight only, and its plot list has
# just TWO entries -- observed BW, then the BW Kaplan-Meier. Hard-coding the
# 12-position table would save that KM as "fat_by_fat".
#
# Stage 07 builds the list as c(obs_plots, kap_plots, unique_plots), so for n
# outcomes the length is n + n + n*(n-1) = n^2 + n. That inverts cleanly:
#   2 plots -> 1 outcome    12 plots -> 3 outcomes
# The first n are the diagonals, the next n the KMs, and the remainder the
# cross-references (none when n == 1).
# Outcomes are PER CONFIG, in the order the config lists its datasets. Most
# SLAM runs are bw/fat/gluc, but slam_c1-c10_age_all_bwadipositygluc swaps fat
# for adiposity, and the ITP run is body weight only. Hard-coding bw/fat/gluc
# would have written the adiposity panels out as "fat_by_fat".
DEFAULT_OUTCOMES <- c("bw", "fat", "gluc")

# Cross-reference order for the 3-outcome case, positions 7-12, as (outcome
# plotted, class system colouring it) index pairs into the config's outcome
# vector. Derived from stage 07's `selector` (the off-diagonal of a 3x3 grid)
# and confirmed against the rendered panels.
CROSS_3_PAIRS <- list(c(2, 1), c(1, 2), c(1, 3), c(3, 1), c(3, 2), c(2, 3))

panels_for <- function(n_plots, outcomes = DEFAULT_OUTCOMES) {
  n <- (-1 + sqrt(1 + 4 * n_plots)) / 2
  if (abs(n - round(n)) > 1e-9) {
    warning("plot list of length ", n_plots,
            " does not fit n^2 + n -- skipping this environment")
    return(NULL)
  }
  n <- round(n)
  if (length(outcomes) < n) {
    warning("only ", length(outcomes), " outcome names for ", n,
            " outcomes -- skipping this environment")
    return(NULL)
  }
  oc <- outcomes[seq_len(n)]

  out <- list()
  for (k in seq_len(n))                      # diagonals
    out[[length(out) + 1]] <- list(i = k, name = paste0(oc[k], "_by_", oc[k]),
                                   outcome = oc[k], diagonal = TRUE)
  for (k in seq_len(n))                      # Kaplan-Meiers
    out[[length(out) + 1]] <- list(i = n + k, name = paste0("km_", oc[k]),
                                   outcome = "km", diagonal = FALSE)
  if (n == 3) {                              # cross-references
    for (k in seq_along(CROSS_3_PAIRS)) {
      pr <- CROSS_3_PAIRS[[k]]
      out[[length(out) + 1]] <- list(
        i = 2 * n + k,
        name = paste0(oc[pr[1]], "_by_", oc[pr[2]]),
        outcome = oc[pr[1]], diagonal = FALSE)
    }
  } else if (n > 1) {
    warning("no cross-reference naming defined for ", n, " outcomes -- ",
            "only diagonals and KMs will be written")
  }
  out
}

Y_LABEL  <- c(bw = "Body weight (g)",
              fat = "Fat mass (g)",
              adiposity = "Adiposity (%)",
              gluc = "Blood glucose (mg/dL)")

# Fixed ranges keep panels comparable across cohorts. An outcome with no entry
# here is left to autoscale.
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
  list(pattern = "adipos",                  label = "Adiposity (%)"),
  list(pattern = "fat|\\bfm\\b",            label = "Fat mass (g)"),
  list(pattern = "gluc|\\bfbg\\b",          label = "Blood glucose (mg/dL)"),
  list(pattern = "body ?wei?gh?t|^bw\\b",   label = "Body weight (g)"),
  # KM axes. Stage 07 emits 'Age (Weeks) ' (title case, trailing space) and
  # 'Survival Probability'; the manuscript uses sentence case throughout, as
  # with the outcome labels above. Normalising here means every KM in the deck
  # agrees without touching 07. Anything OUTSIDE this stage that draws its own
  # KM must match these two strings by hand -- 92_overlap_analysis writes its
  # PNG directly and so is the one place that has to be kept in step.
  list(pattern = "^age *\\(weeks?\\)$",     label = "Age (weeks)"),
  list(pattern = "^survival probability$",  label = "Survival probability"),
  # Forest-panel x axis. Table HEADERS stay Title Case ("Hazard Ratio (CI)");
  # this is an axis title, so sentence case like every other axis in the deck.
  list(pattern = "^hazard ratio$",          label = "Hazard ratio")
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

# ---- significance stars -----------------------------------------------------
# SLAM::surv_gethr bakes stars into its `final` string using
#   *** p<0.001 | ** p<0.005 | * p<0.05
# Note the 0.005 -- NOT the conventional 0.01. Anything reading `final` inherits
# that silently, which is how the manuscript legend came to say p<0.01.
#
# 07 now also saves save_figtabs$hr_numeric (Outcome/Class/Model/value/lower/
# upper/pval/final), so where that exists we can format the string ourselves and
# apply the thresholds below explicitly.
#
# THESE MUST MATCH THE MANUSCRIPT LEGENDS. That is the whole reason this stage
# re-derives the stars instead of passing SLAM's through: the legends are the
# specification, and 99 enforces them.
#
# Current legends state:  *, p<0.05;  **, p<0.01;  ***, p<0.001
# so that is what is set below. Note this DIFFERS from SLAM's baked-in 0.005:
# any HR with 0.005 <= p < 0.01 gains a star relative to the old figures. That
# is intended -- the old figures did not match their own legend.
#
# TO CHANGE THE CONVENTION: edit STAR_RULES and the legends together, never one
# alone. Checked in order, first match wins.
STAR_RULES <- list(
  list(p = 0.001, mark = "***"),
  list(p = 0.01,  mark = "**"),
  list(p = 0.05,  mark = "*")
)

stars <- function(p) {
  if (is.na(p)) return("")
  for (r in STAR_RULES) if (p < r$p) return(r$mark)
  ""
}

# The one HR formatter: "0.8123 (0.7204, 0.9145) ***", built from the numeric
# value/CI/p rather than inheriting SLAM's pre-formatted string, so the stars
# come from STAR_RULES above and therefore match the manuscript legends.
#
# Every HR column in the deck is headed "Hazard Ratio (CI)" or "HR (CI)", so
# the string carries no "HR = " prefix -- it would be redundant with the header.
# There used to be a second formatter that added one; it was removed rather than
# left alongside this one, because choosing the wrong of two near-identical
# formatters is invisible until the PNG is rendered.
format_hr_bare <- function(value, lower, upper, pval, digits = 4) {
  st <- stars(as.numeric(pval))
  # nsmall MUST equal `digits`. With nsmall = 0 a value whose 4th decimal is a
  # zero printed short (0.7240 -> "0.724"), leaving a few cells at 3 dp in a
  # 4 dp column. Verified: those values genuinely carry a trailing zero.
  trimws(sprintf("%s (%s, %s) %s",
                 format(round(as.numeric(value), digits), nsmall = digits),
                 format(round(as.numeric(lower), digits), nsmall = digits),
                 format(round(as.numeric(upper), digits), nsmall = digits), st))
}

# Pull one model's rows out of hr_numeric; NULL if 07 did not produce it (the
# caller then falls back to SLAM's pre-formatted `final` strings).
#
# CLASS LABELS: hr_numeric carries the RAW model term names ("Class2"), because
# cox_table_numeric() reads straight from surv_gethr. hr_table carries the
# DISPLAY labels ("Class 2"), because 07 rewrites them through
# config$legend_labels afterwards. Publishing the raw ones would be wrong, so
# the display label is taken from hr_table, matched on a whitespace-stripped
# key. Doing it that way rather than reinserting a space keeps this correct if
# legend_labels is ever set to something else entirely (e.g. "Early-Peak-BW").
#
# Values were verified identical between the two sources within a run before
# this was relied on.
hr_numeric_rows <- function(env, model = "HR Model 1") {
  hn <- env$save_figtabs$hr_numeric
  if (is.null(hn) || !nrow(hn)) return(NULL)
  rows <- hn[hn$Model == model, , drop = FALSE]
  if (!nrow(rows)) return(NULL)

  ht <- env$save_figtabs$hr_table
  if (!is.null(ht) && nrow(ht)) {
    key      <- function(o, c) paste(gsub("\\s+", "", o), gsub("\\s+", "", c))
    lookup   <- setNames(as.character(ht$Class), key(ht$Outcome, ht$Class))
    display  <- lookup[key(rows$Outcome, rows$Class)]
    rows$Class <- ifelse(is.na(display), as.character(rows$Class), display)
  }
  rows[!is.na(rows$Class), , drop = FALSE]
}

# ---- stage 07 workspaces ----------------------------------------------------
OUTCOME_ENVS <- list(
  all_env       = list(path = "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/outcome/plot_list.RDATA"),
  fb6_env       = list(path = "../07_display_figures/output/slam_c1-c10_age_fb6_bwfatgluc/outcome/plot_list.RDATA"),
  fhet3_env     = list(path = "../07_display_figures/output/slam_c1-c10_age_fhet3_bwfatgluc/outcome/plot_list.RDATA"),
  mb6_env       = list(path = "../07_display_figures/output/slam_c1-c10_age_mb6_bwfatgluc/outcome/plot_list.RDATA"),
  mhet3_env     = list(path = "../07_display_figures/output/slam_c1-c10_age_mhet3_bwfatgluc/outcome/plot_list.RDATA"),
  # body weight only -- 2 plots, not 12
  itp_env       = list(path = "../07_display_figures/output/itp_c10c11c13c16_age_controls_bw/outcome/plot_list.RDATA",
                       outcomes = "bw"),
  # adiposity in place of fat mass
  adiposity_env = list(path = "../07_display_figures/output/slam_c1-c10_age_all_bwadipositygluc/outcome/plot_list.RDATA",
                       outcomes = c("bw", "adiposity", "gluc")),

  # ITP genotyped cohorts (S9). Body weight only, so two plots each: the
  # trajectory then its KM. Routed through this stage for the same reason as
  # everything else -- 07 labels these "Body Weight" / "Survival Probability" /
  # "Age (Weeks) " from the config, and CANON normalises all three on the way
  # out. The three *_tx_* configs are the rapamycin-treated arms; they have a
  # history of failing upstream, and simply do not appear if that happens.
  itp_geno_env      = list(path = "../07_display_figures/output/itp_genotyped/outcome/plot_list.RDATA",
                           outcomes = "bw"),
  itp_geno_f_env    = list(path = "../07_display_figures/output/itp_genotyped_F/outcome/plot_list.RDATA",
                           outcomes = "bw"),
  itp_geno_m_env    = list(path = "../07_display_figures/output/itp_genotyped_M/outcome/plot_list.RDATA",
                           outcomes = "bw"),
  itp_geno_tx_env   = list(path = "../07_display_figures/output/itp_genotyped_treat/outcome/plot_list.RDATA",
                           outcomes = "bw"),
  itp_geno_tx_f_env = list(path = "../07_display_figures/output/itp_genotyped_treat_F/outcome/plot_list.RDATA",
                           outcomes = "bw"),
  itp_geno_tx_m_env = list(path = "../07_display_figures/output/itp_genotyped_treat_M/outcome/plot_list.RDATA",
                           outcomes = "bw")
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
# Collect the ITP-genotype trajectory/KM ggplots as they are rendered, to
# assemble the S9 composite panels (controls = A, treated = B) after the loop.
itp_geno_ggplots <- new.env()

for (env_name in names(OUTCOME_ENVS)) {
  spec <- OUTCOME_ENVS[[env_name]]
  path <- spec$path
  oc   <- if (is.null(spec$outcomes)) DEFAULT_OUTCOMES else spec$outcomes
  if (!file.exists(path)) {
    skip(env_name, " -- not found: ", path)
    next
  }
  e <- new.env()
  load(path, envir = e)
  plots   <- e$new_figure1_plot_list
  out_dir <- file.path("output", env_name, "define_class")

  panels <- panels_for(length(plots), oc)
  if (is.null(panels)) next

  for (p in panels) {
    if (p$i > length(plots)) {
      skip(env_name, "/", p$name,
              " -- plot list has only ", length(plots), " entries")
      next
    }
    g <- plots[[p$i]]

    if (p$outcome != "km") {
      face <- if (p$diagonal) "bold" else "plain"
      g <- g + ggplot2::ylab(Y_LABEL[[p$outcome]]) +
        ggplot2::theme(axis.title.y = ggplot2::element_text(face = face))
      if (!is.null(Y_LIMITS[[p$outcome]])) {
        g <- g + ggplot2::coord_cartesian(ylim = Y_LIMITS[[p$outcome]])
      }
    }

    # S9 (itp_geno_*) panels KEEP their class legend -- the deck had no key for
    # those lines. Every other define-class panel is stripped for manual layout,
    # where one shared legend is placed per group instead.
    keep_legend <- startsWith(env_name, "itp_geno")
    g_out <- if (keep_legend) g else g + ggplot2::theme(legend.position = "none")
    save_png(g_out, out_dir, p$name)

    # keep the legend'd ITP-genotype plot for the S9 composite assembly below
    if (keep_legend)
      assign(paste0(env_name, "__", p$name), normalise_labels(g),
             envir = itp_geno_ggplots)
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

# ---- S9 composite panels: controls (A) and treated (B) ----------------------
# The published S9 collapses the twelve ITP-genotype subplots into TWO lettered
# panels: A = controls, B = treated. Each is a 3-row x 2-col grid --
#   (Unstratified / Females / Males) x (BW trajectory / KM survival) --
# with each cohort row titled and ONE shared class legend on the right. Assemble
# them here from the per-env ggplots collected in the loop above, so the deck's
# S9A/S9B match the figure rather than showing eleven separate letters. The six
# per-env PNGs are still written above, in case the individual pieces are wanted
# for manual layout.
assemble_itp_composite <- function(envs, cohorts, group, file) {
  gp <- function(en, nm)
    get0(paste0(en, "__", nm), envir = itp_geno_ggplots, inherits = FALSE)
  missing <- vapply(envs, function(en)
    is.null(gp(en, "bw_by_bw")) || is.null(gp(en, "km_bw")), logical(1))
  if (any(missing)) {
    skip("S9 composite '", group, "' -- missing subplot(s) for: ",
         paste(envs[missing], collapse = ", "))
    return(invisible(NULL))
  }
  # one shared legend for the whole panel; strip the per-subplot legends
  shared_legend <- cowplot::get_legend(
    gp(envs[[1]], "bw_by_bw") +
      ggplot2::theme(legend.position = "right",
                     legend.box.margin = ggplot2::margin(0, 0, 0, 6)))
  strip <- ggplot2::theme(legend.position = "none")
  rows <- lapply(seq_along(envs), function(k) {
    body <- cowplot::plot_grid(
      gp(envs[[k]], "bw_by_bw") + strip,
      gp(envs[[k]], "km_bw")    + strip,
      nrow = 1)
    title <- cowplot::ggdraw() +
      cowplot::draw_label(paste0(group, " (", cohorts[[k]], ")"),
                          fontface = "bold", size = 13, x = 0.02, hjust = 0)
    cowplot::plot_grid(title, body, ncol = 1, rel_heights = c(0.10, 1))
  })
  grid <- cowplot::plot_grid(plotlist = rows, ncol = 1)
  full <- cowplot::plot_grid(grid, shared_legend, nrow = 1, rel_widths = c(1, 0.15))
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  ggplot2::ggsave(file, full, width = 9, height = 11, dpi = 300, bg = "white")
  message("wrote S9 composite: ", file)
}

assemble_itp_composite(
  c("itp_geno_env", "itp_geno_f_env", "itp_geno_m_env"),
  c("Unstratified", "Females", "Males"), "Controls",
  file.path("output", "itp_geno_composite", "controls.png"))
assemble_itp_composite(
  c("itp_geno_tx_env", "itp_geno_tx_f_env", "itp_geno_tx_m_env"),
  # The *_tx_* configs model controls AND NDE-treated mice together (n = 5118 =
  # 2395 control + 2723 treated), so this block is NOT treated-only -- label it
  # to match the S9 legend ("combined control and NDE-treated mice").
  c("Unstratified", "Females", "Males"), "Controls + Treated",
  file.path("output", "itp_geno_composite", "treated.png"))

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
    skip(env_name, " validation -- not found: ", path)
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
        ggplot2::ylab("Linear predictor") + ggplot2::xlab("Upper bound age (weeks)")
    } else {
      g + ggplot2::coord_cartesian(ylim = c(0.4, 0.8)) +
        ggplot2::geom_hline(yintercept = 0.5, linetype = "dotted", colour = "red") +
        ggplot2::ylab("Concordance") + ggplot2::xlab("Upper bound age (weeks)")
    }
    save_png(g + ggplot2::theme(legend.position = "none"), out_dir, p$name)
  }
}

# =============================================================================
# TABLES
#
# The HR tables live inside each stage-07 workspace as data (save_figtabs),
# not as files, so they are assembled and rendered here -- the same place as
# every other panel, so that ALL appearance decisions live in one stage.
#
# WHERE TO CHANGE WHAT
#   appearance (fonts, borders, spacing, number formatting)  -> the flextable
#     pipeline in each block below
#   which columns appear, if derivable from what is already
#     in save_figtabs                                        -> the cbind/rbind
#     lines in each block below
#   a column that does not exist at all                      -> stage 07. Note
#     07_display_figures.Rmd:453 keeps ONLY the "final" column of
#     kap_plot_hrs$hr_table and discards the rest, so anything else (p-values,
#     separate CI bounds, n) has to be kept there first, which costs a re-run
#     of stage 07 for the affected configs.
#
# Each table writes to its own file. They previously all wrote to
# "mortality_panel_hr.png" and were read back immediately, so only the last one
# survived on disk and correctness depended on that adjacency.
# =============================================================================

WORKSPACE_ENVS <- list(
  all_env      = "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/workspace.RDATA",
  fb6_env      = "../07_display_figures/output/slam_c1-c10_age_fb6_bwfatgluc/workspace.RDATA",
  fhet3_env    = "../07_display_figures/output/slam_c1-c10_age_fhet3_bwfatgluc/workspace.RDATA",
  mb6_env      = "../07_display_figures/output/slam_c1-c10_age_mb6_bwfatgluc/workspace.RDATA",
  mhet3_env    = "../07_display_figures/output/slam_c1-c10_age_mhet3_bwfatgluc/workspace.RDATA",
  itp_env      = "../07_display_figures/output/itp_c10c11c13c16_age_controls_bw/workspace.RDATA",
  held_out_env = "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/workspace.RDATA",
  # adiposity variant (bwadipositygluc): its workspace carries save_figtabs/t1_df
  # for the demographics_adiposity (S1G) and hr_adiposity (S1H) tables. Without it
  # here it is never assigned to .GlobalEnv, so those two blocks cannot see it.
  adiposity_env = "../07_display_figures/output/slam_c1-c10_age_all_bwadipositygluc/workspace.RDATA"
)

# Load whatever workspaces exist. Each table below is wrapped in tbl(), so a
# config that has not run yet skips only the tables that need it -- the rest
# still build. This is what makes 99 runnable partway through a pipeline run.
for (env_name in names(WORKSPACE_ENVS)) {
  path <- WORKSPACE_ENVS[[env_name]]
  if (!file.exists(path)) {
    skip("workspace (not run yet): ", env_name)
    next
  }
  e <- new.env(); load(path, envir = e); assign(env_name, e, envir = .GlobalEnv)
}

# Run one table block, reporting rather than aborting if its inputs are absent.
tbl <- function(label, expr) {
  tryCatch({ force(expr); message("  table OK: ", label) },
           error = function(e) skip("table ", label, " -- ", conditionMessage(e)))
  invisible(NULL)
}

if (TRUE) {
  library(flextable)
  library(magrittr)
  max_width <- 7

  # ---- house style for FIGURE tables ----------------------------------------
  # One look for every table that sits inside a figure (the hr_* panels):
  # bold header on grey, plain body text, body rows alternating grey/white.
  #
  # NOT applied to Table 1, Table 2 or S1G. Those come from demographics_table()
  # and follow the Word manuscript's own scheme -- accent-red title, spanning
  # headers, block shading that groups rows by metabolic variable. Striping
  # those would fight the grouping the shading exists to show.
  #
  # The header grey is a step darker than the stripe so the header still reads
  # as a header when body row 1 is also grey. Both are the Word defaults; change
  # them here and every figure table follows.
  TBL_HEADER_GREY <- "#D9D9D9"
  TBL_STRIPE_GREY <- "#F2F2F2"

  fig_table_theme <- function(ft) {
    ft %>%
      theme_zebra(odd_header = TBL_HEADER_GREY, even_header = TBL_HEADER_GREY,
                  odd_body   = TBL_STRIPE_GREY, even_body   = "transparent") %>%
      bold(part = "header") %>%
      bold(part = "body", bold = FALSE) %>%
      align(align = "center", part = "all") %>%
      valign(valign = "center", part = "all") %>%
      padding(padding.top = 4, padding.bottom = 4, part = "all")
  }
  if (!dir.exists("output/tables")) dir.create("output/tables", recursive = TRUE)


  tbl("demographics", {
    # ---- demographics tables (Table 1, Table 2) --------------------------
    # Class demographics after classing: n, sex split, strain split, median
    # survival, one row per class plus a total. `oc_name` is the outcome the
    # classes came from (Body Weight / Body Fat / Glucose) and is dropped --
    # the published tables are body-weight classes only.
  })
  tbl("demographics", {
    # ---- demographics tables (Table 1, Table 2, S1G) ---------------------
    # Matched to the Word versions: spanning Sex / Genetic background headers,
    # descriptive class names, en-dash for missing, scientific p-values.
    DEMOG_ACCENT <- "#A6272B"   # the dark red used for titles and header groups
    DEMOG_BAND   <- "#F2F2F2"   # alternating block shading

    # The pipeline renames classes by peak, so these mappings are stable for the
    # 3-class runs (see the note in 96_similarity_slam_itp/similarity_table.R).
    # A class with no entry here is left as-is and warned about.
    CLASS_DESCRIPTOR <- c(
      "Class 1" = "Early-peak", "Class 2" = "Stable",  "Class 3" = "Late-peak",
      "Class 4" = "Early-peak", "Class 5" = "Stable",  "Class 6" = "Late-peak",
      "Class 7" = "Decline",    "Class 8" = "Stable",
      "Class 9" = "Low",        "Class 10" = "High"
    )

    # Adiposity classes are renumbered 4/5 -> 9/10 for display, CONTINUING the
    # manuscript's sequential class numbering across metabolic indices:
    #   Body Weight 1-3 | Fat Mass 4-6 | FBG 7-8 | Adiposity 9-10.
    # The adiposity config (bwadipositygluc) has no Fat Mass, so its LCM numbers
    # the two adiposity classes LOCALLY as 4/5. Left as-is they would (a) collide
    # with Fat Mass's 4/5 and (b) inherit Fat Mass's descriptors (Early-peak /
    # Stable) rather than adiposity's (Low / High). Remapping before display fixes
    # both -- CLASS_DESCRIPTOR above already carries the correct 9=Low / 10=High.
    # PURE DISPLAY RELABEL: class assignments, HRs and the reference derivation are
    # unchanged -- the reference is derived on the raw 4/5 labels, THEN relabeled.
    ADIPOSITY_CLASS_RELABEL <- c("Class 4" = "Class 9", "Class 5" = "Class 10")
    relabel_classes <- function(x, map) {
      x <- as.character(x); hit <- x %in% names(map); x[hit] <- map[x[hit]]; x
    }

    # "Body Weight" / "Fat Mass" / "FBG" as printed in the Metabolic Variable
    # column (07 supplies "Body Weight" / "Body Fat" / "Glucose").
    METVAR_LABEL <- c("Body Weight" = "Body Weight", "Body Fat" = "Fat Mass",
                      "Glucose" = "FBG", "Adiposity" = "Adiposity")

    # p_digits: mantissa precision below 0.001. Tables 1/2 are Word tables that
    # keep footnote c ("...and rounded to the nearest integer"), so they use 0.
    # S1G is composited into a supplementary figure where footnotes are dropped,
    # so it uses 1 -- matching S3C and S9C, whose legends state only the 0.001
    # threshold and make no claim about rounding.
    fmt_demog_p <- function(x, p_digits = 0) {
      p <- suppressWarnings(as.numeric(x))
      ifelse(is.na(p), "-",
        ifelse(p < 0.001,
               sub("e([+-])0", "e\\1", formatC(p, format = "e", digits = p_digits)),
               formatC(p, format = "f", digits = 4)))
    }

    # median_header: Tables 1 and 2 are Word tables that keep their footnotes, so
    # they use the plain label and put the unit in footnote b. S1G is composited
    # into a supplementary figure where the footnotes are dropped, so the unit has
    # to live in the header; the CI notation is stated in the S1 legend instead.
    # A comma-offset unit (not "(weeks)") avoids a header parenthetical competing
    # with the interval parentheses in the cells below.
    # Note this string is also the data-frame column name, hence the footnote
    # calls reference `median_header` rather than a literal.
    demographics_table <- function(env, file, lcm = NULL, title = NULL,
                                   strain = TRUE, class_relabel = NULL,
                                   median_header = "Median Survival",
                                   p_digits = 0) {
      self_describing <- !identical(median_header, "Median Survival")
      t1 <- env$save_figtabs$t1_df
      if (is.null(t1)) { warning("demographics: t1_df missing -- skipped"); return(invisible(NULL)) }
      tb <- t1
      if (!is.null(lcm)) {
        tb <- tb[as.character(tb$oc_name) == lcm, , drop = FALSE]
        if (!nrow(tb)) {
          warning("demographics: no rows for LCM '", lcm, "' -- have: ",
                  paste(unique(t1$oc_name), collapse = ", ")); return(invisible(NULL))
        }
      }

      # descriptive class names: "Class 2" -> "Class 2 (Stable)"
      rn   <- as.character(tb$row_names)
      # relabel BEFORE the descriptor lookup so remapped classes pick up the right
      # descriptor (e.g. adiposity 4/5 -> 9/10 -> Low/High, not Early-peak/Stable)
      if (!is.null(class_relabel)) rn <- relabel_classes(rn, class_relabel)
      desc <- CLASS_DESCRIPTOR[rn]
      unk  <- grepl("^Class ", rn) & is.na(desc)
      if (any(unk)) warning("demographics: no descriptor for ",
                            paste(unique(rn[unk]), collapse = ", "))
      rn <- ifelse(is.na(desc), rn, paste0(rn, " (", desc, ")"))
      rn <- sub("^total$", "Total", rn, ignore.case = TRUE)
      rn <- sub("^pval$", "p-value", rn)

      is_p <- grepl("^p-value$", rn)
      out  <- data.frame(`Class or Variable` = rn, check.names = FALSE,
                         stringsAsFactors = FALSE)
      if (is.null(lcm)) {
        out <- cbind(`Metabolic Variable` =
                       unname(METVAR_LABEL[as.character(tb$oc_name)]), out)
      }

      cols <- c(n = "n (%)", sex_F = "Female", sex_M = "Male")
      if (strain) cols <- c(cols, strain_B6 = "B6", strain_HET3 = "HET3")
      cols <- c(cols, median_surv = median_header)
      for (nm in names(cols)) {
        if (!nm %in% names(tb)) next
        v <- as.character(tb[[nm]])
        v[is_p] <- fmt_demog_p(v[is_p], p_digits)  # p-value row -> scientific
        # Plain hyphen, not an en dash: the pipeline can run under a C locale,
        # where a multi-byte dash is read as raw bytes and breaks the flextable
        # renderer. Visually equivalent at table scale.
        v[is.na(v) | v == "NA"] <- "-"
        out[[cols[[nm]]]] <- v
      }

      ft <- flextable(out)
      if (strain && ncol(out) >= 7) {
        # spanning "Sex" / "Genetic background" over their pairs
        lead <- ncol(out) - 5
        ft <- add_header_row(ft,
          values = c(rep("", lead), "Sex", "Genetic background", ""),
          colwidths = c(rep(1, lead), 2, 2, 1))
        ft <- color(ft, i = 1, part = "header", color = DEMOG_ACCENT)
      }
      ft <- theme_booktabs(ft)
      ft <- bold(ft, part = "header")
      ft <- italic(ft, i = which(is_p), j = 1, part = "body")
      if (!is.null(title)) {
        ft <- add_header_lines(ft, values = title)
        ft <- color(ft, i = 1, part = "header", color = DEMOG_ACCENT)
        ft <- bold(ft, i = 1, part = "header")
      }
      # shade alternate metabolic-variable blocks
      if (is.null(lcm) && "Metabolic Variable" %in% names(out)) {
        grp <- as.integer(factor(out$`Metabolic Variable`,
                                 levels = unique(out$`Metabolic Variable`)))
        shade <- which(grp %% 2 == 1)
        if (length(shade)) ft <- bg(ft, i = shade, bg = DEMOG_BAND, part = "body")
        ft <- merge_v(ft, j = "Metabolic Variable")
      }
      ft <- add_footer_lines(ft,
        values = "Chi-squared tests were performed to compute the displayed p-values.")
      # lettered markers, as in the Word tables. The column-name row is the last
      # header row, whichever spanning/title rows were added above it.
      hrow <- nrow(ft$header$dataset)
      if (!self_describing) {
      ft <- flextable::footnote(ft, i = hrow, j = median_header, part = "header",
        # Wording tracks the Word tables, which abbreviate: CI is defined in the
        # Results ("Confidence intervals (CIs) for the macro-F1 scores...").
        # Keep the verb -- all three instances in the manuscript and supplement
        # read "95% CIs are indicated ...", so this string must match verbatim.
        value = as_paragraph("95% CIs are indicated in parentheses following values."),
        ref_symbols = "a")
      ft <- flextable::footnote(ft, i = hrow, j = median_header, part = "header",
        value = as_paragraph("In weeks."), ref_symbols = "b")
      }
      if (any(is_p)) {
        ft <- flextable::footnote(ft, i = which(is_p)[1], j = "Class or Variable",
          part = "body",
          value = as_paragraph(
            "p-values < 0.001 are written in scientific notation and rounded to the nearest integer."),
          ref_symbols = if (self_describing) "a" else "c")
      }
      ft <- italic(ft, part = "footer"); ft <- fontsize(ft, size = 8, part = "footer")
      # Arial renders the en dash; the default substitutes a glyph for it
      ft <- font(ft, fontname = "Arial", part = "all")
      ft <- autofit(ft) %>% set_table_properties(layout = "autofit") %>%
        fit_to_width(max_width = max_width, inc = .25, max_iter = 100)
      # res = 600, NOT zoom = 10. flextable 0.9.9 removed the `zoom` argument
    # from save_as_image(); it was being swallowed by `...` and every table
    # here silently rendered at the default res = 200 (~600-960 px), which is
    # why 1N/2I/5D/5I/S3C/S4I/S4R were the lowest-resolution panels in the deck.
    invisible(save_as_image(ft, file, res = 600))
    }

    demographics_table(all_env, "output/tables/demographics_slam.png",
                       title = "Table 1. Metabolic Class Demographics.")
    # ITP is all HET3, so no genetic-background columns.
    # "Full", not "Complete": the manuscript reserves *complete* for the
    # 1,315-mouse SLAM set (Methods L581), so reusing it for the 2,240-mouse ITP
    # data would collide with that vocabulary.
    # "Control": these 2,240 are the ITP control arm only, not all ITP mice. The
    # trajectory input is 00a_itp2/output/itp_control_train.csv, whose `tx`
    # column is "control" for all 7,889 rows; the 2005 tx+control cohort
    # (itp_tx_control_test.csv) is a disjoint id set and feeds 5E-5K instead.
    demographics_table(itp_env, "output/tables/demographics_itp.png",
                       title = paste("Table 2. Body Weight Class Demographics of",
                                     "the Full ITP Control Dataset."),
                       strain = FALSE)
    # S1G -- adiposity classes only (9 and 10)
    demographics_table(adiposity_env, "output/tables/demographics_adiposity.png",
                       lcm = "Adiposity", class_relabel = ADIPOSITY_CLASS_RELABEL,
                       median_header = "Median Survival, weeks", p_digits = 1)
  })
  tbl("partial_correlation", {
    # ---- partial_correlation (S2C) ---------------------------------------
    # Rebuilt here rather than used as 91's own PNG. 91 draws it with
    # gridExtra::tableGrob, which cannot take the flextable house style, but it
    # also writes the same data to CSV -- and it writes that CSV AFTER renaming
    # the columns, so the headers are already final:
    #   Variable 1 (Class) | Variable 2 (Class) | Corr. | P value
    # Reading the CSV means no upstream change and no risk of the two drifting:
    # this table and 91's are the same numbers by construction.
    #
    # check.names = FALSE keeps the spaces and parentheses in the headers.
    pc_path <- "../91_partial_correlation/output/partial_correlation_results.csv"
    if (!file.exists(pc_path))
      stop("partial correlation CSV not found: ", pc_path, " (91 has not run)")

    pc <- utils::read.csv(pc_path, check.names = FALSE, stringsAsFactors = FALSE)

    # 91 already sorted by descending |correlation|; preserve that order.
    pc[["Corr."]]   <- formatC(pc[["Corr."]], format = "f", digits = 2)
    pc[["P value"]] <- formatC(pc[["P value"]], format = "e", digits = 1)

    # Display-layer only -- 91's CSV is left untouched so its own guard still
    # matches on the original strings. The manuscript hyphenates class nicknames
    # throughout ("early-peak-BW"), so the table should too.
    PC_LABEL_FIX <- c(
      "Early-peak FM (4)" = "Early-peak-FM (4)",
      "Early-peak BW (1)" = "Early-peak-BW (1)",
      "Decline FBG (7)"   = "Decline-FBG (7)"
    )
    for (.j in c("Variable 1 (Class)", "Variable 2 (Class)")) {
      .hit <- pc[[.j]] %in% names(PC_LABEL_FIX)
      pc[[.j]][.hit] <- unname(PC_LABEL_FIX[pc[[.j]][.hit]])
    }
    # "p" is a statistical symbol and stays lowercase; hyphenated per the
    # manuscript convention.
    names(pc)[names(pc) == "P value"] <- "p-value"

    pc_ft <- flextable(pc) %>%
      fig_table_theme() %>%
      align(j = c("Variable 1 (Class)", "Variable 2 (Class)"),
            align = "left", part = "all") %>%
      autofit() %>%
      set_table_properties(layout = "autofit") %>%
      fit_to_width(max_width = max_width, inc = .25, max_iter = 100)

    invisible(save_as_image(pc_ft, "output/tables/partial_correlation.png", res = 600))
  })
  # reference_class: derive the reference (dropped) class for an outcome from
  # t1_df. Defined here, ABOVE the table blocks, because tbl() evaluates its block
  # eagerly -- a definition placed after the blocks is not yet visible when they run.
  # (For the full rationale of showing the reference row, see the HR table rules
  # comment further down.)
  .cls_key <- function(x) gsub("[^A-Za-z0-9]", "", as.character(x))

  reference_class <- function(env, outcome, present) {
    t1 <- env$save_figtabs$t1_df
    if (is.null(t1) || !all(c("oc_name", "row_names") %in% names(t1))) return(NULL)
    rows <- t1[trimws(as.character(t1$oc_name)) == outcome, , drop = FALSE]
    cls  <- trimws(as.character(rows$row_names))
    keep <- grepl("^Class", cls)                      # drop the 'total'/'pval' rows
    cls  <- cls[keep]
    if (!length(cls)) return(NULL)
    miss <- setdiff(.cls_key(cls), .cls_key(present))
    if (length(miss) != 1) return(NULL)               # ambiguous -- say nothing
    cls[match(miss, .cls_key(cls))]
  }

  # Order rows by the HR table rules (grouping columns before "Class", reference
  # first, then class ascending) and write the PNG. Defined here, above the table
  # blocks, because tbl() runs its block eagerly. `df` carries a logical .ref
  # column marking the reference row; it drives the ordering and is then dropped.
  write_hr_table <- function(df, file) {
    if (!".ref" %in% names(df)) df$.ref <- FALSE
    if ("Class" %in% names(df)) {
      grp_cols <- names(df)[seq_len(match("Class", names(df)) - 1L)]
      grp <- if (length(grp_cols))
               do.call(paste, c(df[grp_cols], sep = "\r")) else rep("", nrow(df))
      cls_no <- suppressWarnings(as.numeric(gsub("[^0-9]", "", df$Class)))
      df <- df[order(match(grp, unique(grp)), !df$.ref, cls_no), , drop = FALSE]
      rownames(df) <- NULL
    }
    df$.ref <- NULL
    ft <- flextable(df) %>%
      fig_table_theme() %>%
      autofit() %>%
      set_table_properties(layout = "autofit") %>%
      fit_to_width(max_width = max_width, inc = .25, max_iter = 100)
    invisible(save_as_image(ft, file, res = 600))
  }

  tbl("hr_adiposity", {
    # ---- hr_adiposity (S1H) ----------------------------------------------
    # Outcome | Class | HR (CI) Model 1 | Model 2 | Model 3, adiposity only.
    # Model 1 is unadjusted ("~ Class"); 2 and 3 are the adjusted specifications
    # in the config's individual_cox list.
    #
    # Built from hr_numeric (long: one row per Outcome x Class x Model) and
    # pivoted to one column per model, so the stars come from STAR_RULES rather
    # than SLAM's pre-formatted strings. Falls back to hr_table's strings, whose
    # ** is p<0.005, if 07 has not produced hr_numeric for this config.
    .adip_hr <- function(env, outcome = "Adiposity") {
      # via hr_numeric_rows() per model so the DISPLAY class labels ("Class 10")
      # are used, not hr_numeric's raw model terms ("Class10").
      hn <- env$save_figtabs$hr_numeric
      if (!is.null(hn) && nrow(hn)) {
        hn <- do.call(rbind, lapply(sort(unique(as.character(hn$Model))),
                                    function(mo) hr_numeric_rows(env, mo)))
        hn <- hn[as.character(hn$Outcome) == outcome, , drop = FALSE]
        if (nrow(hn)) {
          models <- sort(unique(as.character(hn$Model)))
          classes <- unique(as.character(hn$Class))
          out <- data.frame(Outcome = outcome, Class = classes,
                            check.names = FALSE, stringsAsFactors = FALSE)
          for (mo in models) {
            r <- hn[hn$Model == mo, , drop = FALSE]
            out[[sub("^HR ", "HR (CI) ", mo)]] <-
              mapply(format_hr_bare, r$value, r$lower, r$upper, r$pval)[
                match(classes, as.character(r$Class))]
          }
          return(out)
        }
      }
      warning("hr_adiposity: hr_numeric absent for '", outcome,
              "' -- using SLAM's strings, whose ** is p<0.005, not the legend's 0.01")
      ht <- env$save_figtabs$hr_table
      ht <- ht[as.character(ht$Outcome) == outcome, , drop = FALSE]
      names(ht) <- sub("^HR Model", "HR (CI) Model", names(ht))
      ht
    }

    if (exists("adiposity_env")) {
      hr_table <- .adip_hr(adiposity_env)
      if (!is.null(hr_table) && nrow(hr_table)) {
        hr_table$.ref <- FALSE
        oc  <- unique(as.character(hr_table$Outcome))
        ref <- if (length(oc) == 1)
                 reference_class(adiposity_env, oc, hr_table$Class) else NULL
        if (!is.null(ref)) {
          r <- hr_table[1, , drop = FALSE]
          r$Class <- ref
          # every model column reads Reference in the full table
          for (cc in grep("^HR", names(r), value = TRUE)) r[[cc]] <- "Reference"
          r$.ref <- TRUE
          hr_table <- rbind(r, hr_table)
          rownames(hr_table) <- NULL
        }
        # relabel AFTER the reference row is added (reference_class ran on the raw
        # 4/5 labels above): adiposity 4/5 -> 9/10 for the sequential class scheme.
        hr_table$Class <- relabel_classes(hr_table$Class, ADIPOSITY_CLASS_RELABEL)
        write_hr_table(hr_table, "output/tables/hr_adiposity.png")
      }
    }
  })
  tbl("hr_all", {
    # ---- hr_all ----------------------------------------------------------
    # Figure 1N. Three columns: LCM | Class | Hazard Ratio (CI).
    #
    # Source is save_figtabs$hr_table rather than mortality_panel_hr: it holds
    # the same numbers (its "HR Model 1" column is identical to
    # mortality_panel_hr's "final") but already carries the Outcome label, which
    # is what the LCM column needs.
    #
    # "HR Model 1" is the UNADJUSTED model -- individual_cox[[1]] in the config
    # is "~ Class", no covariates. Models 2 and 3 are the adjusted ones.
    #
    # The significance stars arrive already baked into the string by the
    # in-house package that builds kap_plot$hr; nothing here sets them. They
    # behave like p<0.05 / <0.01 / <0.001 (verified against 31 of 32 rows).
    #
    # LCM_LABEL maps stage-07 outcome names onto the abbreviations used in the
    # 1A schematic. Extend it if an outcome is added.
    LCM_LABEL <- c("Body Weight" = "BW", "Body Fat" = "FM", "Glucose" = "FBG")

    # Prefer hr_numeric: real p-values, so STAR_RULES above decide the asterisks.
    # Fall back to hr_table's pre-formatted strings (SLAM's 0.005 convention) when
    # 07 did not produce hr_numeric -- e.g. workspaces from an older run.
    hn <- hr_numeric_rows(all_env, "HR Model 1")
    if (!is.null(hn)) {
      hr_table <- data.frame(
        LCM                 = unname(LCM_LABEL[as.character(hn$Outcome)]),
        Class               = as.character(hn$Class),
        `Hazard Ratio (CI)` = mapply(format_hr_bare, hn$value, hn$lower, hn$upper, hn$pval),
        check.names = FALSE, stringsAsFactors = FALSE
      )
    } else {
      warning("hr_all: hr_numeric absent -- falling back to SLAM's pre-formatted ",
              "strings, whose stars use p<0.005 for ** and therefore DO NOT match ",
              "the manuscript legend (p<0.01). Re-run stage 07 so hr_numeric exists.")
      hr_src   <- all_env$save_figtabs$hr_table
      hr_table <- data.frame(
        LCM                 = unname(LCM_LABEL[as.character(hr_src$Outcome)]),
        Class               = as.character(hr_src$Class),
        `Hazard Ratio (CI)` = as.character(hr_src[["HR Model 1"]]),
        check.names = FALSE, stringsAsFactors = FALSE
      )
    }
    if (anyNA(hr_table$LCM)) {
      warning("hr_all: an outcome has no LCM_LABEL entry -- LCM column contains NA")
    }

    # One reference per outcome: for the pooled cohort Body Weight -> Class 1,
    # Body Fat -> Class 4, Glucose -> Class 7. Derived from t1_df, not hardcoded.
    hr_table$.ref <- FALSE
    hr_table <- do.call(rbind, lapply(unique(hr_table$LCM), function(l) {
      blk <- hr_table[hr_table$LCM == l, , drop = FALSE]
      oc  <- names(LCM_LABEL)[match(l, unname(LCM_LABEL))]
      ref <- reference_class(all_env, oc, blk$Class)
      if (is.null(ref)) return(blk)
      r <- blk[1, , drop = FALSE]
      r$Class <- ref; r[["Hazard Ratio (CI)"]] <- "Reference"; r$.ref <- TRUE
      rbind(r, blk)
    }))
    rownames(hr_table) <- NULL

    write_hr_table(hr_table, "output/tables/hr_all.png")
  })
  # ---- HR table rules --------------------------------------------------------
  # TWO conventions, applied to every class-based HR table in the deck.
  #
  # 1. THE REFERENCE CLASS IS ALWAYS SHOWN. A Cox model drops it, so the raw
  #    output lists only the non-reference classes and an HR like "0.34" has no
  #    stated referent. The forest plots (4B, S6B, S7B) already print a
  #    "reference" row, so omitting it here contradicted them. Stating it in the
  #    caption instead does not scale: the sex/strain tables have a separate
  #    reference per cohort, and those references are not the same class.
  #
  # 2. ROWS ARE ORDERED BY GROUP, THEN REFERENCE FIRST, THEN CLASS ASCENDING --
  #    never by effect size. Class number is semantic here (1/4/7 are the
  #    high-risk classes) and drives the KM legends, trajectory colours, the S2A
  #    heatmap and overlap.R's high-risk definitions, so a reader must be able to
  #    map a table row onto a curve. Sorting by HR would order the classes
  #    differently in each cohort of S3I. It would also strand the reference,
  #    which is 1.00 by definition. Effect-size sorting is right only where rows
  #    have no intrinsic order -- which is why S2C IS sorted by |r|.
  #
  # Excluded: hr_treatment (5I), whose rows are rapamycin-vs-control within each
  # class -- its reference is the control arm, not a class.
  #
  # The reference is DERIVED, never assumed: t1_df lists every class for the
  # outcome, the model rows list every non-reference class, and the one class in
  # the first but not the second is the reference. For the pooled cohort that is
  # always the shortest-lived class (1/4/7, medians 94/100/107 weeks against
  # 114-117), but this is NOT guaranteed -- some sex/strain HRs exceed 1, which
  # means their reference is not the highest-hazard group.
  # .cls_key / reference_class are defined ABOVE the first table block (tbl() runs
  # its block eagerly, so a definition here would come too late for hr_all/hr_adiposity).

  # write_hr_table is defined ABOVE the first table block, alongside
  # reference_class, for the same reason (tbl() evaluates its block eagerly).

  # ---- sex/strain HR tables (2I, S3I, S3R) ---------------------------------
  # ONE builder for all three. Columns: LCM | Sex / Strain | Class | Hazard
  # Ratio (CI). No spanning headers anywhere, and the Class column is kept even
  # when every row carries the same class (S3R is all Class 7) so the three
  # tables share a layout.
  #
  # `outcome` selects rows inside hr_numeric, whose Outcome values are the
  # config's oc_name strings; `slot` does the same in the fallback, where
  # mortality_panel_hr is ordered bw, fat, gluc.
  #
  # Prefer hr_numeric so STAR_RULES decides the asterisks. The two sources
  # agree: hr_numeric comes from final_models$cox_models via surv_gethr,
  # mortality_panel_hr from kap_plot_hrs -- both the unadjusted "~ Class" fit,
  # verified identical (values and class ordering) across cohorts.
  #
  # A cohort contributes one row per NON-REFERENCE class, so a model that
  # converged on a single class contributes NOTHING and has to drop out rather
  # than error. That is the FBG case: both B6 cohorts are single-class, so only
  # F/HET3 and M/HET3 appear in S3R, one row each.
  SEX_STRAIN_LABEL <- c(fb6 = "F/B6", mb6 = "M/B6",
                        fhet3 = "F/HET3", mhet3 = "M/HET3")

  sexstrain_rows <- function(strata, env, slot, lcm, outcome) {
    hn <- hr_numeric_rows(env, "HR Model 1")
    if (!is.null(hn))
      hn <- hn[hn$Outcome == outcome & !is.na(hn$Class) & !is.na(hn$pval), , drop = FALSE]
    if (!is.null(hn) && nrow(hn)) {
      # hr_numeric$Class labels non-reference classes SEQUENTIALLY (Class2, Class3,
      # ...), which is only right when the true classes are 2,3,.. in that row
      # order. It is wrong for cohorts whose classes aren't (F/B6's fourth class is
      # "9"; M/HET3's are ordered 3,2), which also breaks reference_class(). The
      # true identities are in mortality_panel_hr, in the SAME row order (both are
      # the unadjusted ~Class fit), so take the labels from there.
      tb  <- env$save_figtabs$mortality_panel_hr[[slot]]
      cls <- if (!is.null(tb) && nrow(tb) == nrow(hn)) rownames(tb) else as.character(hn$Class)
      return(data.frame(
        LCM                 = lcm,
        `Sex / Strain`      = unname(SEX_STRAIN_LABEL[[strata]]),
        Class               = cls,
        `Hazard Ratio (CI)` = mapply(format_hr_bare, hn$value, hn$lower, hn$upper, hn$pval),
        check.names = FALSE, stringsAsFactors = FALSE
      ))
    }
    tb <- env$save_figtabs$mortality_panel_hr[[slot]]
    if (is.null(tb) || !nrow(tb)) return(NULL)          # single-class model
    data.frame(
      LCM                 = lcm,
      `Sex / Strain`      = unname(SEX_STRAIN_LABEL[[strata]]),
      Class               = rownames(tb),
      `Hazard Ratio (CI)` = as.character(tb[["final"]]),
      check.names = FALSE, stringsAsFactors = FALSE
    )
  }

  # Prepend this cohort's reference class, marked .ref so only the full table
  # keeps it. Each cohort has its own reference, so this happens per group
  # rather than once for the whole table.
  with_reference <- function(rows, env, outcome) {
    if (is.null(rows) || !nrow(rows)) return(rows)
    rows$.ref <- FALSE
    ref <- reference_class(env, outcome, rows$Class)
    if (is.null(ref)) return(rows)
    r <- rows[1, , drop = FALSE]
    r$Class <- ref
    r[["Hazard Ratio (CI)"]] <- "Reference"
    r$.ref <- TRUE
    rbind(r, rows)
  }

  sexstrain_table <- function(slot, lcm, outcome, file) {
    hr_table <- rbind(
      with_reference(sexstrain_rows("fb6",   fb6_env,   slot, lcm, outcome), fb6_env,   outcome),
      with_reference(sexstrain_rows("mb6",   mb6_env,   slot, lcm, outcome), mb6_env,   outcome),
      with_reference(sexstrain_rows("fhet3", fhet3_env, slot, lcm, outcome), fhet3_env, outcome),
      with_reference(sexstrain_rows("mhet3", mhet3_env, slot, lcm, outcome), mhet3_env, outcome)
    )
    if (is.null(hr_table) || !nrow(hr_table))
      stop("no HR rows for ", lcm, " -- did every cohort converge on one class?")
    rownames(hr_table) <- NULL
    write_hr_table(hr_table, file)
  }

  tbl("hr_sexstrain_bw", {
    # Figure 2I -- body weight.
    sexstrain_table(1, "BW", "Body Weight",
                    "output/tables/hr_sexstrain_bw.png")
  })
  tbl("hr_treatment", {
    # ---- hr_treatment ----------------------------------------------------
    # Rapamycin vs control, one row per predicted class, plus the pooled 1+3 row
    # at the bottom. Columns: Class | Treatment | Hazard Ratio (CI).
    #
    # 97 saves these as two separate objects, both named `hrs_table`, so they are
    # loaded into their own environments to avoid clobbering:
    #   hr_table/hr_table.RDATA                     per class (1, 2, 3)
    #   hr_table_nonresponder/...RDATA              0 = responder (class 2),
    #                                               1 = classes 1+3 pooled
    # Only the pooled row is taken from the second; the responder row duplicates
    # class 2, which is already present.
    #
    # Stars come from STAR_RULES via the pval that 97 now keeps, not from SLAM's
    # pre-formatted string (which uses p<0.005 for "**").
    .e1 <- new.env(); load("../97_treatment_response/output/hr_table/hr_table.RDATA", envir = .e1)
    .e2 <- new.env()
    .np <- "../97_treatment_response/output/hr_table_nonresponder/hr_table_nonresponder.RDATA"
    if (file.exists(.np)) load(.np, envir = .e2)

    .hr_row <- function(tb, class_label) {
      ci <- if (all(c("value", "lower", "upper", "pval") %in% colnames(tb))) {
        format_hr_bare(tb$value[1], tb$lower[1], tb$upper[1], tb$pval[1])
      } else {
        warning("hr_treatment: no pval for '", class_label,
                "' -- using SLAM's string, whose ** is p<0.005, not the legend's 0.01")
        as.character(tb$final[1])
      }
      data.frame(Class = class_label, Treatment = "Rapamycin",
                 `Hazard Ratio (CI)` = ci,
                 check.names = FALSE, stringsAsFactors = FALSE)
    }

    hr_table <- do.call(rbind, lapply(.e1$hrs_table, function(tb)
      .hr_row(tb, as.character(tb$Class[1]))))

    if (!is.null(.e2$hrs_table)) {
      .pooled <- Filter(function(tb) as.character(tb$Nonresponder[1]) == "1", .e2$hrs_table)
      if (length(.pooled)) {
        hr_table <- rbind(hr_table, .hr_row(.pooled[[1]], "1+3"))
      }
    } else {
      warning("hr_treatment: pooled 1+3 table not found -- table will have 3 rows")
    }
    rownames(hr_table) <- NULL

    hr_table <- hr_table %>%
      flextable() %>%
      fig_table_theme() %>%
      autofit() %>%
      set_table_properties(layout = "autofit") %>%
      fit_to_width(max_width = max_width, inc = .25, max_iter = 100)

    invisible(save_as_image(hr_table, "output/tables/hr_treatment.png", res = 600))
  })
  tbl("hr_itp", {
    # ---- hr_itp ----------------------------------------------------------
    # Figure 5D. Two columns: Class | Hazard Ratio (CI).
    # The ITP control run models body weight only, so there is a single outcome
    # and no LCM column is needed. Prefers hr_numeric so STAR_RULES sets the
    # asterisks; falls back to SLAM's pre-formatted strings if 07 has not
    # produced it for this config yet.
    hn <- hr_numeric_rows(itp_env, "HR Model 1")
    if (!is.null(hn)) {
      hr_table <- data.frame(
        Class               = as.character(hn$Class),
        `Hazard Ratio (CI)` = mapply(format_hr_bare, hn$value, hn$lower, hn$upper, hn$pval),
        check.names = FALSE, stringsAsFactors = FALSE
      )
    } else {
      warning("hr_itp: hr_numeric absent -- falling back to SLAM's strings, whose ",
              "stars use p<0.005 for ** and do NOT match the legend (p<0.01).")
      tb <- itp_env$save_figtabs$mortality_panel_hr[[1]]
      hr_table <- data.frame(
        Class               = rownames(tb),
        `Hazard Ratio (CI)` = as.character(tb[["final"]]),
        check.names = FALSE, stringsAsFactors = FALSE
      )
    }

    # Body weight only, so a single reference class.
    hr_table$.ref <- FALSE
    ref <- reference_class(itp_env, "Body Weight", hr_table$Class)
    if (!is.null(ref)) {
      r <- hr_table[1, , drop = FALSE]
      r$Class <- ref; r[["Hazard Ratio (CI)"]] <- "Reference"; r$.ref <- TRUE
      hr_table <- rbind(r, hr_table)
      rownames(hr_table) <- NULL
    }

    write_hr_table(hr_table, "output/tables/hr_itp.png")
  })
  tbl("hr_sexstrain_fat", {
    # Figure S3I -- fat mass.
    sexstrain_table(2, "FM", "Body Fat",
                    "output/tables/hr_sexstrain_fat.png")
  })
  tbl("hr_sexstrain_gluc", {
    # Figure S3R -- fasting blood glucose. Only the HET3 cohorts contribute.
    sexstrain_table(3, "FBG", "Glucose",
                    "output/tables/hr_sexstrain_gluc.png")
  })
  tbl("hr_km_external", {
    # ---- hr_km_external --------------------------------------------------
    hr_table <- held_out_env$save_figtabs$km_hr_combine_validation_panels_hr
    hr_table <- lapply(hr_table, function(table) {
      table <- cbind(Tertile = seq_len(nrow(table)) + 1, table)
      table <- cbind(explicit = rownames(table), table)
      table$column <- rep(colnames(table)[3], nrow(table))
      colnames(table)[3] <- "HR"
      rownames(table) <- NULL
      table
    })
    hr_table <- cbind(explicit = rownames(hr_table), hr_table)
    hr_table <- hr_table[1:10]
    hr_table <- do.call(rbind, hr_table)
    hr_table <- flextable(hr_table) %>%
      fig_table_theme() %>%
      autofit() %>%
      set_table_properties(layout = "autofit") %>%
      fit_to_width(max_width = max_width, inc = .25, max_iter = 100)

    invisible(save_as_image(hr_table, "output/tables/hr_km_external.png", res = 600))
  })

}

message("99_pub_ready_figs: done")


# =============================================================================
# VITA / SOMA LOCUS HEATMAPS   (5L filtered, S9D unfiltered)
#
# INPUT: 98_itp_genotype/output/census_mapping.txt (trajectory.R). Cells are -log10(p)
# from a likelihood-ratio test, NOT p-values.
#
# COLOUR uses LOD breaks; 3.84 is the Bonferroni threshold. STARS follow the
# manuscript's manual annotation -- a per-LOCUS Bonferroni-LEVEL scheme (* at
# alpha 0.05 / -log10 3.84, ** at alpha 0.01 / -log10 4.54; see locus_stars),
# NOT the per-cell p<0.05/0.01/0.001 used on the other figures. Only cells that
# clear the 3.84 colour cut are marked, so colour and stars agree here.
#
#   5L   filtered   loci with >=1 Bonferroni-significant cell   4 colours
#   S9D  unfiltered  all loci                                    8 colours
# =============================================================================

LOCUS_ORDER <- c(
  "Vita1a", "Vita1b", "Vita1c", "Vita1d", "Vita2a", "Vita2b", "Vita2c",
  "Vita3a", "Vita4a", "Vita4b", "Vita5a", "Vita6a", "Vita6b", "Vita9a",
  "Vita9b", "Vita9c", "Vita10a", "Vita11a", "Vita11b", "Vita11c", "Vita12a",
  "Vita13a", "Vita14a", "Vita14b", "Vita15a", "Vita15b", "Vita17a", "Vita18a",
  "VitaXa",
  "Soma1a", "Soma1b", "Soma2a", "Soma2b", "Soma2c", "Soma3a", "Soma3b",
  "Soma4a", "Soma4b", "Soma6a", "Soma6b", "Soma7a", "Soma7b", "Soma8a",
  "Soma8b", "Soma9a", "Soma10a", "Soma11a", "Soma12a", "Soma12b", "Soma13a",
  "Soma13b", "Soma14a", "Soma14b", "Soma15a", "Soma16a", "Soma17a", "Soma18a",
  "Soma19a", "Soma19b"
)

# Column order and headings as published: F, M, All. These are the
# TREATMENT-ADJUSTED census columns (census_tx_*), matching canonical Fig 5L /
# S9D: the plain census_f/census_m/census columns peak at 3.38 (all below the
# 3.84 Bonferroni cut), which would empty the 5L filter; the significant loci
# (Vita9b, VitaXa, Soma17a, ...) live in the treatment-adjusted mapping.
LOCUS_COLS <- c(census_tx_f = "F", census_tx_m = "M", census_tx = "All")

BONFERRONI_NEGLOG <- 3.84        # colour cut, and the 5L row filter

# sampled from the legend artwork (.A/sample_legend_hex.R)
PAL_5L    <- c("#F3F3F3", "#FDCBB4", "#F9A077", "#F57941")
BREAKS_5L <- c(0, 3.84, 5, 6, Inf)

PAL_S9D    <- c("#F3F3F3", "#91DFF7", "#5FCCEC", "#22B9E1", "#00A5D5",
                "#FDCBB4", "#F9A077", "#F57941")
BREAKS_S9D <- c(0, 3.04, 3.24, 3.44, 3.64, 3.84, 5, 6, Inf)

# 5L asterisks follow the manuscript's manual annotation: a Bonferroni-LEVEL,
# PER-LOCUS scheme (NOT the per-cell p<0.05/0.01/0.001 used on the other figures).
#   - a cell is marked only if its OWN -log10(p) clears the genome-wide cut
#     (3.84 = -log10(0.05/N), Bonferroni alpha = 0.05);
#   - the number of stars is set by the LOCUS's strongest cohort (row max):
#       *  = alpha 0.05  (row max > 3.84)
#       ** = alpha 0.01  (row max > 4.54 = 3.84 + log10(5), same N)
#     capped at ** as in the annotation (even -log10 = 7.36 stays **);
#   - that level is stamped on EVERY marked cohort of the locus, so all its
#     significant cells share one count (e.g. Vita9c F=4.96 and M=4.30 both **).
# Reproduces the manual annotation exactly (the * loci top out at 4.07, the **
# loci start at 4.94, so any cut in that gap -- 4.54 is the principled one).
STAR_A01_NEGLOG <- BONFERRONI_NEGLOG + log10(5)   # 4.54: shift alpha 0.05 -> 0.01
locus_stars <- function(mat) {
  out <- matrix("", nrow(mat), ncol(mat), dimnames = dimnames(mat))
  for (i in seq_len(nrow(mat))) {
    row  <- mat[i, ]
    rmax <- suppressWarnings(max(row, na.rm = TRUE))
    lvl  <- if (rmax > STAR_A01_NEGLOG) "**" else if (rmax > BONFERRONI_NEGLOG) "*" else ""
    out[i, ] <- ifelse(!is.na(row) & row > BONFERRONI_NEGLOG, lvl, "")
  }
  out
}

# `cells` selects what is printed in each square:
#   "stars"   -> */** by per-locus Bonferroni level         (5L)
#   "values"  -> the -log10(p) number itself               (S9D)
locus_heatmap <- function(mat, title, file, pal, breaks, gap = NULL,
                          cells = c("stars", "values")) {
  cells <- match.arg(cells)
  if (!nrow(mat)) { message("locus heatmap '", title, "': empty -- skipped"); return(invisible(NULL)) }
  # pheatmap opens its own device unless silent = TRUE; calling it inside
  # png()/dev.off() closes the wrong one and silently drops the file.
  hm <- pheatmap::pheatmap(
    mat, cluster_rows = FALSE, cluster_cols = FALSE,
    display_numbers = if (cells == "stars") {
      locus_stars(mat)
    } else {
      matrix(formatC(mat, format = "f", digits = 2), nrow = nrow(mat),
             dimnames = dimnames(mat))
    },
    number_color = "black", fontsize_number = 12,
    color = pal, breaks = breaks, border_color = "grey85",
    gaps_row = if (!is.null(gap) && gap > 0 && gap < nrow(mat)) gap else NULL,
    main = title, silent = TRUE
  )
  grDevices::png(file, width = 5, height = max(4, 0.22 * nrow(mat) + 1),
                 units = "in", res = 300, bg = "white")
  grid::grid.newpage(); grid::grid.draw(hm$gtable)
  grDevices::dev.off()
  invisible(file)
}

.map_path <- "../98_itp_genotype/output/census_mapping.txt"
if (!file.exists(.map_path)) {
  skip("locus heatmaps -- not found: ", .map_path, " (trajectory.R has not run)")
} else {
  .lod <- utils::read.table(.map_path, sep = "\t", header = TRUE,
                            check.names = FALSE, stringsAsFactors = FALSE)
  if (length(setdiff(names(LOCUS_COLS), colnames(.lod)))) {
    warning("locus heatmaps: census_mapping.txt missing expected columns -- skipped")
  } else {
    .m <- as.matrix(.lod[, names(LOCUS_COLS), drop = FALSE])
    storage.mode(.m) <- "numeric"
    colnames(.m) <- unname(LOCUS_COLS); rownames(.m) <- rownames(.lod)

    # ONE heatmap, Vita then Soma, in LOCUS_ORDER. gaps_row draws a break at the
    # Vita/Soma boundary so the two groups stay visually separable.
    keep <- intersect(LOCUS_ORDER, rownames(.m))
    full <- .m[keep, , drop = FALSE]

    out_dir <- file.path("output", "locus_heatmaps")
    if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

    # S9D -- every locus
    locus_heatmap(full, "Vita and Soma loci",
                  file.path(out_dir, "loci_all.png"),
                  PAL_S9D, BREAKS_S9D,
                  gap = sum(startsWith(rownames(full), "Vita")),
                  cells = "values")

    # 5L -- only loci with at least one Bonferroni-significant cell
    sig  <- apply(full, 1, function(r) any(r > BONFERRONI_NEGLOG, na.rm = TRUE))
    filt <- full[sig, , drop = FALSE]
    # rownames() on an all-FALSE matrix subset is NULL, not character(0), so read
    # them through a NULL-safe helper before startsWith() to avoid a crash if no
    # locus passes the cut.
    filt_rn <- rownames(filt); if (is.null(filt_rn)) filt_rn <- character(0)
    message("locus heatmap: ", nrow(filt), " of ", nrow(full),
            " loci pass Bonferroni (-log10 p > ", BONFERRONI_NEGLOG, ")  [",
            sum(startsWith(filt_rn, "Vita")), " Vita, ",
            sum(startsWith(filt_rn, "Soma")), " Soma]")
    if (nrow(filt) == 0) {
      warning("no loci pass the Bonferroni cut -- skipping loci_filtered.png (5L)")
    } else {
      locus_heatmap(filt, "Vita and Soma loci",
                    file.path(out_dir, "loci_filtered.png"),
                    PAL_5L, BREAKS_5L,
                    gap = sum(startsWith(filt_rn, "Vita")),
                    cells = "stars")
    }
  }
}
