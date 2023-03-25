# metabolic-class
A Latent Class Mixed Effects Modelling Pipeline. A rewrite of the traj analysis
repository. 

### Purpose
This is an attempt to make a generalized modelling pipeline for applying 
large longitudinal datasets to latent class mixed effects models.

## How to use on Biowulf

This repository runs using predominantly R code, a little shell, and yaml 
files for configuration. 

### Step 1: Installation

```
cd /data/$USER
```

```
git clone https://github.com/wfmueller29/metabolic-class.git
```

### Step 2: Run code

Move to correct working Directory
```
cd /data/$USER/metabolic-class/analysis
```

Submit general_prep_model_data.R with correct config file as a command line 
argument. If no config file is provided, the test config is run

```
bash submit/02_submit_prep_data.sh <Config file path>
```

Submit model.R.

```
bash submit/03_submit_models.sh <Name of output directory from prep model>
```


