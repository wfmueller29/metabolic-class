# ITP Genotype create CSVs

library(consoler)

# controls --------------------------------------------------------------------
itp_geno <- read.csv("../04_create_census/output/itp_genotyped/complete_census.csv")
itp_geno_m <- read.csv("../04_create_census/output/itp_genotyped_m/complete_census.csv")
itp_geno_f <- read.csv("../04_create_census/output/itp_genotyped_f/complete_census.csv")
itp_census <- read.csv("../00a_clean_itp_geno/data/main_cat_surv.csv")

itp_census <- itp_census[c("idno", "id")]

# treatment and controls ------------------------------------------------------
itp_geno_tx <- read.csv("../04_create_census/output/itp_genotyped_treat/complete_census.csv")
itp_geno_tx_f <- read.csv("../04_create_census/output/itp_genotyped_treat_f/complete_census.csv")
itp_geno_tx_m <- read.csv("../04_create_census/output/itp_genotyped_treat_m/complete_census.csv")
itp_tx_census <- read.csv("../00a_clean_itp_geno/output/itp_genotyped_treat_surv.csv")

itp_tx_census <- itp_tx_census[c("idno", "id")]

itp_geno <- merge(itp_geno, itp_census, "idno")
itp_geno_m <- merge(itp_geno_m, itp_census, "idno")
itp_geno_f <- merge(itp_geno_f, itp_census, "idno")

itp_geno_tx <- merge(itp_geno_tx, itp_tx_census, by = "idno")
itp_geno_tx_f <- merge(itp_geno_tx_f, itp_tx_census, by = "idno")
itp_geno_tx_m <- merge(itp_geno_tx_m, itp_tx_census, by = "idno")


if (!dir.exists("output")) {
  dir.create("output")
}

write.csv(itp_geno, "output/itp_geno_census.csv")
write.csv(itp_geno_f, "output/itp_geno_f_census.csv")
write.csv(itp_geno_m, "output/itp_geno_m_census.csv")

write.csv(itp_geno_tx, "output/itp_geno_tx_census.csv")
write.csv(itp_geno_tx_f, "output/itp_geno_tx_f_census.csv")
write.csv(itp_geno_tx_m, "output/itp_geno_tx_m_census.csv")
