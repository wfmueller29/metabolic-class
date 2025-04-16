# Create file get predictions for testing intervation response
library(consoler)

itp_e2_16m <- read.csv("data/itp_bw_17aE2_16m.csv")
itp_e2_20m <- read.csv("data/itp_bw_17aE2_20m.csv")
itp_control <- read.csv("data/itp_bw_controls.csv")
itp_rapa <- read.csv("data/itp_bw_rapa.csv")

itp_e2_16m_surv <- read.csv("data/itp_surv_17aE2_16m.csv")
itp_e2_20m_surv <- read.csv("data/itp_surv_17aE2_20m.csv")
itp_control_surv <- read.csv("data/itp_surv_controls.csv")
itp_rapa_surv <- read.csv("data/itp_surv_rapa.csv")


# create treatment variable ---------------------------------------------------
itp_control$tx <- "control"
itp_e2_16m$tx <- "e2_16m"
itp_e2_20m$tx <- "e2_20m"
itp_rapa$tx <- "rapa"

# rbind data ------------------------------------------------------------------
itp_tx_bw <- rbind(itp_control, itp_e2_16m, itp_e2_20m, itp_rapa)

itp_tx_surv <- rbind(
  itp_control_surv, itp_e2_16m_surv, itp_e2_20m_surv, itp_rapa_surv
)

itp_tx_control_surv <- rbind(
  itp_e2_20m_surv, itp_control_surv, itp_rapa_surv, itp_e2_16m_surv
)

# only keep cohorts of interest -----------------------------------------------
train_cohorts <- c("C2010", "C2011", "C2013")
test_cohorts <- c("C2005", "C2016")

itp_control_train <- itp_tx_bw[itp_tx_bw[, "cohort"] %in% train_cohorts, ]
itp_control_tx_test <- itp_tx_bw[itp_tx_bw[, "cohort"] %in% test_cohorts, ]

# save csvs -------------------------------------------------------------------

dir.create("output", recursive = TRUE)
train_path <- file.path("output", "itp_control_train.csv")
write.csv(itp_control_train, train_path)

test_path <- file.path("output", "itp_tx_control_test.csv")
write.csv(itp_control_tx_test, test_path)

surv_path <- file.path("output", "itp_tx_control_surv.csv")
write.csv(itp_tx_control_surv, surv_path)
