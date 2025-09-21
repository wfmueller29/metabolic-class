# ITP genotype mice

library(consoler)


clean_itp <- function(data) {
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

  data <- data[, columns_keep]

  # filter data so le_wk > age_wk
  data <- data[data$le_wk > data$age_wk, ]

  data
}


itp_geno <- read.csv("data/itp_genotyped_bw_og.csv")
itp_geno_m <- itp_geno[itp_geno$sex_M == 1, ]
itp_geno_f <- itp_geno[itp_geno$sex_M == 0, ]

itp_geno <- clean_itp(itp_geno)
itp_geno_m <- clean_itp(itp_geno_m)
itp_geno_f <- clean_itp(itp_geno_f)

if (!dir.exists("output")) {
  dir.create("output")
}

write.csv(itp_geno, "output/itp_genotyped_bw_og.csv")
write.csv(itp_geno_m, "output/itp_genotyped_bw_og_m.csv")
write.csv(itp_geno_f, "output/itp_genotyped_bw_og_f.csv")
