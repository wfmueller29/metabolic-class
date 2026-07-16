# =============================================================================
# hydrate.R  --  single engine for provisioning the pipeline from a master
#               "single source of truth" store.
#
# ONE engine, three LAYERS (see `layers` below):
#   raw    -> the per-stage data/ folders (super-raw inputs)
#   clean  -> the 00a/00b/00c output/ folders (deterministic cleaned data)
#   model  -> the 01-07 output/ folders (fitted objects / workspaces / figures;
#             the env-sensitive stuff you freeze rather than re-fit)
#
# THREE modes:
#   status(layer)   report, per tracked path: present in repo? in master? match?
#   seed(layer)     repo  -> master   (bootstrap the master FROM the current repo)
#   hydrate(layer)  master -> repo    (populate a fresh clone FROM the master)
#
# The master mirrors repo-relative paths under a per-layer root, so the tree is
# self-describing and the same copy logic serves every layer:
#     <MASTER>/<layer>/<repo-relative-path>   <->   <repo>/<repo-relative-path>
#
# Master location is ONE variable (repo-relative default; override via env), so
# nothing machine-specific is baked in -- portable for a Zenodo deposit.
#
# Usage (from the repo root):
#   source("hydrate.R")
#   status("raw"); status("clean"); status("model")
#   seed("raw")            # build master/raw from what's in your data/ folders now
#   hydrate("raw")         # later, on a fresh clone: restore data/ from the master
#   seed("all"); hydrate("all")
# =============================================================================

repo   <- "/Users/JoshsMacbook2015/Desktop/Repos/Manuscripts/Submitted/metabolic-class"
MASTER <- Sys.getenv("MASTER_DIR", unset = file.path(repo, "data_master"))

# ---- what each layer tracks (repo-relative dirs) ----------------------------
layers <- list(
  # LAYER 1: super-raw inputs -- the four active cleaning stages' data/ folders
  raw = c(
    "00a_clean_slam_c1-c10/data",
    "00a_clean_slam_c16-c18/data",
    "00a_clean_itp_geno/data",
    "00a_itp/data"
  ),
  # LAYER 2: cleaned/derived outputs (deterministic; regenerable from raw)
  clean = c(
    "00a_clean_slam_c1-c10/output",
    "00a_clean_slam_c16-c18/output",
    "00a_clean_itp_geno/output",
    "00a_itp/output",
    "00b_dataset_mods/output",
    "00c_survival_data/output"
  ),
  # LAYER 3: fitted objects / figures (env-sensitive; freeze these).
  # Captures the WHOLE 01-07 output/ trees -- every out_tag's models, censuses,
  # workspaces, and figures -- so seed("model") stores the complete modeling
  # result and hydrate("model") restores a figure-ready pipeline with NO re-fit.
  # (Whole-tree, same pattern as `clean`; prune to specific out_tags later if
  # you want a leaner published deposit.)
  model = c(
    "01_prep_model_data/output",
    "02_model/output",
    "03_model_select/output",
    "04_create_census/output",
    "05_prediction_data/output",
    "06_create_figures/output",
    "07_display_figures/output"
  )
)

# ---- copy helper: mirror the CONTENTS of `from` into `to` --------------------
mirror <- function(from, to) {
  if (!dir.exists(from)) return(FALSE)
  dir.create(to, showWarnings = FALSE, recursive = TRUE)
  entries <- list.files(from, full.names = TRUE, all.files = TRUE, no.. = TRUE)
  if (length(entries)) file.copy(entries, to, recursive = TRUE, overwrite = TRUE,
                                 copy.date = TRUE)
  TRUE
}

# quick recursive content signature (relative path + size) for a dir, so status
# can say match/differ without hashing huge trees
sig <- function(dir) {
  if (!dir.exists(dir)) return(NULL)
  f <- list.files(dir, recursive = TRUE, full.names = TRUE)
  f <- f[!grepl("\\.(yaml|yml|html)$", f, ignore.case = TRUE)]  # ignore manifests/render junk
  if (!length(f)) return(character(0))
  rel <- sub(paste0("^", dir, "/?"), "", f)
  sort(paste0(tolower(rel), ":", file.info(f)$size))
}

