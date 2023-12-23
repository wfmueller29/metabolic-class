---
title: "Dataset Creation for Trajectory SLAM"
author: "Eric Shiroma, William Mueller"
date: "2023 November 04"
output:
  html_document:
    df_print: paged
---



## Analysis 
#### census data read in
  - input file census.csv (10/30/2019)
  - edit csv column name 'Animal_ID'
  


#### body weight data read in and clean
  - input file BW_Temp_FC_All_2019-11-16 (11/16/2019)
  - input file NMR.csv (10/30/2019)
  - clean body weights (funny values) 
    - text to missing 
    - bw < 10 to missing 
    - bw > 100 to missing
  - merge nmr body weights into main body weight dataset (bodywt)
    - bodywt_nmr
  
![plot of chunk slam_bodyweight](figure/slam_bodyweight-1.png)

#### glucose data read in and clean 
  - input file Glucose_Lactate.csv (10/30/2019)
  - edit csv column name 'Stress_Notes'
  - clean glucose (funny values) 
    - text to missing 
    - gluc < 20 or gluc >= 300 to missing 
    
![plot of chunk slam_glucose](figure/slam_glucose-1.png)

#### body comp data read in and clean 
  - input file NMR.csv (10/30/2019)
  - clean nmr (funny values) 
    - text to missing 
    - fat <= 0 to missing
    - lean <= 5 to NA
    - lean >= 40 to NA

![plot of chunk slam_nmr](figure/slam_nmr-1.png)![plot of chunk slam_nmr](figure/slam_nmr-2.png)



#### survival data read in and clean 
  - input file Survival.csv (10/30/2019)
  - clean survival (funny values) 
    - text to missing 
    - recode old to new idnos 
    


#### merging all datasets into a main file and clean
  - glucose
  - bodywt (body weight)
  - nmr (body fat)
  - census
  - removal of timepoints before dob or mouse facility arrival date
  

  
#### restriction to cohorts 1 to 10



#### population characteristics
- 2145 mice with valid indices 
- 49.79 % female 
- 49.37 % B6 

#### age characteristics



<table class="table table-striped" style="width: auto !important; margin-left: auto; margin-right: auto;">
<caption>Age Characteristics</caption>
 <thead>
  <tr>
   <th style="text-align:center;"> group </th>
   <th style="text-align:center;"> n </th>
   <th style="text-align:center;"> mean </th>
   <th style="text-align:center;"> sd </th>
   <th style="text-align:center;"> median </th>
   <th style="text-align:center;"> trimmed </th>
   <th style="text-align:center;"> mad </th>
   <th style="text-align:center;"> min </th>
   <th style="text-align:center;"> max </th>
   <th style="text-align:center;"> range </th>
   <th style="text-align:center;"> skew </th>
   <th style="text-align:center;"> kurtosis </th>
   <th style="text-align:center;"> se </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:center;"> all </td>
   <td style="text-align:center;"> 2145 </td>
   <td style="text-align:center;"> 13.75 </td>
   <td style="text-align:center;"> 3.34 </td>
   <td style="text-align:center;"> 14 </td>
   <td style="text-align:center;"> 13.71 </td>
   <td style="text-align:center;"> 1.05 </td>
   <td style="text-align:center;"> 8.29 </td>
   <td style="text-align:center;"> 113.14 </td>
   <td style="text-align:center;"> 104.85 </td>
   <td style="text-align:center;"> 19.84 </td>
   <td style="text-align:center;"> 498.35 </td>
   <td style="text-align:center;"> 0.07 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> F </td>
   <td style="text-align:center;"> 1068 </td>
   <td style="text-align:center;"> 13.94 </td>
   <td style="text-align:center;"> 3.27 </td>
   <td style="text-align:center;"> 14 </td>
   <td style="text-align:center;"> 13.79 </td>
   <td style="text-align:center;"> 1.05 </td>
   <td style="text-align:center;"> 11.14 </td>
   <td style="text-align:center;"> 72.43 </td>
   <td style="text-align:center;"> 61.29 </td>
   <td style="text-align:center;"> 16.05 </td>
   <td style="text-align:center;"> 284.40 </td>
   <td style="text-align:center;"> 0.10 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> M </td>
   <td style="text-align:center;"> 1077 </td>
   <td style="text-align:center;"> 13.57 </td>
   <td style="text-align:center;"> 3.39 </td>
   <td style="text-align:center;"> 14 </td>
   <td style="text-align:center;"> 13.63 </td>
   <td style="text-align:center;"> 1.05 </td>
   <td style="text-align:center;"> 8.29 </td>
   <td style="text-align:center;"> 113.14 </td>
   <td style="text-align:center;"> 104.85 </td>
   <td style="text-align:center;"> 23.35 </td>
   <td style="text-align:center;"> 687.68 </td>
   <td style="text-align:center;"> 0.10 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> B6 </td>
   <td style="text-align:center;"> 1059 </td>
   <td style="text-align:center;"> 13.84 </td>
   <td style="text-align:center;"> 3.21 </td>
   <td style="text-align:center;"> 14 </td>
   <td style="text-align:center;"> 13.72 </td>
   <td style="text-align:center;"> 0.85 </td>
   <td style="text-align:center;"> 12.00 </td>
   <td style="text-align:center;"> 113.14 </td>
   <td style="text-align:center;"> 101.14 </td>
   <td style="text-align:center;"> 27.83 </td>
   <td style="text-align:center;"> 856.83 </td>
   <td style="text-align:center;"> 0.10 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> HET3 </td>
   <td style="text-align:center;"> 1086 </td>
   <td style="text-align:center;"> 13.67 </td>
   <td style="text-align:center;"> 3.45 </td>
   <td style="text-align:center;"> 14 </td>
   <td style="text-align:center;"> 13.70 </td>
   <td style="text-align:center;"> 1.05 </td>
   <td style="text-align:center;"> 8.29 </td>
   <td style="text-align:center;"> 72.43 </td>
   <td style="text-align:center;"> 64.14 </td>
   <td style="text-align:center;"> 13.48 </td>
   <td style="text-align:center;"> 229.80 </td>
   <td style="text-align:center;"> 0.10 </td>
  </tr>
