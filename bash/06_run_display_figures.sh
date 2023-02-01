#!/bin/bash


# load R
module load R/4.1 || echo "WARNING: Could not load R module, continuing anyway"

# change dir
cd 06_display_figures/

# Run slam2_models
Rscript render_display_figures.R