.paths <- function(layer) {
  stopifnot(layer %in% names(layers))
  layers[[layer]]
}

# ---- STATUS -----------------------------------------------------------------
status <- function(layer = "all") {
  if (layer == "all") { invisible(lapply(names(layers), status)); return(invisible()) }
  cat("\n==== status: ", layer, "  (master = ", MASTER, ") ====\n", sep = "")
  for (p in .paths(layer)) {
    rp <- file.path(repo, p); mp <- file.path(MASTER, layer, p)
    inR <- dir.exists(rp); inM <- dir.exists(mp)
    verdict <- if (inR && inM) {
      if (identical(sig(rp), sig(mp))) "match" else "DIFFER"
    } else if (inR && !inM) "repo-only (needs seed)"
    else if (!inR && inM) "master-only (needs hydrate)"
    else "absent both"
    cat(sprintf("  %-55s %s\n", p, verdict))
  }
}

# ---- SEED: repo -> master ---------------------------------------------------
seed <- function(layer = "raw") {
  if (layer == "all") { invisible(lapply(names(layers), seed)); return(invisible()) }
  cat("\n==== seed (repo -> master): ", layer, " ====\n", sep = "")
  for (p in .paths(layer)) {
    ok <- mirror(file.path(repo, p), file.path(MASTER, layer, p))
    cat(sprintf("  %-55s %s\n", p, if (ok) "seeded" else "SKIP (not in repo)"))
  }
}

# ---- HYDRATE: master -> repo ------------------------------------------------
hydrate <- function(layer = "raw") {
  if (layer == "all") { invisible(lapply(names(layers), hydrate)); return(invisible()) }
  cat("\n==== hydrate (master -> repo): ", layer, " ====\n", sep = "")
  for (p in .paths(layer)) {
    ok <- mirror(file.path(MASTER, layer, p), file.path(repo, p))
    cat(sprintf("  %-55s %s\n", p, if (ok) "hydrated" else "SKIP (not in master)"))
  }
}

# ---- optional interactive wrapper (sugar; delegates to the core functions) --
# Guard-railed: only runs in an interactive session, never hangs a headless run.
hydrate_wizard <- function() {
  if (!interactive()) {
    message("hydrate_wizard() is interactive-only. Use status()/seed()/hydrate() ",
            "directly, e.g. hydrate('raw'). Set the master with ",
            "Sys.setenv(MASTER_DIR='...') before source('hydrate.R').")
    return(invisible())
  }
  choose <- function(title, opts) { s <- utils::menu(opts, title = title); if (s == 0) NULL else opts[s] }

  cat("\n=== hydrate wizard ===\n")
  cat("LAYERS: raw (data/) | clean (00a/b/c output/) | model (01-07 output/)\n")
  cat("MODES:  status (report) | seed (repo->master) | hydrate (master->repo)\n")

  cat("\nCurrent master (MASTER_DIR):\n  ", MASTER, "\n", sep = "")
  if (identical(tolower(readline("Change master path? [y/N]: ")), "y")) {
    np <- readline("  New master path: ")
    if (nzchar(np)) {
      MASTER <<- path.expand(np); Sys.setenv(MASTER_DIR = MASTER)
      cat("  -> master set to ", MASTER, "\n", sep = "")
    }
  }

  mode  <- choose("\nMode?", c("status", "seed", "hydrate"))
  if (is.null(mode))  return(invisible(cat("cancelled.\n")))
  layer <- choose("Layer?", c("raw", "clean", "model", "all"))
  if (is.null(layer)) return(invisible(cat("cancelled.\n")))

  if (mode == "hydrate") {
    cat("\nhydrate will OVERWRITE repo files under layer '", layer,
        "' from the master.\n", sep = "")
    if (!identical(tolower(readline("Proceed? [y/N]: ")), "y"))
      return(invisible(cat("cancelled.\n")))
  }
  do.call(mode, list(layer))
  invisible()
}

cat("hydrate.R loaded. master =", MASTER, "\n")
cat("  programmatic:  status(layer) | seed(layer) | hydrate(layer)\n")
cat("  interactive :  hydrate_wizard()\n")
cat("  layers: 'raw'  'clean'  'model'  'all'\n")
