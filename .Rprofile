source("renv/activate.R")

# --- R version notice --------------------------------------------------------
# renv pins PACKAGE versions but cannot pin R itself, so a mismatch between your
# R and the one recorded in renv.lock is silent. LCMM class assignments are
# sensitive to the numerical stack (R build, BLAS/LAPACK), so surface it here.
# Informational only -- never blocks, and degrades quietly on a fresh clone.
local({
  want <- tryCatch(renv::lockfile_read("renv.lock")$R$Version, error = function(e) NULL)
  have <- as.character(getRversion())
  if (!is.null(want) && !identical(want, have))
    message(sprintf(
      paste0("NOTE: renv.lock records R %s; this session is R %s.\n",
             "      Base package builds (Matrix/MASS/nlme) and model numerics can differ."),
      want, have))

  # renv cannot pin the BLAS either, and a THREADED BLAS (e.g. pthreads OpenBLAS)
  # varies summation order across runs -- enough to flip a marginally
  # positive-definite covariance and change LCMM class assignments. The reference
  # BLAS shipped with R (libRblas) is single-threaded and deterministic.
  blas <- tryCatch(sessionInfo()$BLAS, error = function(e) NULL)
  if (!is.null(blas) && !grepl("libRblas", blas, fixed = TRUE))
    message(sprintf(
      paste0("NOTE: this session's BLAS is not R's reference libRblas:\n",
             "        %s\n",
             "      Threaded BLAS can change results run-to-run. If reproducing the\n",
             "      published analysis, prefer the reference BLAS, or at minimum set\n",
             "      OPENBLAS_NUM_THREADS=1 to force deterministic single-threaded math."),
      blas))
})
