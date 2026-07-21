# For c1-c10 ------------------------------------------------------------------

setwd("00a_clean_slam_c1-c10/")

rmarkdown::render("traj_dataset.Rmd")

setwd("../00b_dataset_mods/")

exit_code <- system2("Rscript",
  args = c("dataset_mods.R", "input/slam_c1-c10.yaml")
)
if (exit_code != 0) stop("Error was thrown from system2 command")

setwd("../00c_survival_data/")

exit_code <- system2("Rscript",
  args = c("create_survival_data.R ", "input/slam_c1-c10.yaml")
)
if (exit_code != 0) stop("Error was thrown from system2 command")


# For c16-c18 -----------------------------------------------------------------
setwd("../00a_clean_slam_c16-c18/")

rmarkdown::render("traj_dataset.Rmd")

setwd("../00b_dataset_mods/")

exit_code <- system2("Rscript", args = c("dataset_mods.R", "input/slam_c16-c18.yaml"))
if (exit_code != 0) stop("Error was thrown from system2 command")

setwd("../00c_survival_data/")

exit_code <- system2("Rscript",
  args = c("create_survival_data.R ", "input/slam_c16-c18.yaml")
)
if (exit_code != 0) stop("Error was thrown from system2 command")

# For itp  --------------------------------------------------------------------
setwd("../00a_itp2/")

exit_code <- system2("Rscript", args = c("itp2_clean.R"))
if (exit_code != 0) stop("Error was thrown from system2 command")

# For genotyped itp -----------------------------------------------------------
# Cleans the raw genotyped-ITP data into 00a_clean_itp_geno/output/. The six
# itp_genotyped* train configs read their datasets from there, and
# 98_itp_genotype/prep_census.R reads output/itp_genotyped_treat_surv.csv, so
# this has to run before any of them.
setwd("../00a_clean_itp_geno/")

exit_code <- system2("Rscript", args = c("00a_clean_itp_geno.R"))
if (exit_code != 0) stop("Error was thrown from system2 command")
