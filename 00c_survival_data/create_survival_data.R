# Just to write survival data as CSV
# Author: William Mueller

load("../00a_dataset/output/main_cat_surv.RDATA")

keep_cols <- c(
  "idno", "dead_censor", "fu_age_wk", "le_wk", "cod",
  "lastdate", "maxdate", "tod"
)

main_cat_surv <- main_cat_surv[keep_cols]

main_cat_surv$percent_le <- 1

dir.create("output")
write.csv(x = main_cat_surv, file = "output/main_cat_surv.csv")
