# Author: William Mueller
# Purpose: The purpose of this file is to prep the datasets that were used for
# the previous glucose paper so they can be modeled
# We also removed outliers based upon outcome velocity

library(tidyverse)
library(helphlme)
source("R/per_change.R")

load("../01_dataset/output/main_all2.RDATA")

# Read in config file

config <- yaml::read_yaml("yaml/default.yaml")


traj_gluc <- main_all2 %>%
  filter(!is.na(gluc)) %>%
  select(idno, cohort, gluc, sex, strain, age_wk, le_wk, per_age_wk) %>%
  mutate(
    age_wk2 = age_wk * age_wk,
    per_age_wk2 = per_age_wk * per_age_wk,
    idno = as.numeric(idno)
  ) %>%
  per_change("gluc") %>%
  mutate(threshold = ifelse(abs(gluc_velocity) > 50, 1, 0)) %>%
  filter(threshold != 1) %>%
  as.data.frame()

hist(traj_gluc$gluc_velocity)

traj_bw <- main_all2 %>%
  filter(!is.na(bw)) %>%
  select(idno, cohort, bw, sex, strain, age_wk, le_wk, per_age_wk) %>%
  mutate(
    age_wk2 = age_wk * age_wk,
    per_age_wk2 = per_age_wk * per_age_wk,
    idno = as.numeric(idno)
  )

traj_fat <- main_all2 %>%
  filter(!is.na(fat)) %>%
  select(idno, cohort, fat, sex, strain, age_wk, le_wk, per_age_wk) %>%
  mutate(
    age_wk2 = age_wk * age_wk,
    per_age_wk2 = per_age_wk * per_age_wk,
    idno = as.numeric(idno)
  ) %>%
  per_change("fat") %>%
  mutate(threshold = ifelse(abs(fat_velocity) > 5, 1, 0)) %>%
  filter(threshold != 1) %>%
  as.data.frame()

hist(traj_fat$fat_velocity)

traj_lean <- main_all2 %>%
  filter(!is.na(lean)) %>%
  select(idno, cohort, lean, sex, strain, age_wk, le_wk, per_age_wk) %>%
  mutate(
    age_wk2 = age_wk * age_wk,
    per_age_wk2 = per_age_wk * per_age_wk,
    idno = as.numeric(idno)
  ) %>%
  per_change("lean") %>%
  mutate(threshold = ifelse(abs(lean_velocity) > 8, 1, 0)) %>%
  filter(threshold != 1) %>%
  as.data.frame()

# View(traj_lean[traj_lean$threshold == 1 & !is.na(traj_lean$threshold), ])
hist(traj_lean$lean_velocity)

### keep bw measurements closest to 3 month intervals
traj_bw <- traj_bw %>%
  mutate(
    age_m = round(age_wk * 0.230137 / 3) * 3,
    age_wk_m = age_m / 0.230137,
    dif = abs(age_wk_m - age_wk)
  ) %>%
  group_by(idno, age_m) %>%
  mutate(min_dif = min(dif)) %>%
  ungroup() %>%
  filter(dif == min_dif) %>%
  per_change("bw") %>%
  mutate(threshold = ifelse(abs(bw_velocity) > 3, 1, 0)) %>%
  filter(bw_threshol != 1) %>%
  as.data.frame()

View(traj_bw[traj_bw$threshold == 1 & !is.na(traj_bw$threshold), ])
hist(df_list$bw_main$bw_velocity)


df_list <- list(
  gluc_main = traj_gluc,
  bw_main = traj_bw,
  fat_main = traj_fat,
  lean_main = traj_lean
)

df_list <- lapply(df_list,
  helphlme::prep_hlme,
  c("age_wk", "age_wk2", "per_age_wk", "per_age_wk2"),
  center = config$center,
  scale = config$scale
)


lapply(df_list, function(df) apply(apply(df, 2, is.na), 2, sum))


save(df_list, file = "output/df_list.RDATA")
