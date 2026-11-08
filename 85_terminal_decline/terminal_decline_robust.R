#* Robustness of the pre-death decline start point (R2 comments 2 and 3)
#! Run from the metabolic-class root: VECLIB_MAXIMUM_THREADS=1 Rscript 85_terminal_decline/terminal_decline_robust.R 200. The number is bootstrap resamples per group (default 200). Saves 85_terminal_decline/terminal_decline_boot.csv, appended group by group so a stopped run keeps what finished.
source("85_terminal_decline/R/fit_decline_start.R")
args <- commandArgs(trailingOnly = TRUE)
n_boot <- if (length(args) > 0) as.integer(args[[1]]) else 200L
boot_grid <- seq(4, 52, 4)
#+ 0: Data (the 1,315 mice in the manuscript, last 104 weeks of life)
model_ids <- as.integer(read.csv("04_create_census/output/slam_c1-c10_age_all_bwfatgluc/complete_census.csv")$idno)
cat(sprintf("Mice in complete census: %d\n", dplyr::n_distinct(model_ids)))
surv <- read.csv("00c_survival_data/output/slam_c1-c10/data/main_cat_surv.csv") |>
  dplyr::transmute(idno = as.integer(idno), dead_censor, le_wk = as.numeric(le_wk)) |>
  dplyr::filter(dead_censor == 1, idno %in% model_ids)
files <- c(bw = "slam_bw_og.csv", fat = "slam_fat_og.csv", gluc = "slam_gluc_og.csv")
long <- dplyr::bind_rows(lapply(names(files), \(m) {
  read.csv(file.path("00b_dataset_mods/output/slam_c1-c10/data", files[[m]])) |>
    dplyr::transmute(idno = as.integer(idno), sex, strain, age_wk = as.numeric(age_wk), value = as.numeric(.data[[m]]), measure = m)
})) |>
  dplyr::filter(!is.na(value), !is.na(age_wk)) |>
  dplyr::inner_join(surv, by = "idno") |>
  dplyr::mutate(wk_before = le_wk - age_wk) |>
  dplyr::filter(wk_before >= 0, wk_before < 104)
#- Cause of death, for the found-dead sensitivity (survival file keyed by tag, tag fixes as in traj_dataset.Rmd)
cod <- read.csv("00a_clean_slam_c1-c10/data/survival_2021-12-17.csv") |>
  dplyr::transmute(tag = as.character(tag), cod = tolower(as.character(cod))) |>
  dplyr::mutate(tag = dplyr::case_when(tag == "R" ~ "179060", tag == "L" ~ "179217", .default = tag))
tags <- read.csv("00a_clean_slam_c1-c10/data/census.csv") |>
  dplyr::transmute(idno = as.integer(idno), tag = trimws(as.character(tag))) |>
  dplyr::distinct()
cod_mice <- dplyr::inner_join(tags, cod, by = "tag") |>
  dplyr::filter(idno %in% model_ids)
print(sort(table(cod_mice$cod), decreasing = TRUE))
found_dead <- cod_mice$idno[cod_mice$cod == "found dead"]
has_cod <- length(found_dead) > 0
#- Groups: measure x sex, and measure x sex x strain
by_sex <- split(long, ~ measure + sex, drop = TRUE, sep = " ")
by_sex_strain <- split(long, ~ measure + sex + strain, drop = TRUE, sep = " ")
groups <- c(by_sex, by_sex_strain)
#+ 1: Decline shape: linear vs quadratic ramp, all groups
shapes <- dplyr::bind_rows(lapply(names(groups), \(g) {
  linear <- fit_decline_start(groups[[g]], shape = "linear")
  quadratic <- fit_decline_start(groups[[g]], shape = "quadratic")
  data.frame(group = g, mice = dplyr::n_distinct(groups[[g]]$idno), linear_start = linear$start_wk, linear_lo = linear$support_lo, linear_hi = linear$support_hi, linear_drop = linear$drop_total, quad_start = quadratic$start_wk, quad_lo = quadratic$support_lo, quad_hi = quadratic$support_hi, quad_drop = quadratic$drop_total, ll_quad_minus_linear = quadratic$ll - linear$ll)
}))
print(shapes, row.names = FALSE, digits = 3)
#+ 2: Sensitivity, by sex: drop measures in the last 2 weeks of life; found-dead mice only
sensitivity <- dplyr::bind_rows(lapply(names(by_sex), \(g) {
  d <- by_sex[[g]]
  no_last <- fit_decline_start(dplyr::filter(d, wk_before >= 2), grid = seq(4, 52, 2))
  spontaneous <- if (has_cod) fit_decline_start(dplyr::filter(d, idno %in% found_dead)) else data.frame(start_wk = NA, drop_total = NA)
  data.frame(group = g, no_last2_start = no_last$start_wk, no_last2_drop = no_last$drop_total, found_dead_mice = dplyr::n_distinct(d$idno[d$idno %in% found_dead]), found_dead_start = spontaneous$start_wk, found_dead_drop = spontaneous$drop_total)
}))
print(sensitivity, row.names = FALSE, digits = 3)
#- Mice lost at the 32.5-week cutoff with a 28-week or 52-week buffer
print(as.data.frame(dplyr::distinct(long, idno, sex, le_wk) |> dplyr::summarise(mice = dplyr::n(), died_by_60.5 = sum(le_wk <= 60.5), died_by_84.5 = sum(le_wk <= 84.5), .by = sex)))
#+ 3: Bootstrap of the start point: resample mice within group, linear shape, 4-week grid
RNGkind("L'Ecuyer-CMRG")
set.seed(85)
out_file <- "85_terminal_decline/terminal_decline_boot.csv"
unlink(out_file)
for (g in names(groups)) {
  started <- Sys.time()
  d <- groups[[g]]
  rows_by_mouse <- split(seq_len(nrow(d)), d$idno)
  reps <- parallel::mclapply(seq_len(n_boot), \(b) {
    drawn <- sample(length(rows_by_mouse), replace = TRUE)
    rows <- rows_by_mouse[drawn]
    resampled <- d[unlist(rows), ]
    resampled$idno <- rep(seq_along(drawn), lengths(rows))
    fit <- tryCatch(fit_decline_start(resampled, grid = boot_grid), error = \(e) NULL)
    if (is.null(fit)) NULL else data.frame(group = g, rep = b, start_wk = fit$start_wk, drop_total = fit$drop_total)
  }, mc.cores = max(1L, parallel::detectCores() - 1L))
  reps <- dplyr::bind_rows(reps)
  write.table(reps, out_file, sep = ",", row.names = FALSE, col.names = !file.exists(out_file), append = file.exists(out_file))
  cat(sprintf("%s: %d of %d resamples, %.1f min\n", g, nrow(reps), n_boot, as.numeric(difftime(Sys.time(), started, units = "mins"))))
}
#- Percentile intervals
boot <- read.csv(out_file)
print(as.data.frame(dplyr::summarise(boot, resamples = dplyr::n(), start_median = median(start_wk), start_lo = quantile(start_wk, 0.025), start_hi = quantile(start_wk, 0.975), at_limit = mean(start_wk == max(boot_grid)), drop_median = median(drop_total), drop_lo = quantile(drop_total, 0.025), drop_hi = quantile(drop_total, 0.975), .by = group)), digits = 3)
