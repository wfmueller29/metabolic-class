# For c1-c10 ------------------------------------------------------------------

setwd("00a_clean_slam_c1-c10/")

rmarkdown::render("traj_dataset.Rmd")

setwd("../00b_dataset_mods/")

system2("Rscript", args = c("dataset_mods.R", "input/slam_c1-c10.yaml"))

setwd("../00c_survival_data/")

system2("Rscript",
        args = c("create_survival_data.R ", "input/slam_c1-c10.yaml"))


# For c16-c18 -----------------------------------------------------------------
setwd("../00a_clean_slam_c16-c18/")

rmarkdown::render("traj_dataset.Rmd")

setwd("../00b_dataset_mods/")

system2("Rscript", args = c("dataset_mods.R", "input/slam_c16-c18.yaml"))

setwd("../00c_survival_data/")

system2("Rscript",
        args = c("create_survival_data.R ", "input/slam_c16-c18.yaml"))
