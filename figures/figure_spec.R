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
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/dose_response/plot_1.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/dose_response/plot_4.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/dose_response/plot_7.png",
      "images/Basic LCM.png",
      "images/Graded Mortality.png"
    )
  ),
  list(
    part  = "primary",
    title = "Held Out Cohort Validation",
    panels = c(
      "images/External Validation.png",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/forest/plot_5.png",
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_combined_hr_validation/plot_[6.5, 58.5]_4.png",
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_combined_hr_validation/plot_[6.5, 84.5]_6.png",
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_combined_hr_validation/plot_[6.5, 110.5]_8.png",
      "../07_display_figures/output/slam_c1-10_x_slam_c16-18_age_bwfatgluc/km_combined_hr_validation/plot_[6.5, 136.5]_10.png"
    )
  ),
  list(
    part  = "primary",
    title = "ITP Validation",
    panels = c(
      "../07_display_figures/output/itp_c10c11c13c16_age_controls_bw/outcome/plot_1.png",
      "../07_display_figures/output/itp_c10c11c13c16_age_controls_bw/outcome/plot_2.png",
      "../99_pub_ready_figs/output/tables/hr_itp.png",
      "images/ITP Treatment.png",
      "../97_treatment_response/output/treatment_response/plot_1.png",
      "../97_treatment_response/output/treatment_response/plot_2.png",
      "../97_treatment_response/output/treatment_response/plot_3.png",
      "../99_pub_ready_figs/output/tables/hr_treatment.png"
    )
  ),
  list(
    part  = "supplemental",
    title = "Sex/Strain Classes FM",
    panels = c(
      "../99_pub_ready_figs/output/fb6_env/define_class/fat_by_fat.png",
      "../99_pub_ready_figs/output/fb6_env/define_class/km_fat.png",
      "../99_pub_ready_figs/output/mb6_env/define_class/fat_by_fat.png",
      "../99_pub_ready_figs/output/mb6_env/define_class/km_fat.png",
      "../99_pub_ready_figs/output/fhet3_env/define_class/fat_by_fat.png",
      "../99_pub_ready_figs/output/fhet3_env/define_class/km_fat.png",
      "../99_pub_ready_figs/output/mhet3_env/define_class/fat_by_fat.png",
      "../99_pub_ready_figs/output/mhet3_env/define_class/km_fat.png",
      "../99_pub_ready_figs/output/tables/hr_sexstrain_fat.png"
    )
  ),
  list(
    part  = "supplemental",
    title = "Sex/Strain Classes FBG",
    panels = c(
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
    title = "Heatmaps",
    panels = c(
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/heatmap/heatmap2.jpg",
      "../07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/heatmap/heatmap1.jpg",
      "../91_partial_correlation/output/partial_correlation_network.jpg",
      "../91_partial_correlation/output/partial_correlation_results_clean_table.png"
    )
  ),
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
