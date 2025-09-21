# ITP Genotype create CSVs

library(consoler)

itp_geno <- read.csv("../04_create_census/output/itp_genotyped/complete_census.csv")
itp_geno_m <- read.csv("../04_create_census/output/itp_genotyped_m/complete_census.csv")
itp_geno_f <- read.csv("../04_create_census/output/itp_genotyped_f/complete_census.csv")
itp_census <- read.csv("../00a_clean_itp_geno/data/main_cat_surv.csv")

itp_census <- itp_census[c("idno", "id")]

merge_census <- function(census) {
  merge(census, itp_census, id = "idno")
}

itp_geno <- merge_census(itp_geno)
itp_geno_m <- merge_census(itp_geno_m)
itp_geno_f <- merge_census(itp_geno_f)


if (!dir.exists("output")) {
  dir.create("output")
}

write.csv(itp_geno, "output/itp_geno_census.csv")
write.csv(itp_geno_f, "output/itp_geno_f_census.csv")
write.csv(itp_geno_m, "output/itp_geno_m_census.csv")
