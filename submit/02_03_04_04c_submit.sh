#!/bin/bash

CONFIG=$1

sbatch --mem=120g \
  --cpus-per-task=60 \
  -t 10-00:00:00 \
  -o log/02_to_04c-slurmo-%A_%a.out \
  -e log/02_t0_04c-slurme-%A_%a.out \
  --export=CONFIG=$CONFIG \
  --mail-type=END bash/02_03_04_04c.sh
