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

# FROZEN reference / roster files. The frozen census is no longer in the master
# (pruned to just the xlsx), so it points at its Box original; the roster points
# at the pipeline's own SLAM census in the MASTER raw layer (identical data).
#   complete_census.csv -> the Box copy (the frozen healthcard census, ground truth)
#   census.csv (roster) -> master raw SLAM census (validate_95 doesn't need it; the
#                          exploratory checks below use it as the tag<->idno source)
# Edit these if your copies live elsewhere.
master_complete <- "/Users/JoshsMacbook2015/Library/CloudStorage/Box-Box/metabolic-class-ITP/98_healthcard_cod/data/20250426_all_cohort/complete_census.csv"
master_census   <- file.path(sub("/raw/downstream/.*$", "", RAW_DIR),
                             "raw/pipeline/00a_clean_slam_c1-c10/data/census.csv")

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

# ---- trace provenance of the columns ADDED to the healthcard census ---------
# The census = pipeline all-cohort census + these 7 cols. Where do they come from?
# If cod + dates trace to the roster / xlsx, complete_census is fully
# reconstructable and only census.csv + the xlsx are truly raw.
ADDED <- c("X", "fu_age_wk", "cod", "lastdate", "maxdate", "tod", "percent_le")
trace_added <- function() {
  cat("\n================================================================\n")
  cat(" PROVENANCE: the 7 columns added beyond the pipeline census\n")
  cat("================================================================\n")
  cc <- rd(master_complete)
  ros <- tryCatch(rd(master_census), error = function(e) NULL)
  cat("\n  roster census.csv columns:\n     ",
      if (is.null(ros)) "(unreadable)" else paste(names(ros), collapse = ", "), "\n")
  xlsx <- file.path(RAW_DIR, "SLAM Healthcard reconciled.xlsx")
  xcols <- NULL
  if (requireNamespace("readxl", quietly = TRUE) && file.exists(xlsx)) {
    sheets <- tryCatch(readxl::excel_sheets(xlsx), error = function(e) character())
    cat("\n  healthcard xlsx sheets:", paste(sheets, collapse = ", "), "\n")
    hc <- tryCatch(as.data.frame(readxl::read_xlsx(xlsx, sheet = "Healthcard", n_max = 5)),
                   error = function(e) NULL)
    if (!is.null(hc)) { xcols <- names(hc)
      cat("  'Healthcard' sheet columns:\n     ", paste(xcols, collapse = ", "), "\n") }
  } else cat("\n  (readxl not available or xlsx missing -- skipping sheet columns)\n")

  cat("\n  per added column -- name in roster? in xlsx? + sample values:\n")
  for (col in ADDED) {
    inros <- !is.null(ros)   && col %in% names(ros)
    inx   <- !is.null(xcols) && col %in% xcols
    vals  <- head(unique(cc[[col]]), 6)
    cat(sprintf("     %-12s roster:%-5s xlsx:%-5s  e.g. %s\n",
                col, inros, inx, paste(vals, collapse = " | ")))
  }
  cat("\n  NOTE: source cols are often RENAMED/derived, so name-match is a hint, not\n")
  cat("  proof. cod's sample values reveal if it's COD categories (xlsx/roster).\n")
}

# ---- availability: are the columns the healthcard needs actually PRODUCED by
#      the current pipeline (04 census + 00c survival), and do values match? ----
CAN0      <- RUNS[["canonical"]]
CENSUS_04 <- file.path(CAN0, "04_create_census/output/slam_c1-c10_age_all_bwfatgluc/complete_census.csv")
SURV_00C  <- c(file.path(CAN0, "00c_survival_data/output/slam_c1-c10/data/main_cat_surv.csv"),
               file.path(CAN0, "00c_survival_data/output/slam_c16-c18/data/main_cat_surv.csv"))
