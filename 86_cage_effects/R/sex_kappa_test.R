# Purpose: Does cagemate class agreement differ between females and males? For each class measure: kappa
# (agreement_kappa()) in each sex from cage_agreement(), and the male - female difference, with 95% CIs from B
# bootstrap resamples of cages (boot::boot) stratified by cohort x sex x genetic background cell (the `within`
# columns), so every replicate keeps the cohort and genetic background mix of each sex. CIs are boot.ci()
# normal-approximation intervals, as for the reclassification accuracy CIs (06_create_figures/R/extract_accuracy_ci.R).
# Use classes defined the same way in both sexes (the pooled fit). Expects sex coded "F" and "M".
#   seed : set at the start, so results do not depend on what ran before.
sex_kappa_test <- function(data, measures, within = c("cohort", "sex", "strain"), B = 2000, seed = 86) {
  stopifnot(setequal(unique(data$sex), c("F", "M")))
  set.seed(seed)
  dplyr::bind_rows(lapply(names(measures), \(lcm) {
    ca <- cage_agreement(data, measures[[lcm]], within)
    stat <- \(x, i) {
      x <- x[i, ]
      k <- c(F = agreement_kappa(x$observed[x$sex == "F"], x$chance[x$sex == "F"]), M = agreement_kappa(x$observed[x$sex == "M"], x$chance[x$sex == "M"]))
      c(k, MF = k[["M"]] - k[["F"]])
    }
    bt <- boot::boot(ca, stat, R = B, strata = factor(ca$cell))
    ci <- \(j) boot::boot.ci(bt, type = "norm", index = j)$normal[2:3]
    data.frame(LCM = lcm, cages_F = sum(ca$sex == "F"), cages_M = sum(ca$sex == "M"),
               chance_F = mean(ca$chance[ca$sex == "F"]), chance_M = mean(ca$chance[ca$sex == "M"]),
               kappa_F = bt$t0[["F"]], kappa_F_lo = ci(1)[1], kappa_F_hi = ci(1)[2],
               kappa_M = bt$t0[["M"]], kappa_M_lo = ci(2)[1], kappa_M_hi = ci(2)[2],
               diff_MF = bt$t0[["MF"]], diff_lo = ci(3)[1], diff_hi = ci(3)[2])
  }))
}
