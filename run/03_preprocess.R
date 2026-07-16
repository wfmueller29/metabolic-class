# Runs all cleaning stages. Anchored to the repo root so re-running after a
# mid-way failure doesn't strand the working directory in a subfolder.
setwd("pipeline")  # launched from the repo root; the ../ sibling hops below stay inside pipeline/

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
  args = c("create_survival_data.R", "input/slam_c1-c10.yaml")
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
  args = c("create_survival_data.R", "input/slam_c16-c18.yaml")
)
if (exit_code != 0) stop("Error was thrown from system2 command")

# For itp  --------------------------------------------------------------------
setwd("../00a_clean_itp/")

exit_code <- system2("Rscript", args = c("itp_clean.R"))
if (exit_code != 0) stop("Error was thrown from system2 command")

# For itp genotype ------------------------------------------------------------
setwd("../00a_clean_itp_geno/")

exit_code <- system2("Rscript", args = c("00a_clea_itp_geno.R"))
if (exit_code != 0) stop("Error was thrown from system2 command")
