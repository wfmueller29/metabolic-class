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
#- 86.1.9: Class assignments from the sex x genetic background model fits (for 86.2)
#! Each fit was built on one group only, so it spreads that group's mice across classes; the pooled fit put most females in one BW class, leaving little room for a cage effect to show. Class numbers differ between fits, which does not matter: the test only asks same class or not.
group_fits <- c(`F B6` = "fb6", `M B6` = "mb6", `F HET3` = "fhet3", `M HET3` = "mhet3")
group_classes <- lapply(group_fits, \(tag) readr::read_csv(file.path("04_create_census/output", paste0("slam_c1-c10_age_", tag, "_bwfatgluc"), "complete_census.csv"), col_types = readr::cols(idno = "c"), show_col_types = FALSE, name_repair = "unique_quiet") |>
  dplyr::select(idno, new_class_bw, new_class_fat, new_class_gluc))
#- 86.1.10: Swap each fit's classes in for the pooled ones and keep cages with at least two of its mice
group_cages <- lapply(group_classes, \(gc) class_cages |>
  dplyr::select(-new_class_bw, -new_class_fat, -new_class_gluc) |>
  dplyr::inner_join(gc, by = "idno") |>
  dplyr::filter(dplyr::n() >= 2, .by = cage))
#- 86.1.11: Mice and cages per sex x genetic background fit (n for the Figure S2.10A legend)
#! "classified" = mice with a class in that fit (Figure 2.2 n); "retained" = those with a cagemate in it, as tested in 86.2.2.
data.frame(fit = names(group_fits), classified = sapply(group_classes, nrow), retained = sapply(group_cages, nrow), cages = sapply(group_cages, \(g) dplyr::n_distinct(g$cage))) |>
  rbind(data.frame(fit = "all fits", classified = sum(sapply(group_classes, nrow)), retained = sum(sapply(group_cages, nrow)), cages = sum(sapply(group_cages, \(g) dplyr::n_distinct(g$cage))))) |>
  print(row.names = FALSE)
#- 86.1.12: Cage size at assignment (all census mice in the cage, classified or not)
#! Counted over the whole census, not the classified subset, so it reflects how many mice actually shared the cage.
cage_sizes <- cages |>
  dplyr::mutate(dplyr::across(dplyr::everything(), trimws), cage = paste(cohort, cage)) |>
  dplyr::summarise(cage_size = dplyr::n_distinct(idno), .by = cage)
class_cages <- dplyr::left_join(class_cages, cage_sizes, by = "cage") |>
  dplyr::mutate(housing = factor(ifelse(cage_size < 4, "Fewer than four", "Four"), levels = c("Four", "Fewer than four")))
