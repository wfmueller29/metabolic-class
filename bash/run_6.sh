#!/bin/zsh

Rscript run_6.R 01_prep_model_data/input/slam_age_all.yaml ; \
Rscript run_6.R 01_prep_model_data/input/slam_age_mb6.yaml ; \
Rscript run_6.R 01_prep_model_data/input/slam_age_mhet3.yaml ; \
Rscript run_6.R 01_prep_model_data/input/slam_age_fb6.yaml ; \
Rscript run_6.R 01_prep_model_data/input/slam_age_fhet3.yaml ; \
Rscript run_6.R 01_prep_model_data/input/itp_bw.yaml
