# =============================================================================
# similarity_table.R
# -----------------------------------------------------------------------------
# Reviewer comment #15: describe the similarity between BW trajectory classes
# across datasets WITHOUT formally fitting ITP onto the SLAM equations.
#
# This builds a single comparison table of the BW trajectory classes across:
#   - SLAM (all)   : C57BL/6J (B6) + UM-HET3, both sexes
#   - SLAM (HET3)  : UM-HET3 only, both sexes
#   - ITP  (HET3)  : UM-HET3 only (ITP is HET3-only), both sexes
#
# For each dataset it reports, per BW class and overall: N (%), Female (%),
# and median life expectancy (MLE) with 95% CI — the same descriptive stats
# used elsewhere in the paper.
#
# Data source: the pipeline census CSVs (no model refitting, no posteriors).
#
# RUN FROM INSIDE THIS FOLDER (paths are relative, like 90_overlap_analysis):
#   cd 100_similarity_slam_itp
#   Rscript similarity_table.R
#
# Outputs (written here):
#   similarity_table.csv   <- always written
#   similarity_table.png   <- written if webshot2/Chrome is available
# =============================================================================

library(survival)
library(survminer)
library(flextable)
library(magrittr)

# ---- config -----------------------------------------------------------------

datasets <- list(
  list(key = "d1", label = "SLAM (all)",  tag = "slam_c1-c10_age_all_bwfatgluc"),
  list(key = "d2", label = "SLAM (HET3)", tag = "slam_c1-c10_age_het3_bwfatgluc"),
  list(key = "d3", label = "ITP (HET3)",  tag = "itp_c10c11c13c16_age_controls_bw")
)

# Resolve paths so this works whether run from INSIDE 100_similarity_slam_itp/
# (Rscript / cd here / source(..., chdir = TRUE)) OR sourced from the repo root.
.base <- if (dir.exists("../04_create_census")) ".." else
         if (dir.exists("04_create_census")) "." else
         stop("Cannot find 04_create_census/. Run from the repo root or from 100_similarity_slam_itp/.")
# where to write outputs: the folder itself, wherever we were launched from
.out <- if (.base == "..") "." else "100_similarity_slam_itp"

census_file <- function(tag) {
  file.path(.base, "04_create_census", "output", tag, "complete_census.csv")
}

# Row labels for BW classes. The pipeline renames classes by peak, so for the
# 3-class runs 1/2/3 == Early-peak/Stable/Late-peak. NOTE: SLAM (HET3) resolves
# into 4 BW classes, so its class<->peak mapping is NOT guaranteed to match the
# 3-class runs. VERIFY the peak assignment for each run (e.g. from its trajectory
# plot) before trusting these labels, and edit this map as needed.
class_labels <- c(
  "1" = "Class 1 (Early-peak)",
  "2" = "Class 2 (Stable)",
  "3" = "Class 3 (Late-peak)",
  "4" = "Class 4"
)

# ---- helpers ----------------------------------------------------------------

# robust female count (dummy col may be numeric 0/1 or character)
n_female <- function(df) sum(as.numeric(as.character(df$sex_F)) == 1, na.rm = TRUE)

pct <- function(x, denom) if (denom == 0) NA_real_ else 100 * x / denom

# median life expectancy + 95% CI from a Surv fit, formatted "med (lo, hi)"
mle_str <- function(df) {
  if (nrow(df) == 0) return("—")
  fit <- survival::survfit(survival::Surv(le_wk, dead_censor) ~ 1, data = df)
  tab <- summary(fit)$table
  g <- function(nm) if (nm %in% names(tab)) unname(tab[nm]) else NA_real_
  f <- function(x) if (is.na(x)) "NA" else format(round(x), nsmall = 0)
  sprintf("%s (%s, %s)", f(g("median")), f(g("0.95LCL")), f(g("0.95UCL")))
}

# summarize one census into rows keyed by "Overall" + each class number present
summarize_ds <- function(cen, all_classes) {
  cen <- cen[!is.na(cen$new_class_bw), ]
  total_n <- nrow(cen)

  make_row <- function(sub, is_overall = FALSE) {
    n <- nrow(sub)
    nf <- n_female(sub)
    n_txt <- if (is_overall) sprintf("%d (100%%)", n)
             else sprintf("%d (%.1f%%)", n, pct(n, total_n))
    c(
      N      = n_txt,
      Female = sprintf("%d (%.0f%%)", nf, pct(nf, n)),
      MLE    = mle_str(sub)
    )
  }

  rows <- list(Overall = make_row(cen, is_overall = TRUE))
  for (k in all_classes) {
    sub <- cen[cen$new_class_bw == k, ]
    rows[[as.character(k)]] <-
      if (nrow(sub) == 0) c(N = "—", Female = "—", MLE = "—")
      else make_row(sub)
  }
  rows
}

# ---- load censuses ----------------------------------------------------------

censuses <- lapply(datasets, function(d) {
  f <- census_file(d$tag)
  if (!file.exists(f)) stop("Missing census for '", d$label, "': ", f)
  read.csv(f)
})
names(censuses) <- vapply(datasets, `[[`, "", "key")

