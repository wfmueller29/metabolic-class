# Author: William Mueller
# Purpose: The purpose of this file is to add necropsy, pathology, and
# healthcard information to the census
# the previous glucose paper so they can be modeled
library(tidyverse)
library(readxl)

# load in main_cat_surv
load("data/main_cat_surv.RDATA")

# read in csv's
dvr <- readxl::read_xlsx("data/Record of DVR Reports.xlsx")
dvr_health <- readxl::read_xlsx(
  "data/Record of DVR Reports with Healthcards 2.xlsx"
)
health <- readxl::read_xlsx("data/SLAM Healthcard.xlsx")
census <- read.csv("data/census.csv") %>%
  rename(animal_id = Animal_ID)

tags <- census %>%
  select(tag, idno)

# clean datasets
# clean dvr
dvr <- dvr %>%
  select(
    tag = `Mouse Tag`,
    cohort,
    path_report_number = `Path Report Number`,
    date_recieved = `Date received by DVR`,
    sex = Sex,
    strain = Strain,
    age_mo = `Age (MO)`,
    dod = DOD,
    cod = COD,
    cod_coded = `COD Coded`,
    slides = Slides
  ) %>%
  left_join(tags, by = "tag")

# clean health
health <- health %>%
  select(
    tag = Tag,
    dod = `Date of Death`,
    date_created = `Created Date`,
    date_recovered = `Recovery Date`,
    condition = Condition
  ) %>%
  left_join(tags, by = "tag")


# fix id's and check if it improves current id's
fixID_history <- function(idno, census) {
  census <- census %>%
    separate(taghistory, c("th1", "th2", "th3", "th4", "th5", "th6"), sep = ",", extra = "warn")

  idnos <- trimws(idno)
  idnos[idnos %in% census$animal_id] <- census$idno[match(idnos[idnos %in% census$animal_id], census$animal_id)]
  idnos[idnos %in% census$tag] <- census$idno[match(idnos[idnos %in% census$tag], census$tag)]
  idnos[idnos %in% census$th1] <- census$idno[match(idnos[idnos %in% census$th1], census$th1)]
  idnos[idnos %in% census$th2] <- census$idno[match(idnos[idnos %in% census$th2], census$th2)]
  idnos[idnos %in% census$th3] <- census$idno[match(idnos[idnos %in% census$th3], census$th3)]
  idnos[idnos %in% census$th4] <- census$idno[match(idnos[idnos %in% census$th4], census$th4)]
  idnos[idnos %in% census$th5] <- census$idno[match(idnos[idnos %in% census$th5], census$th5)]
  idnos[idnos %in% census$th6] <- census$idno[match(idnos[idnos %in% census$th6], census$th6)]

  return(idnos)
}
health_idno_fix <- fixID_history(health$tag, census = census)
dvr_idno_fix <- fixID_history(dvr$tag, census = census)

# we can see that fixing id's does not improve current id's
table(health_idno_fix == health$idno)
table(dvr_idno_fix == dvr$idno)
table(is.na(health$idno))
table(is.na(dvr$idno))

# lets now add tags to main_cat_surv
main_cat_surv <- main_cat_surv %>%
  mutate(idno = as.numeric(idno)) %>%
  left_join(tags, by = "idno")

# source strings.R
source("R/strings.R")

# unique health condition
unique(health$condition)
health$condition_clean <- clean_string(health$condition)
unique(health$condition_clean)
sort(unique(health$condition_clean))