</tbody>
</table>

*** 

#### census_c16_death creation
  - merge 
    - census
    - surv
    - main_all2
  - restrict to cohorts 1 to 10
  - remove mice with missing time of death
  - create all cause death censor category
    - all-cause mortality included: "Found dead", "Per PI", "Culled", "DVR or Pathology", "Culled Per Vet"
    
*** 



#### cause of death 

<table class="table table-striped" style="width: auto !important; margin-left: auto; margin-right: auto;">
<caption>Cause of Death</caption>
 <thead>
  <tr>
   <th style="text-align:center;"> Cause of Death </th>
   <th style="text-align:center;"> Frequency </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:center;"> cage flood </td>
   <td style="text-align:center;"> 4 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> cull per pi </td>
   <td style="text-align:center;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> cull per vet </td>
   <td style="text-align:center;"> 8 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> culled </td>
   <td style="text-align:center;"> 14 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> culled per vet </td>
   <td style="text-align:center;"> 248 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> died during experiment </td>
   <td style="text-align:center;"> 3 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> died during procedure </td>
   <td style="text-align:center;"> 47 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> dvr or pathology </td>
   <td style="text-align:center;"> 58 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> end of study </td>
   <td style="text-align:center;"> 11 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> end of study, organs removed </td>
   <td style="text-align:center;"> 344 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> euthanized </td>
   <td style="text-align:center;"> 8 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> found dead </td>
   <td style="text-align:center;"> 830 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> not in room </td>
   <td style="text-align:center;"> 9 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> per pi </td>
   <td style="text-align:center;"> 181 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> per vet </td>
   <td style="text-align:center;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> used in experiment </td>
   <td style="text-align:center;"> 374 </td>
  </tr>
</tbody>
</table>

***

#### death frequency 

<table class="table table-striped" style="width: auto !important; margin-left: auto; margin-right: auto;">
<caption>Death Frequency</caption>
 <thead>
  <tr>
   <th style="text-align:center;"> Dead = 1 </th>
   <th style="text-align:center;"> Frequency </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:center;"> 0 </td>
   <td style="text-align:center;"> 800 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> 1 </td>
   <td style="text-align:center;"> 1341 </td>
  </tr>
</tbody>
</table>

***

#### follow up time 

