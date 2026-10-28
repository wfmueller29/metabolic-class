# Purpose: Format a hazard ratio as in Table S2.1 and Figure 1N: "0.3374 (0.2766, 0.4116) ***".
# Same convention as format_hr_bare() in 99_pub_ready_figs/pub_ready_figs.R (4 dp; *** p < 0.001,
# ** p < 0.01, * p < 0.05, matching the manuscript legends). Vectorised over all arguments.
format_hr <- function(hr, lower, upper, p) {
  stars <- as.character(cut(p, c(-Inf, 0.001, 0.01, 0.05, Inf), c("***", "**", "*", ""), right = FALSE))
  trimws(sprintf("%.4f (%.4f, %.4f) %s", hr, lower, upper, stars))
}
