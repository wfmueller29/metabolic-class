#* Cage-mate concordance of the Chapter 2 trajectory classes (committee comment on social rank, 2026-10-22)
#! QUESTION. Do the body weight, fat mass and fasting glucose trajectory classes depend on cage / social order? SLAM recorded no dominance behaviour, so rank cannot be measured directly; this tests its imprint instead.
#! LOGIC. If a dominance hierarchy drove class membership (dominant mice gaining, subordinates losing), cage-mates would fall into DIFFERENT classes more often than chance. A shared cage environment (food access, temperature, microbiome) would make them MORE alike than chance. Neither = classes independent of housing.
#! DATA. Classes: the Chapter 2 class pipeline's own assignments, metabolic-class/04_create_census/output/slam_c1-c10_age_all_bwfatgluc/complete_census.csv (C1-C10; new_class_bw 1-3, new_class_fat 4-6, new_class_gluc 7-8). Cage, sex, genetic background, cohort: the NIH census.csv since 2026-10-22 (all 1,315 classified mice have a cage). The first run used config$paths$body_weight_data (freezer-search file, 541 classified mice with a cage: 323 mice in 140 cages; fat, females P_different = 0.002, males P_alike = 0.051); the two sources agree on 99.2% of same-cage pairs (cage_crosscheck.R). Joined by idno (NIH).
#! RESULT (census, 2026-10-22): 1,187 mice in 416 cages. No outcome or sex shows cage-mates more DIFFERENT than chance (every P_different >= 0.39); the first run's female-fat P = 0.002 did not survive the larger sample. Cage-mates are modestly MORE alike: pooled bw 0.573 vs 0.545 (P = 0.032), fat 0.447 vs 0.411 (P = 0.021), glucose 0.849 vs 0.822 (P = 0.002); strongest in males (fat 0.470 vs 0.389, P = 0.002); females null for bw and fat, glucose P = 0.027.
#! TEST. Per cage with >= 2 classified mice: share of cage-mate pairs in the same class; statistic = mean over cages. Null: class labels shuffled within cohort x sex x genetic background (so the known sex / background differences in class make-up cannot drive it), k = 999, seed 5100 + r. P_alike = share of shuffles >= observed; P_different = share <= observed. Run per outcome, pooled and within each sex (males fight more). Printout only.
#! Not sourced by run.R. Needs only config (load_dynamic_config + 01/02 setup): source("R/Scripts/non_pipeline/cage_effect_classes.R"). Class numbers are the census's computational labels (bw 1-3, fat 4-6, glucose 7-8; see 19 §19.25's note), so this script never names a class.
#+ 0: Inputs
mc_dir <- if (is.null(config$paths$metabolic_class_dir)) path.expand("~/Desktop/Repos/metabolic-class") else config$paths$metabolic_class_dir   # as 18 §18.0
mc_census <- file.path(mc_dir, "04_create_census/output/slam_c1-c10_age_all_bwfatgluc/complete_census.csv")   # the C1-C10 fit 18 §18.4 reads (mc_fit_c110)
stopifnot(file.exists(mc_census))
cls <- readr::read_csv(mc_census, show_col_types = FALSE, name_repair = "unique_quiet") |>
  dplyr::transmute(idno = as.character(idno), bw = as.integer(new_class_bw), fat = as.integer(new_class_fat), gluc = as.integer(new_class_gluc)) |>
  dplyr::distinct(idno, .keep_all = TRUE)
# cage source since 2026-10-22: the NIH census (every C1-C10 mouse has a cage; agrees with the freezer-search file on 99.2% of same-cage pairs, cage_crosscheck.R); cages keyed cohort + label, since 8 labels recur across cohorts
cen_path <- path.expand("~/Library/CloudStorage/OneDrive-NationalInstitutesofHealth/Mueller2026_final_data/raw/00a_clean_slam_c1-c10/data/census.csv")
stopifnot(file.exists(cen_path))
cag <- readr::read_csv(cen_path, col_types = readr::cols(.default = "c"), show_col_types = FALSE, name_repair = "unique_quiet") |>
  dplyr::transmute(idno = trimws(idno), cohort = trimws(cohort), cage = paste(cohort, trimws(cage)), sex = toupper(substr(trimws(sex), 1, 1)), strain = toupper(trimws(strain))) |>
  dplyr::filter(!is.na(idno), !is.na(cage)) |> dplyr::distinct()
cag <- cag |> dplyr::group_by(idno) |> dplyr::filter(dplyr::n() == 1) |> dplyr::ungroup()   # drops an idno listed with conflicting rows
stopifnot(!anyDuplicated(cag$idno))
d0 <- dplyr::inner_join(cls, cag, by = "idno")
cat(sprintf("C1-C10 mice with a class: %d | with a cage too: %d | cages: %d\n", nrow(cls), nrow(d0), dplyr::n_distinct(d0$cage)))
#+ 1: The statistic and its null
same_share <- function(cage, cl) {   # mean over cages of the share of cage-mate pairs in the same class
  s <- split(cl, cage); v <- vapply(s, function(x) { if (length(x) < 2) return(NA_real_); p <- utils::combn(x, 2); mean(p[1, ] == p[2, ]) }, numeric(1))
  mean(v, na.rm = TRUE)
}
run_one <- function(d, outcome, label, k = 999) {
  d <- d[!is.na(d[[outcome]]), ]
  keep <- names(which(table(d$cage) >= 2)); d <- d[d$cage %in% keep, ]
  if (dplyr::n_distinct(d$cage) < 5) return(tibble::tibble(outcome, group = label, mice = nrow(d), cages = dplyr::n_distinct(d$cage), obs = NA_real_))
  strat <- interaction(d$cohort, d$sex, d$strain, drop = TRUE)
  obs <- same_share(d$cage, d[[outcome]])
  nul <- vapply(seq_len(k), function(r) { set.seed(5100 + r); cl <- d[[outcome]]; for (g in levels(strat)) { i <- which(strat == g); if (length(i) > 1) cl[i] <- cl[i][sample.int(length(i))] }; same_share(d$cage, cl) }, numeric(1))
  tibble::tibble(outcome, group = label, mice = nrow(d), cages = dplyr::n_distinct(d$cage), obs = obs, null_mean = mean(nul), null_lo = stats::quantile(nul, 0.025), null_hi = stats::quantile(nul, 0.975),
                  p_alike = (1 + sum(nul >= obs)) / (k + 1), p_different = (1 + sum(nul <= obs)) / (k + 1))
}
#+ 2: Run per outcome, pooled and by sex
res <- dplyr::bind_rows(lapply(c("bw", "fat", "gluc"), function(o) dplyr::bind_rows(
  run_one(d0, o, "all"), run_one(d0[d0$sex == "M", ], o, "males"), run_one(d0[d0$sex == "F", ], o, "females"))))
cat("\nShare of cage-mate pairs in the same class: observed vs shuffles within cohort x sex x genetic background (k = 999)\n")
print(as.data.frame(res |> dplyr::mutate(dplyr::across(where(is.double), ~ signif(.x, 3)))), row.names = FALSE)
cat("\nReading: p_alike < 0.05 = cage-mates MORE alike than chance (shared environment); p_different < 0.05 = cage-mates MORE different (consistent with a rank effect); both large = no detectable cage dependence.\n")
cage_class_concordance <- res
rm(mc_dir, mc_census, cen_path, cls, cag, d0, same_share, run_one, res)
