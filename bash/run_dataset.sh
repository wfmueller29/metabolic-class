#!/bin/bash

module load R/4.1 || echo WARNING: Could not load R module, continuing anyway

cd 01_dataset/

Rscript render_dataset.R
