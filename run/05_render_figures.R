# =============================================================================
# 05_render_figures.R  --  reproduce-flow: assemble the publication figures.
#
# Runs AFTER models + analyses (run/04_reproduce.R). Two steps:
#   1. figures/R/pub_ready_figs.R -- turns the 07_display_figures plot lists into
#      publication-ready PNG components under figures/raw/ (gitignored scratch).
#   2. render figures/primary_figures.Rmd + sup_figures.Rmd -> figures/output/*.pdf
#      (they embed the figures/raw/ components + 07 + 99 outputs).
#
# Prereqs that must already exist (produced by 04_reproduce.R):
#   pipeline/07_display_figures/output/<tag>/...
#   downstream/97_treatment_response/output/...   (for the supplemental panels)
#
# Run from the repo root:  Rscript run/05_render_figures.R
# =============================================================================

# 1) generate the figure COMPONENTS the Rmds embed.
#  1a) partial-correlation network -- runs IN pipeline/97 (reads the 04 census via its
#      own ../ relative paths, writes downstream/91_partial_correlation/output/).
wd <- getwd(); setwd("downstream/91_partial_correlation")
ec <- system2("Rscript", "partial_corr.R"); setwd(wd)
if (ec != 0) stop("downstream/91_partial_correlation/partial_corr.R failed (exit ", ec, ")")

#  1b) publication-ready outcome/validation components -> figures/raw/
ec <- system2("Rscript", "figures/R/pub_ready_figs.R")
if (ec != 0) stop("figures/R/pub_ready_figs.R failed (exit ", ec, ")")

# 2) assemble the final figure PDFs (knit_root_dir defaults to figures/, so the
#    Rmds' relative refs -- raw/, ../pipeline/07..., etc. -- resolve correctly)
rmarkdown::render("figures/primary_figures.Rmd",
  output_format = "pdf_document",
  output_dir    = "figures/output",
  output_file   = "Primary Figures.pdf"
)
rmarkdown::render("figures/sup_figures.Rmd",
  output_format = "pdf_document",
  output_dir    = "figures/output",
  output_file   = "Supplemental Material.pdf"
)
