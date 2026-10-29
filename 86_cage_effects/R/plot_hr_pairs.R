# Purpose: Paired forest plot of hazard ratios fitted two ways (here without vs with a cage frailty term), styled
# after the lab manager's Figure S2.10B (itself after the deck's faceted forests, Figure 3E): one panel per model
# (label rotated on the left), one row per class with the reference class shown at HR = 1, row labels, HR (95% CI)
# text and a P column on the right, log10 HR axis, grey/white row stripes alternating continuously down the whole
# figure, dashed lines at the ticks and at HR = 1. Each non-reference row carries both fits as squares with error
# bars in the condition's colour; the reference class is a square of its own colour, listed in the key.
# `d`: facet, row, condition, value, lower, upper, p and reference (TRUE for reference rows, value = 1); facets and
# rows keep their order of appearance. `colors` is a named vector, one entry per condition; the first is drawn
# above the second. Default colours sampled from the mockup.
plot_hr_pairs <- function(d, colors, ref_color = "#0080FF", ref_label = "Reference class") {
  font_mm <- 0.7 * 11 / 72.27 * 25.4   # 07's forest_font_mm (ggforest annotation size)
  conds <- names(colors)
  d <- d |>
    dplyr::mutate(facet = factor(facet, levels = unique(facet)), condition = factor(condition, levels = conds)) |>
    dplyr::mutate(row_y = match(row, rev(unique(row))), .by = facet) |>
    dplyr::mutate(y = ifelse(reference, row_y, row_y + ifelse(condition == conds[1], 0.2, -0.2)),
                  hr_text = ifelse(reference, "reference", sprintf("%.2f (%.2f - %.2f)", value, lower, upper)),
                  p_text = dplyr::case_when(reference ~ "", p < 0.001 ~ "<0.001 ***", p < 0.01 ~ "<0.01 **", p < 0.05 ~ "<0.05 *", TRUE ~ "n.s."))
  pairs <- dplyr::filter(d, !reference)
  refs <- dplyr::filter(d, reference, condition == conds[1])
  refs$condition <- ref_label
  rows <- dplyr::distinct(d, facet, row, row_y) |>
    dplyr::arrange(facet, dplyr::desc(row_y)) |>
    dplyr::mutate(shaded = dplyr::row_number() %% 2 == 1)   # counted down the whole figure, so stripes carry across panels (first row shaded)
  lg_lo <- log10(min(pairs$lower))
  lg_hi <- log10(max(pairs$upper, 1))
  span <- lg_hi - lg_lo
  x_lim <- c(10^(lg_lo - 1.75 * span), 10^(lg_hi + 0.7 * span))   # also the stripes' extent: -Inf is not valid on a log axis
  breaks <- c(0.2, 0.5, 1)
  ggplot2::ggplot() +
    ggplot2::geom_rect(data = dplyr::filter(rows, shaded), ggplot2::aes(xmin = x_lim[1], xmax = x_lim[2], ymin = row_y - 0.5, ymax = row_y + 0.5), fill = "#D2D2D2") +
    ggplot2::geom_vline(xintercept = breaks, linetype = "dashed", color = "grey50", linewidth = 0.4) +   # gridlines and HR = 1, drawn over the opaque stripes
    ggplot2::geom_errorbar(data = pairs, ggplot2::aes(xmin = lower, xmax = upper, y = y, color = condition), orientation = "y", width = 0.15, show.legend = FALSE) +
    ggplot2::geom_point(data = dplyr::bind_rows(pairs, refs), ggplot2::aes(x = value, y = y, color = condition), shape = 15, size = 2.6) +
    ggplot2::geom_text(data = rows, ggplot2::aes(x = x_lim[1] * 1.12, y = row_y, label = row), hjust = 0, size = font_mm) +
    ggplot2::geom_text(data = dplyr::bind_rows(pairs, refs), ggplot2::aes(x = 10^(lg_lo - 0.55 * span), y = y, label = hr_text), hjust = 0.5, size = font_mm) +
    ggplot2::geom_text(data = pairs, ggplot2::aes(x = 10^(lg_hi + 0.12 * span), y = y, label = p_text), hjust = 0, size = font_mm) +
    ggplot2::scale_color_manual(values = c(colors, stats::setNames(ref_color, ref_label)), breaks = c(conds, ref_label), name = NULL) +
    ggplot2::scale_x_log10(breaks = breaks, labels = function(b) sprintf("%g", b), limits = x_lim, expand = ggplot2::expansion(mult = 0)) +
    ggplot2::scale_y_continuous(NULL, breaks = NULL, expand = c(0, 0), limits = function(l) c(0.5, floor(max(l) + 0.3) + 0.5)) +   # whole rows: unshaded rows have no rect to set the panel edge
    ggplot2::guides(color = ggplot2::guide_legend(ncol = 1)) +
    ggplot2::facet_grid(rows = ggplot2::vars(facet), scales = "free_y", space = "free_y", switch = "y") +
    ggplot2::labs(x = "Hazard ratio") +
    ggplot2::theme_light() +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(), panel.grid.major = ggplot2::element_blank(),   # gridlines drawn as geom_vline above
                   panel.border = ggplot2::element_rect(color = "black", fill = NA, linewidth = 0.9),         # deck forests: black panel border
                   panel.spacing = ggplot2::unit(4, "pt"),
                   strip.placement = "outside", strip.background = ggplot2::element_blank(),
                   strip.text.y.left = ggplot2::element_text(angle = 90, color = "black"),
                   legend.position = "right", legend.justification = "top")   # key at top right, as in the mockup
}
