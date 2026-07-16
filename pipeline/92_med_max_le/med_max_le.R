# Get med and max life expectancy for the sex/strain strata datasets

library(survival)

mb6 <- read.csv("../04_create_census/output/slam_c1-c10_age_mb6_bwfatgluc/complete_census.csv")
fb6 <- read.csv("../04_create_census/output/slam_c1-c10_age_fb6_bwfatgluc/complete_census.csv")
fhet3 <- read.csv("../04_create_census/output/slam_c1-c10_age_fhet3_bwfatgluc/complete_census.csv")
mhet3 <- read.csv("../04_create_census/output/slam_c1-c10_age_mhet3_bwfatgluc/complete_census.csv")


datasets <- list(mb6 = mb6, fb6 = fb6, fhet3 = fhet3, mhet3 = mhet3)

datasets <- lapply(datasets, function(data) {
  data$status <- 1
  data
})



## dat is a data.frame with columns: le_wk, status, new_class_bw
summ_le_by_class <- function(data) {
  fit <- survfit(Surv(le_wk, status) ~ new_class_bw, data = data)
  tab <- summary(fit)$table

  med_vec <- tab[, "median"]
  max_vec <- tapply(data$le_wk, data$new_class_bw, max, na.rm = TRUE)
  n_vec <- table(data$new_class_bw)

  # Align by class name and combine
  classes <- sort(unique(data$new_class_bw))

  out <- data.frame(
    new_class_bw = classes,
    n = as.numeric(n_vec),
    median_le_wk = as.numeric(med_vec),
    max_le_wk = as.numeric(max_vec),
    row.names = NULL
  )

  out
}


surv_list <- lapply(datasets, summ_le_by_class)

surv_df <- do.call(rbind, lapply(names(surv_list), function(nm) {
  tmp <- surv_list[[nm]]
  tmp$dataset <- nm
  tmp
}))

if (!dir.exists("output")) {
  dir.create("output", recursive = TRUE)
}

write.csv(surv_df, "output/class_sexstrain_surv_data.csv")
