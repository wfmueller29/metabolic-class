# Purpose: Per-cage class agreement and its chance level, one row per cage. observed = share of cagemate
# pairs in the same class; chance = the probability two mice drawn from the cage's cohort x sex x genetic
# background cell (the `within` columns) share a class, sum n_c (n_c - 1) / (N (N - 1)) over classes c.
# Averaged over cages, chance is the exact mean of the shuffle null in concordance_test(), which shuffles
# labels within the same cells. Every cage must hold at least two mice and sit in one cell.
cage_agreement <- function(data, class_col, within = c("cohort", "sex", "strain")) {
  d <- data.frame(cage = data$cage, sex = data$sex, cell = as.character(interaction(data[within], drop = TRUE)), cls = data[[class_col]])
  chance <- tapply(d$cls, d$cell, \(x) { n <- table(x); sum(n * (n - 1)) / (length(x) * (length(x) - 1)) })
  dplyr::summarise(d, sex = sex[1], cell = cell[1], observed = { p <- utils::combn(cls, 2); mean(p[1, ] == p[2, ]) }, .by = cage) |>
    dplyr::mutate(chance = as.numeric(chance[cell]))
}
