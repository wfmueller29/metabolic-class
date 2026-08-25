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
rapa_n <- local({
  p <- read.csv(file.path(cen, "itp_controls_p_treatment/test_census.csv"))
  t <- read.csv("../00a_itp2/output/itp_tx_control_test.csv")[, c("idno", "tx")]
  m <- merge(t[!duplicated(t$idno), ], p, by = "idno")
  table(m$tx[m$le_wk > 86])
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
  data.frame(Group = "ITP", Description = "2005 cohort, treated + control (classified)",
             n = n_ids("../00a_itp2/output/itp_tx_control_test.csv"),
             Source = "00a_itp2/output/itp_tx_control_test.csv"),
  data.frame(Group = "ITP", Description = "2005 cohort analyzed, control (Figures 5E-5I)",
             n = rapa_n["control"],
             Source = "test_census + tx, le_wk > 86 (treatment_response.Rmd:62)"),
  data.frame(Group = "ITP", Description = "2005 cohort analyzed, rapamycin (Figures 5E-5I)",
             n = rapa_n["rapa"],
             Source = "test_census + tx, le_wk > 86 (treatment_response.Rmd:62)"),
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
             Source = "combined - control")
)

# The four strata partition the complete census, so assert it rather than trust
# it: if a config is ever refit, this catches a stratum drifting out of step.
stopifnot(sum(sizes$n[sizes$Group == "Sex x background"]) ==
            sizes$n[sizes$Description == "Complete (died of natural causes; modeled)"])

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
