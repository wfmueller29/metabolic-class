#* Import data, clean, and compile
  #+ Import lifespan and BW merged files
    BW_raw <- read_excel("combined_data.xlsx", sheet = "BW")
    LS_raw <- read_excel("combined_data.xlsx", sheet = "LS") %>%
      select(id,status, dead, age_days)
  #+ Leftjoin BW files with LS
      LS_BW <- BW_raw %>%
        left_join(LS_raw, by = "id") %>%
        filter(!if_all(c(bw_1.39,bw_3,bw_6, bw_12, bw_18, bw_24), is.na)) %>%
        filter(!is.na(age_days)) %>%
        filter(status == "dead") %>%
        rename(dead_censor = dead, strain = population) %>%
        mutate(
          le_wk = age_days / 7, 
          strain_HET3 = ifelse(strain == "UM-HET3", 1, 0),
          strain_B6 = ifelse(strain == "B6", 1, 0), 
          sex_M = ifelse(sex == "M", 1, 0), 
          sex_F = ifelse(sex == "F", 1, 0) 
        ) %>%
        mutate(idno = row_number()) %>%
        select(group, id, idno,dead_censor, site, sex, cohort, group, bw_1.39:bw_24, age_days, le_wk, sex_M, sex_F)
  #+ Pivot long the BW data
    BW_long <- LS_BW %>%
      pivot_longer(
        cols = starts_with("bw_"),
        names_to = "age_wk", 
        values_to = "bw" 
      ) %>%
      mutate(
        age_wk = as.numeric(sub("bw_", "", age_wk)) * 4.3333,
        age_wk2 = age_wk^2
      ) %>%
      select(-c(age_days)) %>%
      filter(!is.na(bw)) %>%
      filter(le_wk > age_wk)
  #+ Filter into groups
    complete_controls <- BW_long %>%
      filter(group == "Control")
    complete_rapa <- BW_long %>%
      filter(group == "Rapa") %>%
      filter(age_wk < 86.6)
    complete_17aE2_20m <- BW_long %>%
      filter(group == "17aE2_20m") %>%
      filter(age_wk < 86.6)
    complete_17aE2_16m <- BW_long %>%
      filter(group == "17aE2_16m") %>%
      filter(age_wk < 69.28)
  #+ Get LS and BW sheets
    #- ITP
      itp_bw_controls <- complete_controls %>%
        select(site, idno, bw, sex, cohort, age_wk, age_wk2, sex_F, sex_M)
      itp_surv_controls <- complete_controls %>%
        select(idno, le_wk,dead_censor) %>%
        unique()
      write.csv(itp_bw_controls, "itp_bw_controls.csv")
      write.csv(itp_surv_controls, "itp_surv_controls.csv")
    #- Rapa
      itp_bw_rapa <- complete_rapa %>%
        select(site,idno,bw,sex,cohort,age_wk,age_wk2,sex_F,sex_M)
      itp_surv_rapa <- complete_rapa %>%
        select(idno, le_wk, dead_censor) %>%
        unique()
      write.csv(itp_bw_rapa, "itp_bw_rapa.csv")
      write.csv(itp_surv_rapa, "itp_surv_rapa.csv")
    #- 17aE2 16m
      itp_bw_17aE2_16m <- complete_17aE2_16m %>%
        select(site, idno, bw, sex, cohort, age_wk, age_wk2, sex_F, sex_M)
      itp_surv_17aE2_16m <- complete_17aE2_16m %>%
        select(idno, le_wk, dead_censor) %>%
        unique()
      write.csv(itp_bw_17aE2_16m, "itp_bw_17aE2_16m.csv")
      write.csv(itp_surv_17aE2_16m, "itp_surv_17aE2_16m.csv")
    #- 17aE2 20m
      itp_bw_17aE2_20m <- complete_17aE2_20m %>%
        select(site, idno, bw, sex, cohort, age_wk, age_wk2, sex_F, sex_M)
      itp_surv_17aE2_20m <- complete_17aE2_20m %>%
        select(idno, le_wk, dead_censor) %>%
        unique()
      write.csv(itp_bw_17aE2_20m, "itp_bw_17aE2_20m.csv")
      write.csv(itp_surv_17aE2_20m, "itp_surv_17aE2_20m.csv")