health <- health %>%
  mutate(condition_clean = ifelse(
    condition_clean == "ear problems", "ear problem",
    ifelse(
      condition_clean == "eye issue", "eye problem",
      ifelse(condition_clean == "dehydration", "dehydrated",
        ifelse(condition_clean == "lesions", "lesion",
          ifelse(condition_clean == "lethargy", "lethargic",
            ifelse(condition_clean == "low body temperature", "low temperature",
              ifelse(condition_clean == "prolpase", "prolapse",
                ifelse(condition_clean == "losing weight", "weight loss",
                  ifelse(condition_clean == "slow moving", "lethargic",
                    ifelse(condition_clean == "thin/hunched", "thin",
                      ifelse(condition_clean == "prolapsed penis", "prolapse",
                        ifelse(condition_clean == "rectal prolapse", "prolapse",
                          ifelse(condition_clean == "penile prolapse",
                            "prolapse",
                            ifelse(condition_clean == "tramatic injury",
                              "traumatic injury",
                              condition_clean
                            )
                          )
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  ))


health <- health %>%
  mutate(condition_clean = ifelse(
    condition_clean == "favoring hindlinb", "abnormal gait",
    ifelse(
      condition_clean == "swollen feet" |
        condition_clean == "swollen hindfoot" |
        condition_clean == "swollen testicle" |
        condition_clean == "swollen feet",
      "swelling",
      ifelse(condition_clean == "enlarged testicle" |
        condition_clean == "enlarged bladder",
      "enlarged organs",
      ifelse(condition_clean == "cloudy/tinted urine", "discolored urine",
        ifelse(condition_clean == "unsteady gait",
          "abnormal gait",
          condition_clean
        )
      )
      )
    )
  ))

sort(unique(health$condition_clean))

# clean up dvr cod
dvr_cod_df <- dvr_cod_protocol(dvr$cod)
head(dvr_cod_df)
dvr <- cbind(dvr, dvr_cod_df)

# clean up cod_coded
dvr <- dvr %>%
  mutate(cod_coded = ifelse(cod_coded == "Neoplastic", "N",
    ifelse(cod_coded == "Both Non-Neoplastic + Neoplastic", "NN + N",
      ifelse(cod_coded == "NN&NN Non-Neoplastic", "NN + NN",
        ifelse(cod_coded == "Non-Neoplastic", "NN",
          ifelse(cod_coded == "N&N Neoplastic", "N + N",
            ifelse(cod_coded == "N+NN+N", "N + NN + N",
              ifelse(cod_coded == "Nx3 Neoplastic", "N + N + N", cod_coded)
            )
          )
        )
      )
    )
  ))

sort(unique(dvr$cod_1))

save(dvr, file = "output/dvr.RDATA")
save(health, file = "output/health.RDATA")
save(main_cat_surv, file = "output/main_cat_surv.RDATA")


# #### Healthcard Cleaning
# ```{r healthcard}
# now we have to add the health card information. lets convert it to wide format
# so that we can add it to the subject summary
# create wave for health
health <- health %>%
  group_by(tag) %>%
  arrange(date_created) %>%
  mutate(wave = row_number()) %>%
  ungroup()
health <- as.data.frame(health)

health_wide <- pivot_wider(health,
  id_cols = c("idno", "tag", "dod"),
  names_from = "wave",
  names_prefix = "condition_",
  values_from = "condition_clean"
)
health_wide <- as.data.frame(health_wide)

health_wide_heat <- pivot_wider(health,
  id_cols = c("idno", "tag", "dod"),
  names_from = "condition_clean",
  values_from = "condition_clean"
)
health_wide <- as.data.frame(health_wide)

health_wide_heat <- health_wide_heat

col_of_interest <- 4:length(health_wide_heat)

health_wide_heat[, col_of_interest] <- lapply(
  health_wide_heat[, col_of_interest],
  function(col) {
    ifelse(col == "NULL", 0, 1)
  }
)

count <- as.data.frame(apply(health_wide_heat[, col_of_interest], 2, sum))

count

names(count) <- "n"
count$condition <- rownames(count)
rownames(count) <- NULL

# select interesting healthcard
count <- arrange(count, -n)

# save healthcard count
write.csv(count, file = "output/conditions_and_counts.csv")
# ```


# #### Create Summary Dataframe
# ```{r create summary dataframe}
merge_dvr <- dvr %>%
  select(idno, cod, dod, cod_coded, cod_1:cod_4_parens)

merge_health <- health_wide_heat %>%
  select(-dod, -idno)

main_cat_surv_prep <- main_cat_surv %>%
  select(
    -tag,
    -sex,
    -strain,
    dead_censor,
    fu_age_wk,
    le_wk,
    cod,
    lastdate,
    maxdate,
    tod
  )
main_cat_surv_prep <- as.data.frame(main_cat_surv_prep)

subject_sum <- census %>%
  left_join(main_cat_surv_prep, by = "idno") %>%
  mutate(idno = as.numeric(idno)) %>%
  left_join(merge_dvr, by = "idno")


# check na's after merging
apply(apply(subject_sum, 2, is.na), 2, sum)

# obs goe from 1304 to 1310, so their are duplicates, lets find these duplicates
# and choose the correct one
id <- subject_sum$idno
subject_sum[duplicated(id) | duplicated(id, fromLast = TRUE), ]

# if there a duplicates, we are going to take the observation with the cod.y
# that is not NA or Undetermined. If there is no NA or undetermined, we are
# going to take the observation with the later dod
subject_sum <- subject_sum %>%
  group_by(idno) %>%
  # cod_effective is 0 if "undetermined" or is.na
  mutate(cod_effective = ifelse(cod.y == "Undetermined" | is.na(cod.y), 0, 1)) %>%
  arrange(desc(cod_effective), desc(dod)) %>%
  distinct(idno, .keep_all = TRUE) %>%
  ungroup() %>%
  as.data.frame() %>%
  rename(
    cod_census = cod.x,
    cod_dvr = cod.y
  ) %>%
  mutate(
    female = ifelse(sex == "F", 1, 0),
    het3 = ifelse(strain == "HET3", 1, 0)
  )

subject_sum <- subject_sum %>%
  left_join(merge_health, by = "tag")
# ```
