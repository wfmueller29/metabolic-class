# In this analysis we will investigate the overlap between classes
# We will use the Rand index

library(consoler)
library(mclust)
library(flextable)
library(magrittr)
library(webshot2)
library(UpSetR)

# load data -------------------------------------------------------------------
# All figures from this stage go under output/, as in every other stage.
if (!dir.exists("output")) dir.create("output", recursive = TRUE)

# Complete C1-10 census (n = 1,315), NOT the 80% training split. This analysis is
# descriptive -- it asks how far three independently fitted class assignments
# agree -- so it fits nothing and predicts nothing, and the train/test split does
# no work here. Using the complete set also matches the Methods ("across all
# animals with complete class assignments") and the partial-correlation panels
# S3B/S3C, which read this same file. C16-18 are excluded either way.
#
# CAUTION on the file names: "train_census.csv" means different things per config.
# Here (internal) it is an 80% SAMPLE WITHIN C1-10 -- 1,056 of 1,315, cohorts 1-10
# on both sides of the split. In the external config
# (slam_c1-10_x_slam_c16-18) "train" instead means ALL of C1-10 (1,315) with
# C16-18 held out as test. Same file name, different meaning -- this is also why
# Fig 4B ("Complete") and Fig S6H ("Training") render identical statistics.
census <- read.csv("../04_create_census/output/slam_c1-c10_age_all_bwfatgluc/complete_census.csv")


ari_bw_fat <- adjustedRandIndex(
  census$new_class_bw,
  census$new_class_fat
)

ari_bw_gluc <- adjustedRandIndex(
  census$new_class_bw,
  census$new_class_gluc
)

ari_fat_gluc <- adjustedRandIndex(
  census$new_class_fat,
  census$new_class_gluc
)

ari_bw_fat
ari_bw_gluc
ari_fat_gluc

# make pairwise matrix --------------------------------------------------------
class_df <- census[, c("new_class_bw", "new_class_fat", "new_class_gluc")]
class_df <- class_df[complete.cases(class_df), ]

ari_mat <- matrix(
  NA_real_,
  nrow = ncol(class_df),
  ncol = ncol(class_df),
  dimnames = list(names(class_df), names(class_df))
)

for (i in seq_along(class_df)) {
  for (j in seq_along(class_df)) {
    ari_mat[i, j] <- adjustedRandIndex(class_df[[i]], class_df[[j]])
  }
}

ari_mat


dimnames(ari_mat) <- list(
  c("BW Class", "FM Class", "FBG Class"),
  c("BW Class", "FM Class", "FBG Class")
)

# ari_mat should already exist from your ARI code
ari_df <- as.data.frame(round(ari_mat, 3))

# Add row names as first column
ari_df <- cbind(
  Comparison = rownames(ari_df),
  ari_df
)

# Make flextable
ari_ft <- flextable(ari_df) %>%
  theme_booktabs() %>%
  autofit() %>%
  align(align = "center", part = "all") %>%
  align(j = "Comparison", align = "left", part = "all") %>%
  bold(part = "header") %>%
  # NOTE: save_as_image() DROPS flextable captions -- verified against the
  # rendered PNGs (this table and the one at ~189 both export titleless despite
  # having captions here). So this string never reaches S3D. The visible "Rand
  # Index, All Classes" title in the composite deck is typeset by the figure
  # maintainer, and revision card 3 is a composite-level instruction, not a code
  # one. Kept short and correct for any future HTML/docx render of this table;
  # do not "fix" S3D's title here, it will have no effect.
  set_caption("Rand Index, All Classes")

# Preview in RStudio Viewer
ari_ft

save_as_image(
  ari_ft,
  path = "output/ari_matrix.png",
  # res = 600 to match the HR table below and the table exports in 99.
  # Without it flextable defaults to 200, which put S3D at 831 px -- ~119 dpi
  # at full column width, below the 300 dpi floor for a submitted panel.
  res = 600
)

# redo analysis comparing just high risk to non-high risk groups
# NOTE: Class 1, 4, and 7 are the high risk groups

census_risk <- census
census_risk$bw_high_risk <- ifelse(census_risk$new_class_bw == 1, 1, 0)
census_risk$fat_high_risk <- ifelse(census_risk$new_class_fat == 4, 1, 0)
census_risk$gluc_high_risk <- ifelse(census_risk$new_class_gluc == 7, 1, 0)

