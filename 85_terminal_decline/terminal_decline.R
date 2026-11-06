#* Check: size and timing of the pre-death decline (R2 comments 2 and 3; nothing is saved)
#! Run from the metabolic-class root. Prints summaries only. Weeks before death = le_wk - age_wk, in mice with dead_censor == 1 (includes culled and per-vet deaths, which can end a decline early).
#+ 0: Data
#- The 1,315 mice in the manuscript (complete census, as in 92_overlap_analysis)
model_ids <- as.integer(read.csv("04_create_census/output/slam_c1-c10_age_all_bwfatgluc/complete_census.csv")$idno)
cat(sprintf("Mice in complete census: %d\n", dplyr::n_distinct(model_ids)))
surv_all <- read.csv("00c_survival_data/output/slam_c1-c10/data/main_cat_surv.csv") |>
  dplyr::transmute(idno = as.integer(idno), dead_censor, le_wk = as.numeric(le_wk)) |>
  dplyr::filter(idno %in% model_ids)
files <- c(bw = "slam_bw_og.csv", fat = "slam_fat_og.csv", gluc = "slam_gluc_og.csv")
long_all <- dplyr::bind_rows(lapply(names(files), \(m) {
  read.csv(file.path("00b_dataset_mods/output/slam_c1-c10/data", files[[m]])) |>
    dplyr::transmute(idno = as.integer(idno), sex, age_wk = as.numeric(age_wk), value = as.numeric(.data[[m]]), measure = m)
})) |>
  dplyr::filter(!is.na(value), !is.na(age_wk)) |>
  dplyr::inner_join(surv_all, by = "idno")
long <- long_all |>
  dplyr::filter(dead_censor == 1) |>
  dplyr::mutate(wk_before = le_wk - age_wk) |>
  dplyr::filter(wk_before >= 0)
#+ 1: How finely can the data see a 1-3 week decline?
#- 1.1: Median gap between measures, and weeks from each mouse's last measure to death
sampling <- long |>
  dplyr::arrange(measure, idno, age_wk) |>
  dplyr::mutate(gap = age_wk - dplyr::lag(age_wk), .by = c(measure, idno)) |>
  dplyr::summarise(gap = median(gap, na.rm = TRUE), last_to_death = min(wk_before), .by = c(measure, sex, idno)) |>
  dplyr::summarise(mice = dplyr::n(), median_gap_wk = median(gap, na.rm = TRUE), last_to_death_q25 = quantile(last_to_death, 0.25), last_to_death_q50 = median(last_to_death), last_to_death_q75 = quantile(last_to_death, 0.75), .by = c(measure, sex)) |>
  dplyr::arrange(measure, sex)
print(as.data.frame(sampling), digits = 3)
#+ 2: Percent change from each mouse's own baseline (mean at 26-52 weeks before death), by weeks before death
baseline <- long |>
  dplyr::filter(wk_before >= 26, wk_before < 52) |>
  dplyr::summarise(base = mean(value), .by = c(measure, idno))
decline <- long |>
  dplyr::inner_join(baseline, by = c("measure", "idno")) |>
  dplyr::filter(wk_before < 26, base > 0) |>
  dplyr::mutate(pct = 100 * (value / base - 1), bin = cut(wk_before, c(0, 1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 26), right = FALSE)) |>
  dplyr::summarise(mice = dplyr::n_distinct(idno), median_pct = median(pct), .by = c(measure, sex, bin)) |>
  dplyr::arrange(measure, sex, bin)
print(as.data.frame(tidyr::pivot_wider(decline, names_from = sex, values_from = c(mice, median_pct))), digits = 3)
#+ 3: When does the decline start, beyond normal aging?
#! Per measure and sex, last 104 weeks of life: value ~ quadratic age + pmax(c - wk_before, 0) + (1 + age_c | idno), for each start point c = 2, 4, ... 52 weeks before death. Best c = highest log-likelihood; support = all c within 1.92 log-likelihood units of the best. drop_total = estimated change by the time of death, in raw units.
fits <- dplyr::bind_rows(lapply(split(dplyr::filter(long, wk_before < 104), ~ measure + sex, drop = TRUE), \(d) {
  d$age_c <- (d$age_wk - 100) / 52
  d$age_c2 <- d$age_c^2
  null_fit <- lme4::lmer(value ~ age_c + age_c2 + (1 + age_c | idno), data = d, REML = FALSE)
  profile <- dplyr::bind_rows(lapply(seq(2, 52, 2), \(c_wk) {
    d$terminal <- pmax(c_wk - d$wk_before, 0)
    fit <- lme4::lmer(value ~ age_c + age_c2 + terminal + (1 + age_c | idno), data = d, REML = FALSE)
    data.frame(c_wk, ll = as.numeric(logLik(fit)), slope = lme4::fixef(fit)[["terminal"]])
  }))
  best <- profile[which.max(profile$ll), ]
  support <- profile$c_wk[profile$ll >= best$ll - 1.92]
  data.frame(measure = d$measure[1], sex = d$sex[1], mice = dplyr::n_distinct(d$idno), best_start_wk = best$c_wk, support_lo = min(support), support_hi = max(support), slope_per_wk = best$slope, drop_total = best$slope * best$c_wk, median_value = median(d$value), lr_vs_no_break = 2 * (best$ll - as.numeric(logLik(null_fit))))
}))
print(fits, row.names = FALSE, digits = 3)
#+ 4: How much data sits near death, and what would the stricter early-window analysis cost?
#- 4.1: Share of each measure's observations within 2, 4 and 8 weeks of death
print(as.data.frame(dplyr::summarise(long, n = dplyr::n(), within_2 = mean(wk_before < 2), within_4 = mean(wk_before < 4), within_8 = mean(wk_before < 8), .by = c(measure, sex)) |> dplyr::arrange(measure, sex)), digits = 3)
#- 4.2: Mice lost at the 32.5-week cutoff (0, 4 or 8 week buffer) and at landmark.R's L = 60, g = 4
cutoff_mice <- long_all |>
  dplyr::filter(measure == "bw") |>
  dplyr::distinct(idno, sex, dead_censor, le_wk)
print(as.data.frame(dplyr::summarise(cutoff_mice, mice = dplyr::n(), died_by_32.5 = sum(dead_censor == 1 & le_wk <= 32.5), died_by_36.5 = sum(dead_censor == 1 & le_wk <= 36.5), died_by_40.5 = sum(dead_censor == 1 & le_wk <= 40.5), died_by_60 = sum(dead_censor == 1 & le_wk <= 60), died_by_64 = sum(dead_censor == 1 & le_wk <= 64), died_by_86 = sum(dead_censor == 1 & le_wk <= 86), .by = sex)))