availability_check <- function() {
  cat("\n================================================================\n")
  cat(" AVAILABILITY: columns the healthcard reads from complete_census --\n")
  cat(" produced by the current pipeline (04 census + 00c survival)? match?\n")
  cat("================================================================\n")
  cc  <- rd(master_complete)
  c04 <- tryCatch(rd(CENSUS_04), error = function(e) NULL)
  s00 <- tryCatch(do.call(rbind, lapply(Filter(file.exists, SURV_00C),
                          function(f) rd(f)[, intersect(c("idno","dead_censor","le_wk","percent_le"), names(rd(f))), drop=FALSE])),
                  error = function(e) NULL)
  a04 <- if (!is.null(c04)) c04[match(cc$idno, c04$idno), , drop = FALSE] else NULL
  a00 <- if (!is.null(s00)) s00[match(cc$idno, s00$idno), , drop = FALSE] else NULL
  diffs <- function(x, y) {
    xn <- suppressWarnings(as.numeric(x)); yn <- suppressWarnings(as.numeric(y))
    num <- !any(is.na(xn) & !is.na(x)) && !any(is.na(yn) & !is.na(y))
    if (num) sum(abs(xn - yn) > 1e-6 | (is.na(xn) != is.na(yn)), na.rm = TRUE)
    else     sum(as.character(x) != as.character(y) | (is.na(x) != is.na(y)), na.rm = TRUE)
  }
  NEED <- c("new_class_bw","dead_censor","le_wk","percent_le","cod","tod","lastdate","maxdate","fu_age_wk")
  cat(sprintf("  %-14s %-16s %s\n", "column", "pipeline source", "values vs frozen"))
  cat(sprintf("  %-14s %-16s %s\n", strrep("-",14), strrep("-",16), strrep("-",16)))
  for (col in NEED) {
    src <- "** MISSING **"; verdict <- "-"
    if (!is.null(a04) && col %in% names(a04)) {
      src <- "04 census";    nd <- diffs(cc[[col]], a04[[col]]); verdict <- if (nd==0) "IDENTICAL" else sprintf("%d diffs", nd)
    } else if (!is.null(a00) && col %in% names(a00)) {
      src <- "00c survival";  nd <- diffs(cc[[col]], a00[[col]]); verdict <- if (nd==0) "IDENTICAL" else sprintf("%d diffs", nd)
    }
    cat(sprintf("  %-14s %-16s %s\n", col, src, verdict))
  }
  cat("\n  ** MISSING ** = not surfaced by the pipeline. cod/tod ARE in the raw\n")
  cat("  SLAM survival CSVs (already in master raw); 00c just drops them. dates are\n")
  cat("  derived. To reconstruct, 00c must output them OR the prep reads raw survival.\n")
}

