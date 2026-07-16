# =============================================================================
# diagnose.R  --  is the healthcard's frozen census actually a pipeline output?
#
# The 95_healthcard_cod analysis reads two "census" files from the master raw
# store. If complete_census.csv is byte/content-identical to a pipeline
# 04_create_census output, we should SOURCE it from the pipeline (weave it in)
# rather than freeze it as raw -- leaving the SLAM Healthcard .xlsx as the only
# truly-raw healthcard input. This script tests that against a saved run.
#
# Run from the repo root:  Rscript diagnose.R
# =============================================================================

# ---- paths (edit RUN_DIR if you want to compare against a different run) -----
RAW_DIR <- "/Users/JoshsMacbook2015/Library/CloudStorage/OneDrive-NationalInstitutesofHealth/Mueller2026_final_data/raw/downstream/95_healthcard_cod/data"
RUNS <- c(
  overnight = "/Users/JoshsMacbook2015/Desktop/metabolic-class_run_backup_2026-07-16",
  canonical = "/Users/JoshsMacbook2015/Desktop/Repos/metabolic-class-canonical-7-15-26"
)

master_complete <- file.path(RAW_DIR, "complete_census.csv")
master_census   <- file.path(RAW_DIR, "census.csv")

# ---- helpers ----------------------------------------------------------------
# normalize a census for CONTENT comparison: drop the write.csv row-index col,
# sort rows by a stable key so row order can't create false differences.
norm <- function(df) {
  if (ncol(df) && names(df)[1] %in% c("X", "", "X.1")) df <- df[, -1, drop = FALSE]
  key <- intersect(c("idno", "id"), names(df))
  if (length(key)) df <- df[order(df[[key[1]]]), , drop = FALSE]
  rownames(df) <- NULL
  df
}
rd <- function(p) read.csv(p, stringsAsFactors = FALSE, check.names = FALSE)

compare_one <- function(master_path, cand_path) {
  a <- tryCatch(rd(master_path), error = function(e) NULL)
  b <- tryCatch(rd(cand_path),   error = function(e) NULL)
  if (is.null(a) || is.null(b)) return(NULL)
  md5 <- tools::md5sum(c(master_path, cand_path))
  byte_ident <- unname(md5[1] == md5[2])
  na <- norm(a); nb <- norm(b)
  same_dim  <- identical(dim(na), dim(nb))
  same_cols <- identical(sort(names(na)), sort(names(nb)))
  content_ident <- FALSE; approx <- NA; ndiff <- NA_integer_
  if (same_dim && same_cols) {
    nb2 <- nb[, names(na), drop = FALSE]           # align col order
    content_ident <- identical(na, nb2)
    approx <- isTRUE(all.equal(na, nb2))           # tolerant (floats)
    ndiff <- sum(mapply(function(x, y) sum(x != y | (is.na(x) != is.na(y))),
                        na, nb2), na.rm = TRUE)
  }
  data.frame(
    candidate = sub(paste0("^", normalizePath(dirname(dirname(dirname(cand_path))), mustWork = FALSE)), "", cand_path),
    m_rows = nrow(a), c_rows = nrow(b),
    byte_identical = byte_ident, content_identical = content_ident,
    all_equal_tol = approx, cell_diffs = ndiff, same_cols = same_cols,
    stringsAsFactors = FALSE
  )
}

