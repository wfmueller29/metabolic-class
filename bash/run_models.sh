#!/bin/bash


# load R
module load R/4.1 || true

# change dir
cd 03_model/

# Run slam2_models
Rscript R/model.R $CONFIG
