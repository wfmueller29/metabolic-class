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
#+ 86.2: Does survival cluster by cage assignment?
#- 86.2.1: Keep cages with at least two classified mice
paired_cages <- class_cages |>
  dplyr::filter(dplyr::n() >= 2, .by = cage)
#- 86.2.2: Determine number of mice available for modeling
cat(sprintf("complete dataset: %d mice | retained (with a cagemate in the complete dataset): %d mice in %d cages | excluded: %d\n", nrow(class_cages), nrow(paired_cages), dplyr::n_distinct(paired_cages$cage), nrow(class_cages) - nrow(paired_cages)))
#- 86.2.3: Fit model of survival vs cage + strata
#! Stratified because cages are nested within cohort x sex x genetic background.
cage_frailty <- survival::coxph(survival::Surv(le_wk, dead_censor == 1) ~ survival::frailty(cage) + survival::strata(cohort, sex, strain), data = paired_cages)
#- 86.2.4: Build a null model without cage for the LRT
no_cage <- survival::coxph(survival::Surv(le_wk, dead_censor == 1) ~ survival::strata(cohort, sex, strain), data = paired_cages)
#- 86.2.5: Compute LRT
frailty_lrt(cage_frailty, no_cage) |> round(4) |> print()
#+ 86.3: Does adding a frailty term for cage alter class/survival associations?
#- 86.3.1: Pipeline's individual Cox models (slam_age_all.yaml)
models <- c(`Model 1` = "", `Model 2` = " + sex * strain", `Model 3` = " + sex + survival::strata(strain)")
#- 86.3.2: Map column names to the three class measures from the pipeline
measures <- c(BW = "new_class_bw", FM = "new_class_fat", FBG = "new_class_gluc")
#- 86.3.3: Make a grid of all model x class measure combinations
#! Complete dataset (n = 1,315), as in Table S2.1; mice with no cagemate count as cages of one.
fits <- expand.grid(Model = names(models), LCM = names(measures), stringsAsFactors = FALSE)
#- 86.3.4: Fit the original models (no cage term)
#! Should reproduce Table S2.1 exactly.
hr_original <- dplyr::bind_rows(Map(\(lcm, model) data.frame(LCM = lcm, Model = model, fit_class_hrs(class_cages, measures[[lcm]], models[[model]])), fits$LCM, fits$Model))
#- 86.3.5: Fit the same models with a cage frailty term
hr_frailty <- dplyr::bind_rows(Map(\(lcm, model) data.frame(LCM = lcm, Model = model, fit_class_hrs(class_cages, measures[[lcm]], models[[model]], frailty = TRUE)), fits$LCM, fits$Model))
#- 86.3.6: Compare side by side
#! change = % change in HR with cage; direction = relative to HR = 1 (no effect); sig_flipped = significance at P < 0.05 changed.
hr_compare <- dplyr::left_join(dplyr::rename(hr_original, without_cage = hr, est_without = est, p_without = p), dplyr::rename(hr_frailty, with_cage = hr, est_with = est, p_with = p), by = c("LCM", "Model", "Class")) |>
  dplyr::mutate(change = dplyr::if_else(is.na(est_with), "", sprintf("%+.1f%%", 100 * (est_with / est_without - 1))),
                direction = dplyr::if_else(is.na(est_with), "", dplyr::if_else(abs(log(est_with)) > abs(log(est_without)), "away from 1", "toward 1")),
                sig_flipped = dplyr::if_else(is.na(est_with), "", dplyr::if_else((p_without < 0.05) != (p_with < 0.05), "YES", "no")))
print(dplyr::select(hr_compare, LCM, Model, Class, without_cage, with_cage, change, direction, sig_flipped), row.names = FALSE)
#+ 86.4: Are class assignments of cagemates more or less similar than expected by chance
#- 86.4.1: Define shuffle groups
#! Labels are only ever shuffled among mice of the same cohort x sex x genetic background, the groups cages are nested in.
group <- interaction(paired_cages$cohort, paired_cages$sex, paired_cages$strain, drop = TRUE)
#- 86.4.2: Observed share of cagemate pairs in the same class, per class measure
obs_same <- sapply(measures, \(v) same_class_share(paired_cages[[v]], paired_cages$cage))
#- 86.4.3: Null distribution from 999 within-group shuffles
set.seed(86)
null_same <- replicate(999, sapply(measures, \(v) same_class_share(shuffle_within(paired_cages[[v]], group), paired_cages$cage)))
#- 86.4.4: Compare observed to null in both directions
#! more_alike_P = cage effect; more_different_P = consistent with social order.
data.frame(LCM = names(measures), observed = obs_same, null_mean = rowMeans(null_same), more_alike_P = (1 + rowSums(null_same >= obs_same)) / 1000, more_different_P = (1 + rowSums(null_same <= obs_same)) / 1000) |>
  print(row.names = FALSE)