#+ 86.2: Are class assignments of cagemates more or less similar than expected by chance
#! concordance_test(): share of cagemate pairs in the same class vs 999 shuffles within cohort x sex x genetic background. more_alike_P = cage effect; more_different_P = consistent with social order.
#- 86.2.1: Pooled classes, all mice
pooled_concordance <- concordance_test(paired_cages, measures)
print(pooled_concordance, row.names = FALSE)
#- 86.2.2: Sex x genetic background fit classes, within each fit
group_concordance <- dplyr::bind_rows(lapply(group_cages, concordance_test, measures = measures), .id = "fit")
print(group_concordance, row.names = FALSE)
#+ 86.3: Does survival cluster by cage assignment?
#- 86.3.1: Fit model of survival vs cage + strata
#! Stratified because cages are nested within cohort x sex x genetic background.
cage_frailty <- survival::coxph(survival::Surv(le_wk, dead_censor == 1) ~ survival::frailty(cage) + survival::strata(cohort, sex, strain), data = paired_cages)
#- 86.3.2: Build a null model without cage for the LRT
no_cage <- survival::coxph(survival::Surv(le_wk, dead_censor == 1) ~ survival::strata(cohort, sex, strain), data = paired_cages)
#- 86.3.3: Compute LRT
frailty_lrt(cage_frailty, no_cage) |> round(4) |> print()
#+ 86.4: Does adding a frailty term for cage alter class/survival associations?
#- 86.4.1: Pipeline's individual Cox models (slam_age_all.yaml)
models <- c(`Model 1` = "", `Model 2` = " + sex * strain", `Model 3` = " + sex + survival::strata(strain)")
#- 86.4.2: Make a grid of all model x class measure combinations
#! Complete dataset (n = 1,315), as in Table S2.1; mice with no cagemate count as cages of one.
fits <- expand.grid(Model = names(models), LCM = names(measures), stringsAsFactors = FALSE)
#- 86.4.3: Fit the original models (no cage term)
#! Should reproduce Table S2.1 exactly.
hr_original <- dplyr::bind_rows(Map(\(lcm, model) data.frame(LCM = lcm, Model = model, fit_class_hrs(class_cages, measures[[lcm]], models[[model]])), fits$LCM, fits$Model))
#- 86.4.4: Fit the same models with a cage frailty term
hr_frailty <- dplyr::bind_rows(Map(\(lcm, model) data.frame(LCM = lcm, Model = model, fit_class_hrs(class_cages, measures[[lcm]], models[[model]], frailty = TRUE)), fits$LCM, fits$Model))
#- 86.4.5: Compare side by side
#! change = % change in HR with cage; direction = relative to HR = 1 (no effect); sig_flipped = significance at P < 0.05 changed.
hr_compare <- dplyr::left_join(dplyr::rename(hr_original, without_cage = hr, est_without = est, lower_without = lower, upper_without = upper, p_without = p), dplyr::rename(hr_frailty, with_cage = hr, est_with = est, lower_with = lower, upper_with = upper, p_with = p), by = c("LCM", "Model", "Class")) |>
  dplyr::mutate(change = dplyr::if_else(is.na(est_with), "", sprintf("%+.1f%%", 100 * (est_with / est_without - 1))),
                direction = dplyr::if_else(is.na(est_with), "", dplyr::if_else(abs(log(est_with)) > abs(log(est_without)), "away from 1", "toward 1")),
                sig_flipped = dplyr::if_else(is.na(est_with), "", dplyr::if_else((p_without < 0.05) != (p_with < 0.05), "YES", "no")))
print(dplyr::select(hr_compare, LCM, Model, Class, without_cage, with_cage, change, direction, sig_flipped), row.names = FALSE)
#+ 86.5: Is survival associated with the number of mice housed per cage?
#! Mice were housed four per cage by design; smaller census cages often follow deaths or separations (e.g. fighting males), so this comparison is descriptive. Complete dataset (n = 1,315), stratified by cohort x sex x genetic background as in 86.3.
#- 86.5.1: How many mice were in smaller cages
print(table(housing = class_cages$housing, sex = class_cages$sex))
#- 86.5.2: Cox model of survival on housing (fewer than four vs four)
housing_fit <- survival::coxph(survival::Surv(le_wk, dead_censor == 1) ~ housing + survival::strata(cohort, sex, strain), data = class_cages)
housing_ci <- summary(housing_fit)$conf.int
cat(sprintf("fewer than four vs four per cage: HR %s\n", format_hr(housing_ci[1, 1], housing_ci[1, 3], housing_ci[1, 4], summary(housing_fit)$coefficients[1, "Pr(>|z|)"])))
#+ 86.6: Does cagemate class agreement differ between females and males?
#! Pooled classes only: the stratum refits define different classes in each sex, so their agreement cannot be compared across sexes. Kappa = (observed - chance) / (1 - chance) puts both sexes on one scale although their chance levels differ (the pooled BW fit puts most females in one class).
#! Chance is computed from class counts within cohort x sex x genetic background (cage_agreement()), which is the exact mean of the 86.2 shuffle null, so the bootstrap needs no nested shuffles. 95% CIs from 2,000 boot::boot resamples of cages stratified by those cells, normal-approximation boot.ci() intervals (both as for the reclassification accuracy CIs, Figure S2.5).
#- 86.6.1: Check the computed chance against the shuffle mean in each sex
#! The two columns should agree to about the third decimal (the shuffle mean carries Monte Carlo error).
sex_concordance <- concordance_test(paired_cages, measures, by = "sex")
sex_chance_check <- dplyr::bind_rows(lapply(names(measures), \(lcm) dplyr::summarise(cage_agreement(paired_cages, measures[[lcm]]), chance = mean(chance), .by = sex) |> dplyr::mutate(LCM = lcm))) |>
  dplyr::left_join(dplyr::select(sex_concordance, sex, LCM, null_mean), by = c("sex", "LCM"))
