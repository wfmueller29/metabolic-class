# In this analysis we will investigate the overlap between classes
# We will use the Rand index

library(consoler)
library(mclust)
library(flextable)
library(magrittr)
library(webshot2)

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
