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
# Cells that carry no value print an en dash, matching Table 1 in the paper
# (which uses "–" for the Total/p-value cells that do not apply). "NA" reads as
# missing data rather than not-applicable.
DASH <- "–"

r0 <- function(x) if (length(x) == 0 || is.na(x)) DASH else n0(round(x))
# Thousands separators on every count >= 1000, matching the manuscript
# convention. Applied at the point each integer becomes a string, NOT by a
# regex over the assembled cell -- a cell reads "2395 (46.8%)" and a naive
# 4-digit match would also hit the decimals of a p-value like "0.2593".
n0 <- function(k) if (length(k) == 0 || is.na(k)) DASH else formatC(k, format = "d", big.mark = ",")
cnt <- function(df, cls, mask) sum(df$new_class_bw == cls & mask)
pct <- function(k, tot) if (is.na(k) || is.na(tot) || tot == 0) "" else sprintf(" (%.1f%%)", 100 * k / tot)
# Scientific notation only where it earns its keep. Forcing it on every p-value
# turned 0.1791 into "1.79e-01", which is harder to read and disagrees with the
# convention stated on S1G ("p-values < 0.001 are written in scientific
# notation"). Below that cutoff keep the exponent; at or above it, plain digits.
fmt_p <- function(p) {
  if (length(p) == 0 || is.na(p)) return(DASH)
  # digits = 1: one decimal in the mantissa, matching S1G and S3C. The S9
  # legend states only the 0.001 threshold and makes no rounding claim.
  if (p < 0.001) formatC(p, format = "e", digits = 1) else formatC(p, format = "g", digits = 4)
}

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
        c_n    = if (pc) paste0(n0(cn), pct(cn, cN)) else DASH,
        c_fem  = if (has_sex) (if (pc) paste0(n0(cf), pct(cf, c_f_tot)) else DASH) else "",
        c_male = if (has_sex) (if (pc) paste0(n0(cm), pct(cm, c_m_tot)) else DASH) else "",
        c_med  = if (pc) c_med[as.character(cl)] else DASH,
        t_n    = if (pt) paste0(n0(tn), pct(tn, tN)) else DASH,
        t_fem  = if (has_sex) (if (pt) paste0(n0(tf), pct(tf, t_f_tot)) else DASH) else "",
        t_male = if (has_sex) (if (pt) paste0(n0(tm), pct(tm, t_m_tot)) else DASH) else "",
        t_ctrl = if (pt) paste0(n0(tc), pct(tc, t_ctrl_tot)) else DASH,
        t_trt  = if (pt) paste0(n0(tt), pct(tt, t_trt_tot)) else DASH,
        t_med  = if (pt) t_med[as.character(cl)] else DASH,
        stringsAsFactors = FALSE, check.names = FALSE
      )
    }

    # total row
    rows[[length(rows) + 1]] <- data.frame(
      Stratum = stratum, Row = "Total",
      c_n = n0(cN),
      c_fem = if (has_sex) n0(c_f_tot) else "",
      c_male = if (has_sex) n0(c_m_tot) else "",
      c_med = DASH, t_n = n0(tN),
      t_fem = if (has_sex) n0(t_f_tot) else "",
      t_male = if (has_sex) n0(t_m_tot) else "",
      t_ctrl = n0(t_ctrl_tot), t_trt = n0(t_trt_tot), t_med = DASH,
      stringsAsFactors = FALSE, check.names = FALSE
    )

    # pval row: chi-square class x sex (each section) and class x tx (treated)
    chi_sex_c <- if (has_sex) suppressWarnings(chisq.test(table(c_df$new_class_bw, c_df$sex_F))$p.value) else NA
    chi_sex_t <- if (has_sex) suppressWarnings(chisq.test(table(t_df$new_class_bw, t_df$sex_F))$p.value) else NA
    chi_tx_t  <- if (length(unique(t_df$new_class_bw)) > 1) suppressWarnings(chisq.test(table(t_df$new_class_bw, t_df$tx))$p.value) else NA
    rows[[length(rows) + 1]] <- data.frame(
      Stratum = stratum, Row = "p-value",
      c_n = DASH,
      c_fem = if (has_sex) fmt_p(chi_sex_c) else "",
      c_male = if (has_sex) fmt_p(chi_sex_c) else "",
      c_med = DASH, t_n = DASH,
      t_fem = if (has_sex) fmt_p(chi_sex_t) else "",
      t_male = if (has_sex) fmt_p(chi_sex_t) else "",
      t_ctrl = fmt_p(chi_tx_t), t_trt = fmt_p(chi_tx_t), t_med = DASH,
      stringsAsFactors = FALSE, check.names = FALSE
    )

    do.call(rbind, rows)
  }

  do.call(rbind, lapply(c("Unstratified", "Females", "Males"), build_rows))
}

# ---- render a table to a white-background PNG -------------------------------
save_table_png <- function(tab, path) {
  ft <- flextable(tab)
  # "Median Survival, weeks" -- NOT the plain "Median Survival" used by
  # Tables 1/2. Those carry the unit and the CI level in footnotes a and b, but
  # this panel is composited into S9 and its footnotes are dropped, so the header
  # is the only channel. Stating (95% CI) also stops the header's parenthetical
  # reading as a unit when the cells below use parentheses for the interval.
  ft <- set_header_labels(ft,
    Stratum = "", Row = "",
    c_n = "n (%)", c_fem = "Female", c_male = "Male", c_med = "Median Survival, weeks",
    t_n = "n (%)", t_fem = "Female", t_male = "Male",
    t_ctrl = "Control", t_trt = "Treatment", t_med = "Median Survival, weeks"
  )
  # Second block comes from the *_tx_* censuses, which contain controls AND
  # NDE-treated mice (n = 5118 = 2395 control + 2723 treatment -- hence the
  # Control/Treatment split columns). "Treated" alone would contradict the
  # legend and the n = 2,723 stated there.
  ft <- add_header_row(ft, values = c("", "", "Controls", "Controls + Treated"), colwidths = c(1, 1, 4, 6))
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
