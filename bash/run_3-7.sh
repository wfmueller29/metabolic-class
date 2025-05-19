#!/bin/zsh

Rscript run_3-7.R inputs/train/slam_c1-c10_age_all_bwfatgluc.yaml ; \
Rscript run_3-7.R inputs/train/slam_c1-c10_age_fb6_bwfatgluc.yaml ; \
Rscript run_3-7.R inputs/train/slam_c1-c10_age_fhet3_bwfatgluc.yaml ; \
Rscript run_3-7.R inputs/train/slam_c1-c10_age_mb6_bwfatgluc.yaml ; \
Rscript run_3-7.R inputs/train/slam_c1-c10_age_mhet3_bwfatgluc.yaml ; \
Rscript run_3-7.R inputs/train/itp_c10c11c13c16_age_controls_bw.yaml

