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
  # The old "Heatmaps" figure lived here. All four of its panels are now in the
  # Class Overlap figure above, except heatmap1.jpg (the covariates-as-columns
  # version), which is superseded and intentionally dropped.
  list(
    part  = "supplemental",
    title = "Reclassifcation analysis",
    panels = c(
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/class_prediction_panel/class_prediction_panel.png",
      "images/Reclassification.png"
    )
  ),
  list(
    part  = "supplemental",
    title = "Internal Validation",
    panels = c(
      "images/Internal Validation.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/forest/plot_2.png",
      "../99_pub_ready_figs/output/all_env/validation/window_coef.png",
      "../99_pub_ready_figs/output/all_env/validation/cum_coef.png",
      "../99_pub_ready_figs/output/all_env/validation/window_concord.png",
      "../99_pub_ready_figs/output/all_env/validation/cum_concord.png"
    )
  ),
  list(
    part  = "supplemental",
    title = "External Validation",
    panels = c(
      "images/External Validation.png",
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
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_combined_hr_validation/plot_[6.5, 19.5]_1.png",
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_combined_hr_validation/plot_[6.5, 32.5]_2.png",
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_combined_hr_validation/plot_[6.5, 45.5]_3.png",
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_combined_hr_validation/plot_[6.5, 58.5]_4.png",
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_combined_hr_validation/plot_[6.5, 71.5]_5.png",
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_combined_hr_validation/plot_[6.5, 84.5]_6.png",
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_combined_hr_validation/plot_[6.5, 97.5]_7.png",
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_combined_hr_validation/plot_[6.5, 110.5]_8.png",
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_combined_hr_validation/plot_[6.5, 123.5]_9.png",
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_combined_hr_validation/plot_[6.5, 136.5]_10.png",
      "../99_pub_ready_figs/output/tables/hr_km_external.png"
    )
  ),
  list(
    part  = "supplemental",
    title = "Healthcard Information",
    panels = c(
      "images/Michel Healthcard.png"
    )
  ),
  list(
    part  = "supplemental",
    title = "Treatment Response",
    panels = c(
      "../97_treatment_response/output/treatment_response/plot_1.png",
      "../97_treatment_response/output/treatment_response/plot_2.png",
      "../97_treatment_response/output/treatment_response/plot_3.png"
    )
  ),
  list(
    part  = "supplemental",
    title = "Defining Metabolic Classes - Female B6",
    panels = c(
      "../07_display_figures/output/slam_c1-c10_age_fb6_bwfatgluc/outcome/plot_1.png",
      "../07_display_figures/output/slam_c1-c10_age_fb6_bwfatgluc/outcome/plot_4.png",
      "../07_display_figures/output/slam_c1-c10_age_fb6_bwfatgluc/outcome/plot_7.png",
      "../07_display_figures/output/slam_c1-c10_age_fb6_bwfatgluc/outcome/plot_10.png",
      "../07_display_figures/output/slam_c1-c10_age_fb6_bwfatgluc/outcome/plot_2.png",
      "../07_display_figures/output/slam_c1-c10_age_fb6_bwfatgluc/outcome/plot_5.png",
      "../07_display_figures/output/slam_c1-c10_age_fb6_bwfatgluc/outcome/plot_8.png",
      "../07_display_figures/output/slam_c1-c10_age_fb6_bwfatgluc/outcome/plot_11.png",
      "../07_display_figures/output/slam_c1-c10_age_fb6_bwfatgluc/outcome/plot_3.png",
      "../07_display_figures/output/slam_c1-c10_age_fb6_bwfatgluc/outcome/plot_6.png",
      "../07_display_figures/output/slam_c1-c10_age_fb6_bwfatgluc/outcome/plot_9.png",
      "../07_display_figures/output/slam_c1-c10_age_fb6_bwfatgluc/outcome/plot_12.png",
      "images/Basic LCM.png",
      "../99_pub_ready_figs/output/tables/hr_fb6.png"
    )
  ),
  list(
    part  = "supplemental",
    title = "Defining Metabolic Classes - Female HET3",
    panels = c(
      "../07_display_figures/output/slam_c1-c10_age_fhet3_bwfatgluc/outcome/plot_1.png",
      "../07_display_figures/output/slam_c1-c10_age_fhet3_bwfatgluc/outcome/plot_4.png",
      "../07_display_figures/output/slam_c1-c10_age_fhet3_bwfatgluc/outcome/plot_7.png",
      "../07_display_figures/output/slam_c1-c10_age_fhet3_bwfatgluc/outcome/plot_10.png",
      "../07_display_figures/output/slam_c1-c10_age_fhet3_bwfatgluc/outcome/plot_2.png",
      "../07_display_figures/output/slam_c1-c10_age_fhet3_bwfatgluc/outcome/plot_5.png",
      "../07_display_figures/output/slam_c1-c10_age_fhet3_bwfatgluc/outcome/plot_8.png",
      "../07_display_figures/output/slam_c1-c10_age_fhet3_bwfatgluc/outcome/plot_11.png",
      "../07_display_figures/output/slam_c1-c10_age_fhet3_bwfatgluc/outcome/plot_3.png",
      "../07_display_figures/output/slam_c1-c10_age_fhet3_bwfatgluc/outcome/plot_6.png",
      "../07_display_figures/output/slam_c1-c10_age_fhet3_bwfatgluc/outcome/plot_9.png",
      "../07_display_figures/output/slam_c1-c10_age_fhet3_bwfatgluc/outcome/plot_12.png",
      "images/Basic LCM.png",
      "../99_pub_ready_figs/output/tables/hr_fhet3.png"
    )
  ),
  list(
    part  = "supplemental",
    title = "Defining Metabolic Classes - Male B6",
    panels = c(
      "../07_display_figures/output/slam_c1-c10_age_mb6_bwfatgluc/outcome/plot_1.png",
      "../07_display_figures/output/slam_c1-c10_age_mb6_bwfatgluc/outcome/plot_4.png",
      "../07_display_figures/output/slam_c1-c10_age_mb6_bwfatgluc/outcome/plot_7.png",
      "../07_display_figures/output/slam_c1-c10_age_mb6_bwfatgluc/outcome/plot_10.png",
      "../07_display_figures/output/slam_c1-c10_age_mb6_bwfatgluc/outcome/plot_2.png",
      "../07_display_figures/output/slam_c1-c10_age_mb6_bwfatgluc/outcome/plot_5.png",
      "../07_display_figures/output/slam_c1-c10_age_mb6_bwfatgluc/outcome/plot_8.png",
      "../07_display_figures/output/slam_c1-c10_age_mb6_bwfatgluc/outcome/plot_11.png",
      "../07_display_figures/output/slam_c1-c10_age_mb6_bwfatgluc/outcome/plot_3.png",
      "../07_display_figures/output/slam_c1-c10_age_mb6_bwfatgluc/outcome/plot_6.png",
      "../07_display_figures/output/slam_c1-c10_age_mb6_bwfatgluc/outcome/plot_9.png",
      "../07_display_figures/output/slam_c1-c10_age_mb6_bwfatgluc/outcome/plot_12.png",
      "images/Basic LCM.png",
      "../99_pub_ready_figs/output/tables/hr_mb6.png"
    )
  ),
  list(
    part  = "supplemental",
    title = "Defining Metabolic Classes - Male HET3",
    panels = c(
      "../07_display_figures/output/slam_c1-c10_age_mhet3_bwfatgluc/outcome/plot_1.png",
      "../07_display_figures/output/slam_c1-c10_age_mhet3_bwfatgluc/outcome/plot_4.png",
      "../07_display_figures/output/slam_c1-c10_age_mhet3_bwfatgluc/outcome/plot_7.png",
      "../07_display_figures/output/slam_c1-c10_age_mhet3_bwfatgluc/outcome/plot_10.png",
      "../07_display_figures/output/slam_c1-c10_age_mhet3_bwfatgluc/outcome/plot_2.png",
      "../07_display_figures/output/slam_c1-c10_age_mhet3_bwfatgluc/outcome/plot_5.png",
      "../07_display_figures/output/slam_c1-c10_age_mhet3_bwfatgluc/outcome/plot_8.png",
      "../07_display_figures/output/slam_c1-c10_age_mhet3_bwfatgluc/outcome/plot_11.png",
      "../07_display_figures/output/slam_c1-c10_age_mhet3_bwfatgluc/outcome/plot_3.png",
      "../07_display_figures/output/slam_c1-c10_age_mhet3_bwfatgluc/outcome/plot_6.png",
      "../07_display_figures/output/slam_c1-c10_age_mhet3_bwfatgluc/outcome/plot_9.png",
      "../07_display_figures/output/slam_c1-c10_age_mhet3_bwfatgluc/outcome/plot_12.png",
      "images/Basic LCM.png",
      "../99_pub_ready_figs/output/tables/hr_mhet3.png"
    )
  ),
  list(
    part  = "supplemental",
    title = "Internal Validation KM",
    panels = c(
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/km_combined_hr_validation/plot_[6.5, 19.5]_1.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/km_combined_hr_validation/plot_[6.5, 32.5]_2.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/km_combined_hr_validation/plot_[6.5, 45.5]_3.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/km_combined_hr_validation/plot_[6.5, 58.5]_4.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/km_combined_hr_validation/plot_[6.5, 71.5]_5.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/km_combined_hr_validation/plot_[6.5, 84.5]_6.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/km_combined_hr_validation/plot_[6.5, 97.5]_7.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/km_combined_hr_validation/plot_[6.5, 110.5]_8.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/km_combined_hr_validation/plot_[6.5, 123.5]_9.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/km_combined_hr_validation/plot_[6.5, 136.5]_10.png",
      "../99_pub_ready_figs/output/tables/hr_km_internal.png"
    )
  ),
  list(
    part  = "supplemental",
    title = "Healthcard Supplemental 1",
    panels = c(
      "images/HC Suppl 1.jpg"
    )
  ),
  list(
    part  = "supplemental",
    title = "Healthcard Supplemental 2",
    panels = c(
      "images/HC Suppl 2.jpg"
    )
  ),
  list(
    part  = "supplemental",
    title = "Healthcard Supplemental 3",
    panels = c(
      "images/HC Suppl 3.jpg"
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

      tab_no <- 1 + tab_no
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

      tab_no <- 1 + tab_no
    }
  ),
  list(
    part   = "supplemental",
    title  = "Sex/Strain Adjusted Hazards",
    render = "png",
    build  = function() {
      flextable(all_env$save_figtabs$hr_table) %>%
        theme_vanilla() %>%
        autofit() %>%
        set_table_properties(layout = "autofit") %>%
        fit_to_width(max_width = max_width, inc = .25, max_iter = 100)


      tab_no <- 1 + tab_no
    }
  ),
  list(
    part   = "supplemental",
    title  = "Linear Mixed Effects Models",
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

      lme_coef_table[[1]]
      lme_coef_table[[2]]
      lme_coef_table[[3]]

      tab_no <- 1 + tab_no
    }
  ),
  list(
    part   = "supplemental",
    title  = "Descriptive Statistics SLAM C1-C10 datasets",
    render = "inline",
    build  = function() {
      flextable(rbind(
        all_env$save_figtabs$sum_data,
        all_env$save_figtabs$sum_test
      )) %>%
        theme_vanilla() %>%
        autofit() %>%
        set_table_properties(layout = "autofit") %>%
        fit_to_width(max_width = max_width, inc = .25, max_iter = 100)

      tab_no <- 1 + tab_no
    }
  ),
  list(
    part   = "supplemental",
    title  = "Median Life Expectancy Data",
    render = "inline",
    build  = function() {
      flextable(all_env$save_figtabs$table_mle) %>%
        theme_vanilla() %>%
        autofit() %>%
        set_table_properties(layout = "autofit") %>%
        fit_to_width(max_width = max_width, inc = .25, max_iter = 100)

      tab_no <- 1 + tab_no
    }
  ),
  list(
    part   = "supplemental",
    title  = "LCM Model Information",
    render = "inline",
    build  = function() {
      all_env$save_figtabs$lcmm_table %>%
        dplyr::rename(`Smallest Class %` = `Smallest.Class....`) %>%
        dplyr::mutate(`Smallest Class %` = round(`Smallest Class %`, digits = 3)) %>%
        flextable() %>%
        theme_vanilla() %>%
        autofit() %>%
        set_table_properties(layout = "autofit") %>%
        fit_to_width(max_width = max_width, inc = .25, max_iter = 100)

      tab_no <- 1 + tab_no
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

      tab_no <- 1 + tab_no
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

      tab_no <- 1 + tab_no
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


      tab_no <- 1 + tab_no
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

      tab_no <- 1 + tab_no
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


      tab_no <- 1 + tab_no
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

      tab_no <- 1 + tab_no
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


      tab_no <- 1 + tab_no
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

      tab_no <- 1 + tab_no
    }
  )
)
