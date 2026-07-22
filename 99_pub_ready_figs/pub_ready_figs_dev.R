# Fine tune colors, axis, and theme for publication
library(consoler)
library(cowplot)
library(ggplot2)

# Configs whose upstream stage-07 output doesn't exist yet (e.g. still
# unresolved model-selection issues) are skipped rather than aborting the
# whole script -- mirrors the missing-panel handling in
# figures/final_figure_deck.Rmd. Every downstream loop iterates
# names(render_tasks), so filtering the list itself is enough; nothing else
# needs to change.
#
# Same FIGS_STRICT switch as final_figure_deck.Rmd: tolerate gaps while the
# pipeline is still running, but fail loudly for the run that produces the
# submitted figures, so a missing config cannot be skipped past unnoticed.
filter_existing_tasks <- function(tasks) {
  missing <- names(tasks)[!vapply(tasks, file.exists, logical(1))]
  for (name in missing) {
    cat("SKIPPED (missing input): ", name, " -> ", tasks[[name]], "\n", sep = "")
  }
  if (length(missing) && nzchar(Sys.getenv("FIGS_STRICT"))) {
    stop(length(missing), " config(s) missing input: ",
         paste(missing, collapse = ", "), call. = FALSE)
  }
  tasks[!names(tasks) %in% missing]
}

all_path <- "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/outcome/plot_list.RDATA"
fb6_path <- "../07_display_figures/output/slam_c1-c10_age_fb6_bwfatgluc/outcome/plot_list.RDATA"
mb6_path <- "../07_display_figures/output/slam_c1-c10_age_mb6_bwfatgluc/outcome/plot_list.RDATA"
fhet3_path <- "../07_display_figures/output/slam_c1-c10_age_fhet3_bwfatgluc/outcome/plot_list.RDATA"
mhet3_path <- "../07_display_figures/output/slam_c1-c10_age_mhet3_bwfatgluc/outcome/plot_list.RDATA"

render_tasks <- list(
  all_env = all_path,
  fb6_env = fb6_path,
  fhet3_env = fhet3_path,
  mb6_env = mb6_path,
  mhet3_env = mhet3_path
)
render_tasks <- filter_existing_tasks(render_tasks)

lapply(names(render_tasks), function(env_name) {
  env <- new.env()
  input_path <- render_tasks[[env_name]]
  load(input_path, envir = env)
  assign(env_name, env, envir = .GlobalEnv)
})


for (env in names(render_tasks)) {
  env <- get(env, envir = .GlobalEnv)
  assign("bwbw", env$new_figure1_plot_list[[1]], envir = env)
  assign("fatfat", env$new_figure1_plot_list[[2]], envir = env)
  assign("glucgluc", env$new_figure1_plot_list[[3]], envir = env)
  assign("bwkm", env$new_figure1_plot_list[[4]], envir = env)
  assign("fatkm", env$new_figure1_plot_list[[5]], envir = env)
  assign("gluckm", env$new_figure1_plot_list[[6]], envir = env)
  assign("fatbw", env$new_figure1_plot_list[[7]], envir = env)
  assign("bwfat", env$new_figure1_plot_list[[8]], envir = env)
  assign("bwgluc", env$new_figure1_plot_list[[9]], envir = env)
  assign("glucfat", env$new_figure1_plot_list[[10]], envir = env)
  assign("glucfat", env$new_figure1_plot_list[[11]], envir = env)
  assign("fatgluc", env$new_figure1_plot_list[[12]], envir = env)
}

for (env_name in names(render_tasks)) {
  env <- get(env_name, envir = .GlobalEnv)

  for (obj_name in ls(envir = env)) {
    if (startsWith(obj_name, "bw") && obj_name != "bwkm") {
      obj <- get(obj_name, envir = env)
      assign(obj_name, obj + ggplot2::ylim(0, 70), envir = env)
    }
  }
}

for (env_name in names(render_tasks)) {
  env <- get(env_name, envir = .GlobalEnv)

  for (obj_name in ls(envir = env)) {
    if (startsWith(obj_name, "fat") && obj_name != "fatkm") {
      obj <- get(obj_name, envir = env)
      assign(obj_name, obj + ggplot2::ylim(0, 25), envir = env)
    }
  }
}

for (env_name in names(render_tasks)) {
  env <- get(env_name, envir = .GlobalEnv)

  for (obj_name in ls(envir = env)) {
    if (startsWith(obj_name, "gluc") && obj_name != "gluckm") {
      obj <- get(obj_name, envir = env)
      assign(obj_name, obj + ggplot2::ylim(0, 275), envir = env)
    }
  }
}


