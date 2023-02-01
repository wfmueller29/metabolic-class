#!/bin/bash

sbatch --mem=20g \
  --cpus-per-task=2 \
  -t 1-00:00:00 \
  -o log/figures-slurmo-%A_%a.out \
  -e log/figures-slurme-%A_%a.out \
  --mail-type=END bash/05_run_figures.sh
