# Landmark Analysis
# Pick an age L.
# Classify each mouse using only weights taken before L.
# Drop mice that died before L plus a gap g.
# Count survival only from L + g.

L <- 60
g <- 4
start_age <- L + g

load("../00a_clean_slam_c1-c10/output/main_all2.RDATA")
load("../00a_clean_slam_c1-c10/output/main_cat_surv.RDATA")

# Keep mice observed beyond L + g.
main_cat_surv_landmark <- main_cat_surv[
  !is.na(main_cat_surv$le_wk) &
    main_cat_surv$le_wk > start_age,
]

# Keep observed weights before L for eligible mice.
main_all2_landmark <- main_all2[
  main_all2$idno %in% main_cat_surv_landmark$idno &
    !is.na(main_all2$age_wk) &
    main_all2$age_wk < L &
    !is.na(main_all2$bw),
]

# Restrict survival data to mice with eligible weight measurements.
main_cat_surv_landmark <- main_cat_surv_landmark[
  main_cat_surv_landmark$idno %in% main_all2_landmark$idno,
]

# Survival time from L + g; preserve original age at exit.
main_cat_surv_landmark$surv_wk <-
  main_cat_surv_landmark$le_wk - start_age

dir.create("output", showWarnings = FALSE)

save(main_all2_landmark,
  file = "output/main_all2_landmark.RDATA"
)

save(main_cat_surv_landmark,
  file = "output/main_cat_surv_landmark.RDATA"
)
