#* Figure: pre-death decline in BW, FM and FBG, for the R2 response letter
#! Run from the metabolic-class root. Saves four PNGs in 85_terminal_decline/ (pooled, by sex, by strain, by sex x strain) and nothing else. Same data and baseline as terminal_decline.R sections 0 and 2, in 4-week bins. Shaded band = range of best start points from section 3 (14-24 weeks before death).
#+ 0: Data
#- The 1,315 mice in the manuscript (complete census, as in 92_overlap_analysis)
model_ids <- as.integer(read.csv("04_create_census/output/slam_c1-c10_age_all_bwfatgluc/complete_census.csv")$idno)
cat(sprintf("Mice in complete census: %d\n", dplyr::n_distinct(model_ids)))
surv <- read.csv("00c_survival_data/output/slam_c1-c10/data/main_cat_surv.csv") |>
  dplyr::transmute(idno = as.integer(idno), dead_censor, le_wk = as.numeric(le_wk)) |>
  dplyr::filter(dead_censor == 1, idno %in% model_ids)
files <- c(BW = "slam_bw_og.csv", FM = "slam_fat_og.csv", FBG = "slam_gluc_og.csv")
columns <- c(BW = "bw", FM = "fat", FBG = "gluc")
long <- dplyr::bind_rows(lapply(names(files), \(m) {
  read.csv(file.path("00b_dataset_mods/output/slam_c1-c10/data", files[[m]])) |>
    dplyr::transmute(idno = as.integer(idno), sex, strain, age_wk = as.numeric(age_wk), value = as.numeric(.data[[columns[[m]]]]), measure = m)
})) |>
  dplyr::filter(!is.na(value), !is.na(age_wk)) |>
  dplyr::inner_join(surv, by = "idno") |>
  dplyr::mutate(wk_before = le_wk - age_wk) |>
  dplyr::filter(wk_before >= 0)
#+ 1: Percent change from each mouse's own baseline (mean at 26-52 weeks before death)
baseline <- long |>
  dplyr::filter(wk_before >= 26, wk_before < 52) |>
  dplyr::summarise(base = mean(value), .by = c(measure, idno))
pct <- long |>
  dplyr::inner_join(baseline, by = c("measure", "idno")) |>
  dplyr::filter(wk_before < 28, base > 0) |>
  dplyr::mutate(pct = 100 * (value / base - 1), wk_mid = 4 * floor(wk_before / 4) + 2, measure = factor(measure, levels = names(files)), sex = factor(sex, levels = c("F", "M"), labels = c("Female", "Male")), strain = factor(strain))
#+ 2: Figures
library(ggplot2)
versions <- list(pooled = character(), sex = "sex", strain = "strain", sex_strain = c("sex", "strain"))
colors <- c(All = "#333333", Female = "#D1651C", Male = "#1F6FB2", B6 = "#2E8B57", HET3 = "#7A4FA3")
for (v in names(versions)) {
  groups <- versions[[v]]
  binned <- dplyr::summarise(pct, median_pct = median(pct), mice = dplyr::n_distinct(idno), .by = dplyr::all_of(c("measure", "wk_mid", groups)))
  binned$color_group <- if (length(groups) == 0) "All" else as.character(binned[[groups[1]]])
  binned$line_group <- if (v == "sex_strain") as.character(binned$strain) else binned$color_group
  binned$series <- if (v == "sex_strain") paste(binned$sex, binned$strain) else binned$color_group
  cat(sprintf("%s: fewest mice in any bin = %d\n", v, min(binned$mice)))
  p <- ggplot(binned, aes(wk_mid, median_pct, group = series, color = color_group, linetype = line_group, shape = line_group)) +
    annotate("rect", xmin = 14, xmax = 24, ymin = -Inf, ymax = Inf, fill = "grey88") +
    annotate("text", x = 19, y = Inf, label = "Decline begins", vjust = -0.5, size = 2.4, color = "grey30") +
    geom_hline(yintercept = 0, linewidth = 0.3, color = "grey50") +
    geom_line(linewidth = 0.7) +
    geom_point(size = 2) +
    facet_wrap(~ measure, scales = "free_y") +
    coord_cartesian(clip = "off") +
    scale_x_reverse(breaks = seq(0, 28, 7), limits = c(28, 0)) +
    scale_color_manual(values = colors) +
    labs(x = "Weeks before death", y = "Median change\nfrom baseline (%)", color = NULL, linetype = NULL, shape = NULL) +
    theme_classic(base_size = 10) +
    theme(strip.background = element_blank(), strip.text = element_text(face = "bold", margin = margin(b = 14)), legend.position = if (v == "pooled") "none" else "inside", legend.position.inside = c(0.005, 0.01), legend.justification.inside = c(0, 0), legend.direction = "vertical", legend.box = "vertical", legend.spacing.y = unit(1, "pt"), legend.margin = margin(0, 0, 0, 0), legend.background = element_blank(), legend.key.height = unit(9, "pt"), legend.key.width = unit(16, "pt"), legend.text = element_text(size = 7))
  ggsave(file.path("85_terminal_decline", sprintf("terminal_decline_%s.png", v)), p, width = 7, height = 2.4, dpi = 300)
}
