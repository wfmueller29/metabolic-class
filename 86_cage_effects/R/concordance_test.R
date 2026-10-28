# Purpose: Are cagemates' classes more or less alike than chance? For each class measure: the observed
# share of cagemate pairs in the same class (same_class_share()) against k shuffles of class labels
# that only move between mice sharing the `within` columns (shuffle_within()). Returns one row per
# measure with the chance mean, the middle 90% of the shuffles (so lying past it matches a one-sided
# P < 0.05) and P values in both directions.
#   by     : optional column to split on first (e.g. "sex"); runs the test within each level. Splits
#            must keep whole cages, which sex and strain do (cages are single-sex, single-strain).
#   within : what the shuffles hold fixed; default cohort x sex x genetic background.
#   seed   : set at the start of every test, so results do not depend on what ran before.
# Measures where every mouse shares one class have nothing to test and are dropped.
concordance_test <- function(data, measures, by = NULL, within = c("cohort", "sex", "strain"), k = 999, seed = 86) {
  if (!is.null(by)) return(dplyr::bind_rows(lapply(split(data, data[[by]]), concordance_test, measures = measures, within = within, k = k, seed = seed), .id = by))
  set.seed(seed)
  measures <- measures[sapply(measures, \(v) dplyr::n_distinct(data[[v]]) > 1)]
  group <- interaction(data[within], drop = TRUE)
  obs <- sapply(measures, \(v) same_class_share(data[[v]], data$cage))
  null <- matrix(replicate(k, sapply(measures, \(v) same_class_share(shuffle_within(data[[v]], group), data$cage))), nrow = length(measures))   # one row per measure, even when only one remains
  data.frame(LCM = names(measures), mice = nrow(data), cages = dplyr::n_distinct(data$cage), observed = obs, null_mean = rowMeans(null), null_lo = apply(null, 1, stats::quantile, 0.05), null_hi = apply(null, 1, stats::quantile, 0.95),
             more_alike_P = (1 + rowSums(null >= obs)) / (k + 1), more_different_P = (1 + rowSums(null <= obs)) / (k + 1))
}