# Save no-legend plot, full original, and legend separately
for (env_name in names(render_tasks)) {
  env <- get(env_name, envir = .GlobalEnv)

  output_dir <- file.path("output", env_name, "define_class")
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  for (obj_name in ls(envir = env)) {
    obj <- get(obj_name, envir = env)
    if (inherits(obj, "gg")) {
      # Plot without legend
      no_legend_plot <- obj + ggplot2::theme(legend.position = "none")
      no_legend_path <- file.path(output_dir, paste0(obj_name, ".png"))
      ggplot2::ggsave(
        filename = no_legend_path,
        plot = no_legend_plot,
        width = 4, height = 5, dpi = 300
      )

      # Full original with legend
      full_plot_path <- file.path(output_dir, paste0(obj_name, "_withlegend.png"))
      ggplot2::ggsave(
        filename = full_plot_path,
        plot = obj,
        width = 5, height = 5, dpi = 300
      )

      # Legend only
      legend_grob <- cowplot::get_legend(obj)
      if (!is.null(legend_grob)) {
        legend_plot <- cowplot::ggdraw(legend_grob)
        legend_path <- file.path(output_dir, paste0(obj_name, "_legend.png"))
        ggplot2::ggsave(
          filename = legend_path,
          plot = legend_plot,
          width = 3, height = 3, dpi = 300
        )
      }
    }
  }
}


# Validation Plots  -----------------------------------------------------------

all_path <- "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/validation/validation_list.RDATA"
held_out_path <- "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/validation/validation_list.RDATA"

render_tasks <- list(
  all_env = all_path,
  held_out_env = held_out_path
)
render_tasks <- filter_existing_tasks(render_tasks)

lapply(names(render_tasks), function(env_name) {
  env <- new.env()
  input_path <- render_tasks[[env_name]]
  load(input_path, envir = env)
  assign(env_name, env, envir = .GlobalEnv)
})


for (env_name in names(render_tasks)) {
  env <- get(env_name, envir = .GlobalEnv)

  assign("window_coef", env$p[[1]], envir = env)
  assign("window_concord", env$p[[2]], envir = env)
  assign("cum_coef", env$p[[3]], envir = env)
  assign("cum_concord", env$p[[4]], envir = env)
  drop(env$p)
}


for (env_name in names(render_tasks)) {
  env <- get(env_name, envir = .GlobalEnv)

  for (obj_name in ls(envir = env)) {
    obj <- get(obj_name, envir = env)

    if (grepl("_coef$", obj_name)) {
      updated_plot <- obj +
        ggplot2::coord_cartesian(ylim = c(-1, 3)) +
        ggplot2::geom_hline(yintercept = 1, linetype = "dotted", color = "gray40") +
        ggplot2::ylab("Linear Predictor") +
        ggplot2::xlab("Upper Bound Age (weeks)")
      assign(obj_name, updated_plot, envir = env)
    } else if (grepl("_concord$", obj_name)) {
      updated_plot <- obj +
        ggplot2::coord_cartesian(ylim = c(0.4, 0.8)) +
        ggplot2::geom_hline(yintercept = 0.5, linetype = "dotted", color = "red") +
        ggplot2::ylab("Concordance") +
        ggplot2::xlab("Upper Bound Age (weeks)")

      assign(obj_name, updated_plot, envir = env)
    }
  }
}


# Save validation plots (no legend, full with legend, and legend only)
for (env_name in names(render_tasks)) {
  env <- get(env_name, envir = .GlobalEnv)

  output_dir <- file.path("output", env_name, "validation")
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  for (obj_name in ls(envir = env)) {
    if (!grepl("_(coef|concord)$", obj_name)) next

    obj <- get(obj_name, envir = env)
    if (!inherits(obj, "gg")) next

    # 1. Plot without legend → plotname.png
    no_legend_plot <- obj + ggplot2::theme(legend.position = "none")
    ggplot2::ggsave(
      filename = file.path(output_dir, paste0(obj_name, ".png")),
      plot = no_legend_plot,
      width = 4, height = 5, dpi = 300
    )

    # Full plot with legend
    ggplot2::ggsave(
      filename = file.path(output_dir, paste0(obj_name, "_withlegend.png")),
      plot = obj,
      width = 5, height = 5, dpi = 300
    )

    # Legend only
    legend_grob <- cowplot::get_legend(obj)
    if (!is.null(legend_grob)) {
      legend_plot <- cowplot::ggdraw(legend_grob)
      ggplot2::ggsave(
        filename = file.path(output_dir, paste0(obj_name, "_legend.png")),
        plot = legend_plot,
        width = 3, height = 3, dpi = 300
      )
    }
  }
}
