#!/bin/bash

# submit 01_dataset
jid01=$(sbatch --mem=20g \
  --cpus-per-task=2 \
  -t 1-00:00:00 \
  -o log/dataset-slurmo-%A_%a.out \
  -e log/dataset-slurme-%A_%a.out \
  --mail-type=END bash/run_dataset.sh | cut -d ' ' -f4)

# submit 02_run_prep_data
jid02=$(sbatch --mem=20g \
  --cpus-per-task=2 \
  -t 1-00:00:00 \
  -o log/prep_data-slurmo-%A_%a.out \
  -e log/prep_data-slurme-%A_%a.out \
  --dependency=afterok:${jid01} \
  --mail-type=END bash/run_prep_data.sh | cut -d ' ' -f4)

