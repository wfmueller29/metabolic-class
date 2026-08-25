# Sample sizes quoted in the manuscript, each traced to the file it comes from.

library(flextable)
library(magrittr)
library(magick)
library(knitr)

n_rows <- function(path) nrow(read.csv(path))

n_ids <- function(path, col = "idno") length(unique(read.csv(path)[[col]]))

n_union <- function(paths, col = "idno")
  length(unique(unlist(lapply(paths, function(p) read.csv(p)[[col]]))))

n_cohorts <- function(path, lo, hi) {
  d <- read.csv(path)
  sum(d$cohort >= lo & d$cohort <= hi)
}

surv <- "../00a_clean_slam_c16-c18/data/Survival_2025-02-14.csv"

# 2,145 is not stored in any output file -- it falls out partway through the 00a
# cleaning chain. Rather than hardcode it, run that chain up to the drop of rows
# with a missing date or idno. Read-only; nothing upstream is modified.
#
# The 36 this implies are NOT the mice in the manuscript's Missing/Excluded data
# section. These 36 are cohort-5 animals enrolled but never measured (zero rows
# in the BW and NMR files). The Methods describe a later complete-case exclusion
# of 13+9+14 mice that DID have data (150 measures). Both totals are 36; that is
# a coincidence. The 13/9/14 split is not reproducible from the pipeline.
eligible <- local({
  f <- tempfile(fileext = ".R")
  knitr::purl("../00a_clean_slam_c1-c10/traj_dataset.Rmd", output = f, quiet = TRUE)
  code <- readLines(f)
  upto <- grep("main_all <- main_all[!na_index, ]", code, fixed = TRUE)[1]
  wd <- setwd("../00a_clean_slam_c1-c10")
  on.exit(setwd(wd))
  e <- new.env()
  invisible(capture.output(suppressWarnings(suppressMessages(
    eval(parse(text = code[seq_len(upto)]), envir = e)
  ))))
  length(unique(e$main_all$idno))
})
cen  <- "../04_create_census/output"
raw  <- "../00b_dataset_mods/output/slam_c1-c10/data"

# Class sizes. Censuses are one row per mouse, but dedupe on idno anyway so this
# stays correct if a long-format census is ever passed in.
n_class <- function(path, col) {
  d <- read.csv(path)
  d <- d[!duplicated(d$idno), ]
  d <- d[!is.na(d[[col]]) & d[[col]] != "", ]
  table(d[[col]])
}

# ---- CANONICAL CENSUS GUARD -------------------------------------------------
# There are TWO all-outcome C1-10 censuses and they are easy to confuse:
#
#   slam_c1-c10_age_all_bwfatgluc    <- CANONICAL; every n in the manuscript
#   slam_c1-c10_lnage_all_bwfatgluc  <- log-age sensitivity fit
#
# Both contain 1,315 mice. Their BW classes are identical (124/598/593) and so
# are their FM classes (358/408/549). They diverge on FBG ALONE:
#
#   _age_    Class 7 = 145, Class 8 = 1,170   <- quoted in the Results
#   _lnage_  Class 7 = 136, Class 8 = 1,179
#
# Neither the filename nor the row count distinguishes them, so reading the wrong
# one raises a false mismatch against a published number. That happened during
# the 2026-08-25 audit. Assert the canonical FBG split rather than trusting the
# path, and print both so the divergence stays visible to whoever runs this.
census_all <- file.path(cen, "slam_c1-c10_age_all_bwfatgluc/complete_census.csv")

bw_cls  <- n_class(census_all, "new_class_bw")
fm_cls  <- n_class(census_all, "new_class_fat")
fbg_cls <- n_class(census_all, "new_class_gluc")

stopifnot(
  identical(as.integer(bw_cls[c("1", "2", "3")]), c(124L, 598L, 593L)),
  identical(as.integer(fm_cls[c("4", "5", "6")]), c(358L, 408L, 549L)),
  identical(as.integer(fbg_cls[c("7", "8")]),     c(145L, 1170L))
)

