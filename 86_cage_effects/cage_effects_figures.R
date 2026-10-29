#* 86 figures: cage effect figures for 2.10.2 (replace Tables S2.6 and S2.7)
#! Figure S2.10: A = cagemate concordance (86.9), B = class-survival HRs with and without cage frailty (86.10).
#! Run after cage_effects.R in the same session: needs its helpers (86.0), measures (86.1.8), pooled_concordance and group_concordance (86.2), hr_original and hr_frailty (86.4); 86.5 adds nothing the figures need. Writes each figure as two 600-dpi PNGs (white and transparent background) to 86_cage_effects/output/.
#+ 86.8: Setup
#- 86.8.1: Output folder
fig_dir <- "86_cage_effects/output"
dir.create(fig_dir, showWarnings = FALSE)
#- 86.8.2: Reader-facing labels for the class models
fit_labels <- c(Pooled = "Pooled", `F B6` = "F/B6", `M B6` = "M/B6", `F HET3` = "F/HET3", `M HET3` = "M/HET3")   # sex/strain labels as in the chapter's tables
#+ 86.9: Concordance of class assignments among cagemates (paragraph one)
#- 86.9.1: Pooled and sex x genetic background fits together, one panel per class model
#! Every panel keeps all three measures: a measure with one class in that model (FBG in the B6 fits) stays as an empty row reading "one class".
concordance_fig_data <- expand.grid(row = names(measures), facet = unname(fit_labels), stringsAsFactors = FALSE) |>
  dplyr::left_join(dplyr::bind_rows(dplyr::mutate(pooled_concordance, fit = "Pooled"), group_concordance) |>
                     dplyr::transmute(facet = unname(fit_labels[fit]), row = LCM, observed, null_mean, null_lo, null_hi, p = more_alike_P),
                   by = c("facet", "row"))
#- 86.9.2: Plot and save
concordance_fig <- plot_concordance(concordance_fig_data)
save_png_pair(concordance_fig, fig_dir, "S2.10A", width = 5.8, height = 5.5)
#+ 86.10: Class-survival hazard ratios with and without a cage frailty term (paragraph three)
#- 86.10.1: Both fits stacked, one panel per model, reference classes kept (drawn at HR = 1)
hr_fig_data <- dplyr::bind_rows(`Original model` = hr_original, `With cage frailty term` = hr_frailty, .id = "condition") |>
  dplyr::transmute(facet = Model, reference = is.na(est), row = paste0(LCM, ", Class ", Class),   # "reference" already shows in the HR column
                   condition, value = ifelse(reference, 1, est), lower, upper, p)
#- 86.10.2: Plot and save
hr_fig <- plot_hr_pairs(hr_fig_data, colors = c(`Original model` = "#000000", `With cage frailty term` = "#FF8000"))   # colours sampled from the lab manager's mockup
save_png_pair(hr_fig, fig_dir, "S2.10B", width = 8.5, height = 10)
