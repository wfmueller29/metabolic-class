# Purpose: Save a ggplot as two PNGs in `dir`: `name`.png on white and `name`_transparent.png with no
# background. The theme's plot, panel, legend and legend-key backgrounds are cleared for the
# transparent copy, since ggsave(bg = "transparent") alone leaves the theme's white fills in place.
save_png_pair <- function(plot, dir, name, width, height, dpi = 600) {
  ggplot2::ggsave(file.path(dir, paste0(name, ".png")), plot, width = width, height = height, dpi = dpi, bg = "white")
  clear <- ggplot2::element_rect(fill = "transparent", colour = NA)
  plot_clear <- plot + ggplot2::theme(plot.background = clear, panel.background = clear, legend.background = clear, legend.key = clear)
  ggplot2::ggsave(file.path(dir, paste0(name, "_transparent.png")), plot_clear, width = width, height = height, dpi = dpi, bg = "transparent")
}
