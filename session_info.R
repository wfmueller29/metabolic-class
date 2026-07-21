# =============================================================================
# session_info.R  --  record the computing environment that produced a run.
#
# renv pins R PACKAGES, but it cannot pin the R build, the CPU architecture, or
# the BLAS/LAPACK libraries R links against -- and the LCMM fits in this pipeline
# are sensitive to all three. Class assignments can shift, and marginally
# positive-definite covariance matrices can fail chol() outright, purely from a
# different numerical stack. This script writes down what was actually used, so
# any result can be traced back to the environment that produced it.
#
# Run from the repo root (it is the last step of reproduce.R):
#   Rscript session_info.R
#
# Writes a timestamped, attributed PAIR of records into run_records/:
#   <run>_session_info.txt  -- the environment
#   <run>_run_timing.txt    -- per-step durations (from run_records/run_log.csv)
# Commit both alongside any results you report.
# =============================================================================

# --- where records go --------------------------------------------------------
# Records ACCUMULATE in run_records/ rather than overwriting, because more than
# one person runs this pipeline on more than one machine. Each file is stamped
# with the run's timestamp and the git author, so (a) runs can be compared against
# each other, (b) two people committing records never collide, and (c) each
# machine's numerical stack is on the record -- the thing renv cannot pin.
# The timestamp is taken from the run's FIRST step when a log exists, so the
# record is named for the run itself rather than for when it was summarized.
RUN_LOG <- file.path("run_records", "run_log.csv")
run_started <- tryCatch({
  .t <- utils::read.csv(RUN_LOG, stringsAsFactors = FALSE)
  s  <- suppressWarnings(as.POSIXct(.t$start))
  if (all(is.na(s))) Sys.time() else min(s, na.rm = TRUE)
}, error = function(e) Sys.time(), warning = function(w) Sys.time())

# Identify WHO ran it. Deliberately NOT the hostname: on a university network
# that is a DHCP name (e.g. "dhcp-227-252-...") that changes with location, so
# the same machine would produce inconsistently-named records. The git author is
# stable and matches the commit history.
who <- tryCatch(trimws(system2("git", c("config", "user.name"),
                               stdout = TRUE, stderr = FALSE)),
                error = function(e) NA_character_)
if (length(who) != 1 || is.na(who) || !nzchar(who)) who <- Sys.info()[["user"]]
who <- gsub("[^A-Za-z0-9]+", "-", who)
run_id <- sprintf("%s_%s", format(run_started, "%Y-%m-%d_%H%M"), who)

dir.create("run_records", showWarnings = FALSE)
out_file <- file.path("run_records", paste0(run_id, "_session_info.txt"))

`%||%` <- function(a, b) if (is.null(a) || !length(a) || is.na(a[1])) b else a
sh <- function(...) tryCatch(
  trimws(paste(system2(..., stdout = TRUE, stderr = FALSE), collapse = " ")),
  error = function(e) NA_character_
)

# --- which code produced this run --------------------------------------------
git_sha    <- sh("git", c("rev-parse", "HEAD"))
git_branch <- sh("git", c("rev-parse", "--abbrev-ref", "HEAD"))
git_dirty  <- sh("git", c("status", "--porcelain"))

# --- hardware ----------------------------------------------------------------
# The CPU model is not in sessionInfo(), but it matters: it distinguishes Apple
# silicon generations from Intel, and combined with R's platform string it is the
# only way to detect that R is running EMULATED under Rosetta.
sysctl <- function(key) {
  v <- tryCatch(system2("sysctl", c("-n", key), stdout = TRUE, stderr = FALSE),
                error = function(e) character())
  if (length(v) != 1 || !nzchar(v)) NA_character_ else trimws(v)
}
cpu_brand <- NA_character_; cores_phys <- NA; cores_log <- NA; mem_gb <- NA_character_
if (Sys.info()[["sysname"]] == "Darwin") {
  cpu_brand  <- sysctl("machdep.cpu.brand_string")
  cores_phys <- sysctl("hw.physicalcpu")
  cores_log  <- sysctl("hw.logicalcpu")
  bytes      <- suppressWarnings(as.numeric(sysctl("hw.memsize")))
  if (!is.na(bytes)) mem_gb <- sprintf("%.0f GB", bytes / 1024^3)
} else if (file.exists("/proc/cpuinfo")) {              # Linux fallback
  ci <- tryCatch(readLines("/proc/cpuinfo", warn = FALSE), error = function(e) character())
  mn <- grep("^model name", ci, value = TRUE)
  if (length(mn)) cpu_brand <- trimws(sub("^model name\\s*:\\s*", "", mn[1]))
  cores_log <- length(grep("^processor", ci))
}
cpu_brand  <- if (is.na(cpu_brand)) "unknown" else cpu_brand
cores_phys <- if (is.na(cores_phys)) "?" else cores_phys
cores_log  <- if (is.na(cores_log))  "?" else cores_log
mem_gb     <- if (is.na(mem_gb))     "unknown" else mem_gb

