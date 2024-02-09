#!/bin/bash

module load R/4.1 || echo WARNING: Could not load R module, continuing anyway

# 02 --------------------------------------------------------------------------
cd 02_prep_model_data/

if [ -z "$1" ]
    then
        echo No command line argument provided
    else 
        CONFIG1=$1
fi

echo Raw config: $CONFIG1

if [ -z $CONFIG1]
    then 
        echo WARNING: No config file provided
        Rscript R/general_prep_model_data.R
    else 
        CONFIG1=$(echo $CONFIG1 | cut -d'/' -f2-)
        echo Using modified config: $CONFIG1
        Rscript R/general_prep_model_data.R $CONFIG1 
fi

# 03 --------------------------------------------------------------------------

# change dir
cd ../03_model/

if [ -z "$2" ]
    then
        echo No command line argument provided
    else 
        CONFIG2=$2
fi

echo Raw config: $CONFIG2

if [ -z $CONFIG2 ]
    then 
        echo WARNING: No config file provided
        Rscript R/model.R
    else 
        CONFIG2=$(echo $CONFIG2 | cut -d'/' -f2-)
        echo Using modified config: $CONFIG2
        Rscript R/model.R $CONFIG2 
fi

# 04 --------------------------------------------------------------------------

# change dir
cd ../04_model_select/

# Run slam2_models
Rscript render_model_select.R
