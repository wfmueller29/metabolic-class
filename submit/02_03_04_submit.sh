#!/bin/bash

CONFIG1=$1
CONFIG2=$2

sbatch --mem=100g \
  --cpus-per-task=50 \
  -t 4-00:00:00 \
  -o log/prep_model_select-slurmo-%A_%a.out \
  -e log/prep_model_select-%A_%a.out \
  --export=CONFIG1=$CONFIG1,CONFIG2=$CONFIG2 \
  --mail-type=END bash/02_03_04_run.sh