# ---- AIRTIGHT: do the RAW SLAM survival cod/tod reproduce the frozen census's
#      cod/tod exactly? (frozen was built from these -- deterministic join) -----
MASTER_ROOT <- sub("/raw/downstream/95_healthcard_cod/data$", "", RAW_DIR)
SURV_C110   <- file.path(MASTER_ROOT, "raw/pipeline/00a_clean_slam_c1-c10/data/survival_2021-12-17.csv")
SURV_C1618  <- file.path(MASTER_ROOT, "raw/pipeline/00a_clean_slam_c16-c18/data/Survival_2025-02-14.csv")
verify_cod_tod <- function() {
  cat("\n================================================================\n")
  cat(" AIRTIGHT: raw SLAM survival cod/tod  vs  frozen census cod/tod\n")
  cat("================================================================\n")
  f <- rd(master_complete)
  fz <- data.frame(idno = f$idno,
                   cod_f = tolower(trimws(as.character(f$cod))),
                   tod_f = suppressWarnings(as.Date(as.character(f$tod))),  # frozen = ISO
                   stringsAsFactors = FALSE)
  ros <- rd(master_census)
  ros <- unique(data.frame(idno = ros$idno, tag = trimws(as.character(ros$tag)),
                           stringsAsFactors = FALSE))
  # raw c1-c10 (tag-keyed, tod = m/d/yy) -> bring in idno via roster
  raw1 <- tryCatch({
    s <- rd(SURV_C110); s$tag <- trimws(as.character(s$tag))
    s <- merge(s, ros, by = "tag")
    data.frame(idno = s$idno, cod_r = tolower(trimws(as.character(s$cod))),
               tod_r = suppressWarnings(as.Date(as.character(s$tod), "%m/%d/%y")),
               src = "c1-c10", stringsAsFactors = FALSE)
  }, error = function(e) NULL)
  # raw c16-c18 (idno-keyed, tod = m/d/YYYY)
  raw2 <- tryCatch({
    s <- rd(SURV_C1618)
    data.frame(idno = s$idno, cod_r = tolower(trimws(as.character(s$cod))),
               tod_r = suppressWarnings(as.Date(as.character(s$tod), "%m/%d/%Y")),
               src = "c16-c18", stringsAsFactors = FALSE)
  }, error = function(e) NULL)
  raw <- rbind(raw1, raw2)
  if (is.null(raw)) { cat("  no raw survival readable\n"); return(invisible()) }
  raw <- raw[!duplicated(raw$idno), ]
  m <- merge(fz, raw, by = "idno", all.x = TRUE)
  cov <- sum(!is.na(m$cod_r))
  cat(sprintf("  frozen animals: %d | matched to raw survival: %d | unmatched: %d\n",
              nrow(fz), cov, nrow(fz) - cov))
  mm <- m[!is.na(m$cod_r), ]
  cod_diff <- sum(mm$cod_f != mm$cod_r, na.rm = TRUE)
  tod_diff <- sum(mm$tod_f != mm$tod_r | (is.na(mm$tod_f) != is.na(mm$tod_r)), na.rm = TRUE)
  cat(sprintf("  cod (lowercased) diffs: %d / %d matched\n", cod_diff, nrow(mm)))
  cat(sprintf("  tod (as Date)     diffs: %d / %d matched\n", tod_diff, nrow(mm)))
  if (cod_diff) { cat("\n  sample cod mismatches (idno | frozen | raw):\n")
    print(utils::head(unique(mm[mm$cod_f != mm$cod_r, c("idno","cod_f","cod_r")]), 10), row.names = FALSE) }
  if (tod_diff) { cat("\n  sample tod mismatches (idno | frozen | raw | src):\n")
    print(utils::head(mm[which(mm$tod_f != mm$tod_r), c("idno","tod_f","tod_r","src")], 10), row.names = FALSE) }
  if (cov == nrow(fz) && cod_diff == 0 && tod_diff == 0)
    cat("\n  >>> AIRTIGHT: all frozen cod/tod reproduced exactly from raw survival.\n")
  else cat("\n  >>> NOT fully airtight -- see counts/samples above.\n")
}

