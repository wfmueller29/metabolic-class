# Recreate the ITP-genotype class demographics table (the "panel C" / S9C figure)
# by recomputing all six blocks from the census objects and assembling them.
# Controls section (n / Female / Male / Median survival) from the three control
# censuses; Treated section (n / Female / Male / Control / Treatment / Median
# survival) from the three treatment censuses. Chi-square p-values: class x sex
# and class x treatment.
#
# This script builds the figure from the censuses prep_census.R wrote into
# output/. Optionally, if ITP_GENO_REF_CENSUS points at a second census set
# (e.g. the run that produced the published S9C), it rebuilds the same table
# from that set and compares the two cell-by-cell in code -- so drift between
# two runs is visible directly, without eyeballing PNGs.
#
# Outputs (in output/):
#   itp_geno_demographics.png            <- this run's figure
#   itp_geno_demographics_reference.png  <- reference set (only if enabled)
#   itp_geno_demographics_comparison.csv <- cell-by-cell diffs (only if enabled)

library(survival)
library(flextable)
library(magick)

# Run from this script's own directory regardless of where it is invoked from,
# so the output/ relative paths resolve. (Only takes effect under Rscript; if
# you source() this interactively, be in 98_itp_genotype/ already.)
local({
  f <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
  if (length(f)) setwd(dirname(normalizePath(f)))
})

# ---- the two census sources -------------------------------------------------
# SRC_LOCAL is what prep_census.R just wrote -> this figure.
# SRC_REF is an OPTIONAL second census set to compare against (the run that
# produced the published S9C). It is not in the repo and is machine-specific;
# set ITP_GENO_REF_CENSUS to its path to enable the comparison, otherwise the
# comparison outputs are skipped and only this figure is built.
SRC_LOCAL <- "output"
SRC_REF   <- Sys.getenv("ITP_GENO_REF_CENSUS", unset = NA)

CLASSES <- 1:3
r0 <- function(x) if (length(x) == 0 || is.na(x)) "NA" else as.character(round(x))
cnt <- function(df, cls, mask) sum(df$new_class_bw == cls & mask)
pct <- function(k, tot) if (is.na(k) || is.na(tot) || tot == 0) "" else sprintf(" (%.1f%%)", 100 * k / tot)
fmt_p <- function(p) if (length(p) == 0 || is.na(p)) "NA" else formatC(p, format = "e", digits = 2)

# median survival "med (lcl, ucl)" per class (named by class number, 1..3)
med_surv <- function(df) {
  out <- setNames(rep(NA_character_, length(CLASSES)), as.character(CLASSES))
  cls_present <- sort(unique(df$new_class_bw))
  fit <- survfit(Surv(le_wk, dead_censor) ~ new_class_bw, data = df)
  tb <- summary(fit)$table
  if (is.null(dim(tb))) {                     # single-class edge case -> vector
    out[as.character(cls_present[1])] <-
      sprintf("%s (%s, %s)", r0(tb["median"]), r0(tb["0.95LCL"]), r0(tb["0.95UCL"]))
  } else {
    cl <- as.integer(sub(".*=", "", rownames(tb)))
    for (i in seq_along(cl)) {
      out[as.character(cl[i])] <-
        sprintf("%s (%s, %s)", r0(tb[i, "median"]), r0(tb[i, "0.95LCL"]), r0(tb[i, "0.95UCL"]))
    }
  }
  out
}

