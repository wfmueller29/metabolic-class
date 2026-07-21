# =============================================================================
# Partial-correlation network: methods comparison figure.
#
# Compares the CURRENT method (Pearson via ppcor::pcor -- which reduces to
# point-biserial for continuous/binary and phi for binary/binary pairs) against
# the type-appropriate cor_auto method (qgraph::cor_auto -> tetrachoric /
# polyserial / Pearson by variable type), both partial-correlated.
#
# Output: ONE composite PNG (output/partial_corr_methods_comp.png) with the two
# correlation networks juxtaposed on top and a side-by-side coefficient/p-value
# comparison table below.
#
# NOTE on interpretation: tetrachoric/polyserial (cor_auto) assume the binary
# variables are dichotomized latent-normal continua, which is questionable for
# TRUE categories like sex/strain. So this is a SENSITIVITY analysis, not a
# claim that cor_auto is definitively more correct. cor_auto p-values here are
# approximate (normal-theory t-test on the polychoric-based estimates).
#
# Run from the 91_partial_correlation/ directory: Rscript partial_corr_methods_comp.R
# =============================================================================

library(ppcor)
library(qgraph)
library(gridExtra)
library(grid)
library(gtable)
library(magick)

# Run from this script's own directory regardless of where it is invoked from,
# so the ../ and output/ relative paths resolve. (Only takes effect under
# Rscript; if you source() this interactively, be in 91_partial_correlation/.)
local({
  f <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
  if (length(f)) setwd(dirname(normalizePath(f)))
})

# --- load the SAME data partial_corr.R uses ---------------------------------
census <- read.csv("../04_create_census/output/slam_c1-c10_age_all_bwfatgluc/complete_census.csv")
keep_vars <- c(
  "Lifespan" = "le_wk",
  "Female" = "sex_F",
  "B6" = "strain_B6",
  "Early-peak BW" = "prob1",
  "Early-peak FM" = "prob4",
  "Decline FBG" = "prob7"
)
dat <- na.omit(census[, keep_vars])
colnames(dat) <- names(keep_vars)
vars <- colnames(dat)
n <- nrow(dat)

# class-tied labels: probN -> class number N. Network plot shows just
# "Class N"; the table shows "descriptor (N)". Non-class variables (Lifespan,
# Female, B6) keep their descriptor in both.
class_num <- sub("^prob(\\d+)$", "\\1", keep_vars)
class_num[!grepl("^prob\\d+$", keep_vars)] <- NA
network_labels <- ifelse(!is.na(class_num), paste0("Class ", class_num), names(keep_vars))
names(network_labels) <- names(keep_vars)
table_labels <- ifelse(
  !is.na(class_num), paste0(names(keep_vars), " (", class_num, ")"), names(keep_vars)
)
names(table_labels) <- names(keep_vars)

# --- Method A: CURRENT default -- Pearson partial correlation ---------------
pcorA <- pcor(dat) # default method = "pearson"
estA <- pcorA$estimate
pA <- pcorA$p.value

# --- Method B: cor_auto (type-appropriate) -> partial correlation -----------
cor_auto_mat <- cor_auto(dat) # tetrachoric/polyserial/Pearson by type
estB <- -cov2cor(solve(cor_auto_mat)) # partial corr = -P_ij / sqrt(P_ii P_jj)
diag(estB) <- 1
dimnames(estB) <- dimnames(estA)
# approximate p-values: t = r*sqrt(df/(1-r^2)), df = n - 2 - k
k <- ncol(dat) - 2
dfree <- n - 2 - k
pB <- 2 * pt(-abs(estB * sqrt(dfree / (1 - estB^2))), dfree)
diag(pB) <- 0

# --- output dir + temp files ------------------------------------------------
if (!dir.exists("output")) dir.create("output", recursive = TRUE)
tmp <- tempdir()
netA_png <- file.path(tmp, "netA.png")
netB_png <- file.path(tmp, "netB.png")
tbl_png <- file.path(tmp, "tbl.png")

