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

itp_tx_control_surv <- rbind(
  itp_e2_20m_surv, itp_control_surv, itp_rapa_surv, itp_e2_16m_surv
)

# only keep cohorts of interest -----------------------------------------------
train_cohorts <- c("C2010", "C2011", "C2013", "C2016")
test_cohorts <- c("C2005")

itp_control_train <- itp_tx_bw[itp_tx_bw[, "cohort"] %in% train_cohorts, ]
itp_control_train <- itp_control_train[itp_control_train$tx == "control", ]
itp_control_tx_test <- itp_tx_bw[itp_tx_bw[, "cohort"] %in% test_cohorts, ]

# remove measurements out of range of trainging set from testing set ----------

ggplot2::ggplot(itp_control_tx_test, ggplot2::aes(x = age_wk)) +
  ggplot2::geom_histogram()

itp_control_tx_test <- itp_control_tx_test[itp_control_tx_test$age_wk > 19, ]

ggplot2::ggplot(itp_control_tx_test, ggplot2::aes(x = age_wk)) +
  ggplot2::geom_histogram()



# save csvs -------------------------------------------------------------------

dir.create("output", recursive = TRUE)
train_path <- file.path("output", "itp_control_train.csv")
write.csv(itp_control_train, train_path)

test_path <- file.path("output", "itp_tx_control_test.csv")
write.csv(itp_control_tx_test, test_path)

surv_path <- file.path("output", "itp_tx_control_surv.csv")
write.csv(itp_tx_control_surv, surv_path)
