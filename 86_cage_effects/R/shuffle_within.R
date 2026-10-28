# Purpose: Permute x within each level of group (one draw). The permutation nulls use it so a
# value only ever moves between mice of the same cohort x sex x genetic background.
shuffle_within <- function(x, group) {
  stats::ave(x, group, FUN = \(v) v[sample.int(length(v))])
}
