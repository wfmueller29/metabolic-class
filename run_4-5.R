# this is for running 4-5

config$out_tag <- "all" # delete this

# 04 -------------------------------------------------------------------------

input_04 <- normalizePath(
  paste0(file.path("03_model_select/output", config$out_tag), ".yaml")
)

setwd("04_prediction_data")
system2("Rscript", args = c("create_prediction_data.R", input_04))
setwd("..")

Sys.sleep(time = 5)
# 05 -------------------------------------------------------------------------

input_05 <- normalizePath(
  paste0(file.path("04_prediction_data/output", config$out_tag), ".yaml")
)

setwd("05_figures")
output_dir <- normalizePath(file.path("output", config$out_tag))
rmarkdown::render("05_figures.Rmd",
  output_dir = output_dir, params = list(input_path = input_05)
)
setwd("..")

# 06 --------------------------------------------------------------------------
input_06 <- normalizePath(
  paste0(file.path("05_figures/output", config$out_tag), ".yaml")
)

setwd("06_display_figures")
output_dir <- normalizePath(file.path("output", config$out_tag))
rmarkdown::render("06_display_figures.Rmd",
  output_dir = output_dir, params = list(input_path = input_06)
)
setwd("..")
