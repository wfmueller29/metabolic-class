#!/bin/bash

# move output to archive
bash batch/archive_output.sh

# load R
module load R/4.1
# Run slam2_models
Rscript R/models.R $config 
