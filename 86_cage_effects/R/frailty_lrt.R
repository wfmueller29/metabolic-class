# Purpose: Likelihood-ratio test of a gamma shared frailty term: the frailty model's integrated
# likelihood (I-likelihood) against the same model without it. The variance cannot go below 0,
# so P is halved (boundary correction). Returns variance, chi-square (1 df) and P.
frailty_lrt <- function(frailty_fit, null_fit) {
  chisq <- 2 * (frailty_fit$history[[1]]$c.loglik - utils::tail(null_fit$loglik, 1))
  c(variance = frailty_fit$history[[1]]$theta, chisq = chisq, p = 0.5 * stats::pchisq(chisq, 1, lower.tail = FALSE))
}
