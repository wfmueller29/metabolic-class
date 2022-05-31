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
  )))

sort(unique(health$condition_clean))

# clean up dvr cod
dvr_cod_df <- dvr_cod_protocol(dvr$cod)
head(dvr_cod_df)
dvr <- cbind(dvr, dvr_cod_df)

sort(unique(dvr$cod_1))

save(dvr, file = "output/dvr.RDATA")
save(health, file = "output/health.RDATA")
save(main_cat_surv, file = "output/main_cat_surv.RDATA")