local({
  ln <- file.path(cen, "slam_c1-c10_lnage_all_bwfatgluc/complete_census.csv")
  if (file.exists(ln)) {
    l <- n_class(ln, "new_class_gluc")
    message(sprintf(
      "canonical census check: _age_ FBG = %s/%s (used) | _lnage_ FBG = %s/%s (NOT used)",
      fbg_cls[["7"]], fbg_cls[["8"]], l[["7"]], l[["8"]]))
  }
})

# ITP LCM classes (Figure 5B-5D, Table 2) and the C2005 classes that Figures
# 5E-5K are split on.
itp_cls <- n_class(file.path(cen, "itp_c10c11c13c16_age_controls_bw/complete_census.csv"),
                   "new_class_bw")

# Figures 2 and S4 are built from four sex x genetic-background configs, not from
# the pooled one. Each config directory also holds train/test censuses, so the
# complete one is named explicitly -- stage 07 draws its outcome plots from
# combined_census[[1]], which is the complete census.
strat <- function(s)
  file.path(cen, sprintf("slam_c1-c10_age_%s_bwfatgluc/complete_census.csv", s))

# Figures 5E-5I are NOT the whole 2005 cohort. treatment_response.Rmd:62 keeps
# only mice alive past 86 weeks -- rapamycin feeding began at 600 days (~85.7
# wk), so this is a survival landmark. Replicated here rather than hardcoded;
# 97 is not sourced because rendering it is expensive and this is three lines.
#
# Returns the tx split, the BW-class split, and the evaluable total, because the
# manuscript quotes all three: n = 755 overall, 503/252 by treatment, and the
# nonresponder group (Classes 1 + 3 = 85) used in Figures 5H-5K.
rapa <- local({
  p <- read.csv(file.path(cen, "itp_controls_p_treatment/test_census.csv"))
  t <- read.csv("../00a_itp2/output/itp_tx_control_test.csv")[, c("idno", "tx")]
  m <- merge(t[!duplicated(t$idno), ], p, by = "idno")
  m <- m[m$le_wk > 86, ]
  list(tx = table(m$tx), cls = table(m$new_class_bw), n = nrow(m))
})

