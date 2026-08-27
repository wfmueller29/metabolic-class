# =============================================================================
# figure_spec.R -- the single source of truth for the publication figure deck
#
# WHAT THIS IS
#   One ordered list describing every figure and, within it, every panel in
#   order. final_figure_deck.Rmd loops over this and does the rest: it numbers
#   the figures, letters the panels, writes each panel as its own PNG, and
#   renders the scrollable HTML.
#
# HOW TO CHANGE THINGS  (this is the whole point of the file)
#   Remove a panel      -> delete its line. Everything after it re-letters
#                          automatically; nothing else needs touching.
#   Reorder panels      -> move lines within a `panels` block.
#   Remove a figure     -> delete its list(...) block. Later figures renumber
#                          automatically.
#   Reorder figures     -> move the list(...) blocks.
#   Repoint a panel     -> change the path.
#
#   After any change, run .A/check_figures.R to confirm every path resolves and
#   to see what is unused.
#
# NUMBERING
#   Figures are numbered by position within their `part`. "primary" numbers as
#   1,2,3...; "supplemental" numbers as S1,S2,S3... Panels letter A,B,C... by
#   position. So panel 3 of the second supplemental figure is S2C, and its file
#   is written as S2C.png.
#
# PATHS
#   Relative to figures/ (knitr's working directory for the .Rmd), so:
#     ../07_display_figures/...  raw plots from stage 07
#     ../99_pub_ready_figs/...   style-harmonized plots from stage 99
#     ../97_treatment_response/, ../91_partial_correlation/
#     images/                    static, hand-made images checked into the repo
#     output/tables/             HR tables built by the deck itself (see the
#                                tables section of final_figure_deck.Rmd)
#
#   NOTE: the 07 and 99 paths are two different styling regimes. Where a panel
#   has a harmonized twin under 99, prefer it -- see .A/check_figures.R, which
#   reports 07 panels that have a 99 equivalent available.
# =============================================================================

