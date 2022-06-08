#!/bin/bash

sbatch --mem=20g \
  --cpus-per-task=2 \
  -t 1-00:00:00 \
  -o log/model_select-slurmo-%A_%a.out \
  -e log/model_select-slurme-%A_%a.out \
  --mail-type=END bash/run_model_select.sh
