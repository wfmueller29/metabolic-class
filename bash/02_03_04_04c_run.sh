#!/bin/bash

module load R/4.1 || echo WARNING: Could not load R module, continuing anyway

# 02_prep_model_data ----------------------------------------------------------

echo -e "\n"
echo --------------------------------------------------------------------------
echo Running 02_prep_model_data .....
echo --------------------------------------------------------------------------
echo -e "\n"

cd 02_prep_model_data/

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
        Rscript R/general_prep_model_data.R
    else 
        CONFIG=$(echo $CONFIG | cut -d'/' -f2-)
        echo Using modified config: $CONFIG
        Rscript R/general_prep_model_data.R $CONFIG 
fi

# 03_model --------------------------------------------------------------------

echo -e "\n"
echo --------------------------------------------------------------------------
echo Running 03_model .....
echo --------------------------------------------------------------------------
echo -e "\n"

# change dir
cd ../03_model/

if [ -z "$1" ]
    then
        echo No command line argument provided
    else 
        OUT_TAG=$(echo $CONFIG | cut -d'/' -f2-)
        OUT_TAG=$(echo $OUT_TAG | cut -d'.' -f 1)
fi

echo Target Output Directory: $OUT_TAG

if [ -z $OUT_TAG ]
    then 
        echo WARNING: No output directory provided
        Rscript R/model.R
    else 
        Rscript R/model.R $OUT_TAG 
fi

# 04_model_select -------------------------------------------------------------

echo -e "\n"
echo --------------------------------------------------------------------------
echo Running 04_model_select  .....
echo --------------------------------------------------------------------------
echo -e "\n"

# change dir
cd ../04_model_select/

# Run slam2_models
Rscript render_model_select.R

# 04c_create_prediction_data.R ------------------------------------------------

echo -e "\n"
echo --------------------------------------------------------------------------
echo Running 04c_create_prediction_data.R  .....
echo --------------------------------------------------------------------------
echo -e "\n"

# change dir
cd ../04c_prediction_data/

if [ -z "$1" ]
    then
        echo No command line argument provided
    else 
        OUT_TAG=$OUT_TAG
fi

echo Target Output Directory: $OUT_TAG

if [ -z $OUT_TAG ]
    then 
        echo WARNING: No output directory provided
        Rscript R/create_prediction_data.R
    else 
        Rscript R/create_prediction_data.R $OUT_TAG 
fi
