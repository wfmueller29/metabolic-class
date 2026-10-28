# Purpose: Significance stars as in the chapter's tables and legends: *** P < 0.001, ** P < 0.01,
# * P < 0.05, otherwise "". Vectorised.
p_stars <- function(p) {
  as.character(cut(p, c(-Inf, 0.001, 0.01, 0.05, Inf), c("***", "**", "*", ""), right = FALSE))
}