report_target <- function(master_path, label) {
  cat("\n================================================================\n")
  cat(" TARGET:", label, "\n  ", master_path, "\n")
  cat("================================================================\n")
  if (!file.exists(master_path)) { cat("  *** master file not found ***\n"); return(invisible()) }
  m <- rd(master_path)
  cat(sprintf("  master dims: %d x %d\n  master cols: %s\n",
              nrow(m), ncol(m), paste(names(m), collapse = ", ")))
  for (rn in names(RUNS)) {
    run <- RUNS[[rn]]
    cands <- Sys.glob(file.path(run, "04_create_census", "output", "*", "complete_census.csv"))
    if (!length(cands)) { cat(sprintf("\n  [%s] no candidates under %s\n", rn, run)); next }
    res <- do.call(rbind, lapply(cands, function(cp) {
      r <- compare_one(master_path, cp); if (!is.null(r)) r$tag <- basename(dirname(cp)); r
    }))
    if (is.null(res)) { cat(sprintf("\n  [%s] no readable candidates\n", rn)); next }
    cat(sprintf("\n  [%s run] %d candidate censuses compared:\n", rn, nrow(res)))
    hit <- res[res$byte_identical | res$content_identical | res$all_equal_tol %in% TRUE, ]
    show <- res[, c("tag", "c_rows", "byte_identical", "content_identical", "all_equal_tol", "cell_diffs")]
    show <- show[order(-as.integer(show$byte_identical), -as.integer(show$content_identical), show$cell_diffs), ]
    print(utils::head(show, 6), row.names = FALSE)
    if (nrow(hit)) {
      cat("  >>> MATCH:", paste(hit$tag, collapse = ", "),
          "(byte:", any(hit$byte_identical), "| content:", any(hit$content_identical),
          "| tol:", any(hit$all_equal_tol %in% TRUE), ")\n")
    } else cat("  >>> NO identical/near-identical match in this run.\n")
  }
}

# ---- deep column-level diff against same-row-count candidates ---------------
# When a candidate has the SAME nrow as the master, the interesting question is
# per-column: which cols the pipeline already provides (and whether they're
# value-identical per animal, aligned by idno) vs which are ADDED downstream.
deep_compare <- function(master_path, run_label, run_dir) {
  a <- rd(master_path)
  cands <- Sys.glob(file.path(run_dir, "04_create_census", "output", "*", "complete_census.csv"))
  same_n <- Filter(function(cp) nrow(rd(cp)) == nrow(a), cands)
  if (!length(same_n)) { cat(sprintf("\n  [%s] no candidate shares nrow=%d\n", run_label, nrow(a))); return(invisible()) }
  for (cp in same_n) {
    b <- rd(cp); tag <- basename(dirname(cp))
    cat(sprintf("\n  ---- column diff vs [%s] %s  (both %d rows) ----\n", run_label, tag, nrow(a)))
    only_master <- setdiff(names(a), names(b))
    only_pipe   <- setdiff(names(b), names(a))
    shared      <- intersect(names(a), names(b))
    cat("   cols ONLY in master (added downstream):\n     ", paste(only_master, collapse = ", "), "\n")
    cat("   cols ONLY in pipeline census:\n     ", paste(only_pipe, collapse = ", "), "\n")
    # align by idno and compare shared columns value-by-value
    if ("idno" %in% shared) {
      am <- a[match(b$idno, a$idno), , drop = FALSE]     # reorder master to pipeline order
      cat("   shared cols -- value-identical per animal (aligned by idno)?\n")
      for (col in setdiff(shared, "idno")) {
        x <- am[[col]]; y <- b[[col]]
        nd <- sum(x != y | (is.na(x) != is.na(y)), na.rm = TRUE)
        cat(sprintf("     %-16s %s%s\n", col,
                    if (nd == 0) "IDENTICAL" else sprintf("%d diffs", nd),
                    if (nd == 0) "" else " <-"))
      }
    } else cat("   (no shared idno column to align on)\n")
  }
}

# ---- run --------------------------------------------------------------------
cat("RAW_DIR:", RAW_DIR, "  exists:", dir.exists(RAW_DIR), "\n")
report_target(master_complete, "complete_census.csv  (class assignments -- expected pipeline-derived)")
cat("\n=== DEEP DIFF: complete_census.csv vs same-row-count pipeline censuses ===\n")
for (rn in names(RUNS)) deep_compare(master_complete, rn, RUNS[[rn]])
report_target(master_census,   "census.csv           (animal roster -- expected genuinely raw)")
cat("\ndone.\n")