# ---- build the whole assembled table from one census source -----------------
build_table <- function(src) {
  rd <- function(f) read.csv(file.path(src, f))
  ctrl <- list(
    Unstratified = rd("itp_geno_census.csv"),
    Females      = rd("itp_geno_f_census.csv"),
    Males        = rd("itp_geno_m_census.csv")
  )
  trt <- list(
    Unstratified = rd("itp_geno_tx_census.csv"),
    Females      = rd("itp_geno_tx_f_census.csv"),
    Males        = rd("itp_geno_tx_m_census.csv")
  )

  build_rows <- function(stratum) {
    c_df <- ctrl[[stratum]]; t_df <- trt[[stratum]]
    has_sex <- stratum == "Unstratified"      # only the pooled set has a sex split
    c_med <- med_surv(c_df); t_med <- med_surv(t_df)

    cN <- nrow(c_df); tN <- nrow(t_df)
    t_ctrl_tot <- sum(t_df$tx == "N"); t_trt_tot <- sum(t_df$tx == "Y")
    c_f_tot <- if (has_sex) sum(c_df$sex_F == 1) else NA
    c_m_tot <- if (has_sex) sum(c_df$sex_M == 1) else NA
    t_f_tot <- if (has_sex) sum(t_df$sex_F == 1) else NA
    t_m_tot <- if (has_sex) sum(t_df$sex_M == 1) else NA

    rows <- list()
    for (cl in CLASSES) {
      pc <- cl %in% c_df$new_class_bw
      pt <- cl %in% t_df$new_class_bw
      cn <- if (pc) sum(c_df$new_class_bw == cl) else NA
      tn <- if (pt) sum(t_df$new_class_bw == cl) else NA
      cf <- if (has_sex && pc) cnt(c_df, cl, c_df$sex_F == 1) else NA
      cm <- if (has_sex && pc) cnt(c_df, cl, c_df$sex_M == 1) else NA
      tf <- if (has_sex && pt) cnt(t_df, cl, t_df$sex_F == 1) else NA
      tm <- if (has_sex && pt) cnt(t_df, cl, t_df$sex_M == 1) else NA
      tc <- if (pt) cnt(t_df, cl, t_df$tx == "N") else NA
      tt <- if (pt) cnt(t_df, cl, t_df$tx == "Y") else NA

      rows[[length(rows) + 1]] <- data.frame(
        Stratum = stratum, Row = paste("Class", cl),
        c_n    = if (pc) as.character(cn) else "---",
        c_fem  = if (has_sex) (if (pc) paste0(cf, pct(cf, c_f_tot)) else "---") else "",
        c_male = if (has_sex) (if (pc) paste0(cm, pct(cm, c_m_tot)) else "---") else "",
        c_med  = if (pc) c_med[as.character(cl)] else "---",
        t_n    = if (pt) paste0(tn, pct(tn, tN)) else "---",
        t_fem  = if (has_sex) (if (pt) paste0(tf, pct(tf, t_f_tot)) else "---") else "",
        t_male = if (has_sex) (if (pt) paste0(tm, pct(tm, t_m_tot)) else "---") else "",
        t_ctrl = if (pt) paste0(tc, pct(tc, t_ctrl_tot)) else "---",
        t_trt  = if (pt) paste0(tt, pct(tt, t_trt_tot)) else "---",
        t_med  = if (pt) t_med[as.character(cl)] else "---",
        stringsAsFactors = FALSE, check.names = FALSE
      )
    }

    # total row
    rows[[length(rows) + 1]] <- data.frame(
      Stratum = stratum, Row = "total",
      c_n = as.character(cN),
      c_fem = if (has_sex) as.character(c_f_tot) else "",
      c_male = if (has_sex) as.character(c_m_tot) else "",
      c_med = "", t_n = as.character(tN),
      t_fem = if (has_sex) as.character(t_f_tot) else "",
      t_male = if (has_sex) as.character(t_m_tot) else "",
      t_ctrl = as.character(t_ctrl_tot), t_trt = as.character(t_trt_tot), t_med = "",
      stringsAsFactors = FALSE, check.names = FALSE
    )

    # pval row: chi-square class x sex (each section) and class x tx (treated)
    chi_sex_c <- if (has_sex) suppressWarnings(chisq.test(table(c_df$new_class_bw, c_df$sex_F))$p.value) else NA
    chi_sex_t <- if (has_sex) suppressWarnings(chisq.test(table(t_df$new_class_bw, t_df$sex_F))$p.value) else NA
    chi_tx_t  <- if (length(unique(t_df$new_class_bw)) > 1) suppressWarnings(chisq.test(table(t_df$new_class_bw, t_df$tx))$p.value) else NA
    rows[[length(rows) + 1]] <- data.frame(
      Stratum = stratum, Row = "pval",
      c_n = "NA",
      c_fem = if (has_sex) fmt_p(chi_sex_c) else "",
      c_male = if (has_sex) fmt_p(chi_sex_c) else "",
      c_med = "NA", t_n = "NA",
      t_fem = if (has_sex) fmt_p(chi_sex_t) else "",
      t_male = if (has_sex) fmt_p(chi_sex_t) else "",
      t_ctrl = fmt_p(chi_tx_t), t_trt = fmt_p(chi_tx_t), t_med = "NA",
      stringsAsFactors = FALSE, check.names = FALSE
    )

    do.call(rbind, rows)
  }

  do.call(rbind, lapply(c("Unstratified", "Females", "Males"), build_rows))
}

