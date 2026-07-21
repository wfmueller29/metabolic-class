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
itp_geno_treat$tx_Y <- ifelse(itp_geno_treat$tx == "Y", 1, 0)
itp_geno_treat_census <- readxl::read_xlsx(path = "data/Mortality_Class_Predictions_RW_JP_fixed(84).xlsx", sheet = 5)
itp_geno_treat_surv <- consoler::rename(itp_geno_treat_census, c(le_wk = "lifespan_wk", tx = "group (tx)"))
itp_geno_treat_surv <- itp_geno_treat_surv[, c("id", "idno", "cohort", "site", "strain", "sex", "tx", "le_wk")]
itp_geno_treat_surv$dead_censor <- 1
itp_geno_treat <- consoler::rename(itp_geno_treat, c(age_wk = "age_of_wegith_wk"))
itp_geno_treat_census <- itp_geno_treat_census[c("id", "idno")]
itp_geno_treat <- merge(itp_geno_treat, itp_geno_treat_census, by = "idno")
itp_geno_treat_m <- itp_geno_treat[itp_geno_treat$sex_M == 1, ]
itp_geno_treat_f <- itp_geno_treat[itp_geno_treat$sex_M == 0, ]

# A few summary stats before cleaning  -----------------------------------------
length(unique(itp_geno$idno))
sum(itp_geno$age_wk == 6)
unique(itp_geno$cohort)
table(itp_geno$sex)

length(unique(itp_geno_treat$idno))
sum(itp_geno_treat$age_wk == 6)
unique(itp_geno_treat$cohort)
table(itp_geno_treat$sex)

# clean ----------------------------------------------------------------------

itp_geno <- clean_itp(itp_geno, filter = TRUE)
itp_geno_m <- clean_itp(itp_geno_m, filter = TRUE)
itp_geno_f <- clean_itp(itp_geno_f, filter = TRUE)

itp_geno_treat <- clean_itp(itp_geno_treat)
itp_geno_treat_m <- clean_itp(itp_geno_treat_m)
itp_geno_treat_f <- clean_itp(itp_geno_treat_f)

# A few summary stats after cleaning  -----------------------------------------
length(unique(itp_geno$idno))
sum(itp_geno$age_wk == 6)
unique(itp_geno$cohort)
table(itp_geno$sex)

length(unique(itp_geno_treat$idno))
sum(itp_geno_treat$age_wk == 6)
unique(itp_geno_treat$cohort)
table(itp_geno_treat$sex)

if (!dir.exists("output")) {
  dir.create("output")
}

write.csv(itp_geno, "output/itp_genotyped_bw_og.csv")
write.csv(itp_geno_m, "output/itp_genotyped_bw_og_m.csv")
write.csv(itp_geno_f, "output/itp_genotyped_bw_og_f.csv")

# Control survival table required by the itp_genotyped run (survival_dataset).
# It is idno / le_wk / dead_censor selected from the cleaned main_cat_surv. This
# reproduces the survival DATA exactly; the leading row-name index differs
# cosmetically from an older run (whose parent frame is not retained) and is
# unused downstream -- the pipeline reads this file by column name.
itp_genotyped_surv <- read.csv("data/main_cat_surv.csv")[, c("idno", "le_wk", "dead_censor")]
write.csv(itp_genotyped_surv, "output/itp_genotyped_surv.csv")

write.csv(itp_geno_treat, "output/itp_genotyped_treat_bw_og.csv")
write.csv(itp_geno_treat_m, "output/itp_genotyped_treat_bw_og_m.csv")
write.csv(itp_geno_treat_f, "output/itp_genotyped_treat_bw_og_f.csv")
write.csv(itp_geno_treat_surv, "output/itp_genotyped_treat_surv.csv")