# Single shared analysis frame (identity by construction): drop any mouse missing
# one of the three high-risk indicators, so EVERY downstream summary — the ARI /
# Jaccard matrices, the UpSet plot, and the burden KM — is guaranteed to use the
# exact same set of mice. Verified a no-op on the current data (0 rows dropped)
# by .A/diagnose.R.
hr_cols <- c("bw_high_risk", "fat_high_risk", "gluc_high_risk")
census_risk <- census_risk[complete.cases(census_risk[, hr_cols]), ]

# Pairwise ARI values ----------------------------------------------------------

ari_bw_fat_risk <- adjustedRandIndex(
  census_risk$bw_high_risk,
  census_risk$fat_high_risk
)

ari_bw_gluc_risk <- adjustedRandIndex(
  census_risk$bw_high_risk,
  census_risk$gluc_high_risk
)

ari_fat_gluc_risk <- adjustedRandIndex(
  census_risk$fat_high_risk,
  census_risk$gluc_high_risk
)

ari_bw_fat_risk
ari_bw_gluc_risk
ari_fat_gluc_risk


# Make pairwise matrix ---------------------------------------------------------

risk_df <- census_risk[, c(
  "bw_high_risk",
  "fat_high_risk",
  "gluc_high_risk"
)]

risk_df <- risk_df[complete.cases(risk_df), ]

ari_risk_mat <- matrix(
  NA_real_,
  nrow = ncol(risk_df),
  ncol = ncol(risk_df),
  dimnames = list(names(risk_df), names(risk_df))
)

for (i in seq_along(risk_df)) {
  for (j in seq_along(risk_df)) {
    ari_risk_mat[i, j] <- adjustedRandIndex(risk_df[[i]], risk_df[[j]])
  }
}

dimnames(ari_risk_mat) <- list(
  c("BW high-risk", "FM high-risk", "FBG high-risk"),
  c("BW high-risk", "FM high-risk", "FBG high-risk")
)

ari_risk_mat

# Make flextable ---------------------------------------------------------------

ari_risk_df <- as.data.frame(round(ari_risk_mat, 3))

ari_risk_df <- cbind(
  Comparison = rownames(ari_risk_df),
  ari_risk_df
)

ari_risk_ft <- flextable(ari_risk_df) %>%
  theme_booktabs() %>%
  autofit() %>%
  align(align = "center", part = "all") %>%
  align(j = "Comparison", align = "left", part = "all") %>%
  bold(part = "header") %>%
  set_caption("Adjusted Rand Index Between High-Risk Latent Class Assignments")

ari_risk_ft

save_as_image(
  ari_risk_ft,
  path = "output/ari_high_risk_matrix.png",
  # res = 600 to match the HR table below and the table exports in 99.
  # Without it flextable defaults to 200, which put S3D at 831 px -- ~119 dpi
  # at full column width, below the 300 dpi floor for a submitted panel.
  res = 600
)

# Jaccard index function -------------------------------------------------------

jaccard_index <- function(x, y) {
  both <- sum(x == 1 & y == 1, na.rm = TRUE)
  either <- sum(x == 1 | y == 1, na.rm = TRUE)

  if (either == 0) {
    return(NA_real_)
  }

  both / either
}


# Pairwise Jaccard values ------------------------------------------------------

jaccard_bw_fat_risk <- jaccard_index(
  census_risk$bw_high_risk,
  census_risk$fat_high_risk
)

jaccard_bw_gluc_risk <- jaccard_index(
  census_risk$bw_high_risk,
  census_risk$gluc_high_risk
)

jaccard_fat_gluc_risk <- jaccard_index(
  census_risk$fat_high_risk,
  census_risk$gluc_high_risk
)

jaccard_bw_fat_risk
jaccard_bw_gluc_risk
jaccard_fat_gluc_risk

# Make pairwise Jaccard matrix -------------------------------------------------

jaccard_risk_mat <- matrix(
  NA_real_,
  nrow = ncol(risk_df),
  ncol = ncol(risk_df),
  dimnames = list(names(risk_df), names(risk_df))
)

for (i in seq_along(risk_df)) {
  for (j in seq_along(risk_df)) {
    jaccard_risk_mat[i, j] <- jaccard_index(risk_df[[i]], risk_df[[j]])
  }
}

