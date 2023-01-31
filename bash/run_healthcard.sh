#!/bin/bash


# load R
module load R/4.1 || echo "WARNING: Could not load R module, continuing anyway"

# change dir
cd 04b_healthcard_cod/

# Run slam2_models
Rscript R/healthcard_cod.R
