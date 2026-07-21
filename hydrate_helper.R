# =============================================================================
# hydrate_helper.R -- one-time copy of the RAW data into the repo
#
# WHAT THIS IS
#   A convenience helper, nothing more. You run it once on a fresh clone, give it
#   the path to the raw data folder, and it copies the raw files into the six
#   places the pipeline expects them. Then you never need it again.
#
#   It is NOT part of the pipeline. `reproduce.R` does not call it, no analysis
#   depends on it, and deleting it would break nothing. It exists purely so you
#   don't have to drag six folders into place by hand.
#
# WHAT IT DOES
#   Copies. That is all. It does not clean, reshape, rename, merge, or process
#   anything -- every file lands byte-identical to the source.
#
# WHAT IT TOUCHES
#   ONLY raw inputs (the files the pipeline cannot regenerate). It never writes
#   into any output/ directory and never touches anything the pipeline produces.
#
# HOW TO RUN
#   Rscript hydrate_helper.R
#     ...then paste the path to the raw folder when prompted. Or skip the prompt:
#   Rscript hydrate_helper.R "/path/to/Mueller2026_final_data/raw"
#
#   Existing files are SKIPPED by default, so re-running is safe and will not
#   clobber anything. Pass --overwrite to replace them:
#   Rscript hydrate_helper.R "/path/to/raw" --overwrite
#
# EXPECTED SOURCE LAYOUT
#   raw/
#     00a_itp2/data/                 00a_clean_slam_c16-c18/data/
#     00a_clean_itp_geno/data/       95_healthcard_cod/data/
#     00a_clean_slam_c1-c10/data/    98_itp_genotype/data/
# =============================================================================

# ---- source -> destination map ----------------------------------------------
# Five folders copy straight across. The sixth is the exception: trajectory.R
# reads "um-het3-rqtl.csvr" from its OWN directory, not from a data/ subfolder,
# so that one file is flattened up a level.
MAP <- list(
  list(from = "00a_itp2/data",               to = "00a_itp2/data"),
  list(from = "00a_clean_itp_geno/data",     to = "00a_clean_itp_geno/data"),
  list(from = "00a_clean_slam_c1-c10/data",  to = "00a_clean_slam_c1-c10/data"),
  list(from = "00a_clean_slam_c16-c18/data", to = "00a_clean_slam_c16-c18/data"),
  list(from = "95_healthcard_cod/data",      to = "95_healthcard_cod/data"),
  list(from = "98_itp_genotype/data",        to = "98_itp_genotype",
       note = "flattened -- trajectory.R reads the .csvr from its own directory")
)

# ---- get the raw path -------------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)
overwrite <- "--overwrite" %in% args
args <- setdiff(args, "--overwrite")

raw <- if (length(args) > 0) {
  args[[1]]
} else {
  cat("\n", strrep("=", 72), "\n", sep = "")
  cat("  WAITING FOR YOUR INPUT -- this script is paused until you answer.\n")
  cat(strrep("=", 72), "\n\n", sep = "")
  cat("  Paste the full path to the raw data folder, then press Enter.\n")
  cat("  (You can also drag the folder from Finder onto this window.)\n\n")
  cat("  It should be the folder named 'raw', e.g.\n")
  cat("    ~/Library/CloudStorage/OneDrive-.../Mueller2026_final_data/raw\n\n")
  cat("  Press Ctrl-C to cancel without copying anything.\n\n")
  cat("  PATH> ")
  utils::flush.console()
  # readline() returns "" under Rscript, so read stdin directly when not interactive
  ans <- if (interactive()) readline() else readLines("stdin", n = 1)
  cat("\n")
  ans
}

raw <- trimws(raw)
raw <- sub("^~", path.expand("~"), raw)
raw <- gsub("\\\\ ", " ", raw)          # un-escape spaces from a drag-and-dropped path
raw <- gsub("^['\"]|['\"]$", "", raw)   # strip surrounding quotes

if (!nzchar(raw)) stop("No path given.")
if (!dir.exists(raw)) stop("Not a directory: ", raw)

cat("\nsource: ", normalizePath(raw), "\n", sep = "")
cat("target: ", normalizePath("."), "\n", sep = "")
cat("mode:   ", if (overwrite) "OVERWRITE existing files" else "skip existing files", "\n\n", sep = "")

# ---- copy -------------------------------------------------------------------
n_copied <- n_skipped <- 0L
missing_src <- character(0)

for (m in MAP) {
  src_dir <- file.path(raw, m$from)
  cat("--- ", m$from, " -> ", m$to, "\n", sep = "")
  if (!is.null(m$note)) cat("      (", m$note, ")\n", sep = "")

  if (!dir.exists(src_dir)) {
    cat("      NOT FOUND in source -- skipping this folder\n")
    missing_src <- c(missing_src, m$from)
    next
  }

  dir.create(m$to, showWarnings = FALSE, recursive = TRUE)

  files <- list.files(src_dir, full.names = TRUE, no.. = TRUE)
  files <- files[!grepl("^\\.", basename(files))]   # ignore .DS_Store etc.
  files <- files[!dir.exists(files)]                # files only, no recursion

  if (!length(files)) { cat("      (no files)\n"); next }

  for (f in files) {
    dest <- file.path(m$to, basename(f))
    if (file.exists(dest) && !overwrite) {
      cat("      skip  ", basename(f), " (already present)\n", sep = "")
      n_skipped <- n_skipped + 1L
      next
    }
    ok <- file.copy(f, dest, overwrite = TRUE, copy.date = TRUE)
    if (!ok) stop("Copy FAILED: ", f, " -> ", dest)

    # OneDrive placeholders can copy as 0 bytes if the file is not downloaded
    if (file.size(dest) == 0 && file.size(f) > 0) {
      stop("Copied 0 bytes from a non-empty source: ", basename(f),
           "\n  The source is probably an undownloaded cloud placeholder.",
           "\n  Make it available offline, then re-run with --overwrite.")
    }
    cat("      copy  ", basename(f),
        "  (", format(structure(file.size(dest), class = "object_size"),
                      units = "auto"), ")\n", sep = "")
    n_copied <- n_copied + 1L
  }
}

# ---- summary ----------------------------------------------------------------
cat("\n", strrep("-", 60), "\n", sep = "")
cat(sprintf("copied %d file(s), skipped %d already present\n", n_copied, n_skipped))
if (length(missing_src)) {
  cat("\nNOT found in the source folder:\n")
  cat(paste0("  ", missing_src, collapse = "\n"), "\n")
  cat("Check that the path points at the 'raw' folder itself.\n")
}
cat("\nThis was a one-time copy. reproduce.R does not need this script.\n")
