# =============================================================================
# 04_reproduce.R  --  MODELS runner: train / validate / predict (stages 01-07)
# + the 99 treatment-response analysis. Figures are a SEPARATE step
# (run/05_render_figures.R).
#
# Assumes you have already run, IN ORDER:
#   run/01_installer.R      - restore the package library (renv)
#   run/02_hydrate_data.R   - provision raw data from the master
#   run/03_preprocess.R     - run the cleaning stages (00a / 00b / 00c)
#
# RESILIENCE (00_config.yaml `resilient:`):
#   false (DEFAULT) -> fail LOUDLY: stop on the first failure (right for a
#                      published reproduce -- a reproducer must see breakage).
#   true            -> unattended/overnight mode: on a config failure, LOG it and
#                      CONTINUE to the next; retry the failed config ONCE first,
#                      EXCEPT `all` (a refit is ~6.5 h -- flagged for a targeted
#                      06->07 re-render instead).
#
# Artifacts (root output/, gitignored):
#   output/run_errors.log  -- written ONLY when something fails (config + stderr tail)
#   output/run_summary.csv -- per-task status + minutes (overnight mode, or on failure)
#
# Run from the repo root:  Rscript run/04_reproduce.R
# =============================================================================

resilient <- isTRUE(tryCatch(yaml::read_yaml("run/00_config.yaml")$resilient,
                             error = function(e) FALSE))

ALL_CFG <- "inputs/train/slam_c1-c10_age_all_bwfatgluc.yaml"  # never auto-retry (refit ~6.5h)
ERR_LOG <- file.path("output", "run_errors.log")
SUMMARY <- file.path("output", "run_summary.csv")
results <- list()

log_err <- function(label, code, msg) {
  dir.create("output", showWarnings = FALSE, recursive = TRUE)
  cat(sprintf("\n===== FAILED: %s  (%s)  %s =====\n%s\n",
              label, code, format(Sys.time()), paste(tail(msg, 25), collapse = "\n")),
      file = ERR_LOG, append = TRUE)
}

write_summary <- function() {
  if (!length(results)) return(invisible())
  has_fail <- any(vapply(results, function(x) grepl("FAILED", x$status), logical(1)))
  if (!resilient && !has_fail) return(invisible())     # clean default run: leave output/ untouched
  dir.create("output", showWarnings = FALSE, recursive = TRUE)
  write.csv(do.call(rbind, lapply(results, as.data.frame, stringsAsFactors = FALSE)),
            SUMMARY, row.names = FALSE)
}

record <- function(driver, cfg, status, mins) {
  results[[length(results) + 1]] <<- list(driver = driver, config = cfg,
                                          status = status, minutes = mins)
  write_summary()
}

# run one driver+config as a subprocess: stdout streams live (progress visible in
# the log), stderr is captured so a failure's error goes to the error log.
attempt <- function(driver, cfg) {
  errf <- tempfile(); t0 <- Sys.time()
  ec <- system2("Rscript", args = c(driver, cfg), stdout = "", stderr = errf)
  list(ok   = identical(ec, 0L), code = ec,
       mins = round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1),
       err  = if (identical(ec, 0L)) character() else readLines(errf, warn = FALSE))
}

run_config <- function(driver, cfg) {
  cat(sprintf("\n########## %s  %s  %s ##########\n", driver, cfg, format(Sys.time())))
  r <- attempt(driver, cfg); status <- "OK"
  if (r$ok) {
    cat(sprintf("  -> OK (%.1f min)\n", r$mins))
  } else {
    log_err(cfg, paste("exit", r$code), r$err)
    cat(sprintf("  -> FAILED (exit %s, %.1f min) -- logged to %s\n", r$code, r$mins, ERR_LOG))
    if (identical(cfg, ALL_CFG)) {
      status <- "FAILED(all,no-retry)"
      cat("  NOTE: `all` not auto-retried (refit ~6.5h). Flagged -- after the run,\n",
          "  re-render just 06->07 for it (the fit in pipeline/02_model is preserved).\n")
    } else if (resilient) {
      cat("  retrying once...\n"); r <- attempt(driver, cfg)
      if (r$ok) { status <- "OK(retry)"; cat(sprintf("  -> OK on retry (%.1f min)\n", r$mins)) }
      else      { status <- "FAILED(retry)"; log_err(paste(cfg, "[retry]"), paste("exit", r$code), r$err) }
    } else status <- "FAILED"
  }
  record(driver, cfg, status, r$mins)
  if (!r$ok && !resilient) stop("FAILED (not resilient): ", cfg, " -- see ", ERR_LOG)
  invisible(r$ok)
}