<table class="table table-striped" style="width: auto !important; margin-left: auto; margin-right: auto;">
<caption>Follow Up Time</caption>
 <thead>
  <tr>
   <th style="text-align:center;"> vars </th>
   <th style="text-align:center;"> n </th>
   <th style="text-align:center;"> mean </th>
   <th style="text-align:center;"> sd </th>
   <th style="text-align:center;"> median </th>
   <th style="text-align:center;"> trimmed </th>
   <th style="text-align:center;"> mad </th>
   <th style="text-align:center;"> min </th>
   <th style="text-align:center;"> max </th>
   <th style="text-align:center;"> range </th>
   <th style="text-align:center;"> skew </th>
   <th style="text-align:center;"> kurtosis </th>
   <th style="text-align:center;"> se </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:center;"> 1.00 </td>
   <td style="text-align:center;"> 2141.00 </td>
   <td style="text-align:center;"> 92.78 </td>
   <td style="text-align:center;"> 32.50 </td>
   <td style="text-align:center;"> 100.00 </td>
   <td style="text-align:center;"> 96.50 </td>
   <td style="text-align:center;"> 28.17 </td>
   <td style="text-align:center;"> -97.00 </td>
   <td style="text-align:center;"> 168.00 </td>
   <td style="text-align:center;"> 265.00 </td>
   <td style="text-align:center;"> -1.10 </td>
   <td style="text-align:center;"> 1.32 </td>
   <td style="text-align:center;"> 0.70 </td>
  </tr>
</tbody>
</table>

*** 

#### life expectancy 



<table class="table table-striped" style="width: auto !important; ">
<caption>Life Expectancy</caption>
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:center;"> Group </th>
   <th style="text-align:center;"> Total </th>
   <th style="text-align:center;"> Dead </th>
   <th style="text-align:center;"> Life Expectancy <br> (weeks) </th>
   <th style="text-align:center;"> iqr </th>
   <th style="text-align:center;"> sd </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:center;"> all </td>
   <td style="text-align:center;"> 2141 </td>
   <td style="text-align:center;"> 1341 </td>
   <td style="text-align:center;"> 114.0 </td>
   <td style="text-align:center;"> 97 days </td>
   <td style="text-align:center;"> 127.00 days </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:center;"> female </td>
   <td style="text-align:center;"> 1066 </td>
   <td style="text-align:center;"> 662 </td>
   <td style="text-align:center;"> 114.5 </td>
   <td style="text-align:center;"> 98 days </td>
   <td style="text-align:center;"> 127.75 days </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:center;"> male </td>
   <td style="text-align:center;"> 1075 </td>
   <td style="text-align:center;"> 679 </td>
   <td style="text-align:center;"> 114.0 </td>
   <td style="text-align:center;"> 96 days </td>
   <td style="text-align:center;"> 127.00 days </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:center;"> HET3 </td>
   <td style="text-align:center;"> 1083 </td>
   <td style="text-align:center;"> 655 </td>
   <td style="text-align:center;"> 113.0 </td>
   <td style="text-align:center;"> 95 days </td>
   <td style="text-align:center;"> 129.00 days </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5 </td>
   <td style="text-align:center;"> B6 </td>
   <td style="text-align:center;"> 1058 </td>
   <td style="text-align:center;"> 686 </td>
   <td style="text-align:center;"> 114.0 </td>
   <td style="text-align:center;"> 99 days </td>
   <td style="text-align:center;"> 126.00 days </td>
  </tr>
</tbody>
</table>

*** 

#### create timepoints as percent life expectancy
- "per_age_wk" in main_all2
- "per_fu_wk" and "per_le_wk" in census_c16_death



***

#### frequencies of measures 



