#!/bin/bash

#load R
module load R/4.1

# Run prep model data
cd 02_prep_model_data/
Rscript R/prep_model_data.R
cd ..