print(sex_chance_check, row.names = FALSE)
#- 86.6.2: Female vs male kappa, all mice
sex_kappa_all <- sex_kappa_test(paired_cages, measures)
print(sex_kappa_all, row.names = FALSE, digits = 3)
#- 86.6.3: Female vs male kappa within each genetic background
#! Keeps a sex difference from standing in for a genetic background difference.
sex_kappa_strain <- dplyr::bind_rows(lapply(split(paired_cages, paired_cages$strain), sex_kappa_test, measures = measures), .id = "strain")
print(sex_kappa_strain, row.names = FALSE, digits = 3)
#+ 86.7: Receipt of every number reported in 2.10.2 and the Figure S2.10 legend
#! Prints each value as written in the text, to check the prose and legend against the run. Agreement in percentage points = 100 x (observed - mean of permutations).
#- 86.7.1: Sample sizes (paragraph one; legend A and B)
cat(sprintf("complete dataset n = %d | with a cagemate n = %d in %d cages\n", nrow(class_cages), nrow(paired_cages), dplyr::n_distinct(paired_cages$cage)))
cat(sprintf("%s retained n = %d\n", names(group_cages), sapply(group_cages, nrow)), sep = "")
#- 86.7.2: Pooled agreement above chance and upper-tail P (paragraph one)
cat(sprintf("pooled %s: %.1f percentage points above chance, P = %.3f\n", pooled_concordance$LCM, 100 * (pooled_concordance$observed - pooled_concordance$null_mean), pooled_concordance$more_alike_P), sep = "")
#- 86.7.3: Sex x genetic background fits (paragraph one)
cat(sprintf("strata: %d of %d testable comparisons above chance; %d of %d with P < 0.05\n", sum(group_concordance$observed > group_concordance$null_mean), nrow(group_concordance), sum(group_concordance$more_alike_P < 0.05), nrow(group_concordance)))
#- 86.7.4: Lower tail, pooled and strata together (paragraph one)
cat(sprintf("less alike than chance: smallest P = %.3f, largest P = %.3f\n", min(c(pooled_concordance$more_different_P, group_concordance$more_different_P)), max(c(pooled_concordance$more_different_P, group_concordance$more_different_P))))
#- 86.7.5: Survival clustering by cage (paragraph two)
cage_lrt <- frailty_lrt(cage_frailty, no_cage)
cat(sprintf("cage frailty: variance = %.4f, likelihood-ratio P = %.2f\n", cage_lrt[["variance"]], cage_lrt[["p"]]))
#- 86.7.6: Class HRs with a cage frailty term (paragraph three; legend B)
#! Reference rows dropped. "away from 1" counts HRs whose distance from 1 (on the log scale) grew with the cage term.
hr_rows <- dplyr::filter(hr_compare, !is.na(est_with))
cat(sprintf("with cage frailty: %d of %d HRs P < 0.001 (largest P = %.2g); %d of %d decreased relative to the original model; %d of %d moved away from 1, by %.1f%%-%.1f%%\n", sum(hr_rows$p_with < 0.001), nrow(hr_rows), max(hr_rows$p_with), sum(hr_rows$est_with < hr_rows$est_without), nrow(hr_rows), sum(hr_rows$direction == "away from 1"), nrow(hr_rows), min(abs(100 * (hr_rows$est_with / hr_rows$est_without - 1))), max(abs(100 * (hr_rows$est_with / hr_rows$est_without - 1)))))
#- 86.7.7: Housing (closing paragraph)
cat(sprintf("housed four per cage: %.0f%% of %d mice | fewer than four vs four: HR %s\n", 100 * mean(class_cages$housing == "Four"), nrow(class_cages), format_hr(housing_ci[1, 1], housing_ci[1, 3], housing_ci[1, 4], summary(housing_fit)$coefficients[1, "Pr(>|z|)"])))
#- 86.7.8: Female vs male chance-corrected agreement (sex comparison)
cat(sprintf("%s %s: kappa F = %.3f, M = %.3f, M - F = %.3f [%.3f, %.3f]\n", c(rep("all", nrow(sex_kappa_all)), sex_kappa_strain$strain), c(sex_kappa_all$LCM, sex_kappa_strain$LCM), c(sex_kappa_all$kappa_F, sex_kappa_strain$kappa_F), c(sex_kappa_all$kappa_M, sex_kappa_strain$kappa_M), c(sex_kappa_all$diff_MF, sex_kappa_strain$diff_MF), c(sex_kappa_all$diff_lo, sex_kappa_strain$diff_lo), c(sex_kappa_all$diff_hi, sex_kappa_strain$diff_hi)), sep = "")
