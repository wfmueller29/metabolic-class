---
title: "SLAM Metabolic Class Figures"
author: "William Mueller"
data: "2024 February 08"
output:
  html_document:
    df_print: paged
params:
  input_path: "../04_prediction_data/output/test_local.yaml"
---



## Analysis

### Load Input File



### Load Models



### Class Analysis

#### Create Census Dataframe


#### Create new class numbering



#### Create Table 1




#### Perform Chi-squared Test




#### Create clean t1




### Surival Analysis 





### Create Cox Models

- Model 1: $ Surv ~ Class $
- Model 2: $ Surv ~ Class + Sex + Strain$
- Model 3: $ Surv ~ Class + Sex * Strain$




### Trajectory Fixed Effects Plotted



![plot of chunk fixed effects](figure/fixed effects-1.png)![plot of chunk fixed effects](figure/fixed effects-2.png)![plot of chunk fixed effects](figure/fixed effects-3.png)![plot of chunk fixed effects](figure/fixed effects-4.png)![plot of chunk fixed effects](figure/fixed effects-5.png)![plot of chunk fixed effects](figure/fixed effects-6.png)

### Create Observed Trajectory Plots



![plot of chunk observed plots](figure/observed plots-1.png)![plot of chunk observed plots](figure/observed plots-2.png)![plot of chunk observed plots](figure/observed plots-3.png)![plot of chunk observed plots](figure/observed plots-4.png)![plot of chunk observed plots](figure/observed plots-5.png)![plot of chunk observed plots](figure/observed plots-6.png)

```
## [[1]]
```

![plot of chunk observed plots](figure/observed plots-7.png)

```
## 
## [[2]]
```

![plot of chunk observed plots](figure/observed plots-8.png)

```
## 
## [[3]]
```

![plot of chunk observed plots](figure/observed plots-9.png)

```
## 
## [[4]]
```

![plot of chunk observed plots](figure/observed plots-10.png)

```
## 
## [[5]]
```

![plot of chunk observed plots](figure/observed plots-11.png)

```
## 
## [[6]]
```

![plot of chunk observed plots](figure/observed plots-12.png)

### Create Plots for Other Metabolic Outcomes by Class




```
## [[1]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-1.png)

```
## 
## [[2]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-2.png)

```
## 
## [[3]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-3.png)

```
## 
## [[4]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-4.png)

```
## 
## [[5]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-5.png)

```
## 
## [[6]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-6.png)

```
## 
## [[1]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-7.png)

```
## 
## [[2]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-8.png)

```
## 
## [[3]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-9.png)

```
## 
## [[4]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-10.png)

```
## 
## [[5]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-11.png)

```
## 
## [[6]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-12.png)

```
## 
## [[1]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-13.png)

```
## 
## [[2]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-14.png)

```
## 
## [[3]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-15.png)

```
## 
## [[4]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-16.png)

```
## 
## [[5]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-17.png)

```
## 
## [[6]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-18.png)

```
## 
## [[1]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-19.png)

```
## 
## [[2]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-20.png)

```
## 
## [[3]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-21.png)

```
## 
## [[4]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-22.png)

```
## 
## [[5]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-23.png)

```
## 
## [[6]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-24.png)

```
## 
## [[1]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-25.png)

```
## 
## [[2]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-26.png)

```
## 
## [[3]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-27.png)

```
## 
## [[4]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-28.png)

```
## 
## [[5]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-29.png)

```
## 
## [[6]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-30.png)

```
## 
## [[1]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-31.png)

```
## 
## [[2]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-32.png)

```
## 
## [[3]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-33.png)

```
## 
## [[4]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-34.png)

