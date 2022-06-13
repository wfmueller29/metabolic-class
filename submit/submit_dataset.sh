#!/bin/bash

sbatch --mem=20g \
  --cpus-per-task=2 \
  -t 1-00:00:00 \
  -o log/dataset-slurmo-%A_%a.out \
  -e log/dataset-slurme-%A_%a.out \
  --mail-type=END bash/run_dataset.sh
