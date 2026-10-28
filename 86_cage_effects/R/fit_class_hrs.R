# Purpose: Fit one Cox model of survival on a class measure and return its class hazard ratios
# (class_hrs() format, one row per non-reference class). `class_col` is the class column, `adj`
# the rest of the right-hand side after the class term (e.g. " + sex * strain"); `frailty = TRUE`
# adds a gamma shared frailty term for cage.
fit_class_hrs <- function(data, class_col, adj = "", frailty = FALSE) {
  d <- dplyr::mutate(data, cls = factor(.data[[class_col]]))
  f <- paste0("survival::Surv(le_wk, dead_censor == 1) ~ cls", adj, if (frailty) " + survival::frailty(cage)")
  class_hrs(survival::coxph(stats::as.formula(f), data = d))
}
