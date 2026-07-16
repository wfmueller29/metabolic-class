# =============================================================================
# 05_downstream.R  --  DOWNSTREAM runner: the self-contained analyses in
# downstream/ that CONSUME the pipeline's outputs (paper figures/tables/results).
#
# Runs AFTER run/04_pipeline.R (needs the 01-07 model outputs) and BEFORE
# run/06_render_figures.R (the figure package embeds 91 + 97 outputs).
#
# RESILIENCE (00_config.yaml `resilient:`) -- same contract as 04_pipeline:
#   false (DEFAULT) -> fail LOUDLY: stop on the first failure.
#   true            -> unattended/overnight: on a failure, LOG it + CONTINUE to
#                      the next analysis; retry the failed one ONCE. Each analysis
#                      also gets a hard TIMEOUT so one hung script can't stall the
#                      whole overnight run.
#
# Each analysis runs as a fresh subprocess FROM ITS OWN DIR (so a crash is
# isolated and its ../ relative paths resolve). `type`:
#   source -> Rscript <script>          (a plain .R analysis)
#   render -> Rscript -e rmarkdown::render(<script>)   (an .Rmd/.rmd report)
#
# Artifacts (root output/, gitignored), written only on failure / in resilient mode:
#   output/run_errors.log             -- config + stderr tail for each failure
#   output/run_downstream_summary.csv -- per-analysis status + minutes
#
# Run from the repo root:  Rscript run/05_downstream.R
# =============================================================================

resilient <- isTRUE(tryCatch(yaml::read_yaml("run/00_config.yaml")$resilient,
                             error = function(e) FALSE))
TIMEOUT <- 60 * 60   # seconds per analysis (overnight guard against a hung script)

REPO    <- getwd()   # every entry point runs from the repo root
ERR_LOG <- file.path(REPO, "output", "run_errors.log")
SUMMARY <- file.path(REPO, "output", "run_downstream_summary.csv")
results <- list()

# Ordered list. dir = wd to run from; script = entry point (relative to dir);
# type = source|render. 98 is TWO ordered steps in one folder (prep MUST precede
# trajectory). 91 + 97 moved here from 06_render_figures / 04_pipeline so the
# runners agree with the folder tree and nothing double-runs.
ANALYSES <- list(
  list(tag = "90_med_max_le",         dir = "downstream/90_med_max_le",          script = "med_max_le.R",           type = "source"),
  list(tag = "91_partial_correlation", dir = "downstream/91_partial_correlation", script = "partial_corr.R",         type = "source"),
  list(tag = "92_overlap_analysis",    dir = "downstream/92_overlap_analysis",    script = "overlap.R",              type = "source"),
  list(tag = "93_strain_analysis",     dir = "downstream/93_strain_analysis",     script = "strain_analysis.R",      type = "source"),
  list(tag = "94_jointlcm",            dir = "downstream/94_jointlcm",            script = "jointlcm.R",             type = "source"),
  list(tag = "95_healthcard_cod",      dir = "downstream/95_healthcard_cod/R",    script = "healthcard_cod.rmd",     type = "render"),
  list(tag = "96_similarity_slam_itp", dir = "downstream/96_similarity_slam_itp", script = "similarity_table.R",     type = "source"),
  list(tag = "97_treatment_response",  dir = "downstream/97_treatment_response",  script = "treatment_response.Rmd", type = "render"),
  list(tag = "98_prep_census",         dir = "downstream/98_itp_genotype",        script = "prep_census.R",          type = "source"),
  list(tag = "98_trajectory",          dir = "downstream/98_itp_genotype",        script = "trajectory.R",           type = "source")
)

log_err <- function(tag, code, msg) {
  dir.create(dirname(ERR_LOG), showWarnings = FALSE, recursive = TRUE)
  cat(sprintf("\n===== FAILED: %s  (%s)  %s =====\n%s\n",
              tag, code, format(Sys.time()), paste(tail(msg, 25), collapse = "\n")),
      file = ERR_LOG, append = TRUE)
}

