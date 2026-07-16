# =============================================================================
# 02_hydrate_data.R  --  reproduce-flow step 2: provision inputs from the master.
#
# Reads run/config.yaml for `master_dir` + `rebuild_from`, then hydrates the
# matching layer via the hydrate engine (helpers/hydrate.R):
#   rebuild_from: raw   -> hydrate("raw")    super-raw inputs; preprocess will clean
#   rebuild_from: clean -> hydrate("clean")  skip preprocess; load cleaned data
#   rebuild_from: model -> hydrate("model")  skip fitting; frozen objects/figures
# Defaults to "raw" if no config is present. Author-side deposit ops (seed/status)
# are NOT here -- source helpers/hydrate.R directly for those.
#
# Run from the repo root:  Rscript run/02_hydrate_data.R
# =============================================================================

layer    <- "raw"
cfg_path <- "run/config.yaml"
if (file.exists(cfg_path)) {
  cfg <- yaml::read_yaml(cfg_path)
  if (!is.null(cfg$master_dir) && nzchar(cfg$master_dir))
    Sys.setenv(MASTER_DIR = path.expand(cfg$master_dir))
  if (!is.null(cfg$rebuild_from)) layer <- cfg$rebuild_from
}
stopifnot(layer %in% c("raw", "clean", "model"))

source("helpers/hydrate.R")
hydrate(layer)
