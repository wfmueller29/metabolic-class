#* 86: Script to test for cage effects of class assignments
#! Scripts in prework/ are from another repo and were simply prework copied from another repo, scripts to build a bigger version of this and to check cage assignments based on differing sources. That settled that the NIH census (00a_clean_slam_c1-c10/data/census.csv) is likely a good source of cage assignment data though it may differ very slightly based on when that census was captured if mice moved or something. For this analysis, just using it, as it is the most stable and comprehensive assignment file, so using it as single source of truth is most principled approach.
#+ 86.0: Helper functions (one per file in 86_cage_effects/R/)
invisible(lapply(list.files("86_cage_effects/R", pattern = "\\.R$", full.names = TRUE), source))
#+ 86.1: Import data and select needed columns
#- 86.1.1: Class assignments
classes <- readr::read_csv("04_create_census/output/slam_c1-c10_age_all_bwfatgluc/complete_census.csv", col_types = readr::cols(idno = "c"), show_col_types = FALSE, name_repair = "unique_quiet") |>
  dplyr::select(idno, new_class_bw, new_class_fat, new_class_gluc, le_wk, dead_censor)
#- 86.1.2: Cage assignments
cages <- readr::read_csv("00a_clean_slam_c1-c10/data/census.csv", col_types = readr::cols(.default = "c"), name_repair = "unique_quiet") |>
  dplyr::select(idno, cohort, cage, sex, strain, dob)
#- 86.1.3: Merge classes onto cages
#! Cage labels repeat across cohorts, so a cage is keyed by cohort + label. The inner join keeps only mice with both a class and a cage. distinct() collapses exact duplicate census rows (one mouse is listed twice).
#! Verified 2026-10-28: all 1,315 classified mice match exactly one census row; 544 cages.
class_cages <- cages |>
  dplyr::mutate(dplyr::across(dplyr::everything(), trimws), cage = paste(cohort, cage)) |>
  dplyr::distinct() |>
  dplyr::inner_join(classes, by = "idno")
#- 86.1.4: Classified mice per cage, by sex, by strain and overall
#! Counts only mice that have a class, so cages look smaller than in the census (most census cages hold 4). No census cage mixes sexes or strains, so each cage has one sex and one strain.
cage_sizes <- dplyr::count(class_cages, cage, sex, strain, name = "mice")
#- 86.1.5: View printout
dplyr::bind_rows(
  dplyr::summarise(cage_sizes, cages = dplyr::n(), mean_per_cage = mean(mice), mice = sum(mice), .by = sex) |> dplyr::rename(group = sex),
  dplyr::summarise(cage_sizes, cages = dplyr::n(), mean_per_cage = mean(mice), mice = sum(mice), .by = strain) |> dplyr::rename(group = strain),
  dplyr::summarise(cage_sizes, cages = dplyr::n(), mean_per_cage = mean(mice), mice = sum(mice)) |> dplyr::mutate(group = "all")
) |> print()
#- 86.1.6: Keep cages with at least two classified mice
paired_cages <- class_cages |>
  dplyr::filter(dplyr::n() >= 2, .by = cage)
#- 86.1.7: Determine number of mice available for modeling
cat(sprintf("complete dataset: %d mice | retained (with a cagemate in the complete dataset): %d mice in %d cages | excluded: %d\n", nrow(class_cages), nrow(paired_cages), dplyr::n_distinct(paired_cages$cage), nrow(class_cages) - nrow(paired_cages)))
#- 86.1.8: Map column names to the three class measures from the pipeline
measures <- c(BW = "new_class_bw", FM = "new_class_fat", FBG = "new_class_gluc")
#- 86.1.9: Class assignments from the sex x genetic background model fits (for 86.4)
#! Each fit was built on one group only, so it spreads that group's mice across classes; the pooled fit put most females in one BW class, leaving little room for a cage effect to show. Class numbers differ between fits, which does not matter: the test only asks same class or not.
group_fits <- c(`F B6` = "fb6", `M B6` = "mb6", `F HET3` = "fhet3", `M HET3` = "mhet3")
group_classes <- lapply(group_fits, \(tag) readr::read_csv(file.path("04_create_census/output", paste0("slam_c1-c10_age_", tag, "_bwfatgluc"), "complete_census.csv"), col_types = readr::cols(idno = "c"), show_col_types = FALSE, name_repair = "unique_quiet") |>
  dplyr::select(idno, new_class_bw, new_class_fat, new_class_gluc))
