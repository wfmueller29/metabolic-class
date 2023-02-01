#!/bin/bash


# load R
module load R/4.1

# change dir
cd 04_model_select/

# Run slam2_models
Rscript render_model_select.R
