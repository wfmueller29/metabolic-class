run_partial_correlation <- function(
    census_path,
    analysis_name,
    keep_vars = c(
      "Lifespan" = "le_wk",
      "Female" = "sex_F",
      "B6" = "strain_B6",
      "Early-peak BW" = "prob1",
      "Early-peak FM" = "prob4",
      "Decline FBG" = "prob7"
    ),
    output_dir = "output",
    minimum = 0.05,
    network_title = "Partial Correlation Network",
    table_title = "Partial Correlation Coefficients") {
  # Read data
  census <- read.csv(census_path)

  # Check that all requested columns exist
  missing_vars <- setdiff(unname(keep_vars), names(census))

  if (length(missing_vars) > 0) {
    stop(
      "The following columns are missing from the census data: ",
      paste(missing_vars, collapse = ", ")
    )
  }

  # Extract latent class numbers from probN column names
  class_num <- sub("^prob(\\d+)$", "\\1", unname(keep_vars))
  class_num[!grepl("^prob\\d+$", unname(keep_vars))] <- NA_character_

  # Labels used in the network plot
  network_labels <- ifelse(
    !is.na(class_num),
    paste0("Class ", class_num),
    names(keep_vars)
  )
  names(network_labels) <- names(keep_vars)

  # Labels used in the results table
  table_labels <- ifelse(
    !is.na(class_num),
    paste0(names(keep_vars), " (", class_num, ")"),
    names(keep_vars)
  )
  names(table_labels) <- names(keep_vars)

  # Rename and retain requested variables
  census <- consoler::rename(census, keep_vars)
  census <- census[, names(keep_vars), drop = FALSE]

  # Remove rows containing missing values
  census <- na.omit(census)

  if (nrow(census) < 3) {
    stop("Too few complete observations remain after removing missing values.")
  }

  # Calculate partial correlations
  pcor_results <- ppcor::pcor(census)

  print(pcor_results$estimate)
  print(pcor_results$p.value)

  # Create output directory
  dir.create(
    output_dir,
    showWarnings = FALSE,
    recursive = TRUE
  )

  # Build output paths
  network_path <- file.path(
    output_dir,
    paste0(analysis_name, "_partial_correlation_network.jpg")
  )

  table_path <- file.path(
    output_dir,
    paste0(analysis_name, "_partial_correlation_results_clean_table.png")
  )

  csv_path <- file.path(
    output_dir,
    paste0(analysis_name, "_partial_correlation_results.csv")
  )

  # Save partial-correlation network
  jpeg(
    filename = network_path,
    width = 2000,
    height = 2000,
    res = 300
  )

  qgraph::qgraph(
    pcor_results$estimate,
    layout = "spring",
    labels = network_labels[colnames(census)],
    minimum = minimum,
    title = network_title
  )

  dev.off()

  # Prepare correlation and p-value matrices
  cor_mat <- round(pcor_results$estimate, 2)
  pval_mat <- signif(pcor_results$p.value, 2)

  vars <- colnames(cor_mat)

  # Extract unique variable pairs from the lower triangle
  pair_indices <- which(lower.tri(cor_mat), arr.ind = TRUE)

  result_table <- data.frame(
    Variable1 = table_labels[vars[pair_indices[, "row"]]],
    Variable2 = table_labels[vars[pair_indices[, "col"]]],
    PartialCorrelation = cor_mat[pair_indices],
    PValue = pval_mat[pair_indices],
    stringsAsFactors = FALSE,
    row.names = NULL
  )

  # Sort by absolute partial correlation
  result_table <- result_table[
    order(-abs(result_table$PartialCorrelation)), ,
    drop = FALSE
  ]

  names(result_table) <- c(
    "Variable 1 (Class)",
    "Variable 2 (Class)",
    "Corr.",
    "P value"
  )

  print(result_table)

  # Create table grob
  tab <- gridExtra::tableGrob(
    result_table,
    rows = NULL
  )

  title_grob <- grid::textGrob(
    table_title,
    gp = grid::gpar(
      fontsize = 14,
      fontface = "bold"
    )
  )

  combined <- gtable::gtable_add_rows(
    tab,
    heights = grid::grobHeight(title_grob) + grid::unit(5, "mm"),
    pos = 0
  )

  combined <- gtable::gtable_add_grob(
    combined,
    title_grob,
    t = 1,
    l = 1,
    b = 1,
    r = ncol(tab)
  )

  # Save results table
  png(
    filename = table_path,
    width = 1200,
    height = 900,
    res = 150
  )

  grid::grid.newpage()
  grid::grid.draw(combined)

  dev.off()

  # Save results as CSV
  write.csv(
    result_table,
    csv_path,
    row.names = FALSE
  )

  # Return useful objects and paths
  invisible(
    list(
      census = census,
      pcor_results = pcor_results,
      result_table = result_table,
      output_paths = list(
        network = network_path,
        table = table_path,
        csv = csv_path
      )
    )
  )
}
