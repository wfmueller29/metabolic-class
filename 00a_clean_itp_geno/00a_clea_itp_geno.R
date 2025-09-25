# ITP genotype mice

library(consoler)


clean_itp <- function(data, filter = FALSE) {
  if (isTRUE(filter)) {
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
  }

  # filter data so le_wk > age_wk
  data <- data[data$le_wk > data$age_wk, ]
  print(consoler::check_na(data))

  data
}


itp_geno <- read.csv("data/itp_genotyped_bw_og.csv")
itp_geno_m <- itp_geno[itp_geno$sex_M == 1, ]
itp_geno_f <- itp_geno[itp_geno$sex_M == 0, ]

itp_geno_treat <- readxl::read_xlsx(path = "data/Mortality_Class_Predictions_RW_JP_fixed(84).xlsx", sheet = 6)
itp_geno_treat_census <- readxl::read_xlsx(path = "data/Mortality_Class_Predictions_RW_JP_fixed(84).xlsx", sheet = 5)
itp_geno_treat <- consoler::rename(itp_geno_treat, c(age_wk = "age_of_wegith_wk"))
itp_geno_treat_census <- itp_geno_treat_census[c("id", "idno")]
itp_geno_treat <- merge(itp_geno_treat, itp_geno_treat_census, by = "idno")
itp_geno_treat_m <- itp_geno_treat[itp_geno_treat$sex_M == 1, ]
itp_geno_treat_f <- itp_geno_treat[itp_geno_treat$sex_M == 0, ]


itp_geno <- clean_itp(itp_geno, filter = TRUE)
itp_geno_m <- clean_itp(itp_geno_m, filter = TRUE)
itp_geno_f <- clean_itp(itp_geno_f, filter = TRUE)

itp_geno_treat <- clean_itp(itp_geno_treat)
itp_geno_treat_m <- clean_itp(itp_geno_treat_m)
itp_geno_treat_f <- clean_itp(itp_geno_treat_f)

length(unique(itp_geno$idno))
sum(itp_geno$age_wk == 6)
unique(itp_geno$cohort)
table(itp_geno$sex)

if (!dir.exists("output")) {
  dir.create("output")
}

write.csv(itp_geno, "output/itp_genotyped_bw_og.csv")
write.csv(itp_geno_m, "output/itp_genotyped_bw_og_m.csv")
write.csv(itp_geno_f, "output/itp_genotyped_bw_og_f.csv")

write.csv(itp_geno_treat, "output/itp_genotyped_treat_bw_og.csv")
write.csv(itp_geno_treat_m, "output/itp_genotyped_treat_bw_og_m.csv")
write.csv(itp_geno_treat_f, "output/itp_genotyped_treat_bw_og_f.csv")
