#!/bin/bash

sbatch --mem=20g \
  --cpus-per-task=2 \
  -t 1-00:00:00 \
  -o log/healthcard-slurmo-%A_%a.out \
  -e log/healthcard-slurme-%A_%a.out \
  --mail-type=END bash/run_healthcard.sh
