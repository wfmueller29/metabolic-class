# metabolic-class
A generalized _Latent Class Mixed Model (LCMM)_ and _Cox Proportional Hazard Model_ pipeline for large longitudinal datasets, like those of _Study of Longitudinal Aging in Mice (SLAM)_. This is a rewrite of [traj_models](https://github.com/wfmueller29/traj_models)

---

## 🚀 Quick start — reproduce the published analysis

**You need:** R, this repo, and the data deposit (the `raw` / `clean` / `model` store from Zenodo / OneDrive).

**1. Clone and enter the repo:**
```bash
git clone https://github.com/wfmueller29/metabolic-class
cd metabolic-class
```

**2. Set the _one_ machine-specific value** in [`run/00_config.yaml`](run/00_config.yaml):
```yaml
master_dir:   "/path/to/your/downloaded/data/deposit"   # the ONLY path you must edit
rebuild_from: "raw"     # raw = rebuild everything | clean = skip cleaning | model = figures only
resilient:    false     # true = keep going + log failures (for long unattended runs)
```

**3. Run _one_ command from the repo root:**
```bash
Rscript run/run.R
```

That's it. `run.R` reads the config and runs the whole pipeline in order, timing each step. A full `raw` rebuild re-fits the models (~6.5 h). For an unattended **overnight run**, keep the machine awake and capture a log:
```bash
caffeinate -i Rscript run/run.R 2>&1 | tee run.log
```

**What you get** (all written into the repo): the figure PDFs in `figures/output/`, the environment record in `session_info.txt`, a per-step timing summary in `run_timing.txt`, and — in resilient mode — failure logs under `output/`.

### What `run.R` does, in order
| # | script | does |
|---|---|---|
| 1 | `run/01_installer.R` | restore the pinned R package library (renv) |
| 2 | `run/02_hydrate_data.R` | provision data for the chosen `rebuild_from` layer from `master_dir` |
| 3 | `run/03_preprocess.R` | run the cleaning stages (`raw` mode only) |
| 4 | `run/04_pipeline.R` | fit the LCMM + Cox models (stages 01–07) |
| 5 | `run/05_downstream.R` | run the downstream analyses (`downstream/`) |
| 6 | `run/06_render_figures.R` | assemble the publication figure PDFs |
| 7 | `run/07_session_info.R` | write the environment + timing record |

Each step is a normal `Rscript`, so you can also run any of them on their own for finer control (e.g. re-render just the figures with `Rscript run/06_render_figures.R` after a completed run).

### Repository layout
| dir | what |
|---|---|
| **`run/`** | the numbered entry points you execute — plus `run.R` (orchestrator) and `00_config.yaml` |
| **`pipeline/`** | the sequential model pipeline stages (`00a` cleaning → `07` figures) |
| **`downstream/`** | self-contained analyses that consume the pipeline's outputs (paper figures/tables) |
| **`helpers/`** | the machinery the runners call (`train` / `validate` / `predict` / `hydrate` / `wipe`) |
| **`figures/`** | the final figure-assembly package |

---

## Installation

To install this end-to-end modelling pipeline in your current working directory, run the following command your terminal: 

```bash
git clone https://github.com/wfmueller29/metabolic-class
```
## Dependencies

The package environment is pinned with [renv](https://rstudio.github.io/renv/) — `renv.lock` records the exact version of every dependency (including the in-house GitHub packages, pinned to specific commits), so the modeling environment is reproducible. To provision it, navigate to the `metabolic-class` directory and run:

```bash
Rscript run/01_installer.R
```

This restores the recorded library via `renv::restore()` (a fast no-op when your library already matches the lockfile) and installs a TeX distribution for the PDF figure renders. It runs automatically as step 1 of `run/run.R`, so you rarely need to invoke it directly. The in-house dependencies it installs:

* [Callframe](https://github.com/wfmueller29/callframe)
* [Helphlme](https://github.com/wfmueller29/helphlme)
* [SLAM](https://github.com/wfmueller29/SLAM)
* [consoler](https://github.com/wfmueller29/consoler)



## Overview

This pipeline uses file in, file out structure with yaml files, with the only two files the user is required to make is the `train_config.yaml` and the `validate_config.yaml` 

### Training
<img width="1159" alt="image" src="https://github.com/user-attachments/assets/3864b34f-2f41-433e-839b-2cdfeb8ad11d" />

### Validation
<img width="1163" alt="image" src="https://github.com/user-attachments/assets/fb23c660-1324-4dd0-9589-9dcb46425d8f" />

## How to use

### Reproduce the published analysis

See the **[Quick start](#-quick-start--reproduce-the-published-analysis)** at the top: set `master_dir` in [`run/00_config.yaml`](run/00_config.yaml) and run `Rscript run/run.R`.

The `rebuild_from` setting controls how deep the rebuild goes:
- `raw` — hydrate raw inputs → clean (`03_preprocess`) → fit models (`04_pipeline`) → downstream (`05_downstream`) → figures (`06_render_figures`)
- `clean` — hydrate cleaned data (skip preprocess) → fit models → downstream → figures
- `model` — hydrate the fitted objects (skip fitting) → downstream → figures only

Set `resilient: true` in the config for long unattended runs: on a failure the models runner (`04_pipeline`) and downstream runner (`05_downstream`) log the error to `output/run_errors.log` and continue, rather than stopping.

### Train on your own data
If you have your own longitudinal dataset that you would like to use to train, navigate to the `metabolic-class` directory and run this command in your terminal.

```bash
Rscript helpers/train.R <train_config.yaml>
```

The tedious part is creating the `train_config.yaml` file (See below)

### Validate
If you have longitudinal data you would like test against a previously trained model, navigate to the `metabolic-class` directory and run this command in your terminal. 
```bash
Rscript helpers/validate.R <validate_config.yaml>
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

