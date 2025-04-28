#!/bin/zsh

Rscript run_7.R inputs/train/slam_age_all.yaml ; \
Rscript run_7.R inputs/train/slam_age_mb6.yaml ; \
Rscript run_7.R inputs/train/slam_age_mhet3.yaml ; \
Rscript run_7.R inputs/train/slam_age_fb6.yaml ; \
Rscript run_7.R inputs/train/slam_age_fhet3.yaml ; \
Rscript run_7.R inputs/train/itp_bw.yaml