FIGURES <- list(
  # The graphical abstract is not a numbered figure -- part "abstract" is
  # excluded from numbering and its single panel is written as GA.png.
  list(
    part  = "abstract",
    title = "Graphical Abstract",
    panels = c(
      "images/graphical_abstract.png"
    )
  ),
  list(
    part  = "primary",
    title = "Defining Metabolic Classes",
    panels = c(
      "images/1A.png",
      "../99_pub_ready_figs/output/all_env/define_class/bw_by_bw.png",
      "../99_pub_ready_figs/output/all_env/define_class/fat_by_bw.png",
      "../99_pub_ready_figs/output/all_env/define_class/gluc_by_bw.png",
      "../99_pub_ready_figs/output/all_env/define_class/km_bw.png",
      "../99_pub_ready_figs/output/all_env/define_class/bw_by_fat.png",
      "../99_pub_ready_figs/output/all_env/define_class/fat_by_fat.png",
      "../99_pub_ready_figs/output/all_env/define_class/gluc_by_fat.png",
      "../99_pub_ready_figs/output/all_env/define_class/km_fat.png",
      "../99_pub_ready_figs/output/all_env/define_class/bw_by_gluc.png",
      "../99_pub_ready_figs/output/all_env/define_class/fat_by_gluc.png",
      "../99_pub_ready_figs/output/all_env/define_class/gluc_by_gluc.png",
      "../99_pub_ready_figs/output/all_env/define_class/km_gluc.png",
      "../99_pub_ready_figs/output/tables/hr_all.png"
    )
  ),
  list(
    part  = "primary",
    title = "Sex/Strain Classes BW",
    panels = c(
      "../99_pub_ready_figs/output/fb6_env/define_class/bw_by_bw.png",
      "../99_pub_ready_figs/output/fb6_env/define_class/km_bw.png",
      "../99_pub_ready_figs/output/mb6_env/define_class/bw_by_bw.png",
      "../99_pub_ready_figs/output/mb6_env/define_class/km_bw.png",
      "../99_pub_ready_figs/output/fhet3_env/define_class/bw_by_bw.png",
      "../99_pub_ready_figs/output/fhet3_env/define_class/km_bw.png",
      "../99_pub_ready_figs/output/mhet3_env/define_class/bw_by_bw.png",
      "../99_pub_ready_figs/output/mhet3_env/define_class/km_bw.png",
      "../99_pub_ready_figs/output/tables/hr_sexstrain_bw.png"
    )
  ),
  list(
    part  = "primary",
    title = "Graded Mortality Response",
    panels = c(
      "images/3A.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/dose_response/plot_1.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/dose_response/plot_4.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/dose_response/plot_7.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/dose_response_forest/forest.png"
    )
  ),
  list(
    part  = "primary",
    title = "Held Out Cohort Validation",
    panels = c(
      "images/4A.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/forest/plot_5.png",
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_combined_hr_validation/plot_[6.5, 58.5]_4.png",
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_combined_hr_validation/plot_[6.5, 84.5]_6.png",
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_combined_hr_validation/plot_[6.5, 110.5]_8.png",
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_combined_hr_validation/plot_[6.5, 136.5]_10.png",
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_validation_forest/forest.png"
    )
  ),
  list(
    part  = "primary",
    title = "ITP Validation",
    panels = c(
      "images/5A.png",
      "../99_pub_ready_figs/output/itp_env/define_class/bw_by_bw.png",
      "../99_pub_ready_figs/output/itp_env/define_class/km_bw.png",
      "../99_pub_ready_figs/output/tables/hr_itp.png",
      "../97_treatment_response/output/treatment_response/plot_1.png",
      "../97_treatment_response/output/treatment_response/plot_2.png",
      "../97_treatment_response/output/treatment_response/plot_3.png",
      "../97_treatment_response/output/treatment_response_combined/predicted_classes_1_3.png",
      "../99_pub_ready_figs/output/tables/hr_treatment.png",
      "../97_treatment_response/output/downsampled_hr_histogram/downsampled_class2_hr_histogram.png",
      "../97_treatment_response/output/tables/class2_downsampled_hr_table.png",
      "../99_pub_ready_figs/output/locus_heatmaps/loci_filtered.png"
    )
  ),
  list(
    part  = "supplemental",
    title = "Adiposity Classes",
    panels = c(
      "../99_pub_ready_figs/output/adiposity_env/define_class/adiposity_by_adiposity.png",
      "../99_pub_ready_figs/output/adiposity_env/define_class/km_adiposity.png",
      "../99_pub_ready_figs/output/adiposity_env/define_class/bw_by_adiposity.png",
      "../99_pub_ready_figs/output/adiposity_env/define_class/gluc_by_adiposity.png",
      "../99_pub_ready_figs/output/adiposity_env/define_class/adiposity_by_bw.png",
      "../99_pub_ready_figs/output/adiposity_env/define_class/adiposity_by_gluc.png",
      "../99_pub_ready_figs/output/tables/demographics_adiposity.png",
      "../99_pub_ready_figs/output/tables/hr_adiposity.png"
    )
  ),
  list(
    part  = "supplemental",
    title = "Joint Latent Class Model",
    note  = paste("These joint latent-class panels are the canonical output from",
                  "Billy Mueller's original run. The joint model is re-fit stochastically",
                  "and is environment-sensitive, so it is not regenerated on this machine",
                  "to avoid drift from the paper-displayed figure."),
    panels = c(
      # 94_jointlcm writes EIGHT panels, lettered A-H in its own scheme, and its
      # letters are NOT this figure's letters: 94's E/F are ADIPOSITY, which this
      # figure does not show. Glucose is 94's G/H. Taking E_/F_ here because they
      # sort next would silently publish adiposity as glucose.
      "../94_jointlcm/output/panel/A_bw_observed.png",
      "../94_jointlcm/output/panel/B_bw_km.png",
      "../94_jointlcm/output/panel/C_fat_observed.png",
      "../94_jointlcm/output/panel/D_fat_km.png",
      "../94_jointlcm/output/panel/G_glucose_observed.png",
      "../94_jointlcm/output/panel/H_glucose_km.png"
    )
  ),
  list(
    part  = "supplemental",
    title = "Class Overlap and Co-occurrence",
    panels = c(
      # A -- subject x class posterior probability, HCA on both axes. Stage 07
      # writes TWO heatmaps: heatmap1 includes the covariates as extra columns,
      # heatmap2 does not. This is heatmap2; heatmap1 is the superseded version
      # and is deliberately not in the deck.
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/heatmap/heatmap2.jpg",
      # B, C -- qgraph network and the coefficient table behind it
      "../91_partial_correlation/output/partial_correlation_network.jpg",
      "../99_pub_ready_figs/output/tables/partial_correlation.png",
      # D-G -- adjusted Rand index, UpSet, and the high-risk-burden survival pair
      "../92_overlap_analysis/output/ari_matrix.png",
      "../92_overlap_analysis/output/upset_high_risk.png",
      "../92_overlap_analysis/output/km_high_risk_burden.png",
      "../92_overlap_analysis/output/km_high_risk_burden_hr.png"
    )
  ),
  list(
    part  = "supplemental",
    # The FM and FBG analogues of main figure 2, in one figure: panels A-I are
    # fat mass (four cohorts, trajectory + KM each, then the HR table), J-R the
    # same for glucose. 18 panels, so the letters run exactly A..R.
    title = "Sex/Strain Classes FM and FBG",
    panels = c(
      "../99_pub_ready_figs/output/fb6_env/define_class/fat_by_fat.png",
      "../99_pub_ready_figs/output/fb6_env/define_class/km_fat.png",
      "../99_pub_ready_figs/output/mb6_env/define_class/fat_by_fat.png",
      "../99_pub_ready_figs/output/mb6_env/define_class/km_fat.png",
      "../99_pub_ready_figs/output/fhet3_env/define_class/fat_by_fat.png",
      "../99_pub_ready_figs/output/fhet3_env/define_class/km_fat.png",
      "../99_pub_ready_figs/output/mhet3_env/define_class/fat_by_fat.png",
      "../99_pub_ready_figs/output/mhet3_env/define_class/km_fat.png",
      "../99_pub_ready_figs/output/tables/hr_sexstrain_fat.png",
      "../99_pub_ready_figs/output/fb6_env/define_class/gluc_by_gluc.png",
      "../99_pub_ready_figs/output/fb6_env/define_class/km_gluc.png",
      "../99_pub_ready_figs/output/mb6_env/define_class/gluc_by_gluc.png",
      "../99_pub_ready_figs/output/mb6_env/define_class/km_gluc.png",
      "../99_pub_ready_figs/output/fhet3_env/define_class/gluc_by_gluc.png",
      "../99_pub_ready_figs/output/fhet3_env/define_class/km_gluc.png",
      "../99_pub_ready_figs/output/mhet3_env/define_class/gluc_by_gluc.png",
      "../99_pub_ready_figs/output/mhet3_env/define_class/km_gluc.png",
      "../99_pub_ready_figs/output/tables/hr_sexstrain_gluc.png"
    )
  ),
  list(
    part  = "supplemental",
    title = "Resampling Validation",
    panels = c(
      # ORDER IS NOT FILE ORDER. Stage 07 builds the list as
      #   c(interval_plots, window_plots, cumulative_plots, resampled_plots)
      # where each is a 3-element column over the outcomes, so plot_N is
      # STRATEGY-major: 1-3 interval, 4-6 window, 7-9 cumulative, 10-12
      # resampling, each in bw/fat/gluc order. This figure is OUTCOME-major --
      # four strategies per outcome -- so the numbers interleave. Reading them
      # in file order would put four different outcomes in one row.
      "images/S5A.png",
      # Body weight: interval, age window, cumulative, resampling
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/classification/plot_1.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/classification/plot_4.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/classification/plot_7.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/classification/plot_10.png",
      # Fat mass: interval, age window, cumulative, resampling
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/classification/plot_2.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/classification/plot_5.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/classification/plot_8.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/classification/plot_11.png",
      # Glucose: interval, age window, cumulative, resampling
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/classification/plot_3.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/classification/plot_6.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/classification/plot_9.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/classification/plot_12.png"
    )
  ),
  list(
    part  = "supplemental",
    title = "Internal and External Validation",
    panels = c(
      # Two previously freestanding figures, merged: A-F are the internal
      # validation (C1-C10, 80:20 split), G-L the identical analysis run as
      # external validation (train C1-C10, test C16-C18). Same panel sequence
      # in both halves, so A<->G, B<->H, C<->I and so on line up.
      #
      # Within each half the order is LP-then-concordance BY SAMPLING SCHEME,
      # not 99's file order: 99 writes window_coef, window_concord, cum_coef,
      # cum_concord, whereas the figure reads across as window/cumulative for
      # the linear predictor, then window/cumulative for concordance.
      "images/S6A.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/forest/plot_2.png",
      "../99_pub_ready_figs/output/all_env/validation/window_coef.png",
      "../99_pub_ready_figs/output/all_env/validation/cum_coef.png",
      "../99_pub_ready_figs/output/all_env/validation/window_concord.png",
      "../99_pub_ready_figs/output/all_env/validation/cum_concord.png",
      "images/S6G.png",
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/forest/plot_2.png",
      "../99_pub_ready_figs/output/held_out_env/validation/window_coef.png",
      "../99_pub_ready_figs/output/held_out_env/validation/cum_coef.png",
      "../99_pub_ready_figs/output/held_out_env/validation/window_concord.png",
      "../99_pub_ready_figs/output/held_out_env/validation/cum_concord.png"
    )
  ),
  list(
    part  = "supplemental",
    title = "External Validation KM",
    panels = c(
      # Windows 1,2,3,5,7,9 -- the COMPLEMENT of figure 4, which shows 4,6,8,10
      # (58.5/84.5/110.5/136.5). Between them the two figures cover all ten
      # upper bounds with no panel repeated. Stage 07 encodes the same split:
      # km_forest_index <- c(4, 6, 8, 10) makes 4G's facets match figure 4's
      # KM panels, so a forest for this figure has to use these indices.
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_combined_hr_validation/plot_[6.5, 19.5]_1.png",
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_combined_hr_validation/plot_[6.5, 32.5]_2.png",
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_combined_hr_validation/plot_[6.5, 45.5]_3.png",
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_combined_hr_validation/plot_[6.5, 71.5]_5.png",
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_combined_hr_validation/plot_[6.5, 97.5]_7.png",
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_combined_hr_validation/plot_[6.5, 123.5]_9.png",
      # G -- faceted forest over exactly the six windows above, built by the
      # same forest_* helpers as 4G. Replaces the old hr_km_external table,
      # which carried raw column names and SLAM's p<0.005 threshold for "**".
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_validation_forest_supp/forest.png"
    )
  ),
  list(
    part  = "supplemental",
    title = "Healthcard Conditions",
    panels = c(
      # 95_healthcard_cod names these S8A-S8E itself, so the file names track
      # the panel letters directly -- unlike every other stage here. If this
      # figure is ever renumbered, those names go stale and only this comment
      # will say so; the panel ORDER below is what actually assigns the letters.
      #   A, B  stacked bars: condition burden, and incidence per year
      #   C, D  cumulative HCs/mouse: mice with events, then all mice
      #   E     per-condition events/year heatmap, clustered
      "../95_healthcard_cod/output/S8A.png",
      "../95_healthcard_cod/output/S8B.png",
      "../95_healthcard_cod/output/S8C.png",
      "../95_healthcard_cod/output/S8D.png",
      "../95_healthcard_cod/output/S8E.png"
    )
  ),
  list(
    part  = "supplemental",
    title = "ITP Genotyped Cohorts",
    panels = c(
      # Four lettered panels, matching the manuscript. A and B are pre-composited
      # by 99 (assemble_itp_composite): each is the whole 3x2 block -- the three
      # cohort rows (Unstratified / Females / Males) x (BW trajectory / KM), with
      # one shared class legend. The six per-env PNGs still exist under
      # output/itp_geno_*/define_class/ if a piece is ever wanted individually;
      # the deck just points at the two assembled blocks instead of lettering
      # eleven separate images.
      # A -- controls composite (3 cohort rows x trajectory/KM)
      "../99_pub_ready_figs/output/itp_geno_composite/controls.png",
      # B -- treated composite (3 cohort rows x trajectory/KM)
      "../99_pub_ready_figs/output/itp_geno_composite/treated.png",
      # C -- controls/treated demographics across the three strata
      "../98_itp_genotype/output/itp_geno_demographics.png",
      # D -- the unfiltered locus heatmap (5L is the Bonferroni-filtered twin)
      "../99_pub_ready_figs/output/locus_heatmaps/loci_all.png"
    )
  )
)

