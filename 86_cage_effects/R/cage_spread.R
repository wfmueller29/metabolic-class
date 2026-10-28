# Purpose: Mean over cages of the mean absolute difference in x between cagemates (dist() on one
# number per mouse = absolute pairwise differences). Small = cagemates alike; large = they differ.
cage_spread <- function(x, cage) {
  mean(tapply(x, cage, \(v) mean(dist(v))))
}
