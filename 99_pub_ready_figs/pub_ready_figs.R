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
OUTCOME_ORDER <- c("bw", "fat", "gluc")   # the order 07 builds them in

# Cross-reference order for the 3-outcome case, positions 7-12. Derived from
# stage 07's `selector` (the off-diagonal of a 3x3 outcome x class grid) and
# confirmed against the rendered panels.
CROSS_3 <- list(
  list(name = "fat_by_bw",   outcome = "fat"),
  list(name = "bw_by_fat",   outcome = "bw"),
  list(name = "bw_by_gluc",  outcome = "bw"),
  list(name = "gluc_by_bw",  outcome = "gluc"),
  list(name = "gluc_by_fat", outcome = "gluc"),
  list(name = "fat_by_gluc", outcome = "fat")
)

panels_for <- function(n_plots) {
  n <- (-1 + sqrt(1 + 4 * n_plots)) / 2
  if (abs(n - round(n)) > 1e-9) {
    warning("plot list of length ", n_plots,
            " does not fit n^2 + n -- skipping this environment")
    return(NULL)
  }
  n <- round(n)
  oc <- OUTCOME_ORDER[seq_len(n)]

  out <- list()
  for (k in seq_len(n))                      # diagonals
    out[[length(out) + 1]] <- list(i = k, name = paste0(oc[k], "_by_", oc[k]),
                                   outcome = oc[k], diagonal = TRUE)
  for (k in seq_len(n))                      # Kaplan-Meiers
    out[[length(out) + 1]] <- list(i = n + k, name = paste0("km_", oc[k]),
                                   outcome = "km", diagonal = FALSE)
  if (n == 3) {                              # cross-references
    for (k in seq_along(CROSS_3))
      out[[length(out) + 1]] <- list(i = 2 * n + k, name = CROSS_3[[k]]$name,
                                     outcome = CROSS_3[[k]]$outcome, diagonal = FALSE)
  } else if (n > 1) {
    warning("no cross-reference naming defined for ", n, " outcomes -- ",
            "only diagonals and KMs will be written")
  }
  out
}

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

