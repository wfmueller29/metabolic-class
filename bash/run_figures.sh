#!/bin/bash


# load R
module load R/4.1 || echo "WARNING: Could not load R module, continuing anyway"

# change dir
cd 05_figures/

# Run slam2_models
Rscript render_figures.R