# =============================================================================
# TABLES
#
# Numbered SEPARATELY from figures, matching the manuscript: primary tables are
# Table 1, Table 2, ...; supplemental are Supplemental Table 1, 2, ...
#
# render = "png"     rasterised by 99 into output/tables/ and treated like any
#                    other panel -- use for small display tables that need to
#                    be placed in Canva.
# render = "inline"  rendered as an HTML table in the deck, not exported. Use
#                    for bulk data tables (some are hundreds of rows) where a
#                    PNG would be unreadable and useless as a Canva asset.
#
# `build` is evaluated with the stage-07 environments already loaded
# (all_env, itp_env, held_out_env, ...). It must return something flextable()
# or knitr::kable() can render.
#
# TO MOVE A TABLE BETWEEN PNG AND INLINE: change its `render` field. Nothing
# else needs touching.
# =============================================================================


# =============================================================================
# SUPPLEMENTARY TABLE HELPERS  (S1-S5)
#
# These five tables ship in the manuscript's supplementary Word file. The
# builders below reproduce them from save_figtabs so the deck shows what was
# submitted, not the raw pipeline dumps.
#
# EVERY code identifier is renamed here. Nothing in S1-S5 reaches the deck
# carrying a pipeline column name.
#
# ROUNDING is per-quantity, not one rule for all five -- forcing a single
# precision would make S4 absurd (114.4286 weeks is ten-minute resolution on a
# mouse lifespan) or S1 useless (HRs need the 4th decimal to separate classes):
#
#   S1  4 dp  HR and both CI bounds, trailing zeros kept
#   S2  4 dp  estimates; p-values BINNED, not printed
#   S3  2 dp  every statistic -- the source is already
#             round(psych::describe(...), 2) at 07_display_figures.Rmd:2793,
#             so this is the data's actual precision, not a choice
#   S4  1 dp  survival quartiles in weeks
#   S5  4 dp  entropy; 1 dp smallest class %; 0 dp with thousands separators
#             for loglik / BIC / AIC / ICL1 / ICL2
#
# ALWAYS round from full precision -- never re-round an already-rounded value.
# =============================================================================