# shared layout + shared edge-width scale so the two networks are comparable
shared_layout <- qgraph(estA, layout = "spring", DoNotPlot = TRUE)$layout
shared_max <- max(abs(estA[lower.tri(estA)]), abs(estB[lower.tri(estB)]))

# --- render each network to its own PNG -------------------------------------
png(netA_png, width = 1800, height = 1800, res = 300, bg = "white")
qgraph(estA,
  layout = shared_layout, labels = network_labels[vars], minimum = 0.05, maximum = shared_max,
  title = "A. Pearson (current)", title.cex = 1.4
)
dev.off()

png(netB_png, width = 1800, height = 1800, res = 300, bg = "white")
qgraph(estB,
  layout = shared_layout, labels = network_labels[vars], minimum = 0.05, maximum = shared_max,
  title = "B. cor_auto (type-appropriate)", title.cex = 1.4
)
dev.off()

# --- married comparison table (each unique variable pair) -------------------
rows <- list()
for (i in 2:length(vars)) {
  for (j in 1:(i - 1)) {
    rows[[length(rows) + 1]] <- data.frame(
      "Variable 1 (Class)" = table_labels[vars[i]],
      "Variable 2 (Class)" = table_labels[vars[j]],
      "Pearson coef" = round(estA[i, j], 3),
      "Pearson p" = signif(pA[i, j], 2),
      "cor_auto coef" = round(estB[i, j], 3),
      "cor_auto p" = signif(pB[i, j], 2),
      "Delta coef" = round(estB[i, j] - estA[i, j], 3),
      check.names = FALSE, stringsAsFactors = FALSE
    )
  }
}
comp <- do.call(rbind, rows)
comp <- comp[order(-abs(comp$"Pearson coef")), ]
rownames(comp) <- NULL

# render table (with title + footnote) to its own PNG at its natural size
tg <- tableGrob(comp, rows = NULL)
title <- textGrob("Partial Correlation: Pearson (current) vs cor_auto (type-appropriate)",
  gp = gpar(fontsize = 13, fontface = "bold")
)
footnote <- textGrob(
  paste0(
    "N = ", n, " complete cases. cor_auto uses tetrachoric/polyserial for the binary variables ",
    "(Female, B6); cor_auto p-values are approximate."
  ),
  gp = gpar(fontsize = 9, fontface = "italic")
)
tg <- gtable_add_rows(tg, heights = grobHeight(title) + unit(6, "mm"), pos = 0)
tg <- gtable_add_grob(tg, title, t = 1, l = 1, r = ncol(tg))
tg <- gtable_add_rows(tg, heights = grobHeight(footnote) + unit(6, "mm"))
tg <- gtable_add_grob(tg, footnote, t = nrow(tg), l = 1, r = ncol(tg))

tw <- convertWidth(sum(tg$widths), "in", valueOnly = TRUE) + 0.4
th <- convertHeight(sum(tg$heights), "in", valueOnly = TRUE) + 0.4
png(tbl_png, width = tw, height = th, units = "in", res = 300, bg = "white")
grid.newpage()
grid.draw(tg)
dev.off()

# --- composite: networks side-by-side on top, table below -------------------
netA <- image_read(netA_png)
netB <- image_read(netB_png)
tbl <- image_read(tbl_png)

top <- image_append(c(netA, netB)) # two networks side by side
top_w <- image_info(top)$width
tbl <- image_scale(tbl, as.character(top_w)) # match table width to the networks
final <- image_append(c(top, tbl), stack = TRUE)
final <- image_border(final, color = "white", geometry = "40x40")

image_write(final, "output/partial_corr_methods_comp.png")
cat("wrote: output/partial_corr_methods_comp.png\n")

# also print the comparison to the console
print(comp, row.names = FALSE)
cat("\nmax |Delta coef|:", max(abs(comp$"Delta coef")), "\n")
cat(
  "any pair flip significance at p<0.05?:",
  any((comp$"Pearson p" < 0.05) != (comp$"cor_auto p" < 0.05)), "\n"
)
