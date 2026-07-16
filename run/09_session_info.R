# =============================================================================
# 09_session_info.R  --  final reproducibility step.
#
# Captures the exact environment that produced the results -- R version, OS,
# BLAS/LAPACK backend, locale, and the versions of every package the pipeline
# relies on -- and writes it to session_info.txt at the repo root (tracked in
# git). This matters here because the LCMM class assignments are environment
# sensitive: BLAS / lcmm / marqLevAlg versions can change which classes a mouse
# lands in, so a committed record of the environment is the reference anyone
# needs to reproduce (or explain drift from) the canonical run.
#
# Run from the repo root, ideally in the same R environment used for the run:
#   Rscript 09_session_info.R
# =============================================================================

out_file <- "session_info.txt"

# Reproducibility-critical packages (version reported even if not attached).
# Extend as the pipeline grows; unknown/uninstalled ones are simply skipped.
key_pkgs <- c(
  # modeling core (env-sensitive)
  "lcmm", "marqLevAlg", "splines", "survival",
  # in-house helpers
  "helphlme", "callframe",
  # parallelism
  "future", "future.apply", "parallel", "parallelly",
  # data / tidyverse
  "dplyr", "tidyr", "purrr", "tibble", "readr", "stringr", "forcats",
  # figures / reporting
  "ggplot2", "cowplot", "rmarkdown", "knitr", "kableExtra", "flextable",
  # io / config
  "yaml", "jsonlite",
  # downstream analyses
  "mclust", "qgraph", "magick", "forestplot"
)

pkg_version <- function(p) {
  v <- tryCatch(as.character(utils::packageVersion(p)), error = function(e) NA_character_)
  v
}

lines <- c(
  "================================================================",
  " SESSION INFO -- metabolic-class pipeline",
  paste0(" captured: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "================================================================",
  "",
  "---- R & platform --------------------------------------------",
  R.version.string,
  paste0("platform:  ", R.version$platform),
  paste0("running:   ", tryCatch(utils::sessionInfo()$running, error = function(e) "NA")),
  paste0("os:        ", Sys.info()[["sysname"]], " ", Sys.info()[["release"]]),
  "",
  "---- numerical backend (LCMM is sensitive to this) -----------",
  paste0("BLAS:      ", tryCatch(utils::sessionInfo()$BLAS,   error = function(e) "NA")),
  paste0("LAPACK:    ", tryCatch(utils::sessionInfo()$LAPACK, error = function(e) "NA")),
  paste0("BLAS ver:  ", tryCatch(extSoftVersion()[["BLAS"]], error = function(e) "NA")),
  paste0("LAPACK ver:", tryCatch(La_version(),               error = function(e) "NA")),
  "",
  "---- locale --------------------------------------------------",
  strsplit(Sys.getlocale(), ";")[[1]],
  "",
  "---- reproducibility-critical package versions ---------------"
)

kv <- vapply(key_pkgs, pkg_version, character(1))
present <- kv[!is.na(kv)]
missing <- names(kv)[is.na(kv)]
lines <- c(lines,
  sprintf("  %-16s %s", names(present), present),
  if (length(missing)) c("", paste0("  (not installed: ", paste(missing, collapse = ", "), ")")) else NULL,
  "",
  "---- full sessionInfo() --------------------------------------",
  capture.output(print(utils::sessionInfo()))
)

# richer report if the sessioninfo package is available
if (requireNamespace("sessioninfo", quietly = TRUE)) {
  lines <- c(lines,
    "",
    "---- sessioninfo::session_info() -----------------------------",
    capture.output(print(sessioninfo::session_info()))
  )
}

writeLines(lines, out_file)
cat("wrote", normalizePath(out_file), "\n")

# --- run timing (SEPARATE artifact -- EXECUTION, not environment) ------------
# run.R appends a per-step row to output/run_log.csv during the run; summarize it
# into a clean run_timing.txt. Kept OUT of session_info.txt so the env record
# stays stable/diffable across runs.
run_log <- file.path("output", "run_log.csv")
if (file.exists(run_log)) {
  t <- tryCatch(utils::read.csv(run_log, stringsAsFactors = FALSE), error = function(e) NULL)
  if (!is.null(t) && nrow(t)) {
    mins <- suppressWarnings(as.numeric(t$minutes))
    tl <- c(
      "================================================================",
      " RUN TIMING -- metabolic-class reproduction",
      paste0(" summarized: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
      "================================================================",
      "",
      sprintf("  %-26s %9s   %s", "step", "minutes", "status"),
      sprintf("  %-26s %9s   %s", strrep("-", 26), strrep("-", 9), strrep("-", 8)),
      sprintf("  %-26s %9.2f   %s", basename(t$step), mins, t$status),
      "",
      sprintf("  %-26s %9.2f", "TOTAL (steps before 09)", sum(mins, na.rm = TRUE)),
      "",
      "(09_session_info itself isn't listed -- run.R records each step's row after",
      " it finishes, so this final step can't time itself.)"
    )
    writeLines(tl, "run_timing.txt")
    cat("wrote", normalizePath("run_timing.txt"), "\n")
  }
} else {
  cat("no output/run_log.csv -- run the pipeline via run/run.R to capture step timing.\n")
}
