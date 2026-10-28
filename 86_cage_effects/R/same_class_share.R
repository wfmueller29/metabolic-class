# Purpose: Mean over cages of the share of cagemate pairs in the same class. High = cagemates
# alike (cage effect); low = cagemates different (consistent with social order). Every cage
# must hold at least two mice.
same_class_share <- function(cls, cage) {
  mean(tapply(cls, cage, \(x) { p <- utils::combn(x, 2); mean(p[1, ] == p[2, ]) }))
}