# ---- render a table to a white-background PNG -------------------------------
save_table_png <- function(tab, path) {
  ft <- flextable(tab)
  ft <- set_header_labels(ft,
    Stratum = "", Row = "",
    c_n = "n", c_fem = "Female", c_male = "Male", c_med = "Median survival (weeks)",
    t_n = "n", t_fem = "Female", t_male = "Male",
    t_ctrl = "Control", t_trt = "Treatment", t_med = "Median survival (weeks)"
  )
  ft <- add_header_row(ft, values = c("", "", "Controls", "Treated"), colwidths = c(1, 1, 4, 6))
  ft <- merge_v(ft, j = "Stratum")
  ft <- theme_booktabs(ft)
  ft <- align(ft, align = "center", part = "all")
  ft <- align(ft, j = c("Stratum", "Row"), align = "left", part = "body")
  ft <- bold(ft, part = "header")
  ft <- valign(ft, j = "Stratum", valign = "top", part = "body")
  ft <- fontsize(ft, size = 8, part = "all")
  ft <- autofit(ft)
  save_as_image(ft, path = path, res = 300)
  # flatten webshot2's transparent background onto white
  image_read(path) |> image_background("white") |> image_flatten() |> image_write(path)
  invisible(path)
}

# ---- build the table --------------------------------------------------------
tab_local <- build_table(SRC_LOCAL)

if (!dir.exists("output")) dir.create("output", recursive = TRUE)

save_table_png(tab_local, "output/itp_geno_demographics.png")
cat("wrote: output/itp_geno_demographics.png\n")

# ---- OPTIONAL: cell-by-cell comparison against a reference census set -------
# Only runs when ITP_GENO_REF_CENSUS points at a second set of censuses.
if (!is.na(SRC_REF) && nzchar(SRC_REF) && dir.exists(SRC_REF)) {
  tab_ref <- build_table(SRC_REF)
  save_table_png(tab_ref, "output/itp_geno_demographics_reference.png")
  cat("wrote: output/itp_geno_demographics_reference.png (from", SRC_REF, ")\n")

  stopifnot(identical(dim(tab_local), dim(tab_ref)))
  stopifnot(identical(tab_local[, c("Stratum", "Row")], tab_ref[, c("Stratum", "Row")]))
  val_cols <- setdiff(names(tab_local), c("Stratum", "Row"))

  diffs <- list()
  for (i in seq_len(nrow(tab_local))) {
    for (col in val_cols) {
      a <- tab_local[i, col]; b <- tab_ref[i, col]
      if (!identical(a, b)) {
        diffs[[length(diffs) + 1]] <- data.frame(
          Stratum = tab_local$Stratum[i], Row = tab_local$Row[i], Column = col,
          from_local = a, from_reference = b,
          stringsAsFactors = FALSE, check.names = FALSE
        )
      }
    }
  }

  cat("\n=== TABLE COMPARISON: this run  vs  reference census set ===\n")
  n_cells <- nrow(tab_local) * length(val_cols)
  if (length(diffs) == 0) {
    cat("IDENTICAL: all", n_cells, "cells match between the two runs.\n")
  } else {
    cmp <- do.call(rbind, diffs)
    write.csv(cmp, "output/itp_geno_demographics_comparison.csv", row.names = FALSE)
    cat(nrow(cmp), "of", n_cells, "cells differ between this run and the reference:\n\n")
    print(cmp, row.names = FALSE)
    cat("\nwrote: output/itp_geno_demographics_comparison.csv\n")
  }
} else {
  cat("\nITP_GENO_REF_CENSUS not set (or missing) -- skipping the run-vs-run comparison.\n")
}
