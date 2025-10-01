# metabolic-class
A generalized _Latent Class Mixed Model (LCMM)_ and _Cox Proportional Hazard Model_ pipeline for large longitudinal datasets, like those of _Study of Longitudinal Aging in Mice (SLAM)_. This is a rewrite of [traj_models](https://github.com/wfmueller29/traj_models)

## Installation

To install this end-to-end modelling pipeline in your current working directory, run the following command your terminal: 

```bash
git clone https://github.com/wfmueller29/metabolic-class
```
## Dependencies 

To install R package dependencies, navigate to the `metabolic-class` directory and run this command in your terminal:

```bash
Rscript installer.R
```
This should install all R packages that the pipeline depends upon, including two in-house dependencies listed below:

* [Callframe Package](https://github.com/wfmueller29/callframe)
* [Helphlme Package](https://github.com/wfmueller29/helphlme)



## Overview

This pipeline uses file in, file out structure with yaml files, with the only two files the user is required to make is the `train_config.yaml` and the `validate_config.yaml` 

### Training
<img width="1159" alt="image" src="https://github.com/user-attachments/assets/3864b34f-2f41-433e-839b-2cdfeb8ad11d" />

### Validation
<img width="1163" alt="image" src="https://github.com/user-attachments/assets/fb23c660-1324-4dd0-9589-9dcb46425d8f" />

## How to use

### Training
If you have your own longitudinal dataset that you would like to use to train, navigate to the `metabolic-class` directory and run this command in your terminal.

```bash
Rscript train.R <train_config.yaml>
```

The tedious part is creating the `train_config.yaml` file (See below)

### Validate
If you have longitudinal data you would like test against a previously trained model, navigate to the `metabolic-class` directory and run this command in your terminal. 
```bash
Rscript validate.R <validate_config.yaml>
```

The tedious part is creating the `validate_config.yaml` file (See below)

## Config Files
Yaml files are required and must follow the provided format. The easiest case would be to copy this example then change as necessary. Think of the yaml files as all the inputs to a function, and the R files as the functions themselves. The function argument names are provided on the left (i.e. "out_tag"), and the acutal arguemnt (i.e. "all") is provided on the right. This file will be read into R as a specifically structured list, so proper indentation is critical.

### Parameters

#### `out_tag`

A character string that specifies the name of the output directories created by the pipeline.

#### `plan`

A character string that specifies the strategy to be used for parellel computing. This string is passed to the argument `strategy` of the [plan](https://future.futureverse.org/reference/plan.html#built-in-evaluation-strategies) function from the [future](https://cran.r-project.org/web/packages/future/index.html) R package. To not use paraellel computing, the plan should be "sequential". If parellel computing is desired, it is recommended to read documentation of the [plan](https://future.futureverse.org/reference/plan.html#built-in-evaluation-strategies) function as the stategy for parellel computing varies depending on operating system etc. NOTE: the "cluster" strategy may not be supported. 

The steps of the pipeline eligible for parellel computing are: 
1. Running all candidate models
2. Boostrapping confidence intervals for F1 accuracy estimates

#### `ncpus`

A numeric value indicating the number of cpus to be used if parellel computing is desired and specfied using the `plan` parameter.

#### `sample_n`

A numeric value indicating the number of subjects to sample of the study population for the run. `FALSE` if no sample is desired. This sampling is useful for saving time and computational resources when doing test runs of the pipeline. 

#### `center`

A boolean variable that specifies if the age variables should be centered around their mean. 

#### `scale`

A boolean variable that specifies if the age variables should be scaled to standard deviations. 

#### `complete_ng`

A variable that can be used to prespecify the number of classes for models in the complete dataset. `NULL` if no prespecification is desired. A numeric vector where each entry corresponds with the desired number of classes for each outcome dataset entered in the pipeline. 

#### `train_ng`

A variable that can be used to prespecify the number of classes for models in the training dataset. `NULL` if no prespecification is desired. Or, a numeric vector where each entry corresponds with the desired number of classes for each outcome dataset entered in the pipeline. Or, "complete_ng" if the number of classes for the training dataset should be determined by the number of classes for the complete dataset. 

#### `external_validate`

`FALSE` if no external validation is desired. If external validation is desired this should be a realtive path specified like this: `../06_create_figures/output/<run>.yaml` to training `<run>` you are trying to validate. 

#### `custom_palette`

A bool specifying if a custom palette should be applied. When first running the pipeline, it is recommended that this be `FALSE`, to avoid mismatching the number of classes in the palette with the actual number of classes produced from the pipeline.

#### `palette_colors`

A list of character strings of hexadecimal (hex) colors ordered to match the class names in `legend_labels`.

#### `legend_labels`

A list of character strings providing the legned labels for the various classes.

#### `custom_palette_train` `palette_colors_train` `legend_labels_train`

The same as above but for the training set.

#### `survival_dataset`

* `path` - Absolute or relative path to the CSV that contains the variables `id`, `age_death`, and `event`
* `id` - A character string specifying the column name of the subject identifier.
* `age_death` - A character string specifiying the column name that contains that age of death of the subject.
* `event` - A character string specifiying the column name that contains whether or not the event occurred. Did the subject die or was lost to follow-up and should be censored? 

#### `individual_cox`

A list of character strings representing three one-side formula for a cox model. For example, \["~ Class", "~ Class + X", "~ Class + X * Y"], where X and Y are covariates that we want to control for when determining the relationship between Class and mortality. 

####

### Testing Config
```yaml
out_tag: all   # this will be the name of output files
tag_time: FALSE   # pretty sure this is an appendage
plan: multicore   # Input for "plan" function or the R Futures Package
ncpus: 10   # Number of CPUs to use when running in parrallel
sample_n: FALSE   # Integer providing desired sample size to reduce computation
center: TRUE   # Boolean specifying to center age variables around mean (note this will not show on figures, only in the model)
scale: FALSE   # Boolean specifying to scale age variabeles to standard deviations
survival_dataset: 
  path: "../00c_survival_data/output/main_cat_surv.csv" # csv providing id, age, age of death, censor, date of death (tod)
  id: "idno"    # to specify id column
  age_var: "age_wk"  # to specify age column
  age_death: "le_wk" # to specify age of death
  event: "dead_censor" # to specify censor column
  tod: "tod"   # to specify date of death
  covariates: "sex_M + strain_HET3" # These will be the covariabtes of the cox models
datasets: # list of datasets with corresponding outcomes. The one dataset case has not been tested and is likely to fail
- name: "slam" # name of dataset
  path: "../00b_dataset_mods/output/data/test/slam_bw_og.csv" # path to csv
  outcome: "bw" # specify outcome column
  age_var: ["age_wk", "age_wk2"] # specify age variables (these must be in increasing polynomial order)
  id: "idno" # specify id 
  covariates: ["sex", "strain"] # specify covariates 
  covariates_dummy: ["sex_M", "strain_HET3"] # specify dummy variables 
  numeric: ["bw", "idno", "le_wk"] # specify numeric variables
  factor: ["cohort"] # specify factor variables 
  train_test:
    sample_by: ["sex", "strain"] # specify covariates to equally split by
    split: .8 # split proportion (80 train, 20 test)
  model:
    fixed: "~ age_wk + age_wk2 + sex_F * strain_HET3" # 
    fixcov: ["sex_F", "strain_HET3"]
    mixture: "~ age_wk + age_wk2" 
    random: 
      - "~ 1"
      - "~ age_wk"
      - "~ age_wk + age_wk2"
    idiag: [FALSE, TRUE]
    nwg: [FALSE, TRUE]
    ng_max: 5
  prediction_data:
    filter_interval:
      intervals:
        - [age_wk_ns: "(0, 57.50)"]
        - [age_wk_ns: "[57.50,86.25)"]
        - [age_wk_ns: "[86.25,103.50)"]
        - [age_wk_ns: "[103.50,Inf)"]
        - [age_wk_ns: "[57.50,103.50]"]
      names:
    filter_window:
      age_var: "age_wk"
      start: 0
      end: 165
      window_size_vector: 52.1429
      step: 10
    filter_cumulative:
      age_var: "age_wk"
      start_vector: 0
      end: 165
      step: 10
    resample:
      age_var: "age_wk"
      fraction_vector: [.75, .667, .5, .337, .25]
  labels:
    oc_name: "Body Weight"
    oc_units: "(g)"
    age_var_name: "Age"
    age_var_units: "(weeks)"
    data_name: "SLAM Body Weight"
  harmonize:
    execute: TRUE
    formula: "~ age_wk + age_wk2 + sex * strain + (1|idno)"
    variable: "cohort"

- name: "slam"
  path: "../00b_dataset_mods/output/data/test/slam_fat_og.csv"
  outcome: "fat"
  age_var: ["age_wk", "age_wk2"]
  id: "idno"
  covariates: ["sex", "strain"]
  covariates_dummy: ["sex_M", "strain_HET3"]
  numeric: ["fat", "idno", "le_wk"]
  factor: ["cohort"]
  train_test:
    sample_by: ["sex", "strain"]
    split: .8
  model:
    fixed: "~ age_wk + age_wk2"
    mixture: "~ age_wk + age_wk2" 
    random: 
      - "~ 1"
      - "~ age_wk"
      - "~ age_wk + age_wk2"
    idiag: [FALSE, TRUE]
    nwg: [FALSE, TRUE]
    ng_max: 5
  prediction_data:
    filter_interval:
      intervals:
        - [age_wk_ns: "(0, 57.50)"]
        - [age_wk_ns: "[57.50,86.25)"]
        - [age_wk_ns: "[86.25,103.50)"]
        - [age_wk_ns: "[103.50,Inf)"]
        - [age_wk_ns: "[57.50,103.50]"]
      names:
    filter_window:
      age_var: "age_wk"
      start: 0
      end: 165
      window_size_vector: 52.1429
      step: 10
    filter_cumulative:
      age_var: "age_wk"
      start_vector: 0
      end: 165
      step: 10
    resample:
      age_var: "age_wk"
      fraction_vector: [.75, .667, .5, .337, .25]
  labels:
    oc_name: "Body Fat"
    oc_units: "(g)"
    age_var_name: "Age"
    age_var_units: "(weeks)"
    data_name: "SLAM Body Fat"
  harmonize:
    execute: TRUE
    formula: "~ age_wk + age_wk2 + sex * strain + (1|idno)"
    variable: "cohort"

```


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


