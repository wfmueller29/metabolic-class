# =============================================================================
# run.R  --  top-level reproduction orchestrator.
#
# Reads run/00_config.yaml and runs the pipeline end-to-end per `rebuild_from`,
# so a reproducer edits ONE config and runs ONE command:
#
#   Rscript run/run.R          (from the repo root)
#
# `rebuild_from` drives which steps execute:
#   raw    installer -> hydrate(raw)   -> preprocess -> reproduce -> figures -> session_info
#   clean  installer -> hydrate(clean) ->               reproduce -> figures -> session_info
#   model  installer -> hydrate(model) ->                            figures -> session_info
#   (reproduce = fit models + 99 analysis; figures = run/05_render_figures.R)
#
# Each step is a fresh Rscript (same as running the run/ scripts by hand); this
# just sequences them and honours the config. Stops on the first failure.
# =============================================================================

`%||%` <- function(a, b) if (is.null(a)) b else a

cfg_path <- "run/00_config.yaml"
if (!file.exists(cfg_path))
  stop("missing ", cfg_path, " -- edit the template there, then re-run.")
cfg <- yaml::read_yaml(cfg_path)

rebuild <- cfg$rebuild_from %||% "raw"
if (!rebuild %in% c("raw", "clean", "model"))
  stop("config rebuild_from must be raw|clean|model, got: ", rebuild)
if (!is.null(cfg$master_dir) && nzchar(cfg$master_dir))
  Sys.setenv(MASTER_DIR = path.expand(cfg$master_dir))

step <- function(script) {
  cat(sprintf("\n>>>>> %s\n", script))
  ec <- system2("Rscript", script)
  if (ec != 0) stop("step FAILED (exit ", ec, "): ", script)
}

cat(sprintf("\n===== reproduction run =====\n  rebuild_from = %s\n  master       = %s\n",
            rebuild, Sys.getenv("MASTER_DIR")))

step("run/01_installer.R")   # idempotent renv::restore() -- always safe (no-op when in sync)
step("run/02_hydrate_data.R")                          # hydrates the `rebuild` layer

if (rebuild == "raw")                step("run/03_preprocess.R")
if (rebuild %in% c("raw", "clean"))  step("run/04_reproduce.R")   # fit models + 99 analysis
if (rebuild == "model")
  cat("\n[model mode] using frozen objects; skipping re-fit. NOTE: supplemental figures",
      "that embed analysis outputs (99 etc.) may be incomplete until those are added to",
      "the model hydrate layer (item 3b).\n")

step("run/05_render_figures.R")                                   # assemble figures (all modes)

step("run/09_session_info.R")
cat("\n===== done (rebuild_from = ", rebuild, ") =====\n", sep = "")