# ---- ROSTER: is the healthcard census.csv redundant with the pipeline's SLAM
#      census.csv? (tag<->idno mapping is what the healthcard merge depends on) --
PIPE_CENSUS <- file.path(MASTER_ROOT, "raw/pipeline/00a_clean_slam_c1-c10/data/census.csv")
verify_roster <- function() {
  cat("\n================================================================\n")
  cat(" ROSTER: healthcard census.csv  vs  pipeline SLAM census.csv\n")
  cat(" (tag<->idno + demographics for the 1315 relevant animals)\n")
  cat("================================================================\n")
  hc <- rd(master_census)
  pc <- tryCatch(rd(PIPE_CENSUS), error = function(e) NULL)
  if (is.null(pc)) { cat("  pipeline SLAM census not found:", PIPE_CENSUS, "\n"); return(invisible()) }
  cat(sprintf("  healthcard roster rows: %d | pipeline SLAM census rows: %d\n", nrow(hc), nrow(pc)))
  ids <- rd(master_complete)$idno                        # the 1315 relevant animals
  norm <- function(d) data.frame(idno = d$idno,
    tag = trimws(as.character(d$tag)), sex = trimws(as.character(d$sex)),
    strain = trimws(as.character(d$strain)), dob = trimws(as.character(d$dob)),
    stringsAsFactors = FALSE)
  H <- norm(hc); P <- norm(pc)
  H <- H[H$idno %in% ids, ]; H <- H[!duplicated(H$idno), ]
  P <- P[!duplicated(P$idno), ]
  m <- merge(H, P, by = "idno", suffixes = c("_hc", "_pipe"), all.x = TRUE)
  cov <- sum(!is.na(m$tag_pipe))
  cat(sprintf("  of %d relevant animals, found in pipeline census: %d | missing: %d\n",
              nrow(H), cov, nrow(H) - cov))
  mm <- m[!is.na(m$tag_pipe), ]
  for (col in c("tag", "sex", "strain", "dob")) {
    x <- mm[[paste0(col, "_hc")]]; y <- mm[[paste0(col, "_pipe")]]
    nd <- sum(x != y | (is.na(x) != is.na(y)), na.rm = TRUE)
    cat(sprintf("     %-8s diffs: %d / %d%s\n", col, nd, nrow(mm),
                if (col == "tag" && nd) "  <- CRITICAL (join key)" else ""))
  }
  td <- mm[mm$tag_hc != mm$tag_pipe, c("idno", "tag_hc", "tag_pipe")]
  if (nrow(td)) { cat("\n  sample tag mismatches:\n"); print(utils::head(td, 10), row.names = FALSE) }
  if (cov == nrow(H) && !nrow(td))
    cat("\n  >>> roster REDUNDANT: tag<->idno identical for all relevant animals.\n")
  else cat("\n  >>> roster NOT fully redundant -- see above.\n")
}