dimnames(jaccard_risk_mat) <- list(
  c("BW high-risk", "FM high-risk", "FBG high-risk"),
  c("BW high-risk", "FM high-risk", "FBG high-risk")
)

jaccard_risk_mat

# Make flextable ---------------------------------------------------------------

jaccard_risk_df <- as.data.frame(round(jaccard_risk_mat, 3))

jaccard_risk_df <- cbind(
  Comparison = rownames(jaccard_risk_df),
  jaccard_risk_df
)

jaccard_risk_ft <- flextable(jaccard_risk_df) %>%
  theme_booktabs() %>%
  autofit() %>%
  align(align = "center", part = "all") %>%
  align(j = "Comparison", align = "left", part = "all") %>%
  bold(part = "header") %>%
  set_caption("Jaccard Index Between High-Risk Latent Class Assignments")

jaccard_risk_ft

save_as_image(
  jaccard_risk_ft,
  path = "output/jaccard_high_risk_matrix.png",
  # res = 600 to match the HR table below and the table exports in 99.
  # Without it flextable defaults to 200, which put S3D at 831 px -- ~119 dpi
  # at full column width, below the 300 dpi floor for a submitted panel.
  res = 600
)

# UpSet plot ------------------------------------------------------------------

upset_data <- census_risk[, c(
  "bw_high_risk",
  "fat_high_risk",
  "gluc_high_risk"
)]

names(upset_data) <- c(
  "BW high-risk",
  "FM high-risk",
  "FBG high-risk"
)

png(
  filename = "output/upset_high_risk.png",
  width = 10,
  height = 6,
  units = "in",
  # 600 to match S3D/S3F/S3G, the other three panels in this row.
  res = 600,
  bg = "white"
)

# print(): UpSetR::upset() draws via an auto-printed grid object. run_90s.R runs
# this script through source(), whose default print.eval = FALSE suppresses that
# auto-print, so the device stayed blank. Forcing print() commits it to the png.
# UpSetR defaults these to "Intersection Size" / "Set Size" (Title Case), which
# was the only Title Case axis left on the S3 page -- S3F beside it reads
# "Survival probability" / "Age (weeks)". Both are plain arguments, so this is a
# label change, not a package modification.
print(upset(
  upset_data,
  sets = c("BW high-risk", "FM high-risk", "FBG high-risk"),
  order.by = "freq",
  text.scale = 1.5,
  mainbar.y.label = "Intersection size",
  sets.x.label = "Set size"
))

dev.off()

# High-risk burden survival analysis ------------------------------------------
# Classify each mouse by the NUMBER of high-risk phenotypes it belongs to
# (0-3, across BW / FM / FBG), then draw a KM curve (styling matched to the
# paper's other KM curves, but WITHOUT the dashed median lines and WITHOUT the
# HR text on the plot) and export the Cox HRs to a separate table image.

library(survival)
library(survminer)

# reuse the project's Cox-HR helper (same HR/CI/star format used elsewhere)
source("../07_display_figures/R/surv_all.R")

# ---- editable labels --------------------------------------------------------
# Each high-risk "class" belongs to a different phenotype (BW / FM / FBG), and a
# mouse can be high-risk in at most one class per phenotype, so the count is the
# number of high-risk PHENOTYPES (0-3). Rename here to taste.
burden_title  <- "No. of High-Risk Phenotypes"   # HR-table column header
burden_legend <- "High-risk phenotypes"          # KM legend title

# census_risk is already the single shared complete-case frame (built near the
# top of this script), so the KM uses exactly the same mice as the UpSet —
# identical by construction, not by coincidence.
census_hr <- census_risk
census_hr$n_high_risk <- with(
  census_hr,
  bw_high_risk + fat_high_risk + gluc_high_risk
)
# factor with 0 as the reference group; drop any empty level so the Cox model
# and the palette/legend stay aligned
census_hr$n_high_risk <- droplevels(
  factor(census_hr$n_high_risk, levels = c(0, 1, 2, 3))
)

cat("\nMice per high-risk burden group:\n")
print(table(census_hr$n_high_risk, useNA = "ifany"))

# ---- KM curve: high-risk burden, no median lines, no on-plot HRs ------------
# Colour scheme: the EXACT heatmap ramp (anchors of `heatmap_palette` in
# 07_display_figures.Rmd, amber -> dark red; palest yellows omitted so the
# 0-group line stays visible on white). Light -> dark encodes the ordinal 0->3
# risk gradient.
lvls <- levels(census_hr$n_high_risk)

