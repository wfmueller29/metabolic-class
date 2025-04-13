# this file will render the model select RMD file

render_model_output <- function(model_dir) {
  output_dir <- normalizePath(file.path("output", model_dir))
  rmarkdown::render(
    input = "06_create_figures.Rmd",
    output_dir = output_dir,
    params = list(model_dir = model_dir)
  )
}


# get all directories within the 03_model/output directory

dirs <- list.dirs(
  path = "../04_model_select/output/.",
  full.names = FALSE,
  recursive = FALSE
)

# drop archive dir
dirs <- dirs[dirs != "archive"]

for (dir in dirs) {
  render_model_output(dir)
}
