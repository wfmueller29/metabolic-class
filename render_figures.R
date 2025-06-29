# Figures ---------------------------------------------------------------------

setwd("96_pub_ready_figs/")
ecode <- system2("Rscript", "pub_ready_figs.R")
if (ecode != 0) stop(paste("Error in pub_ready_figs.R"))
setwd("..")

rmarkdown::render("figures/primary_figures.Rmd",
  output_format = "pdf_document",
  output_dir = "figures/output",
  output_file = "Primary Figures.pdf"
)
rmarkdown::render("figures/sup_figures.Rmd",
  output_format = "pdf_document",
  output_dir = "figures/output",
  output_file = "Supplemental Material.pdf"
)
