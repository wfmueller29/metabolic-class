#!/bin/bash

sbatch --mem=20g \
  --cpus-per-task=2 \
  -t 1-00:00:00 \
  -o log/predict_data-slurmo-%A_%a.out \
  -e log/predict_data-slurme-%A_%a.out \
  --mail-type=END bash/run_predict_data.sh
