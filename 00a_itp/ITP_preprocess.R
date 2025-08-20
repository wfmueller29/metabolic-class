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
        select(group, idno,dead_censor, site, sex, cohort, group, bw_1.39:bw_24, age_days, le_wk, sex_M, sex_F)
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
  #+ Combine Long-Form Data
    control_rapa_long <- BW_long %>%
      filter(group == "Control" | group == "Rapa")
    write.csv(control_rapa_long, "control_rapa_long.csv")