sup_fmt   <- function(x, dp) formatC(as.numeric(x), format = "f", digits = dp)
sup_fmt_k <- function(x) formatC(as.numeric(x), format = "d", big.mark = ",")

SUP_OUTCOME <- c(bw = "BW", fat = "FM", gluc = "FBG",
                 "Body Weight" = "BW", "Body Fat" = "FM", "Glucose" = "FBG")

SUP_DATASET <- c(og = "Complete", data = "Complete",
                 train_test = "Training", training_data = "Training",
                 test_data = "Testing")

# S3's Measure column. "_ns" = NOT SCALED: the raw, uncentered age. dif_time is
# age - lag(age) within mouse (07_display_figures.Rmd:2767), which is why its
# Obs. is lower than the outcome's by exactly the mouse count.
SUP_MEASURE <- c(bw = "BW", fat = "FM", gluc = "FBG",
                 age_wk_ns = "Age (weeks)", age_wk = "Age (weeks)",
                 wave = "Wave", dif_time = "Interval (weeks)")

sup_theme <- function(ft, widths = NULL) {
  ft <- flextable::theme_vanilla(ft)
  ft <- flextable::font(ft, fontname = "Arial", part = "all")
  ft <- flextable::fontsize(ft, size = 8, part = "all")
  ft <- flextable::autofit(ft)
  ft <- flextable::set_table_properties(ft, layout = "autofit")
  flextable::fit_to_width(ft, max_width = max_width, inc = .25, max_iter = 100)
}