#- 86.4.5: Same test within each sex
#! Dominance and fighting are much stronger in males, so social order would most likely show there.
set.seed(86)
dplyr::bind_rows(lapply(split(paired_cages, paired_cages$sex), concordance_test, measures = measures), .id = "sex") |>
  print(row.names = FALSE)
#- 86.4.6: Same test within each genetic background
set.seed(86)
dplyr::bind_rows(lapply(split(paired_cages, paired_cages$strain), concordance_test, measures = measures), .id = "strain") |>
  print(row.names = FALSE)
#- 86.4.7: Read the class assignments from the sex x genetic background model fits
#! Each fit was built on one group only, so it spreads that group's mice across classes; the pooled fit put most females in one BW class, leaving little room for a cage effect to show. Class numbers differ between fits, which does not matter: the test only asks same class or not.
group_fits <- c(`F B6` = "fb6", `M B6` = "mb6", `F HET3` = "fhet3", `M HET3` = "mhet3")
group_classes <- lapply(group_fits, \(tag) readr::read_csv(file.path("04_create_census/output", paste0("slam_c1-c10_age_", tag, "_bwfatgluc"), "complete_census.csv"), col_types = readr::cols(idno = "c"), show_col_types = FALSE, name_repair = "unique_quiet") |>
  dplyr::select(idno, new_class_bw, new_class_fat, new_class_gluc))
#- 86.4.8: Swap each fit's classes in for the pooled ones and keep cages with at least two of its mice
group_cages <- lapply(group_classes, \(gc) class_cages |>
  dplyr::select(-new_class_bw, -new_class_fat, -new_class_gluc) |>
  dplyr::inner_join(gc, by = "idno") |>
  dplyr::filter(dplyr::n() >= 2, .by = cage))
#- 86.4.9: Concordance test per fit
#! A measure where every mouse in the group shares one class has nothing to test and is skipped.
set.seed(86)
dplyr::bind_rows(lapply(group_cages, \(d) concordance_test(d, measures[sapply(measures, \(v) dplyr::n_distinct(d[[v]]) > 1)])), .id = "fit") |>
  print(row.names = FALSE)

