# Figures ---------------------------------------------------------------------
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