# p-values are binned rather than printed. "n.s." replaced a bare dash so a
# label reads as a label rather than as a missing value.
sup_bin_p <- function(p) {
  p <- as.numeric(p)
  ifelse(p < 0.0001, "< 0.0001",
  ifelse(p < 0.001,  "< 0.001",
  ifelse(p < 0.01,   "< 0.01",
  ifelse(p < 0.05,   "< 0.05", "n.s."))))
}

TABLES <- list(
  list(
    part   = "primary",
    title  = "SLAM C1-C10 Class Demographics",
    render = "png",
    build  = function() {
      all_env$save_figtabs$t1_df %>%
        select(-oc_name) %>%
        mutate(Class = row_names) %>%
        flextable() %>%
        theme_vanilla() %>%
        autofit() %>%
        set_table_properties(layout = "autofit") %>%
        fit_to_width(max_width = max_width, inc = .25, max_iter = 100)
    }
  ),
  list(
    part   = "primary",
    title  = "ITP Class Demographics",
    render = "png",
    build  = function() {
      itp_env$save_figtabs$t1_df %>%
        select(-oc_name) %>%
        mutate(Class = row_names) %>%
        flextable() %>%
        theme_vanilla() %>%
        autofit() %>%
        set_table_properties(layout = "autofit") %>%
        fit_to_width(max_width = max_width, inc = .25, max_iter = 100)
    }
  ),
  list(
    part   = "supplemental",
    title  = "HRs estimated using three Cox models",
    render = "png",
    # S1. Source: save_figtabs$hr_numeric (Outcome/Class/Model/value/lower/
    # upper/pval). Stage 07 emits one block per Cox specification; they are
    # reshaped side by side into Model 1/2/3 columns keyed on Outcome+Class.
    # Reference classes (1, 4, 7) carry the literal "Reference".
    # Stars are DERIVED from pval, not parsed from stage 07's pre-formatted
    # $final string, so the deck does not inherit that formatting.
    build  = function() {
      hn <- all_env$save_figtabs$hr_numeric
      hn$pval  <- as.numeric(hn$pval)
      stars    <- ifelse(hn$pval < 0.001, "***",
                  ifelse(hn$pval < 0.01,  "**",
                  ifelse(hn$pval < 0.05,  "*", "")))
      hn$cell  <- trimws(sprintf("%s (%s, %s) %s", sup_fmt(hn$value, 4),
                                 sup_fmt(hn$lower, 4), sup_fmt(hn$upper, 4), stars))
      hn$Model <- sub("^HR ", "", hn$Model)
      w <- stats::reshape(hn[, c("Outcome", "Class", "Model", "cell")],
                          idvar = c("Outcome", "Class"), timevar = "Model",
                          direction = "wide")
      names(w) <- c("LCM", "Class", "HR (CI) Model 1", "HR (CI) Model 2",
                    "HR (CI) Model 3")
      w$LCM   <- SUP_OUTCOME[as.character(w$LCM)]
      w$Class <- sub("^Class", "", as.character(w$Class))
      sup_theme(flextable(w))
    }
  ),
  list(
    part   = "supplemental",
    title  = "Linear Mixed Effects Models",
    note   = paste("These coefficients are re-fit on this machine and can differ",
                   "from the published values by a tiny, environment-dependent amount",
                   "(the lmer optimizer / BLAS / OS math differ between machines).",
                   "The canonical, paper-displayed version is Billy Mueller's original run."),
    render = "inline",
    build  = function() {
      lme_coef_table <- all_env$save_figtabs$lme_coef_table_broom
      lme_coef_table <- lapply(lme_coef_table, function(table) {
        table <- table %>%
          mutate(across(ends_with("p.value"), ~ case_when(
            .x < 0.0001 ~ "< 0.0001",
            .x < 0.001 ~ "< 0.001",
            .x < 0.01 ~ "< 0.01",
            .x < 0.05 ~ "< 0.05",
            TRUE ~ "-"
          )))
        return(table)
      })

      # Function to alternate estimate and p.value columns
      reorder_estimate_pvalue <- function(df) {
        term_col <- "term"
        all_cols <- names(df)
        prefixes <- unique(gsub(
          "_(estimate|p.value)$", "",
          all_cols[!all_cols %in% term_col]
        ))
        new_order <- c(term_col, unlist(lapply(prefixes, function(prefix) {
          c(paste0(prefix, "_estimate"), paste0(prefix, "_p.value"))
        })))

        df[, new_order]
      }

      # Apply to each table in your list
      lme_coef_table <- lapply(lme_coef_table, reorder_estimate_pvalue)

      lme_coef_table <- lapply(lme_coef_table, function(table) {
        flextable(table) %>%
          theme_vanilla() %>%
          autofit() %>%
          set_table_properties(layout = "autofit") %>%
          fit_to_width(max_width = max_width, inc = .25, max_iter = 100)
      })

      # All THREE blocks (LCM for Body Weight / Fat Mass / FBG), returned as a
      # list. Listing them as bare expressions only ever returned the last one,
      # so the deck showed the FBG block alone -- a holdover from the old PDF
      # Rmd, where each top-level line auto-printed.
      lme_coef_table
    }
  ),
  list(
    part   = "supplemental",
    title  = "Descriptive statistics of the modeling variables",
    render = "inline",
    # S3. Sources: sum_data (complete 12 + training 12) and sum_test (12) = 36
    # rows. sum_missing (the 13/9/14 excluded mice) is DELIBERATELY excluded --
    # S3 describes the modelled data, not what was dropped.
    #
    # DROPPED  data_id  a pure function of dataset + outcome, and LESS
    #                   informative than dataset since training and testing
    #                   share one value
    #          vars     the describe() row index, 1:4 repeating
    #          range    max - min, derivable; Min and Max are merged instead
    #          se       exactly SD/sqrt(Obs.), and pseudo-replicated -- it
    #                   divides by observations (10,819) when the independent
    #                   units are mice (1,315), understating uncertainty ~2.8x
    #
    # TWO N's  Obs. counts measurements; mice counts animals. Kept distinct.
    # kurtosis is EXCESS kurtosis (raw - 3); psych returns it that way, and
    # 26/36 rows fall below 1+skew^2, impossible for raw kurtosis.
    build  = function() {
      d <- rbind(all_env$save_figtabs$sum_data, all_env$save_figtabs$sum_test)
      out <- data.frame(
        Dataset               = SUP_DATASET[as.character(d$data_name)],
        `Metabolic Variable`  = SUP_OUTCOME[as.character(d$outcome)],
        Measure               = SUP_MEASURE[as.character(d$variables)],
        Mice                  = sup_fmt_k(d$unique_id),
        `Obs.`                = sup_fmt_k(d$n),
        Mean                  = sup_fmt(d$mean, 2),
        SD                    = sup_fmt(d$sd, 2),
        Median                = sup_fmt(d$median, 2),
        `Trimmed Mean`        = sup_fmt(d$trimmed, 2),
        MAD                   = sup_fmt(d$mad, 2),
        `Min–Max`         = paste0(sup_fmt(d$min, 2), "–", sup_fmt(d$max, 2)),
        Skewness              = sup_fmt(d$skew, 2),
        `Excess Kurtosis`     = sup_fmt(d$kurtosis, 2),
        check.names = FALSE, stringsAsFactors = FALSE
      )
      sup_theme(flextable(out))
    }
  ),
  list(
    part   = "supplemental",
    title  = "Median life expectancy",
    render = "inline",
    # S4. Source: save_figtabs$table_mle, built by describe_le() at
    # 07_display_figures.Rmd:2844 from final_models$combined_census[[1]] -- the
    # object is literally named census_complete. Subgroups come from looping
    # over config$meta_dataset$covariates (sex, strain) WITHIN that same census,
    # so every column is a subset of the complete dataset:
    # 648 + 667 = 1,315 and 649 + 666 = 1,315.
    #
    # ESTIMATOR  survfit(surv_object ~ 1) with every argument at default, which
    #            fixes Kaplan-Meier, conf.int = 0.95 and conf.type = "log".
    #
    # TRANSPOSED to groups-in-rows with "estimate (95% CI)" cells, matching
    # Table 1's Median Survival column. The pipeline emits statistics-in-rows,
    # which separated each estimate from its own limits by three row positions.
    #
    # DROPPED  conf_int (0.95), conf_type (log), type (right) -- constant down
    #          every column and all three are survfit defaults. Restated in the
    #          Word footnote, which is where the 95% now lives.
    build  = function() {
      le  <- all_env$save_figtabs$table_mle
      le  <- le[c("all", "sex.F", "sex.M", "strain.HET3", "strain.B6"), ]
      cel <- function(e, lo, hi) sprintf("%s (%s, %s)", sup_fmt(e, 1),
                                        sup_fmt(lo, 1), sup_fmt(hi, 1))
      out <- data.frame(
        Group             = c("All", "F", "M", "HET3", "B6"),
        n                 = sup_fmt_k(le$n),
        `Median (95% CI)` = cel(le$Median, le$Lower.Median, le$Upper.Median),
        `Q1 (95% CI)`     = cel(le$Q1,     le$Lower.Q1,     le$Upper.Q1),
        `Q3 (95% CI)`     = cel(le$Q3,     le$Lower.Q3,     le$Upper.Q3),
        check.names = FALSE, stringsAsFactors = FALSE
      )
      sup_theme(flextable(out))
    }
  ),
  list(
    part   = "supplemental",
    title  = "LCM information",
    render = "inline",
    # S5. Source: save_figtabs$lcmm_table -- helphlme::compare_models(
    # final_models$final_model)$table with outcome and data_type prepended.
    #
    # TRANSPOSED to models-in-rows with a Dataset column, matching S3.
    #
    # DROPPED  Model.Number  1:6, fully determined by dataset x outcome
    #          conv          1 for all six; lcmm's convergence code, not a
    #                        count. lcmm defines conv = 1 as "the convergence
    #                        criteria were satisfied", and the canonical
    #                        summary() prints "Convergence criteria satisfied"
    #                        six times with zero failures. Stated in words in
    #                        the Word footnote instead.
    #          Model         one distinct value across all six; moved to the
    #                        footnote as an equation.
    #
    # The footnote equation, read verbatim off the hlme call:
    #   outcome ~ (age + age^2) x class + sex x genetic background
    #             + (age + age^2 | mouse ID)
    # with idiag = FALSE (non-structured variance-covariance matrix) and
    # nwg = TRUE (a class-specific PROPORTIONAL parameter multiplies it --
    # lcmm's own wording; ng-1 parameters, not 6 per class).
    #
    # Smallest Class (%) is 1 dp: it is a ratio of integers (124/1315), so the
    # 3rd decimal was 0.001% of the cohort, about 1/100 of a mouse.
    build  = function() {
      lt  <- all_env$save_figtabs$lcmm_table
      sm  <- grep("^Smallest", names(lt), value = TRUE)[1]   # make.names mangles it
      out <- data.frame(
        Dataset              = SUP_DATASET[as.character(lt$data_type)],
        `Metabolic Variable` = SUP_OUTCOME[as.character(lt$outcome)],
        Classes              = lt$k,
        Parameters           = lt$npm,
        `Log-Likelihood`     = sup_fmt_k(lt$loglik),
        BIC                  = sup_fmt_k(lt$BIC),
        AIC                  = sup_fmt_k(lt$AIC),
        Entropy              = sup_fmt(lt$entropy, 4),
        ICL1                 = sup_fmt_k(lt$ICL1),
        ICL2                 = sup_fmt_k(lt$ICL2),
        `Smallest Class (%)` = sup_fmt(lt[[sm]], 1),
        check.names = FALSE, stringsAsFactors = FALSE
      )
      sup_theme(flextable(out))
    }
  ),
  list(
    part   = "supplemental",
    title  = "Individual Cox Information",
    render = "inline",
    build  = function() {
      flextable(all_env$save_figtabs$individual_coxzph_tables) %>%
        theme_vanilla() %>%
        autofit() %>%
        set_table_properties(layout = "autofit") %>%
        fit_to_width(max_width = max_width, inc = .25, max_iter = 100)
    }
  ),
  list(
    part   = "supplemental",
    title  = "Combined Cox Information",
    render = "inline",
    build  = function() {
      all_env$save_figtabs$combined_coxzph_tables %>%
        mutate(df = round(df, digits = 2)) %>%
        select(-outcome) %>%
        flextable() %>%
        theme_vanilla() %>%
        autofit() %>%
        set_table_properties(layout = "autofit") %>%
        fit_to_width(max_width = max_width, inc = .25, max_iter = 100)
    }
  ),
  list(
    part   = "supplemental",
    title  = "Descriptive Census Information",
    render = "inline",
    build  = function() {
      flextable(round(all_env$save_figtabs$describe_census, digits = 3)) %>%
        theme_vanilla() %>%
        autofit() %>%
        set_table_properties(layout = "autofit") %>%
        fit_to_width(max_width = max_width, inc = .25, max_iter = 100)

    }
  ),
  list(
    part   = "supplemental",
    title  = "Descriptive Statistics SLAM C16-C18 datasets",
    render = "inline",
    build  = function() {
      flextable(held_out_env$save_figtabs$sum_test) %>%
        theme_vanilla() %>%
        autofit() %>%
        set_table_properties(layout = "autofit") %>%
        fit_to_width(max_width = max_width, inc = .25, max_iter = 100)
    }
  ),
  list(
    part   = "supplemental",
    title  = "Missing Data Descriptive Statistics SLAM C1-C10 datasets",
    render = "inline",
    build  = function() {
      flextable(all_env$save_figtabs$sum_missing) %>%
        theme_vanilla() %>%
        autofit() %>%
        set_table_properties(layout = "autofit") %>%
        fit_to_width(max_width = max_width, inc = .25, max_iter = 100)

    }
  ),
  list(
    part   = "supplemental",
    title  = "LCM Posterior Probabilities",
    render = "inline",
    build  = function() {
      flextable(all_env$save_figtabs$post_prob_table) %>%
        theme_vanilla() %>%
        autofit() %>%
        set_table_properties(layout = "autofit") %>%
        fit_to_width(max_width = max_width, inc = .25, max_iter = 100)
    }
  ),
  list(
    part   = "supplemental",
    title  = "Candidate LCMs",
    render = "inline",
    build  = function() {
      flextable(all_env$save_figtabs$all_models_table) %>%
        # fontsize(size = 3, part = "all") %>%
        theme_vanilla() %>%
        autofit() %>%
        set_table_properties(layout = "autofit") %>%
        fit_to_width(max_width = max_width, inc = .25, max_iter = 100)

    }
  ),
  list(
    part   = "supplemental",
    title  = "LME Information",
    render = "inline",
    build  = function() {
      all_env$save_figtabs$lme_table %>%
        mutate(sigma = round(sigma, digits = 3)) %>%
        mutate(loglik = round(loglik, digits = 0)) %>%
        mutate(AICtab = round(AICtab, digits = 0)) %>%
        flextable() %>%
        theme_vanilla() %>%
        autofit() %>%
        set_table_properties(layout = "autofit") %>%
        fit_to_width(max_width = max_width, inc = .25, max_iter = 100)
    }
  )
)
