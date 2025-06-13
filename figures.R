# Generate figures

# Figures ---------------------------------------------------------------------
rmarkdown::render("figures/primary_figures.Rmd",
  output_format = "pdf_document",
  output_file = "Primary Figures.pdf"
)
rmarkdown::render("figures/sup_figures.Rmd",
  output_format = "pdf_document",
  output_file = "Supplemental Material.pdf"
)
