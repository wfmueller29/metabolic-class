# Purpose: Class hazard ratios from a Cox fit (with or without a frailty term), formatted by
# format_hr() (hr) plus the numeric HR (est), 95% CI (lower, upper) and P (p), with the reference class first as "Reference" (as in Table S2.1 and Figure 1N).
# `prefix` is the name of the class factor in the model formula. Wald CIs and P from summary();
# works for coxph and coxph.penal (frailty) fits. The reference is read from the fit's own levels.
class_hrs <- function(fit, prefix = "cls") {
  sm <- summary(fit)
  ci <- sm$conf.int[startsWith(rownames(sm$conf.int), prefix), , drop = FALSE]
  p <- sm$coefficients[rownames(ci), ncol(sm$coefficients)]
  rbind(data.frame(Class = fit$xlevels[[prefix]][1], hr = "Reference", est = NA_real_, lower = NA_real_, upper = NA_real_, p = NA_real_),
        data.frame(Class = sub(paste0("^", prefix), "", rownames(ci)), hr = format_hr(ci[, 1], ci[, 3], ci[, 4], p), est = unname(ci[, 1]), lower = unname(ci[, 3]), upper = unname(ci[, 4]), p = unname(p)))
}