<table class="table table-striped" style="width: auto !important; margin-left: auto; margin-right: auto;">
<caption>Assessment Frequencies</caption>
 <thead>
  <tr>
   <th style="text-align:center;"> indices </th>
   <th style="text-align:center;"> group </th>
   <th style="text-align:center;"> n </th>
   <th style="text-align:center;"> mean </th>
   <th style="text-align:center;"> sd </th>
   <th style="text-align:center;"> median </th>
   <th style="text-align:center;"> trimmed </th>
   <th style="text-align:center;"> mad </th>
   <th style="text-align:center;"> min </th>
   <th style="text-align:center;"> max </th>
   <th style="text-align:center;"> range </th>
   <th style="text-align:center;"> skew </th>
   <th style="text-align:center;"> kurtosis </th>
   <th style="text-align:center;"> se </th>
   <th style="text-align:center;"> age_min </th>
   <th style="text-align:center;"> age_max </th>
   <th style="text-align:center;"> le_min </th>
   <th style="text-align:center;"> le_max </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:center;border-right:1px solid;"> glucose </td>
   <td style="text-align:center;"> all </td>
   <td style="text-align:center;"> 1333 </td>
   <td style="text-align:center;"> 6.31 </td>
   <td style="text-align:center;"> 1.86 </td>
   <td style="text-align:center;"> 7.00 </td>
   <td style="text-align:center;"> 6.45 </td>
   <td style="text-align:center;"> 1.48 </td>
   <td style="text-align:center;"> 0.00 </td>
   <td style="text-align:center;"> 10.00 </td>
   <td style="text-align:center;"> 10.00 </td>
   <td style="text-align:center;"> -0.71 </td>
   <td style="text-align:center;"> 0.66 </td>
   <td style="text-align:center;"> 0.05 </td>
   <td style="text-align:center;"> 11.14 </td>
   <td style="text-align:center;"> 146.57 </td>
   <td style="text-align:center;"> 11.14 </td>
   <td style="text-align:center;"> 146.57 </td>
  </tr>
  <tr>
   <td style="text-align:center;border-right:1px solid;"> glucose </td>
   <td style="text-align:center;"> F </td>
   <td style="text-align:center;"> 657 </td>
   <td style="text-align:center;"> 6.36 </td>
   <td style="text-align:center;"> 1.81 </td>
   <td style="text-align:center;"> 7 </td>
   <td style="text-align:center;"> 6.49 </td>
   <td style="text-align:center;"> 1.48 </td>
   <td style="text-align:center;"> 0 </td>
   <td style="text-align:center;"> 10 </td>
   <td style="text-align:center;"> 10 </td>
   <td style="text-align:center;"> -0.79 </td>
   <td style="text-align:center;"> 1.06 </td>
   <td style="text-align:center;"> 0.07 </td>
   <td style="text-align:center;"> 11.14 </td>
   <td style="text-align:center;"> 146.57 </td>
   <td style="text-align:center;"> 11.14 </td>
   <td style="text-align:center;"> 146.57 </td>
  </tr>
  <tr>
   <td style="text-align:center;border-right:1px solid;"> glucose </td>
   <td style="text-align:center;"> M </td>
   <td style="text-align:center;"> 676 </td>
   <td style="text-align:center;"> 6.27 </td>
   <td style="text-align:center;"> 1.9 </td>
   <td style="text-align:center;"> 7 </td>
   <td style="text-align:center;"> 6.42 </td>
   <td style="text-align:center;"> 1.48 </td>
   <td style="text-align:center;"> 0 </td>
   <td style="text-align:center;"> 10 </td>
   <td style="text-align:center;"> 10 </td>
   <td style="text-align:center;"> -0.64 </td>
   <td style="text-align:center;"> 0.32 </td>
   <td style="text-align:center;"> 0.07 </td>
   <td style="text-align:center;"> 11.86 </td>
   <td style="text-align:center;"> 146.29 </td>
   <td style="text-align:center;"> 11.86 </td>
   <td style="text-align:center;"> 146.29 </td>
  </tr>
  <tr>
   <td style="text-align:center;border-right:1px solid;"> body weight </td>
   <td style="text-align:center;"> all </td>
   <td style="text-align:center;"> 1333 </td>
   <td style="text-align:center;"> 50.81 </td>
   <td style="text-align:center;"> 14.08 </td>
   <td style="text-align:center;"> 53.00 </td>
   <td style="text-align:center;"> 51.98 </td>
   <td style="text-align:center;"> 13.34 </td>
   <td style="text-align:center;"> 0.00 </td>
   <td style="text-align:center;"> 89.00 </td>
   <td style="text-align:center;"> 89.00 </td>
   <td style="text-align:center;"> -0.83 </td>
   <td style="text-align:center;"> 1.01 </td>
   <td style="text-align:center;"> 0.39 </td>
   <td style="text-align:center;"> 8.29 </td>
   <td style="text-align:center;"> 179.29 </td>
   <td style="text-align:center;"> 8.29 </td>
   <td style="text-align:center;"> 179.29 </td>
  </tr>
  <tr>
   <td style="text-align:center;border-right:1px solid;"> body weight </td>
   <td style="text-align:center;"> F </td>
   <td style="text-align:center;"> 657 </td>
   <td style="text-align:center;"> 50.84 </td>
   <td style="text-align:center;"> 13.66 </td>
   <td style="text-align:center;"> 53 </td>
   <td style="text-align:center;"> 51.92 </td>
   <td style="text-align:center;"> 13.34 </td>
   <td style="text-align:center;"> 2 </td>
   <td style="text-align:center;"> 89 </td>
   <td style="text-align:center;"> 87 </td>
   <td style="text-align:center;"> -0.74 </td>
   <td style="text-align:center;"> 0.78 </td>
   <td style="text-align:center;"> 0.53 </td>
   <td style="text-align:center;"> 14.14 </td>
   <td style="text-align:center;"> 179.29 </td>
   <td style="text-align:center;"> 14.14 </td>
   <td style="text-align:center;"> 179.29 </td>
  </tr>
  <tr>
   <td style="text-align:center;border-right:1px solid;"> body weight </td>
   <td style="text-align:center;"> M </td>
   <td style="text-align:center;"> 676 </td>
   <td style="text-align:center;"> 50.77 </td>
   <td style="text-align:center;"> 14.48 </td>
   <td style="text-align:center;"> 53 </td>
   <td style="text-align:center;"> 52.04 </td>
   <td style="text-align:center;"> 13.34 </td>
   <td style="text-align:center;"> 0 </td>
   <td style="text-align:center;"> 84 </td>
   <td style="text-align:center;"> 84 </td>
   <td style="text-align:center;"> -0.91 </td>
   <td style="text-align:center;"> 1.15 </td>
   <td style="text-align:center;"> 0.56 </td>
   <td style="text-align:center;"> 8.29 </td>
   <td style="text-align:center;"> 167 </td>
   <td style="text-align:center;"> 8.29 </td>
   <td style="text-align:center;"> 167 </td>
  </tr>
  <tr>
   <td style="text-align:center;border-right:1px solid;"> NMR </td>
   <td style="text-align:center;"> all </td>
   <td style="text-align:center;"> 1333 </td>
   <td style="text-align:center;"> 8.14 </td>
   <td style="text-align:center;"> 2.44 </td>
   <td style="text-align:center;"> 8.00 </td>
   <td style="text-align:center;"> 8.24 </td>
   <td style="text-align:center;"> 2.97 </td>
   <td style="text-align:center;"> 0.00 </td>
   <td style="text-align:center;"> 21.00 </td>
   <td style="text-align:center;"> 21.00 </td>
   <td style="text-align:center;"> -0.36 </td>
   <td style="text-align:center;"> 0.82 </td>
   <td style="text-align:center;"> 0.07 </td>
   <td style="text-align:center;"> 9.14 </td>
   <td style="text-align:center;"> 148.29 </td>
   <td style="text-align:center;"> 9.14 </td>
   <td style="text-align:center;"> 148.29 </td>
  </tr>
  <tr>
   <td style="text-align:center;border-right:1px solid;"> NMR </td>
   <td style="text-align:center;"> F </td>
   <td style="text-align:center;"> 657 </td>
   <td style="text-align:center;"> 8.18 </td>
   <td style="text-align:center;"> 2.35 </td>
   <td style="text-align:center;"> 8 </td>
   <td style="text-align:center;"> 8.27 </td>
   <td style="text-align:center;"> 2.97 </td>
   <td style="text-align:center;"> 0 </td>
   <td style="text-align:center;"> 13 </td>
   <td style="text-align:center;"> 13 </td>
   <td style="text-align:center;"> -0.4 </td>
   <td style="text-align:center;"> 0.27 </td>
   <td style="text-align:center;"> 0.09 </td>
   <td style="text-align:center;"> 17.43 </td>
   <td style="text-align:center;"> 148.29 </td>
   <td style="text-align:center;"> 17.43 </td>
   <td style="text-align:center;"> 148.29 </td>
  </tr>
  <tr>
   <td style="text-align:center;border-right:1px solid;"> NMR </td>
   <td style="text-align:center;"> M </td>
   <td style="text-align:center;"> 676 </td>
   <td style="text-align:center;"> 8.1 </td>
   <td style="text-align:center;"> 2.52 </td>
   <td style="text-align:center;"> 8 </td>
   <td style="text-align:center;"> 8.21 </td>
   <td style="text-align:center;"> 2.97 </td>
   <td style="text-align:center;"> 0 </td>
   <td style="text-align:center;"> 21 </td>
   <td style="text-align:center;"> 21 </td>
   <td style="text-align:center;"> -0.32 </td>
   <td style="text-align:center;"> 1.19 </td>
   <td style="text-align:center;"> 0.1 </td>
   <td style="text-align:center;"> 9.14 </td>
   <td style="text-align:center;"> 148.29 </td>
   <td style="text-align:center;"> 9.14 </td>
   <td style="text-align:center;"> 148.29 </td>
  </tr>