sizes <- rbind(
  data.frame(Group = "SLAM C1-10",
             Description = "Enrolled",
             n = n_cohorts(surv, 1, 10),
             Source = "00a_clean_slam_c16-c18/data/Survival_2025-02-14.csv"),
  data.frame(Group = "SLAM C1-10",
             Description = "Excluded: enrolled but never measured",
             n = n_cohorts(surv, 1, 10) - eligible,
             Source = "enrolled - eligible; all 36 are cohort-5 mice with no measurements"),
  data.frame(Group = "SLAM C1-10", Description = "Eligible (enrolled - excluded)",
             n = eligible,
             Source = "00a traj_dataset.Rmd, after dropping rows with missing date/idno"),
  data.frame(Group = "SLAM C1-10", Description = "Complete (died of natural causes; modeled)",
             n = n_rows(file.path(cen, "slam_c1-c10_age_all_bwfatgluc/complete_census.csv")),
             Source = "04_create_census/.../slam_c1-c10_age_all_bwfatgluc/complete_census.csv"),
  data.frame(Group = "SLAM C1-10", Description = "Training (80% split)",
             n = n_rows(file.path(cen, "slam_c1-c10_age_all_bwfatgluc/train_census.csv")),
             Source = "04_create_census/.../slam_c1-c10_age_all_bwfatgluc/train_census.csv"),
  data.frame(Group = "SLAM C1-10", Description = "Testing (20% split)",
             n = n_rows(file.path(cen, "slam_c1-c10_age_all_bwfatgluc/test_census.csv")),
             Source = "04_create_census/.../slam_c1-c10_age_all_bwfatgluc/test_census.csv"),
  data.frame(Group = "SLAM C1-10", Description = "Adiposity model",
             n = n_rows(file.path(cen, "slam_c1-c10_age_all_bwadipositygluc/complete_census.csv")),
             Source = "04_create_census/.../slam_c1-c10_age_all_bwadipositygluc/complete_census.csv"),

  # Trajectory class sizes quoted in the Results. All three sets partition the
  # complete census; asserted below.
  data.frame(Group = "SLAM classes", Description = "BW Class 1 (early-peak-BW)",
             n = bw_cls[["1"]], Source = "new_class_bw, canonical _age_ census"),
  data.frame(Group = "SLAM classes", Description = "BW Class 2 (stable-BW)",
             n = bw_cls[["2"]], Source = "new_class_bw, canonical _age_ census"),
  data.frame(Group = "SLAM classes", Description = "BW Class 3 (late-peak-BW)",
             n = bw_cls[["3"]], Source = "new_class_bw, canonical _age_ census"),
  data.frame(Group = "SLAM classes", Description = "FM Class 4 (early-peak-FM)",
             n = fm_cls[["4"]], Source = "new_class_fat, canonical _age_ census"),
  data.frame(Group = "SLAM classes", Description = "FM Class 5 (stable-FM)",
             n = fm_cls[["5"]], Source = "new_class_fat, canonical _age_ census"),
  data.frame(Group = "SLAM classes", Description = "FM Class 6 (late-peak-FM)",
             n = fm_cls[["6"]], Source = "new_class_fat, canonical _age_ census"),
  data.frame(Group = "SLAM classes", Description = "FBG Class 7 (decline-FBG)",
             n = fbg_cls[["7"]], Source = "new_class_gluc, canonical _age_ census (NOT _lnage_)"),
  data.frame(Group = "SLAM classes", Description = "FBG Class 8 (stable-FBG)",
             n = fbg_cls[["8"]], Source = "new_class_gluc, canonical _age_ census (NOT _lnage_)"),

  data.frame(Group = "Sex x background", Description = "Female B6",
             n = n_rows(strat("fb6")),
             Source = "04_create_census/.../slam_c1-c10_age_fb6_bwfatgluc/complete_census.csv"),
  data.frame(Group = "Sex x background", Description = "Male B6",
             n = n_rows(strat("mb6")),
             Source = "04_create_census/.../slam_c1-c10_age_mb6_bwfatgluc/complete_census.csv"),
  data.frame(Group = "Sex x background", Description = "Female HET3",
             n = n_rows(strat("fhet3")),
             Source = "04_create_census/.../slam_c1-c10_age_fhet3_bwfatgluc/complete_census.csv"),
  data.frame(Group = "Sex x background", Description = "Male HET3",
             n = n_rows(strat("mhet3")),
             Source = "04_create_census/.../slam_c1-c10_age_mhet3_bwfatgluc/complete_census.csv"),

  data.frame(Group = "SLAM C16-18", Description = "Enrolled",
             n = n_cohorts(surv, 16, 18),
             Source = "00a_clean_slam_c16-c18/data/Survival_2025-02-14.csv"),
  data.frame(Group = "SLAM C16-18", Description = "With usable BW measurements",
             n = n_ids("../00b_dataset_mods/output/slam_c16-c18/data/slam_c16-c18_bw_og.csv"),
             Source = "00b_dataset_mods/output/slam_c16-c18/data/slam_c16-c18_bw_og.csv"),
  data.frame(Group = "SLAM C16-18", Description = "Held-out (used for external validation)",
             n = n_rows(file.path(cen, "slam_c1-10_x_slam_c16-18_age_bwfatgluc/test_census.csv")),
             Source = "04_create_census/.../slam_c1-10_x_slam_c16-18_age_bwfatgluc/test_census.csv"),

  data.frame(Group = "Joint models", Description = "BW",
             n = n_ids(file.path(raw, "slam_bw_og.csv")),
             Source = "00b_dataset_mods/output/slam_c1-c10/data/slam_bw_og.csv"),
  data.frame(Group = "Joint models", Description = "FM",
             n = n_ids(file.path(raw, "slam_fat_og.csv")),
             Source = "00b_dataset_mods/output/slam_c1-c10/data/slam_fat_og.csv"),
  data.frame(Group = "Joint models", Description = "FBG",
             n = n_ids(file.path(raw, "slam_gluc_og.csv")),
             Source = "00b_dataset_mods/output/slam_c1-c10/data/slam_gluc_og.csv"),
  data.frame(Group = "Joint models", Description = "Adiposity (fit, not shown)",
             n = n_ids(file.path(raw, "slam_adiposity_og.csv")),
             Source = "00b_dataset_mods/output/slam_c1-c10/data/slam_adiposity_og.csv"),
  data.frame(Group = "Joint models", Description = "Total unique mice (any joint model)",
             n = n_union(file.path(raw, paste0("slam_", c("bw", "fat", "gluc", "adiposity"), "_og.csv"))),
             Source = "union of the four files above"),

  # Controls ONLY, despite the survival lookup for this config being
  # itp_tx_control_surv.csv (3,412 tx + control). Membership is set by the
  # trajectory input, itp_control_train.csv -- 2,240 mice, a 100% match to this
  # census. Feeds Figures 5A-5D and Table 2.
  data.frame(Group = "ITP", Description = "Controls, C2010/C2011/C2013/C2016 (LCM fit)",
             n = n_rows(file.path(cen, "itp_c10c11c13c16_age_controls_bw/complete_census.csv")),
             Source = "04_create_census/.../itp_c10c11c13c16_age_controls_bw/complete_census.csv"),
  # ITP LCM classes (Figures 5B-5D, Table 2). Partition the 2,240 controls.
  data.frame(Group = "ITP classes", Description = "ITP Class 1 (early-peak-BW)",
             n = itp_cls[["1"]], Source = "new_class_bw, itp_c10c11c13c16 census"),
  data.frame(Group = "ITP classes", Description = "ITP Class 2 (stable-BW)",
             n = itp_cls[["2"]], Source = "new_class_bw, itp_c10c11c13c16 census"),
  data.frame(Group = "ITP classes", Description = "ITP Class 3 (late-peak-BW)",
             n = itp_cls[["3"]], Source = "new_class_bw, itp_c10c11c13c16 census"),

  data.frame(Group = "ITP", Description = "2005 cohort, treated + control (classified)",
             n = n_ids("../00a_itp2/output/itp_tx_control_test.csv"),
             Source = "00a_itp2/output/itp_tx_control_test.csv"),
  data.frame(Group = "ITP", Description = "2005 cohort analyzed, total (Figures 5E-5I)",
             n = rapa$n,
             Source = "test_census + tx, le_wk > 86 (treatment_response.Rmd:62)"),
  data.frame(Group = "ITP", Description = "2005 cohort analyzed, control (Figures 5E-5I)",
             n = rapa$tx[["control"]],
             Source = "test_census + tx, le_wk > 86 (treatment_response.Rmd:62)"),
  data.frame(Group = "ITP", Description = "2005 cohort analyzed, rapamycin (Figures 5E-5I)",
             n = rapa$tx[["rapa"]],
             Source = "test_census + tx, le_wk > 86 (treatment_response.Rmd:62)"),
  data.frame(Group = "ITP classes", Description = "C2005 Class 1 (early-peak-BW)",
             n = rapa$cls[["1"]], Source = "as above, split by new_class_bw"),
  data.frame(Group = "ITP classes", Description = "C2005 Class 2 (stable-BW)",
             n = rapa$cls[["2"]], Source = "as above, split by new_class_bw"),
  data.frame(Group = "ITP classes", Description = "C2005 Class 3 (late-peak-BW)",
             n = rapa$cls[["3"]], Source = "as above, split by new_class_bw"),
  data.frame(Group = "ITP classes", Description = "C2005 nonresponders (Classes 1 + 3; Figures 5H-5K)",
             n = rapa$cls[["1"]] + rapa$cls[["3"]],
             Source = "Classes 1 + 3 combined; the resampling target n"),
  # Figure S9. Note itp_genotyped_treat is the COMBINED control + treated set
  # (5,118), not treated-only -- the treated count the legend quotes is the
  # difference, which is why it is derived rather than read from a file.
  data.frame(Group = "ITP", Description = "Genotyped, control (Figure S9A)",
             n = n_rows(file.path(cen, "itp_genotyped/complete_census.csv")),
             Source = "04_create_census/.../itp_genotyped/complete_census.csv"),
  data.frame(Group = "ITP", Description = "Genotyped, control + treated (Figures S9B-S9D)",
             n = n_rows(file.path(cen, "itp_genotyped_treat/complete_census.csv")),
             Source = "04_create_census/.../itp_genotyped_treat/complete_census.csv"),
  data.frame(Group = "ITP", Description = "Genotyped, treated",
             n = n_rows(file.path(cen, "itp_genotyped_treat/complete_census.csv")) -
                 n_rows(file.path(cen, "itp_genotyped/complete_census.csv")),
             Source = "combined - control"),

  # The abstract quotes a single SLAM figure that appears in no census: the mice
  # carried through modelling plus those held back for external validation.
  # Derived here so the one composite number in the paper is also traceable.
  data.frame(Group = "Derived", Description = "Abstract SLAM total (complete + held-out)",
             n = n_rows(census_all) +
                 n_rows(file.path(cen, "slam_c1-10_x_slam_c16-18_age_bwfatgluc/test_census.csv")),
             Source = "complete (1,315) + held-out (502); quoted in the abstract")
)

