# Just to write survival data as CSV
# Author: William Mueller

# load in config using file path ----------------------------------------------
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  args[[1]] <- "input/slam_c1-c10.yaml"
}

config <- yaml::read_yaml(args[[1]])


load(config$path)

keep_cols <- c(
  "idno", "dead_censor", "le_wk"
)

main_cat_surv <- main_cat_surv[keep_cols]

main_cat_surv$percent_le <- 100

# save all datsets as csv files in output/data --------------------------------
output_name <- basename(args[[1]])
output_name <- strsplit(x = output_name, split = "\\.")[[1]][[1]]
file_path <- file.path("output", output_name, "data")
if (dir.exists(file_path)) {
  files <- list.files(file_path)
  files <- file.path(file_path, files)
  file.remove(files)
} else {
  dir.create(file_path, recursive = TRUE)
}

file_name <- file.path(file_path, "main_cat_surv.csv")
write.csv(x = main_cat_surv, file = file_name)


# create output file ----------------------------------------------------------
file_name <- "main_cat_surv.csv"
names(file_name) <- file.path(getwd(), "output", "data", output_name)

output_name <- basename(args[[1]])
output_path <- file.path("output", output_name)
yaml::write_yaml(x = file_name, file = output_path)