# legend entries annotated with group sizes, e.g. "0 (n = 812)"
grp_n <- as.integer(table(census_hr$n_high_risk)[lvls])
legend_labs <- sprintf("%s (n = %d)", lvls, grp_n)

surv_object <- survival::Surv(time = census_hr$le_wk, event = census_hr$dead_censor)
km_fit <- survminer::surv_fit(surv_object ~ n_high_risk, data = census_hr)

# exact heatmap_palette anchors (amber -> dark red), interpolated to n groups
amber_anchors <- c("#F7BA3C", "#F28400", "#E13C00", "#7D0025")
pal <- grDevices::colorRampPalette(amber_anchors)(length(lvls))

make_km <- function(pal) {
  p <- survminer::ggsurvplot(
    km_fit,
    data = census_hr,
    conf.int = FALSE,
    pval = FALSE,                          # HRs are in a separate table instead
    xlab = "Age (weeks)",
    ylab = "Survival probability",
    legend.labs = legend_labs,             # 0 (n = ...), 1 (n = ...), ...
    legend.title = burden_legend,
    legend = "right",
    size = 2,
    title = "Survival by number of high-risk phenotypes",
    ggtheme = ggplot2::theme(
      plot.title = ggplot2::element_text(
        face = "bold", color = "black", size = 16, hjust = .5
      ),
      plot.margin = ggplot2::unit(c(2, 4, 25, 2), "pt")
    ),
    risk.table = FALSE,
    cumevents = FALSE,
    cumcensor = FALSE,
    palette = pal
  )
  # Match Figure 1b's KM styling exactly (07_display_figures.Rmd): the base
  # ggtheme above only sets title/margin, so ggsurvplot renders on ggplot's
  # gray default unless we explicitly override it here with theme_bw().
  p$plot <- p$plot +
    ggplot2::theme_bw() +
    ggplot2::coord_cartesian(xlim = c(0, NA), ylim = c(0, NA))
  p
}

png("output/km_high_risk_burden.png", width = 8, height = 6, units = "in",
    res = 600, bg = "white")
print(make_km(pal))
dev.off()
cat(sprintf("Wrote km_high_risk_burden.png  (palette: %s)\n",
            paste(pal, collapse = ", ")))

# ---- HR table (each group vs 0), exported as its own PNG ---------------------
hr_burden_stats <- kap_plot_cox(
  census_hr, var = "n_high_risk", age_death = "le_wk", event = "dead_censor"
)
cph <- hr_burden_stats[[3]]                # summary.coxph object

star <- function(p) {
  if (p < .001) "***" else if (p < .01) "**" else if (p < .05) "*" else ""
}
# Four decimals to match every other HR table in the deck (1N, 2I, 5D, 5I,
# S1H, S4I, S4R). Name kept as fmt2 for the call sites below.
fmt2 <- function(x) format(round(x, 4), nsmall = 4)

hr_strings <- vapply(seq_len(nrow(cph$conf.int)), function(i) {
  hr <- fmt2(cph$conf.int[i, "exp(coef)"])
  lo <- fmt2(cph$conf.int[i, "lower .95"])
  hi <- fmt2(cph$conf.int[i, "upper .95"])
  sprintf("%s (%s, %s)%s", hr, lo, hi,
          star(cph$coefficients[i, "Pr(>|z|)"]))
}, character(1))

# level 0 is the reference; levels 1..k map to the Cox coefficients in order
hr_table <- data.frame(
  a = lvls,
  b = c("Reference", hr_strings),
  stringsAsFactors = FALSE, check.names = FALSE
)
names(hr_table) <- c(burden_title, "HR (CI)")

cat("\nHR table (vs 0 high-risk phenotypes):\n")
print(hr_table, row.names = FALSE)

hr_ft <- flextable(hr_table) %>%
  theme_booktabs() %>%
  align(align = "center", part = "all") %>%
  align(j = 1, align = "left", part = "all") %>%
  bold(part = "header") %>%
  autofit() %>%
  set_caption(paste0(
    "Mortality hazard ratios by number of high-risk phenotypes ",
    "(reference = 0). * p<.05, ** p<.01, *** p<.001."
  ))

hr_ft

save_as_image(hr_ft, path = "output/km_high_risk_burden_hr.png", res = 600)
