#!/bin/bash

# load R
module load R/4.1 || echo WARNING: Could not load R module, continuing anyway

# change dir
cd 03_model/

if [ -z "$1" ]
    then
        echo No command line argument provided
    else 
        OUT_TAG=$1
fi

echo Target Output Directory: $OUT_TAG

if [ -z $OUT_TAG ]
    then 
        echo WARNING: No output directory provided
        Rscript R/model.R
    else 
        Rscript R/model.R $OUT_TAG 
fi
