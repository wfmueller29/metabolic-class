#!/bin/bash

module load R/4.1 || echo WARNING: Could not load R module, continuing anyway

cd 02_prep_model_data/

Rscript R/general_prep_model_data.R
