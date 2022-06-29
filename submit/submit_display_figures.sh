#!/bin/bash

sbatch --mem=100g \
  --cpus-per-task=2 \
  -t 1-00:00:00 \
  -o log/display_figures-slurmo-%A_%a.out \
  -e log/display_figures-slurme-%A_%a.out \
  --mail-type=END bash/run_display_figures.sh
