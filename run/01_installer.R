# =============================================================================
# 01_installer.R  --  provision the R package environment from renv.lock.
#
# Idempotent FIRST STOP. renv::restore() installs ONLY the packages that are
# missing or version-mismatched vs renv.lock -- including the pinned GitHub commit
# SHAs for helphlme / callframe / SLAM / consoler, and the exact lcmm / marqLevAlg
# versions (LCMM class assignments are version-sensitive). It's a fast no-op when
# the library already matches the lock, so this is safe to run EVERY time.
#
# renv is auto-activated by the project .Rprofile (renv/activate.R), so a fresh
# clone self-bootstraps renv on R startup; this script just restores the lockfile.
#
# NOT captured by renv (so handled/documented separately):
#   - the TeX distribution: renv installs the tinytex R PACKAGE, not the LaTeX
#     install -- bootstrapped idempotently below (needed for the PDF figure renders).
#   - the BLAS/LAPACK backend (system-level): documented by run/09_session_info.R.
#
# Run from the repo root:  Rscript run/01_installer.R
# =============================================================================

# 1) restore the pinned package library (idempotent; no-op when already in sync)
renv::restore(prompt = FALSE)

# 2) TeX distribution for the PDF figure renders (idempotent -- installs only if absent)
if (!requireNamespace("tinytex", quietly = TRUE) || !tinytex::is_tinytex())
  tinytex::install_tinytex()

# -----------------------------------------------------------------------------
# Fallback reference only -- the pre-renv manual install list (superseded by
# renv.lock, which pins exact versions + GitHub SHAs). Left commented in case you
# ever need to provision without renv:
#
#   install.packages(c("devtools","coxme","fastDummies","lmerTest","tidyverse",
#     "rsample","future","kableExtra","survival","survminer","ggplotify","sjPlot",
#     "lme4","cowplot","RColorBrewer","viridis","yardstick","beepr","tinytex",
#     "flextable","nnet","pheatmap"), repos = "https://cloud.r-project.org")
#   devtools::install_github(c("wfmueller29/helphlme","wfmueller29/callframe",
#     "wfmueller29/SLAM","wfmueller29/consoler"))
# -----------------------------------------------------------------------------
