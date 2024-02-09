#!/bin/bash

module load R/4.1 || echo WARNING: Could not load R module, continuing anyway

cd 01_prep_model_data/

if [ -z "$1" ]
    then
        echo No command line argument provided
    else 
        CONFIG=$1
fi

echo Raw config: $CONFIG

if [ -z $CONFIG ]
    then 
        echo WARNING: No config file provided
        Rscript 01_prep_model_data.R
    else 
        CONFIG=$(realpath $CONFIG)
        echo Using modified config: $CONFIG
        Rscript 01_prep_model_data.R $CONFIG 
fi
