# Purpose: Remove outliers based upon rate of change of outocme variable
# Author: William Mueller

bw_v_threshold <- 5
gluc_v_threshold <- 75
fat_v_threshold <- 7
lean_v_treshold <- 10
bw_per_x_bl30_v_threshold <- 5

# lean ------------------------------------------------------------------------
cat("Number of observations before removing outliers
    by velocity lean mass: \n")
nrow(traj_lean)

traj_lean_xvout <- traj_lean %>%
  per_change("lean") %>%
  mutate(threshold = ifelse(abs(lean_velocity) > lean_v_treshold, 1, 0)) %>%
  filter(threshold != 1) %>%
  as.data.frame()

cat("Number of observations after removing outliers
    by velocity lean mass: \n")
nrow(traj_lean_xvout)

# View(traj_lean_xvout[traj_lean$threshold == 1 & !is.na(traj_lean$threshold), ])
hist(traj_lean_xvout$lean_velocity)

# body weight ----------------------------------------------------------------

cat("Number of observations before removing outliers
    by velocity body weight: \n")
nrow(traj_bw)

traj_bw_xvout <- traj_bw %>%
  per_change("bw") %>%
  mutate(threshold = ifelse(abs(bw_velocity) > bw_v_threshold, 1, 0)) %>%
  filter(threshold != 1) %>%
  as.data.frame()

# View(traj_bw[traj_bw_xvout$threshold == 1 & !is.na(traj_bw_xvout$threshold), ])
cat("Number of observations after removing outliers
    by velocity body weight: \n")
nrow(traj_bw_xvout)

# body fat -----------------------------------------------------------------

cat("Number of observations before removing outliers
    by velocity body fat: \n")
nrow(traj_fat_xvout)

traj_fat_xvout <- traj_fat %>%
  per_change("fat") %>%
  mutate(threshold = ifelse(abs(fat_velocity) > fat_v_threshold, 1, 0)) %>%
  filter(threshold != 1) %>%
  as.data.frame()

cat("Number of observations after removing outliers
    by velocity body fat: \n")
nrow(traj_fat_xvout)

hist(traj_fat_xvout$fat_velocity)

# gluc -----------------------------------------------------------------------

cat("Number of observations before removing outliers
    by velocity glucose: \n")
nrow(traj_gluc)

traj_gluc_xvout <- traj_gluc %>%
  per_change("gluc") %>%
  mutate(threshold = ifelse(abs(gluc_velocity) > gluc_v_threshold, 1, 0)) %>%
  filter(threshold != 1) %>%
  as.data.frame()

cat("Number of observations after removing outliers
    by velocity glucose: \n")
nrow(traj_gluc_xvout)

hist(traj_gluc_xvout$gluc_velocity)

# body weight percent change baseline ------------------------------------------

cat("Number of observations before removing outliers
    by velocity body weight percent change from baseline: \n")
nrow(traj_bwperxbl30)

traj_bwperxbl30_xvout <- traj_bwperxbl30 %>%
  per_change("bw_per_x_bl30") %>%
  mutate(threshold = ifelse(abs(bw_per_x_bl30_velocity) > bw_per_x_bl30_v_threshold, 1, 0)) %>%
  filter(threshold != 1) %>%
  as.data.frame()

cat("Number of observations after removing outliers
    by velocity body weight percent change from baseline: \n")
nrow(traj_bwperxbl30_xvout)

hist(traj_bwperxbl30_xvout$bw_per_x_bl30_velocity)
