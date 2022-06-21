#!/bin/bash


# load R
module load R/4.1

# change dir
cd 04c_prediction_data/

# Run slam2_models
Rscript R/create_prediction_data.R
