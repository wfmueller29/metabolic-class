# =============================================================================
# 06_render_figures.R  --  reproduce-flow: assemble the publication figures.
#
# Runs AFTER run/04_pipeline.R (models) AND run/05_downstream.R (the analyses,
# incl. 91 partial-correlation + 97 treatment-response, whose outputs the figures
# embed). This step ONLY builds the figure components + renders the PDFs.
#
# Prereqs that must already exist (produced by the two prior steps):
#   pipeline/07_display_figures/output/<tag>/...        (04_pipeline)
#   downstream/91_partial_correlation/output/...        (05_downstream)
#   downstream/97_treatment_response/output/...         (05_downstream)
#
# Run from the repo root:  Rscript run/06_render_figures.R
# =============================================================================

# 1) generate the publication-ready figure COMPONENTS the Rmds embed
#    (outcome/validation panels -> figures/raw/). The partial-correlation network
#    (91) is produced upstream in run/05_downstream.R, not here.
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