# Apple-silicon chip + an x86_64 R build == R is emulated under Rosetta.
emulated <- if (grepl("^Apple", cpu_brand) && grepl("^x86_64", R.version$platform)) {
  "YES -- x86_64 R on Apple silicon (running under Rosetta); slower, and a different numerical stack than a native arm64 build"
} else "no (R build matches the CPU architecture)"

# --- the numerical stack (the part renv cannot pin) --------------------------
si   <- utils::sessionInfo()
blas <- si$BLAS %||% "unknown"
# Threaded BLAS varies summation order across runs; record the thread caps too.
thread_vars <- c("OPENBLAS_NUM_THREADS", "OMP_NUM_THREADS", "VECLIB_MAXIMUM_THREADS",
                 "MKL_NUM_THREADS")
threads <- vapply(thread_vars, function(v) Sys.getenv(v, "<unset>"), character(1))

# --- what the lockfile expects, vs what we are running -----------------------
lock_R <- tryCatch(renv::lockfile_read("renv.lock")$R$Version,
                   error = function(e) NA_character_)
renv_ok <- tryCatch({
  st <- renv::status()
  if (isTRUE(st$synchronized)) "synchronized with renv.lock" else "NOT synchronized -- see renv::status()"
}, error = function(e) "could not determine (renv::status() failed)")

# --- packages whose versions materially affect the results -------------------
key_pkgs <- c("lcmm", "marqLevAlg", "survival", "lme4", "Matrix", "nlme", "MASS",
              "splines", "future", "future.apply", "parallelly",
              "dplyr", "tidyr", "ggplot2", "rmarkdown", "knitr",
              "flextable", "gdtools", "officer", "qtl", "mclust", "qgraph")
pkg_line <- function(p) {
  v <- tryCatch(as.character(utils::packageVersion(p)), error = function(e) NA_character_)
  if (is.na(v)) return(NULL)
  sprintf("  %-16s %s", p, v)
}

# --- in-house packages: version AND commit, so the exact code is identifiable -
inhouse <- c("helphlme", "callframe", "SLAM", "consoler")
inhouse_line <- function(p) {
  d <- tryCatch(utils::packageDescription(p), error = function(e) NULL)
  if (is.null(d) || identical(d, NA)) return(sprintf("  %-16s NOT INSTALLED", p))
  sha <- d$RemoteSha %||% "<no commit recorded>"
  sprintf("  %-16s %-12s %s", p, d$Version %||% "?", substr(sha, 1, 40))
}

