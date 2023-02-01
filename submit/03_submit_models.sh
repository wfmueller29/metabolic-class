#!/bin/bash

CONFIG=$1

sbatch --mem=25g \
  --cpus-per-task=40 \
  -t 2-00:00:00 \
  -o log/models-slurmo-%A_%a.out \
  -e log/models-slurme-%A_%a.out \
  --export=CONFIG=$CONFIG \
  --mail-type=END bash/03_run_models.sh