write_summary <- function() {
  if (!length(results)) return(invisible())
  has_fail <- any(vapply(results, function(x) grepl("FAILED", x$status), logical(1)))
  if (!resilient && !has_fail) return(invisible())   # clean default run: leave output/ untouched
  dir.create(dirname(SUMMARY), showWarnings = FALSE, recursive = TRUE)
  write.csv(do.call(rbind, lapply(results, as.data.frame, stringsAsFactors = FALSE)),
            SUMMARY, row.names = FALSE)
}

record <- function(tag, status, mins) {
  results[[length(results) + 1]] <<- list(analysis = tag, status = status, minutes = mins)
  write_summary()
}

# run one analysis as a subprocess from its own dir, with a timeout. stdout
# streams live (progress visible); stderr captured so a failure's error is logged.
attempt <- function(a) {
  errf <- tempfile(); t0 <- Sys.time()
  cmd <- if (identical(a$type, "render"))
           c("-e", sprintf('rmarkdown::render("%s")', a$script))
         else a$script
  setwd(file.path(REPO, a$dir))
  ec <- tryCatch(
    suppressWarnings(system2("Rscript", args = cmd, stdout = "", stderr = errf, timeout = TIMEOUT)),
    error = function(e) { writeLines(conditionMessage(e), errf); 1L }
  )
  setwd(REPO)
  ec <- suppressWarnings(as.integer(ec)); if (is.na(ec)) ec <- 1L
  list(ok   = identical(ec, 0L), code = ec,
       mins = round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1),
       err  = if (identical(ec, 0L)) character()
              else tryCatch(readLines(errf, warn = FALSE), error = function(e) character()))
}

run_analysis <- function(a) {
  cat(sprintf("\n########## %s  (%s)  %s ##########\n", a$tag, a$type, format(Sys.time())))
  entry <- file.path(REPO, a$dir, a$script)
  if (!file.exists(entry)) {
    cat(sprintf("  -> SKIP: entry not found (%s)\n", entry))
    log_err(a$tag, "missing-entry", entry); record(a$tag, "FAILED(missing-entry)", 0)
    if (!resilient) stop("missing entry: ", entry)
    return(invisible(FALSE))
  }
  r <- attempt(a); status <- "OK"
  if (r$ok) {
    cat(sprintf("  -> OK (%.1f min)\n", r$mins))
  } else {
    log_err(a$tag, paste("exit", r$code), r$err)
    cat(sprintf("  -> FAILED (exit %s, %.1f min) -- logged to %s\n", r$code, r$mins, ERR_LOG))
    if (resilient) {
      cat("  retrying once...\n"); r <- attempt(a)
      if (r$ok) { status <- "OK(retry)"; cat(sprintf("  -> OK on retry (%.1f min)\n", r$mins)) }
      else      { status <- "FAILED(retry)"; log_err(paste(a$tag, "[retry]"), paste("exit", r$code), r$err) }
    } else status <- "FAILED"
  }
  record(a$tag, status, r$mins)
  if (!r$ok && !resilient) stop("FAILED (not resilient): ", a$tag, " -- see ", ERR_LOG)
  invisible(r$ok)
}

cat(sprintf("\n===== 05_downstream -- resilient = %s, timeout = %d min/analysis =====\n",
            resilient, TIMEOUT %/% 60))

for (a in ANALYSES) run_analysis(a)

# --- final summary -----------------------------------------------------------
df <- if (length(results)) do.call(rbind, lapply(results, as.data.frame, stringsAsFactors = FALSE)) else NULL
nfail <- if (is.null(df)) 0 else sum(grepl("FAILED", df$status))
cat(sprintf("\n===== 05_downstream done: %d analyses, %d FAILED =====\n",
            if (is.null(df)) 0 else nrow(df), nfail))
if (nfail > 0) {
  cat("failed analyses:\n"); print(df[grepl("FAILED", df$status), c("analysis", "status")], row.names = FALSE)
  cat(sprintf("\nsee %s  (summary: %s)\n", ERR_LOG, SUMMARY))
}