lines <- c(
  "================================================================",
  " SESSION INFO -- metabolic-class",
  paste0(" captured: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "================================================================",
  "",
  "---- code version --------------------------------------------",
  paste0("  git commit : ", git_sha),
  paste0("  git branch : ", git_branch),
  paste0("  worktree   : ", if (is.na(git_dirty) || !nzchar(git_dirty))
                              "clean" else "MODIFIED (uncommitted changes present)"),
  "",
  "---- R & platform --------------------------------------------",
  paste0("  ", R.version.string),
  paste0("  R platform : ", R.version$platform),
  paste0("  running    : ", tryCatch(si$running, error = function(e) "NA")),
  paste0("  os         : ", Sys.info()[["sysname"]], " ", Sys.info()[["release"]]),
  "",
  "---- hardware ------------------------------------------------",
  paste0("  cpu        : ", cpu_brand),
  paste0("  machine    : ", Sys.info()[["machine"]]),
  paste0("  cores      : ", cores_phys, " physical / ", cores_log, " logical"),
  paste0("  memory     : ", mem_gb),
  # An Apple-silicon chip running an x86_64 build of R means R is emulated under
  # Rosetta. That changes the numerical stack (and is far slower) -- and it is
  # invisible in sessionInfo() alone, so flag it explicitly.
  paste0("  emulation  : ", emulated),
  "",
  "---- numerical stack (NOT pinned by renv; affects LCMM results) ",
  paste0("  BLAS       : ", blas),
  paste0("  LAPACK     : ", si$LAPACK %||% "unknown"),
  paste0("  reference BLAS? ", if (grepl("libRblas", blas, fixed = TRUE))
                                 "yes (single-threaded, deterministic)"
                               else "NO -- if threaded, results can vary run to run"),
  "  thread caps:",
  sprintf("    %-24s %s", names(threads), threads),
  "",
  "---- renv ----------------------------------------------------",
  paste0("  renv.lock records R : ", lock_R),
  paste0("  this session is R   : ", as.character(getRversion()),
         if (!is.na(lock_R) && !identical(lock_R, as.character(getRversion())))
           "   <-- MISMATCH" else ""),
  paste0("  library state       : ", renv_ok),
  "",
  "---- in-house packages (version + commit) --------------------",
  vapply(inhouse, inhouse_line, character(1)),
  "",
  "---- key package versions ------------------------------------",
  unlist(lapply(key_pkgs, pkg_line)),
  "",
  "---- locale --------------------------------------------------",
  paste0("  ", strsplit(Sys.getlocale(), ";")[[1]]),
  "",
  "---- full sessionInfo() --------------------------------------",
  utils::capture.output(print(si))
)

if (requireNamespace("sessioninfo", quietly = TRUE))
  lines <- c(lines, "",
             "---- sessioninfo::session_info() -----------------------------",
             utils::capture.output(print(sessioninfo::session_info())))

writeLines(lines, out_file)
cat("wrote", normalizePath(out_file), "\n")

# --- run timing (SEPARATE artifact -- EXECUTION, not environment) ------------
# reproduce.R appends a row to run_records/run_log.csv as each step finishes. Summarize
# it into run_timing.txt. Kept OUT of session_info.txt so the environment record
# stays stable and diffable across runs while timing changes every time.
if (file.exists(RUN_LOG)) {
  t <- tryCatch(utils::read.csv(RUN_LOG, stringsAsFactors = FALSE),
                error = function(e) NULL)
  if (!is.null(t) && nrow(t)) {
    mins   <- suppressWarnings(as.numeric(t$minutes))
    starts <- suppressWarnings(as.POSIXct(t$start))
    ends   <- suppressWarnings(as.POSIXct(t$end))
    began  <- min(starts, na.rm = TRUE)
    ended  <- max(ends,   na.rm = TRUE)
    wall   <- as.numeric(difftime(ended, began, units = "hours"))
    nfail  <- sum(!grepl("^OK", t$status))

    tl <- c(
      "================================================================",
      " RUN TIMING -- metabolic-class",
      paste0(" summarized: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
      "================================================================",
      "",
      paste0("  run started : ", format(began, "%Y-%m-%d %H:%M:%S")),
      paste0("  run ended   : ", format(ended, "%Y-%m-%d %H:%M:%S")),
      sprintf("  wall clock  : %.2f hours (%.0f min)", wall, wall * 60),
      sprintf("  steps       : %d  (%d failed)", nrow(t), nfail),
      "",
      sprintf("  %-46s %9s   %s", "step", "minutes", "status"),
      sprintf("  %-46s %9s   %s", strrep("-", 46), strrep("-", 9), strrep("-", 8)),
      sprintf("  %-46s %9.2f   %s", substr(t$step, 1, 46), mins, t$status),
      sprintf("  %-46s %9s   %s", strrep("-", 46), strrep("-", 9), strrep("-", 8)),
      sprintf("  %-46s %9.2f", "TOTAL (sum of steps)", sum(mins, na.rm = TRUE)),
      "",
      "(session_info itself is not listed -- reproduce.R logs each step as it",
      " finishes, so this final step cannot time itself. 'wall clock' spans the",
      " first step's start to the last step's end, so it includes any gaps.)"
    )
    timing_file <- file.path("run_records", paste0(run_id, "_run_timing.txt"))
    writeLines(tl, timing_file)
    cat("wrote", normalizePath(timing_file), "\n")
  }
} else {
  cat("no", RUN_LOG, "-- run the pipeline via reproduce.R to capture step timing.\n")
}