#* Combine Long-Form Data for Rob Williams Test
  #+ Import Classes
    class_assignments <- read_csv("Formatted Data/treatment_class.csv") %>%
      select(-c(tx_cohort, dead_censor, sex_M, sex_F, cohort, tx)) %>%
      rename_with(~ paste0(.x, "_out")) %>%
      rename(idno = idno_out)
    control_classes <- read_csv("Formatted Data/complete_census.csv") %>%
      select(-c(dead_censor, sex_M, sex_F, cohort,X.1,X)) %>%
      rename_with(~ paste0(.x, "_out")) %>%
      rename(idno = idno_out)
    full_assign <- rbind(class_assignments, control_classes) %>%
      unique()
  #+ Bring in id to idno conversion
    id_conversion <- LS_BW %>%
      select(id, idno)
  #+ Leftjoin BW files with LS, pivot long
  LS_BW_RW <- BW_raw %>%
    left_join(LS_raw, by = "id") %>%
    filter(!if_all(c(bw_1.39, bw_3, bw_6, bw_12, bw_18, bw_24), is.na)) %>%
    filter(!is.na(age_days)) %>%
    filter(status == "dead") %>%
    rename(strain = population, lifespan_days = age_days) %>%
    mutate(lifespan_wk = lifespan_days / 7) %>%
    mutate(idno = row_number()) %>%
    pivot_longer(
      cols = starts_with("bw_"),
      names_to = "age_wk",
      values_to = "bw_measure"
    ) %>%
    mutate(age_wk_bw_measure = as.numeric(sub("bw_", "", age_wk)) * 4.3333) %>%
    filter(!is.na(bw_measure)) %>%
    filter(lifespan_wk > age_wk_bw_measure) %>%
    select(id, cohort, site, strain, sex, group, rx_ppm, age_initiation_mo, lifespan_wk, age_wk_bw_measure, bw_measure)
  write.csv(LS_BW_RW, "LS_BW_RW.csv")
  #+ Filter to just controls and Rapamycin mice, join with ID numbers and class assignments
    control_rapa_long <- LS_BW_RW %>%
      filter(group == "Control" | group == "Rapa") %>%
      left_join(id_conversion, by = "id") %>%
      left_join(full_assign, by = "idno")
  #+ Ensure the matching is correct by comparing LE wks and other features
    bad_rows_test <- control_rapa_long %>%
      select(idno, id, group, sex, sex_out, site, site_out, lifespan_wk, le_wk_out) %>%
      mutate(
        lifespan_wk = round(lifespan_wk, 2),
        le_wk_out   = round(le_wk_out, 2)
      )
    le_mismatch_test <- bad_rows_test %>%
      filter(lifespan_wk != le_wk_out) %>%
      mutate(across(c(lifespan_wk, le_wk_out), ~ sprintf("%.2f", .x)))
    sex_mismatch_test <- bad_rows_test %>%
      filter(sex != sex_out)
    site_mismatch_test <- bad_rows_test %>%
      filter(site != site_out)
    #! All 0 = matches
  #+ Now pull the long form with classes
    control_rapa_long_clean <- control_rapa_long %>%
      select(-c(sex_out:le_wk_out)) %>%
      rename(
        BW_traj_class = new_class_bw_out,
        prob_class1 = prob1_out,
        prob_class2 = prob2_out,
        prob_class3 = prob3_out,
      ) %>%
      select(
        id, idno, cohort, site, strain, sex, group, rx_ppm, age_initiation_mo,
        lifespan_wk, age_wk_bw_measure, bw_measure,
        BW_traj_class, prob_class1, prob_class2, prob_class3
      )
    write.csv(control_rapa_long_clean, "control_rapa_long.csv")
  #+ Filter to just classed mice and remove bws
    control_rapa_long_class_no_BW <- control_rapa_long_clean %>%
      select(-c(age_wk_bw_measure, bw_measure)) %>%
      unique()
    write.csv(control_rapa_long_class_no_BW, "control_rapa_long_class_no_BW.csv")