</tbody>
</table>

#### age at peak indices value creation 



#### main_cat2 creation 
- merge 
  - main_all2 
  - census_c16_death 

#### imputation 
- carry forward previous observed non-missing value 
  - filter out all missing values 
  - filter for rows less than than 25 + 1, 50 + 1, 75 + 1, and 90 + 1 (previous observed values)
  - identify last non-missing value for imputation if needed 
  - leave missing if no last non-missing value 
  - merge into main_cat2 dataset
  

```
## Error in `filter()`:
## ℹ In argument: `if (...) NULL`.
## ℹ In group 2: `idno = "1000"`, `sex = "M"`.
## Caused by error in `if (sex == "F") ...`:
## ! the condition has length > 1
```

```
## Error in `filter()`:
## ℹ In argument: `if (...) NULL`.
## ℹ In group 2: `idno = "1000"`, `sex = "M"`.
## Caused by error in `if (sex == "F") ...`:
## ! the condition has length > 1
```

```
## Error in `filter()`:
## ℹ In argument: `if (...) NULL`.
## ℹ In group 2: `idno = "1000"`, `sex = "M"`.
## Caused by error in `if (sex == "F") ...`:
## ! the condition has length > 1
```

```
## Error in `filter()`:
## ℹ In argument: `if (...) NULL`.
## ℹ In group 1: `idno = "100"`, `sex = "F"`.
## Caused by error in `if (sex == "F") ...`:
## ! the condition has length > 1
```

