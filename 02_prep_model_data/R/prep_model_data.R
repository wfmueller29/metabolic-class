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

# glucose --------------------------------------------------------------------

traj_gluc <- main_all2 %>%
  filter(!is.na(gluc)) %>%
  select(idno, cohort, gluc, sex, strain, age_wk, le_wk, per_age_wk) %>%
  mutate(
    age_wk2 = age_wk * age_wk,
    per_age_wk2 = per_age_wk * per_age_wk,
    idno = as.numeric(idno)
  )

# body fat --------------------------------------------------------------------

traj_fat <- main_all2 %>%
  filter(!is.na(fat)) %>%
  select(idno, cohort, fat, sex, strain, age_wk, le_wk, per_age_wk) %>%
  mutate(
    age_wk2 = age_wk * age_wk,
    per_age_wk2 = per_age_wk * per_age_wk,
    idno = as.numeric(idno)
  )


# lean ------------------------------------------------------------------------

traj_lean <- main_all2 %>%
  filter(!is.na(lean)) %>%
  select(idno, cohort, lean, sex, strain, age_wk, le_wk, per_age_wk) %>%
  mutate(
    age_wk2 = age_wk * age_wk,
    per_age_wk2 = per_age_wk * per_age_wk,
    idno = as.numeric(idno)
  )


# body weight -----------------------------------------------------------------

traj_bw <- main_all2 %>%
  filter(!is.na(bw)) %>%
  select(idno, cohort, bw, sex, strain, age_wk, le_wk, per_age_wk) %>%
  mutate(
    age_wk2 = age_wk * age_wk,
    per_age_wk2 = per_age_wk * per_age_wk,
    idno = as.numeric(idno)
  )

# keep bw measurements closest to 3 month intervals

traj_bwperxbl30 <- traj_bw

traj_bw <- traj_bw %>%
  mutate(
    age_m = round(age_wk * 0.230137 / 3) * 3,
    age_wk_m = age_m / 0.230137,
    dif = abs(age_wk_m - age_wk)
  ) %>%
  group_by(idno, age_m) %>%
  mutate(min_dif = min(dif)) %>%
  ungroup() %>%
  filter(dif == min_dif)

# create percentage change from baseline --------------------------------------

source("R/create_per_x_bl.R")

# remove outliers -------------------------------------------------------------

source("R/remove_velocity_outliers.R")


# Store dataframes

df_list <- list(
  gluc_main = traj_gluc,
  bw_main = traj_bw,
  fat_main = traj_fat,
  lean_main = traj_lean,
  bwperxbl30_main = traj_bwperxbl30
)

df_list <- lapply(df_list,
  helphlme::prep_hlme,
  c("age_wk", "age_wk2", "per_age_wk", "per_age_wk2"),
  center = config$center,
  scale = config$scale
)


lapply(df_list, function(df) apply(apply(df, 2, is.na), 2, sum))


save(df_list, file = "output/df_list.RDATA")
