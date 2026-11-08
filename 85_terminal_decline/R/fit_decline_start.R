#' Best-fitting start of the pre-death decline, by a grid search over start points
#'
#' Fits value ~ quadratic age + terminal + (1 + age_c | idno) at each start point. Linear shape: terminal = pmax(c - wk_before, 0). Quadratic shape: terminal = pmax(c - wk_before, 0)^2 / c, so the slope still gives the total drop as slope * c in both shapes.
#' @param d Rows for one group, with idno, value, age_wk and wk_before.
#' @param grid Start points to try, in weeks before death.
#' @param shape "linear" or "quadratic".
#' @return One-row data frame: best start, support range (within 1.92 log-likelihood units of the best), total drop and log-likelihood.
fit_decline_start <- function(d, grid = seq(2, 52, 2), shape = "linear") {
  d$age_c <- (d$age_wk - 100) / 52
  d$age_c2 <- d$age_c^2
  control <- lme4::lmerControl(calc.derivs = FALSE)
  profile <- dplyr::bind_rows(lapply(grid, \(c_wk) {
    ramp <- pmax(c_wk - d$wk_before, 0)
    d$terminal <- if (shape == "linear") ramp else ramp^2 / c_wk
    fit <- suppressMessages(suppressWarnings(lme4::lmer(value ~ age_c + age_c2 + terminal + (1 + age_c | idno), data = d, REML = FALSE, control = control)))
    data.frame(c_wk, ll = as.numeric(logLik(fit)), slope = lme4::fixef(fit)[["terminal"]])
  }))
  best <- profile[which.max(profile$ll), ]
  support <- profile$c_wk[profile$ll >= best$ll - 1.92]
  data.frame(start_wk = best$c_wk, support_lo = min(support), support_hi = max(support), drop_total = best$slope * best$c_wk, ll = best$ll)
}
