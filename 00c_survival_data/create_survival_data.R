# Just to write survival data as CSV
# Author: William Mueller

load("../00a_dataset/output/main_cat_surv.RDATA")

dir.create("output")

write.csv(x = main_cat_surv, file = "output/main_cat_surv.csv")
