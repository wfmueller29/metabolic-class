#!/bin/bash

config=$1

sbatch --mem=200g \
  --cpus-per-task=20 \
  -t 1-00:00:00 \
  -o log/models-slurmo-%A_%a.out \
  -e log/models-slurme-%A_%a.out \
  --export=config=$config \
  --mail-type=END bash/run_models.sh
