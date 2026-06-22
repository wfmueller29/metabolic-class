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
