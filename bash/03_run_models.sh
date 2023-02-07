#!/bin/bash


# load R
module load R/4.1 || echo WARNING: Could not load R module, continuing anyway

# change dir
cd 03_model/

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
        Rscript R/model.R
    else 
        CONFIG=$(echo $CONFIG | cut -d'/' -f2-)
        echo Using modified config: $CONFIG
        Rscript R/model.R $CONFIG 
fi
