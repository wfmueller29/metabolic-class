# In this analysis we will investigate the overlap between classes
# We will use the Rand index

library(consoler)
library(mclust)
library(flextable)
library(magrittr)
library(webshot2)
library(UpSetR)

# load data -------------------------------------------------------------------
census <- read.csv("../04_create_census/output/slam_c1-c10_age_all_bwfatgluc/train_census.csv")


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
  c("BW Class", "FM Class", "FPG Class"),
  c("BW Class", "FM Class", "FPG Class")
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
  set_caption("Adjusted Rand Index Between Latent Class Assignments")

# Preview in RStudio Viewer
ari_ft

save_as_image(
  ari_ft,
  path = "ari_matrix.png"
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
  c("BW High Risk", "FM High Risk", "FPG High Risk"),
  c("BW High Risk", "FM High Risk", "FPG High Risk")
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
  path = "ari_high_risk_matrix.png"
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
  c("BW High Risk", "FM High Risk", "FPG High Risk"),
  c("BW High Risk", "FM High Risk", "FPG High Risk")
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
  path = "jaccard_high_risk_matrix.png"
)

# UpSet plot ------------------------------------------------------------------

upset_data <- census_risk[, c(
  "bw_high_risk",
  "fat_high_risk",
  "gluc_high_risk"
)]

names(upset_data) <- c(
  "BW High Risk",
  "FM High Risk",
  "FPG High Risk"
)

png(
  filename = "upset_high_risk.png",
  width = 10,
  height = 6,
  units = "in",
  res = 300,
  bg = "white"
)

upset(
  upset_data,
  sets = c("BW High Risk", "FM High Risk", "FPG High Risk"),
  order.by = "freq",
  text.scale = 1.5
)

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
burden_title  <- "No. of high-risk phenotypes"   # HR-table column header
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
  survminer::ggsurvplot(
    km_fit,
    data = census_hr,
    conf.int = FALSE,
    pval = FALSE,                          # HRs are in a separate table instead
    xlab = "Age (Weeks) ",
    ylab = "Survival Probability",
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
}

png("km_high_risk_burden.png", width = 8, height = 6, units = "in",
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
  if (p < .001) "***" else if (p < .005) "**" else if (p < .05) "*" else ""
}
fmt2 <- function(x) format(round(x, 2), nsmall = 2)

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
names(hr_table) <- c(burden_title, "HR (95% CI)")

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
    "(reference = 0). * p<.05, ** p<.005, *** p<.001."
  ))

hr_ft

save_as_image(hr_ft, path = "km_high_risk_burden_hr.png", res = 600)