# ---- INTERNAL CONSISTENCY ---------------------------------------------------
# Every partition in the table is asserted rather than trusted. If any config is
# refit, or a census path is edited, one of these fails loudly instead of the
# table silently reporting numbers that no longer add up to the published ones.
N <- function(d) sizes$n[sizes$Description == d]

complete <- N("Complete (died of natural causes; modeled)")

stopifnot(
  # the four sex x background strata partition the complete census
  sum(sizes$n[sizes$Group == "Sex x background"]) == complete,

  # each set of trajectory classes partitions the same 1,315 mice
  sum(bw_cls)  == complete,
  sum(fm_cls)  == complete,
  sum(fbg_cls) == complete,

  # train/test is an 80/20 split of the complete census, with nothing lost
  N("Training (80% split)") + N("Testing (20% split)") == complete,

  # ITP: the three LCM classes partition the 2,240 controls
  sum(itp_cls) == N("Controls, C2010/C2011/C2013/C2016 (LCM fit)"),

  # C2005: tx split and class split both reconstitute the evaluable total,
  # and the nonresponder group is exactly Classes 1 + 3
  N("2005 cohort analyzed, control (Figures 5E-5I)") +
    N("2005 cohort analyzed, rapamycin (Figures 5E-5I)") ==
      N("2005 cohort analyzed, total (Figures 5E-5I)"),
  sum(rapa$cls) == N("2005 cohort analyzed, total (Figures 5E-5I)"),
  N("C2005 nonresponders (Classes 1 + 3; Figures 5H-5K)") ==
    N("C2005 Class 1 (early-peak-BW)") + N("C2005 Class 3 (late-peak-BW)"),

  # the landmark can only ever remove mice from the classified 2005 cohort
  N("2005 cohort analyzed, total (Figures 5E-5I)") <=
    N("2005 cohort, treated + control (classified)"),

  # genotyped control + treated == the combined census it was derived from
  N("Genotyped, control (Figure S9A)") + N("Genotyped, treated") ==
    N("Genotyped, control + treated (Figures S9B-S9D)"),

  # the abstract composite is exactly complete + held-out
  N("Abstract SLAM total (complete + held-out)") ==
    complete + N("Held-out (used for external validation)")
)

sizes$n <- format(sizes$n, big.mark = ",", trim = TRUE)

options(width = 250)          # keep each row on one line for copy-paste
print(sizes, row.names = FALSE)

ft <- flextable(sizes) %>%
  theme_booktabs() %>%
  merge_v(j = "Group") %>%
  valign(j = "Group", valign = "top") %>%
  bold(j = "Group") %>%
  align(j = "n", align = "right", part = "all") %>%
  fontsize(j = "Source", size = 8) %>%
  bold(part = "header") %>%
  add_header_lines("Sample sizes and their sources") %>%
  align(i = 1, align = "center", part = "header") %>%
  bold(i = 1, part = "header") %>%
  autofit()

save_as_image(ft, path = "output/sample_sizes.png", res = 600)

# flextable writes a transparent background; composite onto white so it is legible.
image_read("output/sample_sizes.png") %>%
  image_background("white") %>%
  image_write("output/sample_sizes.png")