#- 86.1.10: Swap each fit's classes in for the pooled ones and keep cages with at least two of its mice
group_cages <- lapply(group_classes, \(gc) class_cages |>
  dplyr::select(-new_class_bw, -new_class_fat, -new_class_gluc) |>
  dplyr::inner_join(gc, by = "idno") |>
  dplyr::filter(dplyr::n() >= 2, .by = cage))
#+ 86.2: Does survival cluster by cage assignment?
#- 86.2.1: Fit model of survival vs cage + strata
#! Stratified because cages are nested within cohort x sex x genetic background.
cage_frailty <- survival::coxph(survival::Surv(le_wk, dead_censor == 1) ~ survival::frailty(cage) + survival::strata(cohort, sex, strain), data = paired_cages)
#- 86.2.2: Build a null model without cage for the LRT
no_cage <- survival::coxph(survival::Surv(le_wk, dead_censor == 1) ~ survival::strata(cohort, sex, strain), data = paired_cages)
#- 86.2.3: Compute LRT
frailty_lrt(cage_frailty, no_cage) |> round(4) |> print()
#+ 86.3: Does adding a frailty term for cage alter class/survival associations?
#- 86.3.1: Pipeline's individual Cox models (slam_age_all.yaml)
models <- c(`Model 1` = "", `Model 2` = " + sex * strain", `Model 3` = " + sex + survival::strata(strain)")
#- 86.3.2: Make a grid of all model x class measure combinations
#! Complete dataset (n = 1,315), as in Table S2.1; mice with no cagemate count as cages of one.
fits <- expand.grid(Model = names(models), LCM = names(measures), stringsAsFactors = FALSE)
#- 86.3.3: Fit the original models (no cage term)
#! Should reproduce Table S2.1 exactly.
hr_original <- dplyr::bind_rows(Map(\(lcm, model) data.frame(LCM = lcm, Model = model, fit_class_hrs(class_cages, measures[[lcm]], models[[model]])), fits$LCM, fits$Model))
#- 86.3.4: Fit the same models with a cage frailty term
hr_frailty <- dplyr::bind_rows(Map(\(lcm, model) data.frame(LCM = lcm, Model = model, fit_class_hrs(class_cages, measures[[lcm]], models[[model]], frailty = TRUE)), fits$LCM, fits$Model))
#- 86.3.5: Compare side by side
#! change = % change in HR with cage; direction = relative to HR = 1 (no effect); sig_flipped = significance at P < 0.05 changed.
hr_compare <- dplyr::left_join(dplyr::rename(hr_original, without_cage = hr, est_without = est, p_without = p), dplyr::rename(hr_frailty, with_cage = hr, est_with = est, p_with = p), by = c("LCM", "Model", "Class")) |>
  dplyr::mutate(change = dplyr::if_else(is.na(est_with), "", sprintf("%+.1f%%", 100 * (est_with / est_without - 1))),
                direction = dplyr::if_else(is.na(est_with), "", dplyr::if_else(abs(log(est_with)) > abs(log(est_without)), "away from 1", "toward 1")),
                sig_flipped = dplyr::if_else(is.na(est_with), "", dplyr::if_else((p_without < 0.05) != (p_with < 0.05), "YES", "no")))
print(dplyr::select(hr_compare, LCM, Model, Class, without_cage, with_cage, change, direction, sig_flipped), row.names = FALSE)
#+ 86.4: Are class assignments of cagemates more or less similar than expected by chance
#! concordance_test(): share of cagemate pairs in the same class vs 999 shuffles within cohort x sex x genetic background. more_alike_P = cage effect; more_different_P = consistent with social order.
#- 86.4.1: Pooled classes, all mice
pooled_concordance <- concordance_test(paired_cages, measures)
print(pooled_concordance, row.names = FALSE)
#- 86.4.2: Sex x genetic background fit classes, within each fit
group_concordance <- dplyr::bind_rows(lapply(group_cages, concordance_test, measures = measures), .id = "fit")
print(group_concordance, row.names = FALSE)
