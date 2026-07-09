# Deletes all pipeline output for one or more out_tags across stages 01-07,
# so you can regenerate everything cleanly from fresh upstream data.
#
# Does NOT touch raw-data-level output (00a_itp2/output, 00b_dataset_mods/
# output, 00c_survival_data/output, etc.) -- those aren't out_tag-scoped the
# same way (multiple out_tags can share the same raw-cleaning output), and a
# chained out_tag from a separate step (e.g. predict.R's own out_tag) isn't
# automatically traced -- pass it explicitly alongside the training out_tag
# if you want it wiped too. Deliberately explicit, not automatic-guessing.
#
# Usage:
#   Rscript wipe.R <out_tag> [out_tag2] ...            # dry run, lists what would be deleted
#   Rscript wipe.R --confirm <out_tag> [out_tag2] ...  # actually deletes

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  stop("Usage: Rscript wipe.R [--confirm] <out_tag> [out_tag2] ...")
}

confirm <- "--confirm" %in% args
out_tags <- setdiff(args, "--confirm")

if (length(out_tags) == 0) {
  stop("No out_tag provided. Usage: Rscript wipe.R [--confirm] <out_tag> [out_tag2] ...")
}

stages <- c(
  "01_prep_model_data",
  "02_model",
  "03_model_select",
  "04_create_census",
  "05_prediction_data",
  "06_create_figures",
  "07_display_figures"
)

targets <- unlist(lapply(out_tags, function(tag) {
  unlist(lapply(stages, function(stage) {
    c(
      file.path(stage, "output", tag),
      file.path(stage, "output", paste0(tag, ".yaml"))
    )
  }))
}))

existing <- targets[file.exists(targets)]

if (length(existing) == 0) {
  cat("Nothing found to delete for:", paste(out_tags, collapse = ", "), "\n")
  quit(status = 0)
}

cat(if (confirm) "Deleting:\n" else "Would delete (dry run -- pass --confirm to actually delete):\n")
cat(paste0("  ", existing), sep = "\n")

if (confirm) {
  unlink(existing, recursive = TRUE, force = TRUE)
  cat("\nDone.\n")
} else {
  cat("\nDry run only -- nothing deleted. Re-run with --confirm to actually delete.\n")
}

cat(
  "\nNote: this does NOT touch raw-data-level output (00a_itp2/output,",
  "00b_dataset_mods/output, 00c_survival_data/output, etc.) -- wipe those",
  "separately and on purpose if your raw data changed.\n"
)
