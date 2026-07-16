# =============================================================================
# run.R  --  top-level reproduction orchestrator.
#
# Reads run/00_config.yaml and runs the pipeline end-to-end per `rebuild_from`,
# so a reproducer edits ONE config and runs ONE command:
#
#   Rscript run/run.R          (from the repo root)
#
# `rebuild_from` drives which steps execute:
#   raw    installer -> hydrate(raw)   -> preprocess -> pipeline -> downstream -> figures -> session_info
#   clean  installer -> hydrate(clean) ->               pipeline -> downstream -> figures -> session_info
#   model  installer -> hydrate(model) ->                           downstream -> figures -> session_info
#   (pipeline = fit models 01-07; downstream = analyses 90-98; figures = 06_render_figures.R)
#
# Each step is a fresh Rscript (same as running the run/ scripts by hand); this
# just sequences them and honours the config. Stops on the first failure.
# =============================================================================

`%||%` <- function(a, b) if (is.null(a)) b else a

cfg_path <- "run/00_config.yaml"
if (!file.exists(cfg_path))
  stop("missing ", cfg_path, " -- edit the template there, then re-run.")
cfg <- yaml::read_yaml(cfg_path)

rebuild   <- cfg$rebuild_from %||% "raw"
resilient <- isTRUE(cfg$resilient)
if (!rebuild %in% c("raw", "clean", "model"))
  stop("config rebuild_from must be raw|clean|model, got: ", rebuild)
if (!is.null(cfg$master_dir) && nzchar(cfg$master_dir))
  Sys.setenv(MASTER_DIR = path.expand(cfg$master_dir))

# --- per-step timing log (output/run_log.csv, gitignored). 07_session_info.R
#     reads it and writes the run_timing.txt summary; env record stays separate.
RUN_LOG <- file.path("output", "run_log.csv")
dir.create("output", showWarnings = FALSE, recursive = TRUE)
writeLines("step,start,end,minutes,status", RUN_LOG)   # fresh log each run
# clear stale failure artifacts (04/05 APPEND to these) so the morning-after logs
# reflect THIS run only, not an accumulation across runs.
unlink(file.path("output", c("run_errors.log", "run_summary.csv", "run_downstream_summary.csv")))

step <- function(script) {
  cat(sprintf("\n>>>>> %s\n", script))
  t0 <- Sys.time(); ec <- system2("Rscript", script); t1 <- Sys.time()
  cat(sprintf("%s,%s,%s,%.2f,%s\n", script, format(t0), format(t1),
              round(as.numeric(difftime(t1, t0, units = "mins")), 2),
              if (identical(ec, 0L)) "OK" else paste0("FAILED(", ec, ")")),
      file = RUN_LOG, append = TRUE)
  if (ec != 0) stop("step FAILED (exit ", ec, "): ", script)
}

cat(sprintf("\n===== reproduction run =====\n  rebuild_from = %s\n  master       = %s\n",
            rebuild, Sys.getenv("MASTER_DIR")))

step("run/01_installer.R")   # idempotent renv::restore() -- always safe (no-op when in sync)
step("run/02_hydrate_data.R")                          # hydrates the `rebuild` layer

if (rebuild == "raw")                step("run/03_preprocess.R")
if (rebuild %in% c("raw", "clean"))  step("run/04_pipeline.R")    # fit models (stages 01-07)
if (rebuild == "model")
  cat("\n[model mode] using frozen objects; skipping re-fit. NOTE: downstream analyses",
      "that embed model outputs may be incomplete until those are added to the model",
      "hydrate layer.\n")

step("run/05_downstream.R")                                       # downstream analyses (90-98)
# figures embed downstream outputs; if one is missing (a downstream analysis failed),
# the render can fail. In resilient/overnight mode DON'T let that skip the session-info
# + timing record -- log it and press on so 07 always captures what happened.
if (resilient) {
  tryCatch(step("run/06_render_figures.R"),
           error = function(e) cat("\n[resilient] 06_render_figures FAILED -- continuing to session_info.\n"))
} else {
  step("run/06_render_figures.R")
}

step("run/07_session_info.R")                                     # env + timing record (always runs when resilient)
cat("\n===== done (rebuild_from = ", rebuild, ") =====\n", sep = "")
