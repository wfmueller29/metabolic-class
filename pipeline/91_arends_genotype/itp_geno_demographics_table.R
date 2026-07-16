# Recreate the ITP-genotype class demographics table (the "panel C" / S9C figure)
# by recomputing all six blocks from the census objects and assembling them.
# Controls section (n / Female / Male / Median survival) from the three control
# censuses; Treated section (n / Female / Male / Control / Treatment / Median
# survival) from the three treatment censuses. Chi-square p-values: class x sex
# and class x treatment.
#
# This script builds the figure from the LOCAL 91_arends_genotype censuses (the
# data this analysis is supposed to use) and ALSO rebuilds the same table from
# the Downloads set (the run that produced the published S9C), then compares the
# two assembled tables cell-by-cell in code -- so the drift between the two runs
# is visible directly, without eyeballing PNGs.
#
# Outputs (in output/):
#   itp_geno_demographics.png            <- built from the 91 data (this figure)
#   itp_geno_demographics_downloads.png  <- built from the Downloads data (S9C)
#   itp_geno_demographics_comparison.csv <- the cell-by-cell differences

library(survival)
library(flextable)
library(magick)

setwd("/Users/JoshsMacbook2015/Desktop/Repos/Manuscripts/Submitted/metabolic-class/91_arends_genotype")

# ---- the two census sources -------------------------------------------------
SRC_91 <- "."                                        # local 91 copies -> this figure
SRC_DL <- "/Users/JoshsMacbook2015/Downloads/output" # the run that made published S9C

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

# ---- build both tables ------------------------------------------------------
tab_91 <- build_table(SRC_91)
tab_dl <- build_table(SRC_DL)

if (!dir.exists("output")) dir.create("output", recursive = TRUE)

# primary figure = the 91 data; also render the Downloads (S9C) version
save_table_png(tab_91, "output/itp_geno_demographics.png")
save_table_png(tab_dl, "output/itp_geno_demographics_downloads.png")
cat("wrote: output/itp_geno_demographics.png (91 data)\n")
cat("wrote: output/itp_geno_demographics_downloads.png (Downloads/S9C data)\n")

# ---- cell-by-cell comparison of the two assembled tables --------------------
stopifnot(identical(dim(tab_91), dim(tab_dl)))
stopifnot(identical(tab_91[, c("Stratum", "Row")], tab_dl[, c("Stratum", "Row")]))
val_cols <- setdiff(names(tab_91), c("Stratum", "Row"))

diffs <- list()
for (i in seq_len(nrow(tab_91))) {
  for (col in val_cols) {
    a <- tab_91[i, col]; b <- tab_dl[i, col]
    if (!identical(a, b)) {
      diffs[[length(diffs) + 1]] <- data.frame(
        Stratum = tab_91$Stratum[i], Row = tab_91$Row[i], Column = col,
        from_91 = a, from_downloads = b,
        stringsAsFactors = FALSE, check.names = FALSE
      )
    }
  }
}

cat("\n=== TABLE COMPARISON: 91 data  vs  Downloads (S9C) data ===\n")
n_cells <- nrow(tab_91) * length(val_cols)
if (length(diffs) == 0) {
  cat("IDENTICAL: all", n_cells, "cells match between the two runs.\n")
} else {
  cmp <- do.call(rbind, diffs)
  write.csv(cmp, "output/itp_geno_demographics_comparison.csv", row.names = FALSE)
  cat(nrow(cmp), "of", n_cells, "cells differ between the 91 run and the Downloads (S9C) run:\n\n")
  print(cmp, row.names = FALSE)
  cat("\nwrote: output/itp_geno_demographics_comparison.csv\n")
}