# the 99 analysis is an in-process render, wrapped in the same resilient logic
run_render <- function(rmd) {
  cat(sprintf("\n########## render %s  %s ##########\n", rmd, format(Sys.time())))
  t0 <- Sys.time()
  ok <- tryCatch({ rmarkdown::render(rmd); TRUE },
                 error = function(e) { log_err(rmd, "render error", conditionMessage(e)); FALSE })
  mins <- round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1)
  cat(sprintf("  -> %s (%.1f min)\n", if (ok) "OK" else paste0("FAILED -- logged to ", ERR_LOG), mins))
  record("render", rmd, if (ok) "OK" else "FAILED", mins)
  if (!ok && !resilient) stop("render FAILED (not resilient): ", rmd, " -- see ", ERR_LOG)
  invisible(ok)
}

cat(sprintf("\n===== 04_reproduce (models) -- resilient = %s =====\n", resilient))

# Train  (`all` FIRST so a failure surfaces on run #1) -------------------------
for (cfg in c(
  "inputs/train/slam_c1-c10_age_all_bwfatgluc.yaml",
  "inputs/train/slam_c1-c10_age_b6_bwfatgluc.yaml",
  "inputs/train/slam_c1-c10_age_fb6_bwfatgluc.yaml",
  "inputs/train/slam_c1-c10_age_fhet3_bwfatgluc.yaml",
  "inputs/train/slam_c1-c10_age_mb6_bwfatgluc.yaml",
  "inputs/train/slam_c1-c10_age_mhet3_bwfatgluc.yaml",
  "inputs/train/slam_c1-c10_age_het3_bwfatgluc.yaml",
  "inputs/train/itp_c10c11c13c16_age_controls_bw.yaml",
  "inputs/train/itp_genotyped.yaml",
  "inputs/train/itp_genotyped_F.yaml",
  "inputs/train/itp_genotyped_M.yaml",
  "inputs/train/itp_genotyped_treat.yaml",
  "inputs/train/itp_genotyped_treat_F.yaml",
  "inputs/train/itp_genotyped_treat_M.yaml"
)) run_config("helpers/train.R", cfg)

# Validate  -------------------------------------------------------------------
for (cfg in c(
  "inputs/validate/slam_c1-c10_x_slam_c16-c18.yaml"
)) run_config("helpers/validate.R", cfg)

# Predict ---------------------------------------------------------------------
for (cfg in c(
  "inputs/predict/itp_controls_p_treatment.yaml"
)) run_config("helpers/predict.R", cfg)

# Treatment-response analysis (produces output the supplemental figures embed) --
run_render("downstream/97_treatment_response/treatment_response.Rmd")

# --- final summary -----------------------------------------------------------
df <- if (length(results)) do.call(rbind, lapply(results, as.data.frame, stringsAsFactors = FALSE)) else NULL
nfail <- if (is.null(df)) 0 else sum(grepl("FAILED", df$status))
cat(sprintf("\n===== 04_reproduce done: %d tasks, %d FAILED =====\n",
            if (is.null(df)) 0 else nrow(df), nfail))
if (nfail > 0) {
  cat("failed tasks:\n"); print(df[grepl("FAILED", df$status), c("driver", "config", "status")], row.names = FALSE)
  cat(sprintf("\nsee %s  (summary: %s)\n", ERR_LOG, SUMMARY))
}

# Figures are a SEPARATE step -- run/05_render_figures.R (pub_ready_figs + partial
# correlation, then render primary + sup). Run it after this script.
