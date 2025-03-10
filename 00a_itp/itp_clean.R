# clean itp data


itp <- read.csv("data/ITP_bw_og.csv")

columns_keep <- c(
  "site",
  "idno",
  "bw",
  "sex",
  "cohort",
  "age_wk",
  "age_wk2",
  "le_wk",
  "dead_censor",
  "sex_F",
  "sex_M"
)

itp <- itp[, columns_keep]

# filter itp so le_wk > age_wk
itp <- itp[itp$le_wk > itp$age_wk, ]

census <- data.frame(
  old_idno = unique(itp$idno),
  idno = seq_len(length(unique(itp$idno)))
)

itp <- merge(census, itp, by.x = "old_idno", by.y = "idno", all.y = TRUE)

bw_cols <- c(
  "site",
  "idno",
  "bw",
  "sex",
  "cohort",
  "age_wk",
  "age_wk2",
  "sex_F",
  "sex_M"
)

itp_bw <- itp[, bw_cols]

surv_cols <- c(
  "idno",
  "le_wk",
  "dead_censor"
)

itp_surv <- itp[, surv_cols]
itp_surv <- itp_surv[!duplicated(itp_surv$idno), ]

dir.create("output")
write.csv(itp_surv, "output/itp_surv.csv")
write.csv(itp_bw, "output/itp_bw.csv")
