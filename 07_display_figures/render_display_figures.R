# Purpose Render Main and Supplemental Figures
# Author: William Mueller

# Main
all_dir <- "20220618_104254_all"
mb6_dir <- "20220617_045809_mb6"
fb6_dir <- "20220617_072941_fb6"
mhet3_dir <- "20220617_052502_mhet3"
fhet3_dir <- "20220617_033852_fhet3"

rmarkdown::render(
  input = "07_display_figures.Rmd",
  output_file = "main_figures.html",
  params = list(
    sup = FALSE,
    all_dir = all_dir,
    mb6_dir = mb6_dir,
    fb6_dir = fb6_dir,
    mhet3_dir = mhet3_dir,
    fhet3_dir = fhet3_dir
  )
)

rmarkdown::render(
  input = "07_display_figures.Rmd",
  output_file = "supplemental_figures.html",
  params = list(
    sup = TRUE,
    all_dir = all_dir,
    mb6_dir = mb6_dir,
    fb6_dir = fb6_dir,
    mhet3_dir = mhet3_dir,
    fhet3_dir = fhet3_dir
  )
)
