# Purpose: Absolute differences in x for every pair of cagemates, pooled over cages.
pair_gaps <- function(x, cage) {
  unlist(tapply(x, cage, \(v) as.vector(dist(v))))
}
