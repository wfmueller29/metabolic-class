#!/bin/bash

#load R
module load R/4.1

# Run prep model data
cd 04_model_select/
Rscript R/prep_model_data.R
cd ..