```
## Error in `filter()`:
## ℹ In argument: `if (...) NULL`.
## ℹ In group 1: `idno = "100"`, `sex = "F"`.
## Caused by error in `if (sex == "F") ...`:
## ! the condition has length > 1
```

```
## Error in `filter()`:
## ℹ In argument: `if (...) NULL`.
## ℹ In group 1: `idno = "100"`, `sex = "F"`.
## Caused by error in `if (sex == "F") ...`:
## ! the condition has length > 1
```

```
## Error in `filter()`:
## ℹ In argument: `if (...) NULL`.
## ℹ In group 1: `idno = "100"`, `sex = "F"`.
## Caused by error in `if (sex == "F") ...`:
## ! the condition has length > 1
```

```
## Error in `filter()`:
## ℹ In argument: `if (...) NULL`.
## ℹ In group 1: `idno = "100"`, `sex = "F"`.
## Caused by error in `if (sex == "F") ...`:
## ! the condition has length > 1
```

```
## Error in `filter()`:
## ℹ In argument: `if (...) NULL`.
## ℹ In group 1: `idno = "100"`, `sex = "F"`.
## Caused by error in `if (sex == "F") ...`:
## ! the condition has length > 1
```

```
## Error in `filter()`:
## ℹ In argument: `if (...) NULL`.
## ℹ In group 1: `idno = "100"`, `sex = "F"`.
## Caused by error in `if (sex == "F") ...`:
## ! the condition has length > 1
```

```
## Error in `filter()`:
## ℹ In argument: `if (...) NULL`.
## ℹ In group 1: `idno = "100"`, `sex = "F"`.
## Caused by error in `if (sex == "F") ...`:
## ! the condition has length > 1
```

```
## Error in `filter()`:
## ℹ In argument: `if (...) NULL`.
## ℹ In group 1: `idno = "100"`, `sex = "F"`.
## Caused by error in `if (sex == "F") ...`:
## ! the condition has length > 1
```

