# metabolic-class
A generalized _Latent Class Mixed Model (LCMM)_ and _Cox Proportional Hazard Model_ pipeline for large longitudinal datasets, like those of _Study of Longitudinal Aging in Mice (SLAM)_. This is a rewrite of [traj_models](https://github.com/wfmueller29/traj_models)

## Installation

To install this end-to-end modelling pipeline in your current working directory, run the following command your terminal: 

```bash
git clone https://github.com/wfmueller29/metabolic-class
```
## Dependencies 

R package versions are pinned with [renv](https://rstudio.github.io/renv/) so that you get the same versions the analysis was run with. The project `.Rprofile` activates renv automatically whenever you start R in the `metabolic-class` directory, so you only need to restore the library once. Navigate to the `metabolic-class` directory, start R, and run:

```r
renv::restore()
```

This installs every package at the version recorded in `renv.lock`, including the in-house dependencies listed below (installed from GitHub at pinned commits):

* [Callframe Package](https://github.com/wfmueller29/callframe)
* [Helphlme Package](https://github.com/wfmueller29/helphlme)
* [SLAM Package](https://github.com/wfmueller29/SLAM)
* [Consoler Package](https://github.com/wfmueller29/consoler)

`renv.lock` also records the R version the analysis was run under. Running a different version of R will pull different builds of the base/recommended packages (`Matrix`, `MASS`, `nlme`, etc.), which can affect model fitting — so match the recorded R version if you are trying to reproduce the published results exactly.

### Computing environment (important for exact reproduction)

renv pins R *packages*. It cannot pin R itself, your CPU architecture, or the BLAS/LAPACK
libraries R links against — and the LCMM fits in this pipeline are sensitive to all three.
Class assignments can shift, and marginally positive-definite covariance matrices can fail
`chol()` outright, purely from a different numerical stack.

The reference environment is:

| | |
|---|---|
| R version | as recorded in `renv.lock` (`renv::lockfile_read("renv.lock")$R$Version`) |
| build | official CRAN R for macOS (Apple Silicon / arm64) |
| BLAS / LAPACK | R's bundled reference `libRblas` / `libRlapack` (single-threaded) |

Check what you are running with:

```r
c(R.version.string, R.version$platform, sessionInfo()[c("BLAS","LAPACK")])
```

The BLAS matters most. A **multi-threaded** BLAS (e.g. a pthreads OpenBLAS build, which
Homebrew's R links by default) computes sums in whatever order threads finish, so results can
vary *run to run on the same machine*. If you cannot use the reference BLAS, at minimum force
single-threaded math before running the pipeline:

```bash
export OPENBLAS_NUM_THREADS=1
```

The project `.Rprofile` prints a notice at startup if your R version or BLAS differs from the
reference, so a mismatched environment is visible rather than silent.

#### Building source packages on Apple Silicon

Most packages install as prebuilt binaries, but a few pinned versions have no arm64 binary
(notably `gdtools` and `flextable`) and must compile from source. They need `cairo`,
`fontconfig` and `freetype` — and these must be **arm64** libraries. If your Homebrew is the
Intel one under `/usr/local`, `pkg-config` will hand the arm64 compiler x86_64 libraries, the
linker will silently drop them, and the build fails with:

```
symbol not found in flat namespace '_FT_Done_Face'
```

Fix by installing CRAN's prebuilt arm64 libraries into `/opt/R/arm64` (where R already looks):

```bash
BASE=https://mac.r-project.org/bin/darwin20/arm64
for l in cairo-1.17.6 fontconfig-2.14.2 freetype-2.13.2 pixman-0.42.2 \
         libpng-1.6.44 expat-2.6.4 gettext-0.22.5; do
  curl -O "$BASE/${l}-darwin.20-arm64.tar.xz"
  sudo tar -xJf "${l}-darwin.20-arm64.tar.xz" -C /
done
export PKG_CONFIG_PATH=/opt/R/arm64/lib/pkgconfig
```

Verify with `pkg-config --variable=prefix cairo` — it should print `/opt/R/arm64`, not a
Homebrew path. Any other source package needing system libraries can be fixed the same way
using the matching tarball from that CRAN directory.

#### Recording what a run used

`reproduce.R` times every step as it goes (appending to `run_records/run_log.csv`) and finishes
by running `session_info.R`, which writes a **pair of records** into `run_records/`:

```
run_records/2026-07-20_2215_Josh-Preston_session_info.txt
run_records/2026-07-20_2215_Josh-Preston_run_timing.txt
```

* **`*_session_info.txt`** — the environment: git commit, R version **and architecture**,
  BLAS/LAPACK and thread settings, renv sync state, key package versions, and the in-house
  packages with their exact commit SHAs.
* **`*_run_timing.txt`** — the execution: run start/end, wall clock, and per-step duration and
  status for every training config, render, and analysis.

Records are **stamped with the run's start time and the git author**, so they accumulate rather
than overwrite: multiple people running on different machines each leave their own record, runs
can be compared against one another, and nobody's record collides with anybody else's. **Commit
these alongside any results you report** — since renv cannot pin the numerical stack, they are
what lets a result be traced back to the environment that produced it.

You can regenerate the pair at any time (e.g. after a run that failed partway — `log/run_log.csv`
is written incrementally and survives) with:

```bash
Rscript session_info.R
```

> The older `installer.R` script installs these same packages at their *latest* versions rather than the pinned ones. Prefer `renv::restore()`; use `installer.R` only if you deliberately want an unpinned environment.



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

A list of character strings representing three one-side formula for a cox model. For example, `["~ Class", "~ Class + X", "~ Class + X * Y"]`, where X and Y are covariates that we want to control for when determining the relationship between Class and mortality. 

#### `combined_cox`

* `forms` - A list of three strings representing one sided formulas for the combined cox model. The strings `"<probs+>"` and `"<probs*>"` will expand to the posterior probabilities of all classes included additively and multiplicatively, respectively. The strings `"<class+>"` and `"<class*>"` will expand discrete class membership additively and multiplicatively, respectively. For example, `["~ <class+>", "~ <probs+> + frailty(idno)", "~ <probs+>"]` would be three possible formula.
* `tts` - A list of three strings representing time transformation to variables in `forms` that have a `tt()` function. For example, if the formula `"~ <probs+> + bw + gluc + fat + tt(bw) + tt(gluc) + tt(fat) + sex + strata(strain)"` was provided in `forms`, the corresponding tts entry would included a list of three functions, one for each of the variables specified by the `tt` function. The complete example is shown below. `NULL` if no time transformation is desired.

```yaml
forms:
  - "~ <class+> + sex + strata(strain)"
  - "~ <probs+> + sex + strata(strain)"
  - "~ <probs+> + bw + gluc + fat + tt(bw) + tt(gluc) + tt(fat) + sex + strata(strain)"
tts:
  - NULL
  - NULL
  - ["function(x, t, ...) x * log(t + 20) + x * log(t * t + 20)",
     "function(x, t, ...) x * log(t + 20) + x * log(t * t + 20)",
     "function(x, t, ...) x * log(t + 20) + x * log(t * t + 20)"]

```

#### `predication_data`

These parameters determine how testing data will be sampled for the interval, window, cumulative, and resample age-based subsets. 

* `filter_interval$intervals` A list of named character strings were the names are the age variable desired to sample over with the suffix `_ns`, and the strings are an interval over which the origianl data will be sampled.
* `filter_window`
  - `age_var` - a character string specifying the age variable over which to sample
  - `start` - a numeric value specifying the lower bound for the first window
  - `end` - a numeric value specifying the maximum value for the last upper bound
  - `window_size_vector` - a list of numeric values specifying various size for the sampling window
  - `step` - a numeric value specifying the number of units to step forard the bounds of each sampling window.
*  
```yaml
prediction_data:
  filter_interval:
    intervals:
      - [age_wk_ns: "(13, 65)"]
      - [age_wk_ns: "[39, 21)"]
      - [age_wk_ns: "[65, 117)"]
    names:
  filter_window:
    age_var: "age_wk"
    start: 13 # 3 months
    end: 117 # 27 months
    window_size_vector: [26.1, 52.1, 78] # 6, 12, 18 months
    step: 26 # 6 months
  filter_cumulative:
    age_var: "age_wk"
    start_vector: [13, 39] # 3 and 9 months
    end: 117 # 27 months
    step: 26 # 6 months
  resample:
    age_var: "age_wk"
    fraction_vector: [.75, .667, .5, .337, .25]
```
### Testing Config
```yaml
out_tag: all   # this will be the name of output files
tag_time: FALSE   # pretty s
ure this is an appendage
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


