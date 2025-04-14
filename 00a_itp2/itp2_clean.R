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
