# Create a partial correlation analysis

library(consoler)
library(ppcor)
library(qgraph)
library(gridExtra)
library(grid)

census <- read.csv("../04_create_census/output/slam_c1-c10_age_all_bwfatgluc/complete_census.csv")


peek(census)


keep_vars <- c(
  "Lifespan" = "le_wk",
  "Female" = "sex_F",
  "B6" = "strain_B6",
  "Early-peak BW" = "prob1",
  "Early-peak FM" = "prob4",
  "Decline FBG" = "prob7"
)

census <- consoler::rename(census, keep_vars)

census <- census[, names(keep_vars)]

census <- na.omit(census)

pcor_results <- pcor(census)

# View partial correlation coefficients
print(pcor_results$estimate)

# Optional: View p-values
print(pcor_results$p.value)


output_dir <- "output"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
}

jpeg("output/partial_correlation_network.jpg", width = 2000, height = 2000, res = 300) # adjust size and resolution
# Your qgraph plot code
# Visualize partial correlation network
qgraph(pcor_results$estimate,
  layout = "spring",
  labels = colnames(census),
  minimum = 0.05, # Only show correlations above a threshold
  title = "Partial Correlation Network"
)
dev.off()


# Get correlation and p-value matrices
cor_mat <- round(pcor_results$estimate, 2)
pval_mat <- signif(pcor_results$p.value, 2)

# Get variable names
vars <- colnames(cor_mat)

# Initialize combined output table
result_table <- data.frame(
  Variable1 = character(),
  Variable2 = character(),
  PartialCorrelation = numeric(),
  PValue = numeric(),
  stringsAsFactors = FALSE
)

# Loop through lower triangle to extract pairs
for (i in 2:nrow(cor_mat)) {
  for (j in 1:(i - 1)) {
    result_table <- rbind(
      result_table,
      data.frame(
        Variable1 = vars[i],
        Variable2 = vars[j],
        PartialCorrelation = cor_mat[i, j],
        PValue = pval_mat[i, j],
        stringsAsFactors = FALSE
      )
    )
  }
}

# Sort by absolute value of correlation
result_table <- result_table[order(-abs(result_table$PartialCorrelation)), ]

# Print for review
print(result_table)


# Create the grob table from your result_table
tab <- tableGrob(result_table, rows = NULL)

# Optional: add a title grob
title <- textGrob("Partial Correlation Coefficients", gp = gpar(fontsize = 14, fontface = "bold"))

# Combine title and table into one grid
combined <- gtable::gtable_add_rows(tab, heights = grobHeight(title) + unit(5, "mm"), pos = 0)
combined <- gtable::gtable_add_grob(combined, title, 1, 1, 1, ncol(tab))

# Save to PNG
png("output/partial_correlation_results_clean_table.png", width = 1200, height = 900, res = 150)
grid.newpage()
grid.draw(combined)
dev.off()

# Optional: Save to CSV
write.csv(result_table, "output/partial_correlation_results.csv", row.names = FALSE)