# ---- VALIDATE the 95 implementation: replicate the rmd's in-memory
#      reconstruction and compare to the frozen census on the columns 95 uses ---
validate_95 <- function() {
  cat("\n================================================================\n")
  cat(" VALIDATE 95: reconstructed class_census (pipeline+raw survival) vs\n")
  cat(" the frozen census -- ONLY the columns the healthcard uses.\n")
  cat(" Expect: cod/tod/le_wk IDENTICAL; new_class_bw differs by 1 (the mouse).\n")
  cat("================================================================\n")
  if (!file.exists(master_complete)) {
    cat("  frozen reference NOT FOUND:\n    ", master_complete,
        "\n  -> edit master_complete (top of diagnose.R) to point at the Box copy.\n")
    return(invisible())
  }
  can  <- RUNS[["canonical"]]
  c04  <- file.path(can, "04_create_census/output/slam_c1-c10_age_all_bwfatgluc/complete_census.csv")  # 04 output: from run backup
  ros_p<- PIPE_CENSUS   # roster + raw survival live in the MASTER raw layer, not the run backup
  s1_p <- SURV_C110
  s2_p <- SURV_C1618
  ok <- vapply(c(c04, ros_p, s1_p, s2_p), file.exists, logical(1))
  if (!all(ok)) { cat("  missing input(s):\n    ", paste(c(c04,ros_p,s1_p,s2_p)[!ok], collapse="\n    "), "\n"); return(invisible()) }

  # --- replicate healthcard_cod.rmd's reconstruction EXACTLY -------------------
  census       <- read.csv(ros_p)
  class_census <- read.csv(c04)
  .ros <- unique(data.frame(idno = census$idno, tag = trimws(as.character(census$tag)), stringsAsFactors = FALSE))
  .s1  <- read.csv(s1_p); .s1$tag <- trimws(as.character(.s1$tag)); .s1 <- merge(.s1, .ros, by = "tag")
  .ct1 <- data.frame(idno = .s1$idno, cod = tolower(trimws(as.character(.s1$cod))),
                     tod = as.Date(as.character(.s1$tod), "%m/%d/%y"), stringsAsFactors = FALSE)
  .s2  <- read.csv(s2_p)
  .ct2 <- data.frame(idno = .s2$idno, cod = tolower(trimws(as.character(.s2$cod))),
                     tod = as.Date(as.character(.s2$tod), "%m/%d/%Y"), stringsAsFactors = FALSE)
  .cod_tod <- rbind(.ct1, .ct2); .cod_tod <- .cod_tod[!duplicated(.cod_tod$idno), ]
  class_census <- merge(class_census, .cod_tod, by = "idno", all.x = TRUE)

  # --- compare to frozen on the healthcard-used columns, aligned by idno -------
  fz <- rd(master_complete)
  R  <- class_census[match(fz$idno, class_census$idno), , drop = FALSE]
  cat(sprintf("  reconstructed rows: %d | frozen rows: %d | idno matched: %d/%d\n",
              nrow(class_census), nrow(fz), sum(!is.na(R$idno)), nrow(fz)))
  chk <- function(nm, x, y, kind = "chr") {
    if (kind == "date") { x <- as.Date(as.character(x)); y <- as.Date(as.character(y)) }
    if (kind == "num")  { x <- as.numeric(x); y <- as.numeric(y)
      nd <- sum(abs(x - y) > 1e-6 | (is.na(x) != is.na(y)), na.rm = TRUE)
    } else nd <- sum(as.character(x) != as.character(y) | (is.na(x) != is.na(y)), na.rm = TRUE)
    cat(sprintf("     %-14s %s\n", nm, if (nd == 0) "IDENTICAL" else sprintf("%d diffs", nd)))
    nd
  }
  cat("  reconstructed vs frozen (columns the healthcard actually reads):\n")
  d_bw <- chk("new_class_bw", R$new_class_bw, fz$new_class_bw, "num")
  d_cd <- chk("cod",          R$cod,          fz$cod,          "chr")
  d_td <- chk("tod",          R$tod,          fz$tod,          "date")
  d_le <- chk("le_wk",        R$le_wk,        fz$le_wk,        "num")
  if (d_cd == 0 && d_td == 0 && d_le == 0 && d_bw <= 1)
    cat(sprintf("\n  >>> VALIDATED: cod/tod/le_wk IDENTICAL; new_class_bw differs by %d\n      (the single expected env-drift mouse). Implementation reproduces the\n      healthcard-relevant data exactly.\n", d_bw))
  else cat("\n  >>> UNEXPECTED -- diffs beyond the one bw mouse; investigate above.\n")
}

# ---- run --------------------------------------------------------------------
cat("RAW_DIR (xlsx):        ", RAW_DIR, "  dir exists:", dir.exists(RAW_DIR), "\n")
cat("frozen complete_census:", master_complete, "\n  exists:", file.exists(master_complete), "\n")

# THE KEY CHECK: does the 95 implementation reproduce the healthcard-relevant data?
validate_95()

# ---- fuller exploratory receipts (need the frozen reference files) -----------
if (file.exists(master_complete)) {
  report_target(master_complete, "complete_census.csv  (class assignments -- expected pipeline-derived)")
  cat("\n=== DEEP DIFF: complete_census.csv vs same-row-count pipeline censuses ===\n")
  for (rn in names(RUNS)) deep_compare(master_complete, rn, RUNS[[rn]])
  trace_added()
  availability_check()
  verify_cod_tod()
  verify_roster()
  if (file.exists(master_census))
    report_target(master_census, "census.csv           (animal roster -- expected genuinely raw)")
} else {
  cat("\n(skipping exploratory receipts -- frozen complete_census not found; they were the\n",
      " one-time investigation and need that file. validate_95 above is the actual check.)\n")
}
cat("\ndone.\n")
