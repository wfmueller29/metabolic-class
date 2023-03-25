#!/bin/bash

OUT_TAG=$1

sbatch --mem=100g \
  --cpus-per-task=50 \
  -t 4-00:00:00 \
  -o log/models-slurmo-%A_%a.out \
  -e log/models-slurme-%A_%a.out \
  --export=OUT_TAG=$OUT_TAG \
  --mail-type=END bash/03_run_models.sh