# "HR = 0.34 (0.28, 0.41)***" built from numbers rather than inherited.
format_hr <- function(value, lower, upper, pval, digits = 4) {
  sprintf("HR = %s (%s, %s)%s",
          format(round(as.numeric(value), digits), nsmall = 0),
          format(round(as.numeric(lower), digits), nsmall = 0),
          format(round(as.numeric(upper), digits), nsmall = 0),
          stars(as.numeric(pval)))
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
  all_env   = "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/outcome/plot_list.RDATA",
  fb6_env   = "../07_display_figures/output/slam_c1-c10_age_fb6_bwfatgluc/outcome/plot_list.RDATA",
  fhet3_env = "../07_display_figures/output/slam_c1-c10_age_fhet3_bwfatgluc/outcome/plot_list.RDATA",
  mb6_env   = "../07_display_figures/output/slam_c1-c10_age_mb6_bwfatgluc/outcome/plot_list.RDATA",
  mhet3_env = "../07_display_figures/output/slam_c1-c10_age_mhet3_bwfatgluc/outcome/plot_list.RDATA",
  # body weight only -- 2 plots, not 12. panels_for() handles that.
  itp_env   = "../07_display_figures/output/itp_c10c11c13c16_age_controls_bw/outcome/plot_list.RDATA"
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

  panels <- panels_for(length(plots))
  if (is.null(panels)) next

  for (p in panels) {
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
  held_out_env = "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/workspace.RDATA"
)

have_workspaces <- TRUE
for (env_name in names(WORKSPACE_ENVS)) {
  path <- WORKSPACE_ENVS[[env_name]]
  if (!file.exists(path)) {
    message("SKIP tables -- workspace not found: ", path)
    have_workspaces <- FALSE
    next
  }
  e <- new.env(); load(path, envir = e); assign(env_name, e, envir = .GlobalEnv)
}

if (have_workspaces) {
  library(flextable)
  library(magrittr)
  max_width <- 7
  if (!dir.exists("output/tables")) dir.create("output/tables", recursive = TRUE)


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
      `Hazard Ratio (CI)` = mapply(format_hr, hn$value, hn$lower, hn$upper, hn$pval),
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

  hr_table <- flextable(hr_table) %>%
    theme_vanilla() %>%
    autofit() %>%
    set_table_properties(layout = "autofit") %>%
    fit_to_width(max_width = max_width, inc = .25, max_iter = 100)

  invisible(save_as_image(hr_table, "output/tables/hr_all.png", zoom = 10))

  # ---- hr_sexstrain_bw -------------------------------------------------
  # Figure 2I. Columns: LCM | Sex/Strain | Class | Hazard Ratio (CI).
  #
  # mortality_panel_hr is ordered bw, fat, gluc -- so [[1]] is BW on every row,
  # which is why LCM is "BW" throughout. The FM and FBG tables below use [[2]]
  # and [[3]] and share sexstrain_rows(); to give them the same treatment,
  # switch them to it and pass slot 2 / "FM" or 3 / "FBG".
  SEX_STRAIN_LABEL <- c(fb6 = "F/B6", mb6 = "M/B6",
                        fhet3 = "F/HET3", mhet3 = "M/HET3")

  # Prefer hr_numeric so STAR_RULES decides the asterisks, exactly as in hr_all.
  # `outcome` selects the rows within hr_numeric; `slot` is only used by the
  # fallback (mortality_panel_hr is ordered bw, fat, gluc).
  #
  # The two sources agree: hr_numeric comes from final_models$cox_models via
  # surv_gethr, mortality_panel_hr from kap_plot_hrs -- both are the unadjusted
  # "~ Class" fit, and their HR/CI strings were verified identical (values and
  # class ordering) across cohorts before this was wired up.
  sexstrain_rows <- function(strata, env, slot, lcm, outcome) {
    hn <- hr_numeric_rows(env, "HR Model 1")
    if (!is.null(hn)) {
      hn <- hn[hn$Outcome == outcome & !is.na(hn$Class) & !is.na(hn$pval), , drop = FALSE]
    }
    if (!is.null(hn) && nrow(hn)) {
      data.frame(
        LCM                 = lcm,
        `Sex/Strain`        = unname(SEX_STRAIN_LABEL[[strata]]),
        Class               = as.character(hn$Class),
        `Hazard Ratio (CI)` = mapply(format_hr, hn$value, hn$lower, hn$upper, hn$pval),
        check.names = FALSE, stringsAsFactors = FALSE
      )
    } else {
      tb <- env$save_figtabs$mortality_panel_hr[[slot]]
      data.frame(
        LCM                 = lcm,
        `Sex/Strain`        = unname(SEX_STRAIN_LABEL[[strata]]),
        Class               = rownames(tb),
        `Hazard Ratio (CI)` = as.character(tb[["final"]]),
        check.names = FALSE, stringsAsFactors = FALSE
      )
    }
  }

  hr_table <- rbind(
    sexstrain_rows("fb6",   fb6_env,   1, "BW", "Body Weight"),
    sexstrain_rows("mb6",   mb6_env,   1, "BW", "Body Weight"),
    sexstrain_rows("fhet3", fhet3_env, 1, "BW", "Body Weight"),
    sexstrain_rows("mhet3", mhet3_env, 1, "BW", "Body Weight")
  )
  rownames(hr_table) <- NULL

  hr_table <- flextable(hr_table) %>%
    theme_vanilla() %>%
    autofit() %>%
    set_table_properties(layout = "autofit") %>%
    fit_to_width(max_width = max_width, inc = .25, max_iter = 100)

  invisible(save_as_image(hr_table, "output/tables/hr_sexstrain_bw.png", zoom = 10))

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
      format_hr(tb$value[1], tb$lower[1], tb$upper[1], tb$pval[1])
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
    theme_vanilla() %>%
    autofit() %>%
    set_table_properties(layout = "autofit") %>%
    fit_to_width(max_width = max_width, inc = .25, max_iter = 100)

  invisible(save_as_image(hr_table, "output/tables/hr_treatment.png", zoom = 10))

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
      `Hazard Ratio (CI)` = mapply(format_hr, hn$value, hn$lower, hn$upper, hn$pval),
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

  hr_table <- flextable(hr_table) %>%
    theme_vanilla() %>%
    autofit() %>%
    set_table_properties(layout = "autofit") %>%
    fit_to_width(max_width = max_width, inc = .25, max_iter = 100)

  invisible(save_as_image(hr_table, "output/tables/hr_itp.png", zoom = 10))

  # ---- hr_sexstrain_fat ------------------------------------------------
  cbind_hr_table <- function(strata, hr_table) {
    cbind(sex_strain = strata, Class = rownames(hr_table), hr_table)
  }

  hr_table <- rbind(
    cbind_hr_table("fb6", fb6_env$save_figtabs$mortality_panel_hr[[2]]),
    cbind_hr_table("mb6", mb6_env$save_figtabs$mortality_panel_hr[[2]]),
    cbind_hr_table("fhet3", fhet3_env$save_figtabs$mortality_panel_hr[[2]]),
    cbind_hr_table("mhet3", mhet3_env$save_figtabs$mortality_panel_hr[[2]])
  )
  rownames(hr_table) <- NULL

  hr_table <- flextable(hr_table) %>%
    theme_vanilla() %>%
    autofit() %>%
    set_table_properties(layout = "autofit") %>%
    fit_to_width(max_width = max_width, inc = .25, max_iter = 100)

  invisible(save_as_image(hr_table, "output/tables/hr_sexstrain_fat.png", zoom = 10))

  # ---- hr_sexstrain_gluc -----------------------------------------------
  cbind_hr_table <- function(strata, hr_table) {
    if (is.null(hr_table)) {
      return(NULL)
    }
    cbind(sex_strain = strata, Class = rownames(hr_table), hr_table)
  }

  hr_table <- rbind(
    cbind_hr_table("fb6", fb6_env$save_figtabs$mortality_panel_hr[[3]]),
    cbind_hr_table("mb6", mb6_env$save_figtabs$mortality_panel_hr[[3]]),
    cbind_hr_table("fhet3", fhet3_env$save_figtabs$mortality_panel_hr[[3]]),
    cbind_hr_table("mhet3", mhet3_env$save_figtabs$mortality_panel_hr[[3]])
  )
  rownames(hr_table) <- NULL

  hr_table <- flextable(hr_table) %>%
    theme_vanilla() %>%
    autofit() %>%
    set_table_properties(layout = "autofit") %>%
    fit_to_width(max_width = max_width, inc = .25, max_iter = 100)

  invisible(save_as_image(hr_table, "output/tables/hr_sexstrain_gluc.png", zoom = 10))

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
    theme_vanilla() %>%
    autofit() %>%
    set_table_properties(layout = "autofit") %>%
    fit_to_width(max_width = max_width, inc = .25, max_iter = 100)

  invisible(save_as_image(hr_table, "output/tables/hr_km_external.png", zoom = 10))

  # ---- hr_fb6 ----------------------------------------------------------
  hr_table <- do.call(rbind, fb6_env$save_figtabs$mortality_panel_hr)
  hr_table <- cbind(Class = rownames(hr_table), hr_table)
  hr_table <- flextable(hr_table) %>%
    theme_vanilla() %>%
    autofit() %>%
    set_table_properties(layout = "autofit") %>%
    fit_to_width(max_width = max_width, inc = .25, max_iter = 100)

  invisible(save_as_image(hr_table, "output/tables/hr_fb6.png", zoom = 10))

  # ---- hr_fhet3 --------------------------------------------------------
  hr_table <- do.call(rbind, fhet3_env$save_figtabs$mortality_panel_hr)
  hr_table <- cbind(Class = rownames(hr_table), hr_table)
  hr_table <- flextable(hr_table) %>%
    theme_vanilla() %>%
    autofit() %>%
    set_table_properties(layout = "autofit") %>%
    fit_to_width(max_width = max_width, inc = .25, max_iter = 100)

  invisible(save_as_image(hr_table, "output/tables/hr_fhet3.png", zoom = 10))

  # ---- hr_mb6 ----------------------------------------------------------
  hr_table <- do.call(rbind, mb6_env$save_figtabs$mortality_panel_hr)
  hr_table <- cbind(Class = rownames(hr_table), hr_table)
  hr_table <- flextable(hr_table) %>%
    theme_vanilla() %>%
    autofit() %>%
    set_table_properties(layout = "autofit") %>%
    fit_to_width(max_width = max_width, inc = .25, max_iter = 100)

  invisible(save_as_image(hr_table, "output/tables/hr_mb6.png", zoom = 10))

  # ---- hr_mhet3 --------------------------------------------------------
  hr_table <- do.call(rbind, mhet3_env$save_figtabs$mortality_panel_hr)
  hr_table <- cbind(Class = rownames(hr_table), hr_table)
  hr_table <- flextable(hr_table) %>%
    theme_vanilla() %>%
    autofit() %>%
    set_table_properties(layout = "autofit") %>%
    fit_to_width(max_width = max_width, inc = .25, max_iter = 100)

  invisible(save_as_image(hr_table, "output/tables/hr_mhet3.png", zoom = 10))

  # ---- hr_km_internal --------------------------------------------------
  hr_table <- all_env$save_figtabs$km_hr_combine_validation_panels_hr
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
    theme_vanilla() %>%
    autofit() %>%
    set_table_properties(layout = "autofit") %>%
    fit_to_width(max_width = max_width, inc = .25, max_iter = 100)

  invisible(save_as_image(hr_table, "output/tables/hr_km_internal.png", zoom = 10))
}

message("99_pub_ready_figs: done")


# =============================================================================
# VITA / SOMA LOCUS HEATMAPS   (5L filtered, S9D unfiltered)
#
# INPUT: 98_itp_genotype/census_mapping.txt (trajectory.R). Cells are -log10(p)
# from a likelihood-ratio test, NOT p-values.
#
# COLOUR uses LOD breaks; 3.84 is the Bonferroni threshold. STARS use the usual
# paper convention (p<0.05/0.01/0.001 -> -log10 > 1.30/2/3), so the two encode
# different things ON PURPOSE -- a cell can carry a star while sitting below the
# Bonferroni colour cut. The figure legend has to say so.
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

LOCUS_COLS <- c(census = "All", census_f = "Female", census_m = "Male")

BONFERRONI_NEGLOG <- 3.84        # colour cut, and the 5L row filter

# sampled from the legend artwork (.A/sample_legend_hex.R)
PAL_5L    <- c("#F3F3F3", "#FDCBB4", "#F9A077", "#F57941")
BREAKS_5L <- c(0, 3.84, 5, 6, Inf)

PAL_S9D    <- c("#F3F3F3", "#91DFF7", "#5FCCEC", "#22B9E1", "#00A5D5",
                "#FDCBB4", "#F9A077", "#F57941")
BREAKS_S9D <- c(0, 3.04, 3.24, 3.44, 3.64, 3.84, 5, 6, Inf)

neglog_stars <- function(x) {
  vapply(x, function(v) {
    if (is.na(v)) return("")
    if (v > 3) "***" else if (v > 2) "**" else if (v > -log10(0.05)) "*" else ""
  }, character(1))
}

locus_heatmap <- function(mat, title, file, pal, breaks, gap = NULL) {
  if (!nrow(mat)) { message("locus heatmap '", title, "': empty -- skipped"); return(invisible(NULL)) }
  # pheatmap opens its own device unless silent = TRUE; calling it inside
  # png()/dev.off() closes the wrong one and silently drops the file.
  hm <- pheatmap::pheatmap(
    mat, cluster_rows = FALSE, cluster_cols = FALSE,
    display_numbers = matrix(neglog_stars(mat), nrow = nrow(mat), dimnames = dimnames(mat)),
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

.map_path <- "../98_itp_genotype/census_mapping.txt"
if (!file.exists(.map_path)) {
  message("SKIP locus heatmaps -- not found: ", .map_path, " (trajectory.R has not run)")
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
                  gap = sum(startsWith(rownames(full), "Vita")))

    # 5L -- only loci with at least one Bonferroni-significant cell
    sig  <- apply(full, 1, function(r) any(r > BONFERRONI_NEGLOG, na.rm = TRUE))
    filt <- full[sig, , drop = FALSE]
    message("locus heatmap: ", nrow(filt), " of ", nrow(full),
            " loci pass Bonferroni (-log10 p > ", BONFERRONI_NEGLOG, ")  [",
            sum(startsWith(rownames(filt), "Vita")), " Vita, ",
            sum(startsWith(rownames(filt), "Soma")), " Soma]")
    locus_heatmap(filt, "Vita and Soma loci",
                  file.path(out_dir, "loci_filtered.png"),
                  PAL_5L, BREAKS_5L,
                  gap = sum(startsWith(rownames(filt), "Vita")))
  }
}