# union of BW class numbers across all datasets (sorted)
all_classes <- sort(unique(unlist(lapply(censuses, function(c) {
  c$new_class_bw[!is.na(c$new_class_bw)]
}))))

cat("BW classes present per dataset:\n")
for (d in datasets) {
  cl <- sort(unique(censuses[[d$key]]$new_class_bw))
  cat(sprintf("  %-13s: %s  (n = %d)\n", d$label,
              paste(cl, collapse = ", "), nrow(censuses[[d$key]])))
}
cat("\n")

# ---- assemble the wide comparison data frame --------------------------------

row_keys <- c("Overall", as.character(all_classes))
row_names_out <- c("Overall", vapply(as.character(all_classes), function(k) {
  if (k %in% names(class_labels)) class_labels[[k]] else paste("Class", k)
}, ""))

comp <- data.frame(Class = row_names_out, stringsAsFactors = FALSE, check.names = FALSE)

for (d in datasets) {
  rows <- summarize_ds(censuses[[d$key]], all_classes)
  mat <- t(sapply(row_keys, function(rk) rows[[rk]]))  # rows x c(N,Female,MLE)
  comp[[paste0(d$key, "_N")]]   <- mat[, "N"]
  comp[[paste0(d$key, "_F")]]   <- mat[, "Female"]
  comp[[paste0(d$key, "_MLE")]] <- mat[, "MLE"]
}

cat("Comparison table:\n")
print(comp, row.names = FALSE)

# ---- write CSV (always) -----------------------------------------------------

write.csv(comp, file.path(.out, "similarity_table.csv"), row.names = FALSE)
cat("\nWrote similarity_table.csv\n")

# ---- build a nicely-formatted flextable with a spanning header --------------

stat_labels <- setNames(
  rep(c("N (%)", "Female (%)", "MLE (95% CI)"), times = length(datasets)),
  unlist(lapply(datasets, function(d) paste0(d$key, c("_N", "_F", "_MLE"))))
)

ft <- flextable(comp) %>%
  set_header_labels(values = c(list(Class = "BW Class"), as.list(stat_labels))) %>%
  add_header_row(
    top = TRUE,
    values = c("", vapply(datasets, `[[`, "", "label")),
    colwidths = c(1, rep(3, length(datasets)))
  ) %>%
  theme_booktabs() %>%
  merge_v(part = "header") %>%
  align(align = "center", part = "all") %>%
  align(j = "Class", align = "left", part = "all") %>%
  bold(part = "header") %>%
  autofit() %>%
  set_caption(paste0(
    "BW trajectory classes across datasets (descriptive comparison; ",
    "no cross-dataset model fitting). MLE = median life expectancy (weeks)."
  ))

# preview object (in RStudio) and try to save a PNG
print(ft)

ok <- tryCatch({
  save_as_image(ft, path = file.path(.out, "similarity_table.png"))
  TRUE
}, error = function(e) {
  message("Could not save PNG (needs webshot2 + Chrome): ", conditionMessage(e))
  FALSE
})
if (isTRUE(ok) || file.exists("similarity_table.png")) {
  cat("Wrote similarity_table.png\n")
}

# =============================================================================
# Overall-only mini comparison (high-level lead-in table)
# One row per dataset: total N, Female (%), and MLE (95% CI) — no class
# breakdown. Useful to open the reviewer response with a general comparison
# of cohorts/lifespans before getting into class alignment. Denominator matches
# the "Overall" row of the class table above (mice with a BW class assignment).
# =============================================================================

overall <- data.frame(
  Dataset = vapply(datasets, `[[`, "", "label"),
  N = NA_character_, Female = NA_character_, MLE = NA_character_,
  stringsAsFactors = FALSE, check.names = FALSE
)

for (i in seq_along(datasets)) {
  cen <- censuses[[datasets[[i]]$key]]
  cen <- cen[!is.na(cen$new_class_bw), ]
  n <- nrow(cen)
  nf <- n_female(cen)
  overall$N[i]      <- sprintf("%d", n)
  overall$Female[i] <- sprintf("%d (%.0f%%)", nf, pct(nf, n))
  overall$MLE[i]    <- mle_str(cen)
}

cat("\nOverall cohort comparison:\n")
print(overall, row.names = FALSE)

write.csv(overall, file.path(.out, "similarity_overall.csv"), row.names = FALSE)
cat("Wrote similarity_overall.csv\n")

ft_overall <- flextable(overall) %>%
  set_header_labels(
    Dataset = "Dataset", N = "N", Female = "Female (%)", MLE = "MLE (95% CI)"
  ) %>%
  theme_booktabs() %>%
  align(align = "center", part = "all") %>%
  align(j = "Dataset", align = "left", part = "all") %>%
  bold(part = "header") %>%
  autofit() %>%
  set_caption(
    "Overall cohort comparison: sample size, sex, and median life expectancy (weeks)."
  )

print(ft_overall)

ok2 <- tryCatch({
  save_as_image(ft_overall, path = file.path(.out, "similarity_overall.png"))
  TRUE
}, error = function(e) {
  message("Could not save overall PNG (needs webshot2 + Chrome): ", conditionMessage(e))
  FALSE
})
if (isTRUE(ok2) || file.exists("similarity_overall.png")) {
  cat("Wrote similarity_overall.png\n")
}