############### OLD ################
#! Model throughout: Cox on lifespan (dead_censor == 1 = died; all 1,187 mice died, no censoring) with the three classes as factors and strata(cohort, sex, strain), which gives each cohort x sex x strain group its own baseline survival curve. Every cage sits inside one such group, so cages are only compared with cages of the same cohort, sex and strain.
{
#- 86.2.1: Is there a cage effect on overall survival independent of class assignment?
#! Primary test: shared frailty model, the standard model for clustered survival (survival's own littermate example, rats, uses it). frailty(cage) adds a random effect per cage; its row in the printout gives a P value (does cage explain survival beyond class and group?) and the summary gives its variance (how much survival varies between cages). It can only detect cage-mates being MORE alike, so the social order question is left to the permutation in 86.2.2.
cage_frailty <- survival::coxph(survival::Surv(le_wk, dead_censor == 1) ~ factor(new_class_bw) + factor(new_class_fat) + factor(new_class_gluc) + survival::frailty(cage) + survival::strata(cohort, sex, strain), data = paired_cages)
print(cage_frailty)
#! The frailty row's P above is an approximation; the survival documentation recommends a likelihood-ratio test instead: the frailty model's integrated likelihood (I-likelihood) against the same model without the cage term. The variance cannot go below 0, so the P is halved (the standard boundary correction).
no_cage <- survival::coxph(survival::Surv(le_wk, dead_censor == 1) ~ factor(new_class_bw) + factor(new_class_fat) + factor(new_class_gluc) + survival::strata(cohort, sex, strain), data = paired_cages)
cage_lrt <- frailty_lrt(cage_frailty, no_cage)
cat(sprintf("cage frailty: variance %.4f | likelihood-ratio chi-sq %.2f on 1 df, P = %.3f\n", cage_lrt[["variance"]], cage_lrt[["chisq"]], cage_lrt[["p"]]))
#! Check: the same frailty model WITHOUT the class terms, i.e. total clustering of survival by cage, including any that runs through class. A larger variance here than above would mean part of the cage clustering works through class.
cage_frailty_nc <- survival::coxph(survival::Surv(le_wk, dead_censor == 1) ~ survival::frailty(cage) + survival::strata(cohort, sex, strain), data = paired_cages)
no_cage_nc <- survival::coxph(survival::Surv(le_wk, dead_censor == 1) ~ survival::strata(cohort, sex, strain), data = paired_cages)
cage_lrt_nc <- frailty_lrt(cage_frailty_nc, no_cage_nc)
cat(sprintf("without class terms: variance %.4f | likelihood-ratio chi-sq %.2f on 1 df, P = %.3f\n", cage_lrt_nc[["variance"]], cage_lrt_nc[["chisq"]], cage_lrt_nc[["p"]]))
#- 86.2.2: Is there a social order effect on overall survival independent of class assignment?
#! Permutation test on the model without the cage term (no_cage, 86.2.1). Each mouse's deviance residual = how much earlier (positive) or later (negative) it died than expected for its group and classes. Statistic: for each cage, the mean absolute difference in residual between cage-mates, averaged over cages. Null: residuals shuffled within cohort x sex x strain, 999 times. Social order = cage-mates further apart than chance (observed LARGER than the shuffles). The lower tail of the same test is a model-free check on 86.2.1 (cage-mates closer than chance), printed alongside.
surv_resid <- residuals(no_cage, type = "deviance")
group <- interaction(paired_cages$cohort, paired_cages$sex, paired_cages$strain, drop = TRUE)
obs <- cage_spread(surv_resid, paired_cages$cage)
set.seed(86)
null <- replicate(999, cage_spread(shuffle_within(surv_resid, group), paired_cages$cage))
cat(sprintf("cage-mate spread %.3f vs shuffles %.3f [95%%: %.3f-%.3f] | social order (more different) P = %.3f | cage effect check (more alike) P = %.3f\n", obs, mean(null), quantile(null, 0.025), quantile(null, 0.975), (1 + sum(null >= obs)) / 1000, (1 + sum(null <= obs)) / 1000))
}
#- 86.2.3: Do cage-mates die at the same calendar time more often than chance?
#! Explains the 86.2.1 disagreement: frailty (no steady cage effect, P = 0.19) vs permutation (cage-mates' survival alike, P = 0.001). A shared short-term event in a cage (infection, husbandry problem) would kill cage-mates at nearly the same calendar date without a lifelong hazard shift. Death date = dob + le_wk. Statistic: share of cage-mate pairs dying within 7, 30 and 90 days of each other. Null: lifespans shuffled within cohort x sex x strain while each mouse KEEPS its own dob, so cage-mates' shared birth date is preserved and only the timing of death is randomised. Excess concentrated at short windows = shared events; a steady cage effect would spread the excess more evenly.
dob <- as.Date(paired_cages$dob, tryFormats = c("%Y-%m-%d", "%m/%d/%Y"))
stopifnot(length(dob) == nrow(paired_cages), !anyNA(dob))
windows <- c(7, 30, 90)
gaps <- pair_gaps(as.numeric(dob) + paired_cages$le_wk * 7, paired_cages$cage)
obs_close <- sapply(windows, \(w) mean(gaps <= w))
set.seed(86)
null_close <- replicate(999, {
  shuffled <- shuffle_within(paired_cages$le_wk, group)
  g <- pair_gaps(as.numeric(dob) + shuffled * 7, paired_cages$cage)
  sapply(windows, \(w) mean(g <= w))
})
data.frame(within_days = windows, observed = obs_close, null_mean = rowMeans(null_close), P = (1 + rowSums(null_close >= obs_close)) / 1000) |> print()
#- 86.2.4: Is the cage-mate similarity in survival (86.2.2) explained by the deaths within 7 days of each other (86.2.3)?
#! The 86.2.2 permutation repeated without cage-mate pairs that died within 7 days of each other. The same rule is applied inside every shuffle: mice are re-dealt within cohort x sex x strain (lifespan and residual move together, each slot keeps its own dob), and pairs that now die within 7 days are dropped. Dropping them from the observed data alone would remove the most similar pairs and bias the test toward "more different". If cage-mates are no longer more alike than chance, the 86.2.2 signal is the near-simultaneous deaths.
pairs <- do.call(rbind, lapply(split(seq_len(nrow(paired_cages)), paired_cages$cage), \(v) t(utils::combn(v, 2))))
pair_cage <- paired_cages$cage[pairs[, 1]]
death <- as.numeric(dob) + paired_cages$le_wk * 7
kept <- abs(death[pairs[, 1]] - death[pairs[, 2]]) > 7
obs_apart <- mean(tapply(abs(surv_resid[pairs[, 1]] - surv_resid[pairs[, 2]])[kept], pair_cage[kept], mean))
set.seed(86)
null_apart <- replicate(999, {
  perm <- shuffle_within(seq_along(surv_resid), group)
  d <- as.numeric(dob) + paired_cages$le_wk[perm] * 7
  r <- surv_resid[perm]
  k <- abs(d[pairs[, 1]] - d[pairs[, 2]]) > 7
  mean(tapply(abs(r[pairs[, 1]] - r[pairs[, 2]])[k], pair_cage[k], mean))
})
cat(sprintf("without pairs dying within 7 days (%d of %d pairs dropped): spread %.3f vs shuffles %.3f [95%%: %.3f-%.3f] | more alike P = %.3f | more different P = %.3f\n", sum(!kept), length(kept), obs_apart, mean(null_apart), quantile(null_apart, 0.025), quantile(null_apart, 0.975), (1 + sum(null_apart <= obs_apart)) / 1000, (1 + sum(null_apart >= obs_apart)) / 1000))
#- 86.2.5: Is the clustering of deaths within 7 days (86.2.3) sex-specific?
#! Separates explanations for cage-mates dying within a week of each other. Ref 175 (ITP): a cage-mate's death raises the survivors' mortality in FEMALES, not males, so cage-mate loss predicts clustering concentrated in females. Fighting predicts clustering concentrated in males. A shared event (infection, husbandry failure) predicts similar clustering in both. Same statistic and null as 86.2.3 (7-day window), run within each sex; cages are single-sex, so every pair belongs to one sex. Only classified mice's deaths are seen, so cage-mate deaths among unclassified mice are missed in both sexes alike.
set.seed(86)
dplyr::bind_rows(lapply(split(seq_len(nrow(paired_cages)), paired_cages$sex), \(i) {
  gaps_s <- pair_gaps(as.numeric(dob[i]) + paired_cages$le_wk[i] * 7, paired_cages$cage[i])
  null_s <- replicate(999, {
    sh <- shuffle_within(paired_cages$le_wk[i], droplevels(group[i]))
    mean(pair_gaps(as.numeric(dob[i]) + sh * 7, paired_cages$cage[i]) <= 7)
  })
  data.frame(sex = paired_cages$sex[i[1]], pairs = length(gaps_s), within_7_days = mean(gaps_s <= 7), null_mean = mean(null_s), ratio = mean(gaps_s <= 7) / mean(null_s), P = (1 + sum(null_s >= mean(gaps_s <= 7))) / 1000)
})) |> print()
#- 86.2.6: Do the published class-survival HRs (Table S2.1) change when cage is accounted for?
#! Chapter 2's individual Cox models exactly as specified in 01_prep_model_data/input/slam_age_all.yaml, one per outcome: Model 1 ~ Class (Figure 1N), Model 2 ~ Class + sex * strain, Model 3 ~ Class + sex + strata(strain). Each fit on the complete dataset (n = 1,315) without and with + frailty(cage). Mice with no classified cagemate stay in: they add nothing to the cage variance but keep n equal to the chapter's. The without-cage column should reproduce Table S2.1 exactly; the with-cage column shows whether accounting for cage moves any HR. Format as Table S2.1: HR (95% CI) to 4 dp, Wald P, *** < 0.001, ** < 0.01, * < 0.05. Reference classes (BW 1, FM 4, FBG 7) are omitted.
s21 <- dplyr::bind_rows(.id = "LCM", lapply(c(BW = "new_class_bw", FM = "new_class_fat", FBG = "new_class_gluc"), \(v) dplyr::bind_rows(.id = "Model", lapply(c(`Model 1` = "", `Model 2` = " + sex * strain", `Model 3` = " + sex + survival::strata(strain)"), \(adj) {
  d <- dplyr::mutate(class_cages, cls = factor(.data[[v]]))
  fits <- lapply(c(without = "", with = " + survival::frailty(cage)"), \(fr) survival::coxph(stats::as.formula(paste0("survival::Surv(le_wk, dead_censor == 1) ~ cls", adj, fr)), data = d))
  data.frame(dplyr::rename(class_hrs(fits$without), without_cage = hr), with_cage = class_hrs(fits$with)$hr, cage_variance = round(fits$with$history[[1]]$theta, 4))
}))))
print(s21, row.names = FALSE)
