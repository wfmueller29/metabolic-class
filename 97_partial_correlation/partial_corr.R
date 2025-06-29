# Create a partial correlation analysis

library(consoler)
library(ppcor)
library(qgraph)

census <- read.csv("/Users/williammueller/programs/metabolic_class/analysis/04_create_census/output/slam_c1-c10_age_all_bwfatgluc/complete_census.csv")


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
