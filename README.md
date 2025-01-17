# metabolic-class
A Latent Class Mixed Effects Modelling Pipeline. 
This is a rewrite of [traj_models](https://github.com/wfmueller29/traj_models)

### Purpose
This is an attempt to make a generalized _Latent Class Mixed Models (LCMM)_ pipeline for large longitudinal datasets, like the _Study of Longitudinal Aging in Mice (SLAM)_.

### Overview
Training
<img width="1159" alt="image" src="https://github.com/user-attachments/assets/3864b34f-2f41-433e-839b-2cdfeb8ad11d" />
Validation
<img width="1163" alt="image" src="https://github.com/user-attachments/assets/fb23c660-1324-4dd0-9589-9dcb46425d8f" />

### Structure
This pipeline uses file in, file out structure with yaml files. 
## How to use

### Step 1: Training
If you have your own longitudinal dataset that you would like to use to train 





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


