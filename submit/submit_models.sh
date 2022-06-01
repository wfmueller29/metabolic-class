#!/bin/bash

CONFIG=$1

sbatch --mem=25g \
  --cpus-per-task=20 \
  -t 1-00:00:00 \
  -o log/models-slurmo-%A_%a.out \
  -e log/models-slurme-%A_%a.out \
  --export=CONFIG=$CONFIG \
  --mail-type=END bash/run_models.sh