```
## 
## [[5]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-35.png)

```
## 
## [[6]]
```

![plot of chunk other metabolic outcomes](figure/other metabolic outcomes-36.png)

### Fit other metabolic outcomes with LME

- Model0 (No interaction): $outcome = Age + Age^2 + Class + (Age + Age^2 | Subject)$
- Model0.5 : $outcome = Age + Age^2 + Class + sex * Strain + (Age + Age^2 | Subject)$
- Model1 (no controlled): $outcome = (Age + Age^2) * Class + (Age + Age^2| Subject)$
- Model2 (Sex and Strain additive controlled) : $outcome = (Age + Age^2) * Class + Sex * Strain + (Age + Age^2 | Subject)$
- Model3 (Sex and Strain interacted controlled): $outcome = (Age + Age^2) * Class + (Age + Age^2) * Sex * Strain + (Age + Age^2 | Subject)$





### Create Spaghettie Plots





### Class Prediction

#### Class Prediction Raw Results



```
## [1] "filter_cumulative_data"
## [1] 1
## [1] 2
## [1] 3
## [1] 4
## [1] 5
## [1] 6
## [1] "filter_window_data"
## [1] 1
## [1] 2
## [1] 3
## [1] 4
## [1] 5
## [1] 6
## [1] "filter_interval_data"
## [1] 1
## [1] 2
## [1] 3
## [1] 4
## [1] 5
## [1] 6
## [1] "resampled_data"
## [1] 1
## [1] 2
## [1] 3
## [1] 4
## [1] 5
## [1] 6
```

### Sensititviy, Specificity, PPV, NPV, Tables

|  | Gold Yes | Gold No | total |
| --- | --- | --- | ---- |
| pred Yes | $TP = tp$ | $FP = pred\_class - tp$ | pred_class |
| pred No | $FN =og\_class - tp$ | $TN = n - (og\_class + pred\_class - tp)$ | n - pred_class | 
| total | og_class | n - og_class | n

- Sensitivity = 
$\frac{TP}{TP + FN} = 
\frac{tp}{tp + og\_class - tp} =
\frac{tp}{og\_class}$
- Specificity =
$\frac{TN}{FP + TN} = 
\frac{n - (og\_class + pred\_class - tp)}{pred\_class - tp + n - og\_class - pred\_class + tp)} = 
\frac{n - (og\_class + pred\_class - tp)}{n - og\_class}$
- Positive Predictive Value = 
$\frac{TP}{TP + FP} = 
\frac{tp}{tp + pred\_class - tp} = 
\frac{tp}{pred\_classs}$
- Negative Predictive Value = 
$\frac{TN}{FN + TN} = 
\frac{n - (og\_class + pred\_class -tp)}{og\_class - tp + n - og\_class - pred\_class + tp) } =
\frac{n - (og\_class + pred\_class - tp)}{n - pred\_class}$
- Accuracy = 
$\frac{TN + TP}{TN + TP + FN + FP} = 
\frac{2tp + n - og\_class - pred\_class}{n}$






#### Dataframe for each subset type with prediction statistics





#### Prepare prediciton dataframe for plotting





#### Plot Prediction Results




```
## [[1]]
```

![plot of chunk plot pred_results](figure/plot pred_results-1.png)

```
## 
## [[2]]
```

![plot of chunk plot pred_results](figure/plot pred_results-2.png)

```
## 
## [[3]]
```

![plot of chunk plot pred_results](figure/plot pred_results-3.png)

```
## 
## [[4]]
```

![plot of chunk plot pred_results](figure/plot pred_results-4.png)

```
## 
## [[5]]
```

![plot of chunk plot pred_results](figure/plot pred_results-5.png)

```
## 
## [[6]]
```

![plot of chunk plot pred_results](figure/plot pred_results-6.png)

```
## [[1]]
```

![plot of chunk plot pred_results](figure/plot pred_results-7.png)

```
## 
## [[2]]
```

![plot of chunk plot pred_results](figure/plot pred_results-8.png)

```
## 
## [[3]]
```

![plot of chunk plot pred_results](figure/plot pred_results-9.png)

```
## 
## [[4]]
```

![plot of chunk plot pred_results](figure/plot pred_results-10.png)

```
## 
## [[5]]
```

![plot of chunk plot pred_results](figure/plot pred_results-11.png)

```
## 
## [[6]]
```

![plot of chunk plot pred_results](figure/plot pred_results-12.png)

```
## [[1]]
```

![plot of chunk plot pred_results](figure/plot pred_results-13.png)

```
## 
## [[2]]
```

![plot of chunk plot pred_results](figure/plot pred_results-14.png)

```
## 
## [[3]]
```

![plot of chunk plot pred_results](figure/plot pred_results-15.png)

```
## 
## [[4]]
```

![plot of chunk plot pred_results](figure/plot pred_results-16.png)

```
## 
## [[5]]
```

![plot of chunk plot pred_results](figure/plot pred_results-17.png)

```
## 
## [[6]]
```

![plot of chunk plot pred_results](figure/plot pred_results-18.png)

```
## [[1]]
```

![plot of chunk plot pred_results](figure/plot pred_results-19.png)

```
## 
## [[2]]
```

![plot of chunk plot pred_results](figure/plot pred_results-20.png)

```
## 
## [[3]]
```

![plot of chunk plot pred_results](figure/plot pred_results-21.png)

```
## 
## [[4]]
```

![plot of chunk plot pred_results](figure/plot pred_results-22.png)

```
## 
## [[5]]
```

![plot of chunk plot pred_results](figure/plot pred_results-23.png)

```
## 
## [[6]]
```

![plot of chunk plot pred_results](figure/plot pred_results-24.png)

#### Plot Accuracy


```
## [[1]]
```

![plot of chunk plot accuracy](figure/plot accuracy-1.png)

```
## 
## [[2]]
```

![plot of chunk plot accuracy](figure/plot accuracy-2.png)

```
## 
## [[3]]
```

![plot of chunk plot accuracy](figure/plot accuracy-3.png)

```
## 
## [[4]]
```

![plot of chunk plot accuracy](figure/plot accuracy-4.png)

```
## 
## [[5]]
```

![plot of chunk plot accuracy](figure/plot accuracy-5.png)

```
## 
## [[6]]
```

![plot of chunk plot accuracy](figure/plot accuracy-6.png)

```
## [[1]]
```

![plot of chunk plot accuracy](figure/plot accuracy-7.png)

```
## 
## [[2]]
```

![plot of chunk plot accuracy](figure/plot accuracy-8.png)

```
## 
## [[3]]
```

![plot of chunk plot accuracy](figure/plot accuracy-9.png)

```
## 
## [[4]]
```

![plot of chunk plot accuracy](figure/plot accuracy-10.png)

```
## 
## [[5]]
```

![plot of chunk plot accuracy](figure/plot accuracy-11.png)

```
## 
## [[6]]
```

![plot of chunk plot accuracy](figure/plot accuracy-12.png)

```
## [[1]]
```

![plot of chunk plot accuracy](figure/plot accuracy-13.png)

```
## 
## [[2]]
```

![plot of chunk plot accuracy](figure/plot accuracy-14.png)

```
## 
## [[3]]
```

![plot of chunk plot accuracy](figure/plot accuracy-15.png)

```
## 
## [[4]]
```

![plot of chunk plot accuracy](figure/plot accuracy-16.png)

```
## 
## [[5]]
```

![plot of chunk plot accuracy](figure/plot accuracy-17.png)

```
## 
## [[6]]
```

![plot of chunk plot accuracy](figure/plot accuracy-18.png)

```
## [[1]]
```

![plot of chunk plot accuracy](figure/plot accuracy-19.png)

```
## 
## [[2]]
```

![plot of chunk plot accuracy](figure/plot accuracy-20.png)

```
## 
## [[3]]
```

![plot of chunk plot accuracy](figure/plot accuracy-21.png)

```
## 
## [[4]]
```

![plot of chunk plot accuracy](figure/plot accuracy-22.png)

```
## 
## [[5]]
```

![plot of chunk plot accuracy](figure/plot accuracy-23.png)

```
## 
## [[6]]
```

![plot of chunk plot accuracy](figure/plot accuracy-24.png)

### Compute Accuracy Again as Double Check and Bootstrap





#### Combine bootstraped accuracy for each simulation type





#### Prepare Accuracy Dataframe for pLotting



#### Extract Mean and CI from Bootstrapped Accuracy





#### Plot Accuracy Again With confidence Intervals




```
## [[1]]
```

![plot of chunk plot accuracy with bootstrapped confidence intervals](figure/plot accuracy with bootstrapped confidence intervals-1.png)

```
## 
## [[2]]
```

![plot of chunk plot accuracy with bootstrapped confidence intervals](figure/plot accuracy with bootstrapped confidence intervals-2.png)

```
## 
## [[3]]
```

![plot of chunk plot accuracy with bootstrapped confidence intervals](figure/plot accuracy with bootstrapped confidence intervals-3.png)

```
## 
## [[4]]
```

![plot of chunk plot accuracy with bootstrapped confidence intervals](figure/plot accuracy with bootstrapped confidence intervals-4.png)

```
## 
## [[5]]
```

![plot of chunk plot accuracy with bootstrapped confidence intervals](figure/plot accuracy with bootstrapped confidence intervals-5.png)

```
## 
## [[6]]
```

![plot of chunk plot accuracy with bootstrapped confidence intervals](figure/plot accuracy with bootstrapped confidence intervals-6.png)

```
## [[1]]
```

![plot of chunk plot accuracy with bootstrapped confidence intervals](figure/plot accuracy with bootstrapped confidence intervals-7.png)

```
## 
## [[2]]
```

![plot of chunk plot accuracy with bootstrapped confidence intervals](figure/plot accuracy with bootstrapped confidence intervals-8.png)

```
## 
## [[3]]
```

![plot of chunk plot accuracy with bootstrapped confidence intervals](figure/plot accuracy with bootstrapped confidence intervals-9.png)

```
## 
## [[4]]
```

![plot of chunk plot accuracy with bootstrapped confidence intervals](figure/plot accuracy with bootstrapped confidence intervals-10.png)

```
## 
## [[5]]
```

![plot of chunk plot accuracy with bootstrapped confidence intervals](figure/plot accuracy with bootstrapped confidence intervals-11.png)

```
## 
## [[6]]
```

![plot of chunk plot accuracy with bootstrapped confidence intervals](figure/plot accuracy with bootstrapped confidence intervals-12.png)

```
## [[1]]
```

![plot of chunk plot accuracy with bootstrapped confidence intervals](figure/plot accuracy with bootstrapped confidence intervals-13.png)

```
## 
## [[2]]
```

![plot of chunk plot accuracy with bootstrapped confidence intervals](figure/plot accuracy with bootstrapped confidence intervals-14.png)

```
## 
## [[3]]
```

![plot of chunk plot accuracy with bootstrapped confidence intervals](figure/plot accuracy with bootstrapped confidence intervals-15.png)

```
## 
## [[4]]
```

![plot of chunk plot accuracy with bootstrapped confidence intervals](figure/plot accuracy with bootstrapped confidence intervals-16.png)

```
## 
## [[5]]
```

![plot of chunk plot accuracy with bootstrapped confidence intervals](figure/plot accuracy with bootstrapped confidence intervals-17.png)

```
## 
## [[6]]
```

![plot of chunk plot accuracy with bootstrapped confidence intervals](figure/plot accuracy with bootstrapped confidence intervals-18.png)

```
## [[1]]
```

![plot of chunk plot accuracy with bootstrapped confidence intervals](figure/plot accuracy with bootstrapped confidence intervals-19.png)

```
## 
## [[2]]
```

![plot of chunk plot accuracy with bootstrapped confidence intervals](figure/plot accuracy with bootstrapped confidence intervals-20.png)

```
## 
## [[3]]
```

![plot of chunk plot accuracy with bootstrapped confidence intervals](figure/plot accuracy with bootstrapped confidence intervals-21.png)

```
## 
## [[4]]
```

![plot of chunk plot accuracy with bootstrapped confidence intervals](figure/plot accuracy with bootstrapped confidence intervals-22.png)

```
## 
## [[5]]
```

![plot of chunk plot accuracy with bootstrapped confidence intervals](figure/plot accuracy with bootstrapped confidence intervals-23.png)

```
## 
## [[6]]
```

![plot of chunk plot accuracy with bootstrapped confidence intervals](figure/plot accuracy with bootstrapped confidence intervals-24.png)

## Combined Metabolic Class

### Create Combined Cox 





### Determine get Hazard Predictions from test set

#### Predict Class Assignement for Test Dataframe




```
## [1] "filter_cumulative_data"
## [1] 1
## [1] 2
## [1] 3
## [1] 4
## [1] 5
## [1] 6
## [1] "filter_window_data"
## [1] 1
## [1] 2
## [1] 3
## [1] 4
## [1] 5
## [1] 6
## [1] "filter_interval_data"
## [1] 1
## [1] 2
## [1] 3
## [1] 4
## [1] 5
## [1] 6
```

#### Create new test class numbering


```
## [1] "filter_cumulative_test_results"
## [1] "slam_bw_train_test_bw_age_wk"
## [1] "slam_fat_train_test_fat_age_wk"
## [1] "slam_gluc_train_test_gluc_age_wk"
## [1] "filter_window_test_results"
## [1] "slam_bw_train_test_bw_age_wk"
## [1] "slam_fat_train_test_fat_age_wk"
## [1] "slam_gluc_train_test_gluc_age_wk"
## [1] "filter_interval_test_results"
## [1] "slam_bw_train_test_bw_age_wk"
## [1] "slam_fat_train_test_fat_age_wk"
## [1] "slam_gluc_train_test_gluc_age_wk"
```

#### Merge test_data prediction dataframes


```
## [1] "_fat"
## [1] "_gluc"
## [1] "_fat"
## [1] "_gluc"
## [1] "_fat"
## [1] "_gluc"
```

#### Create test census dataframe






```
## [1] 1369
## [1] 2429
## [1] 2890
## [1] 2922
## [1] 2922
## [1] 2922
## [1] 881
## [1] 1300
## [1] 1329
## [1] 1329
## [1] 1329
## [1] 259
## [1] 281
## [1] 281
## [1] 281
## [1] 0
## [1] 0
## [1] 0
## [1] 1369
## [1] 1133
## [1] 1004
## [1] 767
## [1] 487
## [1] 259
## [1] 54
## [1] 25
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 2429
## [1] 1981
## [1] 1639
## [1] 1064
## [1] 619
## [1] 281
## [1] 57
## [1] 25
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 2921
## [1] 1493
## [1] 494
## [1] 645
## [1] 2235
```

#### We need to predict hazard ratios for our test sets


```
## [1] "filter_interval_test"
## [1] 1
## [1] 2
## [1] 3
## [1] 4
## [1] 1368
## [1] 1368
## [1] 1368
## [1] 2428
## [1] 2428
## [1] 2428
## [1] 2889
## [1] 2889
## [1] 2889
## [1] 2921
## [1] 2921
## [1] 2921
## [1] 2921
## [1] 2921
## [1] 2921
## [1] 2921
## [1] 2921
## [1] 2921
## [1] 881
## [1] 881
## [1] 881
## [1] 1300
## [1] 1300
## [1] 1300
## [1] 1329
## [1] 1329
## [1] 1329
## [1] 1329
## [1] 1329
## [1] 1329
## [1] 1329
## [1] 1329
## [1] 1329
## [1] 259
## [1] 259
## [1] 259
## [1] 281
## [1] 281
## [1] 281
## [1] 281
## [1] 281
## [1] 281
## [1] 281
## [1] 281
## [1] 281
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 5
## [1] 1368
## [1] 1368
## [1] 1368
## [1] 2428
## [1] 2428
## [1] 2428
## [1] 2889
## [1] 2889
## [1] 2889
## [1] 2921
## [1] 2921
## [1] 2921
## [1] 2921
## [1] 2921
## [1] 2921
## [1] 2921
## [1] 2921
## [1] 2921
## [1] 881
## [1] 881
## [1] 881
## [1] 1300
## [1] 1300
## [1] 1300
## [1] 1329
## [1] 1329
## [1] 1329
## [1] 1329
## [1] 1329
## [1] 1329
## [1] 1329
## [1] 1329
## [1] 1329
## [1] 259
## [1] 259
## [1] 259
## [1] 281
## [1] 281
## [1] 281
## [1] 281
## [1] 281
## [1] 281
## [1] 281
## [1] 281
## [1] 281
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 6
## [1] 1368
## [1] 1368
## [1] 1368
## [1] 2428
## [1] 2428
## [1] 2428
## [1] 2889
## [1] 2889
## [1] 2889
## [1] 2921
## [1] 2921
## [1] 2921
## [1] 2921
## [1] 2921
## [1] 2921
## [1] 2921
## [1] 2921
## [1] 2921
## [1] 881
## [1] 881
## [1] 881
## [1] 1300
## [1] 1300
## [1] 1300
## [1] 1329
## [1] 1329
## [1] 1329
## [1] 1329
## [1] 1329
## [1] 1329
## [1] 1329
## [1] 1329
## [1] 1329
## [1] 259
## [1] 259
## [1] 259
## [1] 281
## [1] 281
## [1] 281
## [1] 281
## [1] 281
## [1] 281
## [1] 281
## [1] 281
## [1] 281
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] "filter_interval_test"
## [1] 1
## [1] 2
## [1] 3
## [1] 4
## [1] 1368
## [1] 1368
## [1] 1368
## [1] 1132
## [1] 1132
## [1] 1132
## [1] 1004
## [1] 1004
## [1] 1004
## [1] 767
## [1] 767
## [1] 767
## [1] 487
## [1] 487
## [1] 487
## [1] 259
## [1] 259
## [1] 259
## [1] 54
## [1] 54
## [1] 54
## [1] 25
## [1] 25
## [1] 25
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 2428
## [1] 2428
## [1] 2428
## [1] 1980
## [1] 1980
## [1] 1980
## [1] 1639
## [1] 1639
## [1] 1639
## [1] 1064
## [1] 1064
## [1] 1064
## [1] 619
## [1] 619
## [1] 619
## [1] 281
## [1] 281
## [1] 281
## [1] 57
## [1] 57
## [1] 57
## [1] 25
## [1] 25
## [1] 25
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 5
## [1] 1368
## [1] 1368
## [1] 1368
## [1] 1132
## [1] 1132
## [1] 1132
## [1] 1004
## [1] 1004
## [1] 1004
## [1] 767
## [1] 767
## [1] 767
## [1] 487
## [1] 487
## [1] 487
## [1] 259
## [1] 259
## [1] 259
## [1] 54
## [1] 54
## [1] 54
## [1] 25
## [1] 25
## [1] 25
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 2428
## [1] 2428
## [1] 2428
## [1] 1980
## [1] 1980
## [1] 1980
## [1] 1639
## [1] 1639
## [1] 1639
## [1] 1064
## [1] 1064
## [1] 1064
## [1] 619
## [1] 619
## [1] 619
## [1] 281
## [1] 281
## [1] 281
## [1] 57
## [1] 57
## [1] 57
## [1] 25
## [1] 25
## [1] 25
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 6
## [1] 1368
## [1] 1368
## [1] 1368
## [1] 1132
## [1] 1132
## [1] 1132
## [1] 1004
## [1] 1004
## [1] 1004
## [1] 767
## [1] 767
## [1] 767
## [1] 487
## [1] 487
## [1] 487
## [1] 259
## [1] 259
## [1] 259
## [1] 54
## [1] 54
## [1] 54
## [1] 25
## [1] 25
## [1] 25
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 2428
## [1] 2428
## [1] 2428
## [1] 1980
## [1] 1980
## [1] 1980
## [1] 1639
## [1] 1639
## [1] 1639
## [1] 1064
## [1] 1064
## [1] 1064
## [1] 619
## [1] 619
## [1] 619
## [1] 281
## [1] 281
## [1] 281
## [1] 57
## [1] 57
## [1] 57
## [1] 25
## [1] 25
## [1] 25
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] 0
## [1] "filter_interval_test"
## [1] 1
## [1] 2
## [1] 3
## [1] 4
## [1] 2921
## [1] 2921
## [1] 2921
## [1] 1492
## [1] 1492
## [1] 1492
## [1] 494
## [1] 494
## [1] 494
## [1] 645
## [1] 645
## [1] 645
## [1] 2234
## [1] 2234
## [1] 2234
## [1] 5
## [1] 2921
## [1] 2921
## [1] 2921
## [1] 1492
## [1] 1492
## [1] 1492
## [1] 494
## [1] 494
## [1] 494
## [1] 645
## [1] 645
## [1] 645
## [1] 2234
## [1] 2234
## [1] 2234
## [1] 6
## [1] 2921
## [1] 2921
## [1] 2921
## [1] 1492
## [1] 1492
## [1] 1492
## [1] 494
## [1] 494
## [1] 494
## [1] 645
## [1] 645
## [1] 645
## [1] 2234
## [1] 2234
## [1] 2234
```

#### Determine Calibration by Regressing PI on Test outcomes


```
## [1] "filter_cumulative_test"
## [1] "filter_window_test"
## [1] "filter_interval_test"
```

#### Convert from short to long for lp1, lp2, lp3



#### Generated columns for prediction data plotting



#### Create plots of concordances and regression on PI



### Save R Objects

#### Prune Final Models Before Saving 


```
## Percent memory pruned: 80.66358
```

#### Save 






```
## Error in setwd(file.path("output", params$model_dir)): character argument expected
```

```
## Error in save(df_list, file = "df_list.RDATA"): object 'df_list' not found
```

```
## Error in save(dfs_prediction, file = "dfs_prediction.RDATA"): object 'dfs_prediction' not found
```
