# Purpose: The 86.4 concordance test on any subset of mice: observed share of cagemate pairs in the
# same class (same_class_share()) against k shuffles of class labels within cohort x sex x genetic
# background (shuffle_within()), for each class measure. Returns one row per measure with
# P values in both directions. Subsets must keep whole cages (e.g. by sex or strain; cages are
# single-sex, single-strain).
concordance_test <- function(data, measures, k = 999) {
  group <- interaction(data$cohort, data$sex, data$strain, drop = TRUE)
  obs <- sapply(measures, \(v) same_class_share(data[[v]], data$cage))
  null <- replicate(k, sapply(measures, \(v) same_class_share(shuffle_within(data[[v]], group), data$cage)))
  data.frame(LCM = names(measures), mice = nrow(data), cages = dplyr::n_distinct(data$cage), observed = obs, null_mean = rowMeans(null),
             more_alike_P = (1 + rowSums(null >= obs)) / (k + 1), more_different_P = (1 + rowSums(null <= obs)) / (k + 1))
}
