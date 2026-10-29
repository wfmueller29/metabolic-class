# Purpose: Chance-corrected agreement (kappa form): the share of the possible agreement above chance that was
# reached, (mean observed - mean chance) / (1 - mean chance). Puts groups with different chance levels on one
# scale. NA when chance is 1 (every mouse in one class), since nothing could be above it.
agreement_kappa <- function(observed, chance) {
  room <- 1 - mean(chance)
  if (room <= 0) return(NA_real_)
  (mean(observed) - mean(chance)) / room
}
