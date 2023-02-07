#!/bin/bash

CONFIG=$1

sbatch --mem=20g \
  --cpus-per-task=2 \
  -t 1-00:00:00 \
  -o log/prep_data-slurmo-%A_%a.out \
  -e log/prep_data-slurme-%A_%a.out \
  --export=CONFIG=$CONFIG \
  --mail-type=END bash/02_run_prep_data.sh
