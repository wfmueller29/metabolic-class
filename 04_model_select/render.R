# this file will render the model select RMD file


model_dir <- "20220510_124214_test"
output_dir <- normalizePath(file.path("output", model_dir))
rmarkdown::render(input = "04_model_select.Rmd",
                  output_dir = output_dir,
                  params = list(model_dir = model_dir))

model_dir <- "20220523_121216_test"
output_dir <- normalizePath(file.path("output", model_dir))
rmarkdown::render(input = "04_model_select.Rmd",
                  output_dir = output_dir,
                  params = list(model_dir = model_dir))
