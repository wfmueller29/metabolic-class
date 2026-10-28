# Purpose: Cagemate class concordance against chance, laid out like the deck's faceted forests
# (07_display_figures.Rmd, Figure 4G): one panel per class model (label rotated on the left), one
# row per class measure (label inside the panel on the left), P values in a column on the right.
# x = percentage points above the chance mean; grey bar = middle 90% of the shuffles, so a square
# past its right end is more alike than chance at one-sided P < 0.05; dotted line = chance.
# `d` has facet, row, observed, null_mean, null_lo, null_hi (proportions) and p; a row with NA
# values (a measure with a single class in that model) keeps its place and reads "one class".
plot_concordance <- function(d) {
  font_mm <- 0.7 * 11 / 72.27 * 25.4   # 07's forest_font_mm (ggforest annotation size)
  d <- d |>
    dplyr::mutate(facet = factor(facet, levels = unique(facet))) |>
    dplyr::mutate(row_y = match(row, rev(unique(row))), .by = facet) |>   # numeric rows: order of appearance, top to bottom
    dplyr::mutate(shaded = row_y %% 2 == 0) |>
    dplyr::mutate(excess = 100 * (observed - null_mean), lo = 100 * (null_lo - null_mean), hi = 100 * (null_hi - null_mean),
                  p_text = dplyr::case_when(is.na(p) ~ "one class", p <= 0.001 ~ "≤ 0.001", TRUE ~ sprintf("%.3f", p)))
  x_lo <- min(d$lo, d$excess, na.rm = TRUE)
  x_hi <- max(d$hi, d$excess, na.rm = TRUE)
  span <- x_hi - x_lo
  x_label <- x_lo - 0.16 * span                   # measure labels, inside the panel on the left
  p_zone <- x_hi + c(0.06, 0.36) * span           # space reserved for the P column, right of the data
  x_p <- mean(p_zone)                             # P values centred in that space
  breaks <- scales::breaks_pretty(n = 5)(c(x_lo, x_hi))
  breaks <- breaks[breaks >= x_lo & breaks <= x_hi]   # ticks (and their dashed lines) stay within the data, clear of the label and P columns
  ggplot2::ggplot(d, ggplot2::aes(y = row_y)) +
    ggplot2::geom_rect(data = dplyr::filter(d, shaded), ggplot2::aes(xmin = -Inf, xmax = Inf, ymin = row_y - 0.5, ymax = row_y + 0.5), fill = "#00000014", inherit.aes = FALSE) +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.4) +
    ggplot2::geom_segment(ggplot2::aes(x = lo, xend = hi, yend = row_y), linewidth = 3, color = "grey78", na.rm = TRUE) +
    ggplot2::geom_point(ggplot2::aes(x = excess), shape = 15, size = 3, na.rm = TRUE) +
    ggplot2::geom_text(ggplot2::aes(x = x_label, label = row), hjust = 0, size = font_mm) +
    ggplot2::geom_text(ggplot2::aes(x = x_p, label = p_text), hjust = 0.5, size = font_mm) +
    ggplot2::scale_x_continuous(breaks = breaks, labels = function(b) ifelse(b == 0, "0", sprintf("%+g", b)),
                                limits = c(x_label - 0.03 * span, p_zone[2]), expand = ggplot2::expansion(mult = 0)) +
    ggplot2::scale_y_continuous(NULL, breaks = NULL, expand = c(0, 0), limits = function(l) c(0.5, floor(max(l) + 0.3) + 0.5)) +
    ggplot2::facet_grid(rows = ggplot2::vars(facet), scales = "free_y", space = "free_y", switch = "y") +
    ggplot2::labs(x = "Concordance above chance (percentage points)") +
    ggplot2::theme_light() +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(), panel.grid.major.y = ggplot2::element_blank(),
                   panel.grid.major.x = ggplot2::element_line(color = "grey50", linetype = "dashed", linewidth = 0.4),   # deck forests: grey dashed lines at the ticks
                   panel.border = ggplot2::element_rect(color = "black", fill = NA, linewidth = 0.9),                  # deck forests: black panel border panel.spacing = ggplot2::unit(4, "pt"),
                   strip.placement = "outside", strip.background = ggplot2::element_blank(),
                   strip.text.y.left = ggplot2::element_text(angle = 90, color = "black"),
                   axis.text.y = ggplot2::element_blank(), axis.ticks.y = ggplot2::element_blank())
}