```
## Error in `filter()`:
## ℹ In argument: `if (...) NULL`.
## ℹ In group 1: `idno = "100"`, `sex = "F"`.
## Caused by error in `if (sex == "F") ...`:
## ! the condition has length > 1
```

```
## Error in `filter()`:
## ℹ In argument: `if (...) NULL`.
## ℹ In group 1: `idno = "100"`, `sex = "F"`.
## Caused by error in `if (sex == "F") ...`:
## ! the condition has length > 1
```

```
## Error in `filter()`:
## ℹ In argument: `if (...) NULL`.
## ℹ In group 1: `idno = "100"`, `sex = "F"`.
## Caused by error in `if (sex == "F") ...`:
## ! the condition has length > 1
```

#### main_all3 creation
- merge
  - main_all2
  - census_c16_death
  - main_cat2
- create variables for imputation and survival bias analysis



## Results 
#### distribution figure with trend line
- generalized additive model for main indices
- linear model with quadratic fit for lifespan groups (survival bias analyses)
- remove timepoints before max life expectancy period 





![plot of chunk slam_sex_dist_fig](figure/slam_sex_dist_fig-1.png)
 
*** 

![plot of chunk slam_strain_dist_fig](figure/slam_strain_dist_fig-1.png)

*** 

#### pre and post-peak change creation 




```
## Error in `mutate()`:
## ! Can't transform a data frame with `NA` or `""` names.
```

```
## Error in eval(expr, envir, enclos): object 'phases2' not found
```

#### change in metabolic indices pre and post-peak 
- rate of percent change 
 

```
## Error in eval(expr, envir, enclos): object 'slam_phases' not found
```

```
## Error in eval(expr, envir, enclos): object 'slam_phases_out' not found
```

*** 

#### quartile creation


```
## Error in `select()`:
## ! Can't subset columns that don't exist.
## ✖ Column `per_age_wk_50` doesn't exist.
```

```
## Error: object 'main_cont_surv' not found
```

```
## Error: object 'main_cont_surv' not found
```
 

```
## Error in eval(expr, envir, enclos): object 'main_cat_surv_f' not found
```

```
## Error in eval(expr, envir, enclos): object 'main_cat_surv_f' not found
```

```
## Error in eval(expr, envir, enclos): object 'main_cat_surv_f' not found
```

```
## Error in eval(expr, envir, enclos): object 'main_cat_surv_f' not found
```

```
## Error in eval(expr, envir, enclos): object 'main_cat_surv_f' not found
```

```
## Error in eval(expr, envir, enclos): object 'main_cat_surv_f' not found
```

```
## Error in eval(expr, envir, enclos): object 'main_cat_surv_f' not found
```

```
## Error in eval(expr, envir, enclos): object 'main_cat_surv_f' not found
```

```
## Error in eval(expr, envir, enclos): object 'main_cat_surv_f' not found
```

```
## Error in eval(expr, envir, enclos): object 'main_cat_surv_m' not found
```

```
## Error in eval(expr, envir, enclos): object 'main_cat_surv_m' not found
```

```
## Error in eval(expr, envir, enclos): object 'main_cat_surv_m' not found
```

```
## Error in eval(expr, envir, enclos): object 'main_cat_surv_m' not found
```

```
## Error in eval(expr, envir, enclos): object 'main_cat_surv_m' not found
```

```
## Error in eval(expr, envir, enclos): object 'main_cat_surv_m' not found
```

```
## Error in eval(expr, envir, enclos): object 'main_cat_surv_m' not found
```

```
## Error in eval(expr, envir, enclos): object 'main_cat_surv_m' not found
```

```
## Error in eval(expr, envir, enclos): object 'main_cat_surv_m' not found
```

```
## Error in eval(expr, envir, enclos): object 'main_cat_surv_f' not found
```

```
## Error in eval(expr, envir, enclos): object 'main_cat_surv' not found
```


```r
save(main_all2, file = "output/main_all2.RDATA")
save(main_cat_surv, file = "output/main_cat_surv.RDATA")
```

```
## Error in save(main_cat_surv, file = "output/main_cat_surv.RDATA"): object 'main_cat_surv' not found
```

