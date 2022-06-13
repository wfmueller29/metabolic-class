# Purpose: Create a percentage change from baseline variable for each body
# weight measurement
# Author: William Mueller

source("R/per_x_bl.R")
traj_bw <- traj_bw %>%
  create_bl(id = "idno", age_var = "age_wk", var = "bw", cutoff = 50)

traj_bwperxbl30 <- traj_bwperxbl30 %>%
  create_bl(id = "idno", age_var = "age_wk", var = "bw", cutoff = 50)

# histogram of first measurment of body weight for all mice
hist(traj_bw[traj_bw$bl == 1, ]$age_wk)
# histogram of first measuremnt of body weight in og_traj_bw
hist(traj_bwperxbl30[traj_bwperxbl30$bl == 1, ]$age_wk)

# set bl30 as the measurement closest to 30 weeks of age
traj_bwperxbl30 <- traj_bwperxbl30 %>%
  mutate(dif_30 = abs(age_wk - 30)) %>%
  group_by(idno) %>%
  arrange(idno, dif_30) %>%
  mutate(bl30 = ifelse(dif_30 == min(dif_30), 1, 0)) %>%
  mutate(bl30_age_wk = first(age_wk),
         bl30_bw = first(bw)) %>%
  mutate(bw_per_x_bl30 = (bw - bl30_bw) / bl30_bw * 100) %>%
  ungroup()

hist(traj_bwperxbl30[traj_bwperxbl30$bl30 == 1, ]$age_wk)

# get list of id's that hvae baseline measurement before 25 weeks of age
cat("Number of observations before removing mice with baseline measurement
    too early \n")
cat(nrow(traj_bwperxbl30), "\n")

traj_bwperxbl30 <- traj_bwperxbl30 %>%
  filter(bl30_age_wk >= 25) 

cat("Number of observations after removing mice with baseline measurement
    too early \n")
cat(nrow(traj_bwperxbl30), "\n")

cat("Min age_wk at baseline \n")
cat(min(traj_bwperxbl30$bl30_age_wk), "\n")

traj_bwperxbl30 <- traj_bwperxbl30 %>%
  mutate(
    age_m = round(age_wk * 0.230137 / 3) * 3,
    age_wk_m = age_m / 0.230137,
    dif = abs(age_wk_m - age_wk)
  ) %>%
  group_by(idno, age_m) %>%
  mutate(min_dif = min(dif)) %>%
  ungroup() %>%
  filter(dif == min_dif)
