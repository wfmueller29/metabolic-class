#* Setup
  #+ Set paths and import
  census_path <- "/Users/jdp2019/Library/CloudStorage/Box-Box/metabolic-class-ITP/95_healthcard_cod/data/census.csv"
  class_census_path <- "/Users/jdp2019/Library/CloudStorage/Box-Box/metabolic-class-ITP/95_healthcard_cod/data/20250426_all_cohort/complete_census.csv"
  healthcard_path <- "/Users/jdp2019/Library/CloudStorage/Box-Box/metabolic-class-ITP/95_healthcard_cod/data/SLAM Healthcard reconciled.xlsx"

  class_census <- read.csv(class_census_path)
  census <- read.csv(census_path)
  healthcard_ii <- as.data.frame(readxl::read_xlsx(healthcard_path, sheet = "Healthcard"))
  census <- consoler::rename(census, c(animal_id = "Animal_ID", tag_history = "taghistory"))
  #+ Clean Healthcard
    new_names <- c(
      tag = "Tag", dod = "Date of Death",
      created_date = "Created Date",
      recovery_date = "Recovery Date",
      condition = "Condition",
      idno_rec = "idno"
    )
    healthcard_i <- consoler::rename(healthcard_ii, new_names) %>% # trim whitespace
      mutate(condition = str_trim(condition))
    condition_mappings <- tibble::tribble(
      ~canonical_name, ~aliases,
      "fighting", c("Fighting", "fighting"),
      "dermatitis", c("Dermatitis", "Skin Reaction", "Red Skin"),
      "alopecia", c("Alopecia/Barbering"),
      "trauma", c("traumatic injury", "Tramatic Injury", "Traumatic Injury"),
      "dehydration", c("Dehydrated", "Dehydration"),
      "seizure", c("Seizure"),
      "edema", c("Swelling", "Swollen Feet", "edema", "Edema", "Swollen Hindfoot"),
      "flood", c("Flooded Cage", "cage flood", "Cage Flood"),
      "mass", c("Mass", "mass", "Mass (size in mm)", "Mass "),
      "prolapse", c("Prolapse", "prolapse", "Prolapse (rectal/genital)", "Prolapsed Penis", "Rectal Prolapse", "Prolapse ", "Penile Prolapse", "prolpase"),
      "lesion", c("Lesion", "lesion", "Lesions"),
      "weight_loss", c("Weight Loss", "weight loss", "Losing Weight"),
      "bleed", c("Bleeding", "Rectal Bleeding", "Nose Bleeding", "bleeding", "Vaginal Bleeding"),
      "irritation", c("Irritation"),
      "lethargy", c("Lethargy", "lethargy", "Lethargic", "Slow Moving"),
      "hunch", c("Hunched Posture", "Thin/Hunched"),
      "dyspnea", c("Dyspnea", "dyspnea", "Dyspnea ", "Increased RR", "Dyspnea (Labored Breathing)"),
      "distented_abdomen", c("Distended Abdomen"),
      "abscess", c("Abscess"),
      "paralysis", c("Paralysis", "paralysis"),
      "eye_problem", c("Eye Problem", "eye problem", "Eye Issue"),
      "ear_problem", c("Ear Problem", "Ear Problems"),
      "head_tilt", c("Head Tilt", "head tilt"),
      "discharge", c("Discharge", "Vaginal Discharge"),
      "moribund", c("Moribund", "moribund", "Moribund ", "Moribund (near death)"),
      "urinary", c("Urinary Distress", "Urine Staining", "Excessive Urination", "Unable to Urinate", "Discolored Urine", "Cloudy/Tinted Urine"),
      "gait", c("Abnormal Gait", "Unsteady Gait", "Hindlimb Weakness", "Favoring Hindlimb"),
      "malocclusion", c("Malocclusion"),
      "hernia", c("Hernia"),
      "swollen_testicle", c("Swollen Testicle", "Enlarged testicle"),
      "thin", c("Thin"),
      "skin_tag", c("Skin Tag"),
      "hypoglycemic", c("Low Glucose", "hypoglycemic"),
      "cyanotic", c("Cyanotic"),
      "organomegaly", c("Enlarged Organs"),
      "permanent_defect", c("Permanent Defect"),
      "hydrocehpalus", c("Hydrocephalus"),
      "diarrhea", c("Diarrhea"),
      "nutritional_support", c("Nutritional Support"),
      "low_temp", c("Low Temperature", "Low body temperature"),
      "blood_in_cage", c("Blood in Cage"),
      "red_paws", c("Red Paws"),
      "behavior", c("odd behavior"),
      "other", c("Other"),
      "enlarged_bladder", c("enlarged bladder"),
      "tail_issue", c("Tail Issue")
    )
  #+ Rename per above
    for (i in seq_len(nrow(condition_mappings))) {
      row <- condition_mappings[i, ]
      aliases <- unlist(row$aliases)
      canonical_name <- row$canonical_name
      healthcard_i$condition[healthcard_i$condition %in% aliases] <- canonical_name
    }
  #+ Verify the remapping
    mapped_conditions <- unlist(condition_mappings$aliases, use.names = FALSE) %>% trimws()
    unique_conditions <- unique(healthcard_i$condition) %>% trimws()
    unmapped <- setdiff(unique_conditions, condition_mappings$canonical_name)
    if (length(unmapped) > 0) {
      message("⚠️ Unmapped conditions found:")
      print(unmapped)
    } else {
      message("✅ All conditions are mapped correctly.")
    }
  #+ Convert to dummy columns
    healthcard <- fastDummies::dummy_cols(healthcard_i, "condition",
      omit_colname_prefix = TRUE
    ) %>%
    filter(idno_rec != 154) # Filter out this mouse because in the HC reconcile this was report was created by accident on wrong mouse
  #+ Merge with census
    healthcard_final <- as_tibble(merge(census, healthcard, by = "tag", all.y = TRUE)) %>%
      select(idno, idno_rec, everything(), -c(Comments, name, cage, eartag, "Created By", "Entered By"))
  #+ Clean up and pare HC
    HC_relevant <- healthcard_final %>%
      select(idno_rec, created_date, recovery_date, abscess:weight_loss) %>%
      dplyr::rename(idno = idno_rec) %>%
      mutate(recovery_date = as.Date(recovery_date)) %>%
      mutate(created_date = as.Date(as.numeric(created_date), origin = "1899-12-30"))
  #+ Get a count of each mouses number of HCs
    hc_counts <- HC_relevant %>%
      count(idno, name = "num_HC")
  #+ Now assign the counts and HCs to the full class census
    classes_i <- as_tibble(class_census) %>%
      mutate(any_HC = if_else(idno %in% HC_relevant$idno, 1, 0)) %>%
      left_join(HC_relevant, by = "idno") %>%
      left_join(hc_counts, by = "idno") %>%
      mutate(num_HC = replace_na(num_HC, 0)) %>%
      arrange(desc(num_HC)) %>%
      mutate(
        tod = as.Date(tod), # ensure `tod` is Date class
        condition_length = as.integer(coalesce(recovery_date, tod) - created_date),
        condition_to_death = as.integer(tod - created_date)
      )
  #+ Pare this down to get a tibble for prevalence analysis
    classes_prevalence <- classes_i %>%
      select(idno,num_HC, abscess:weight_loss) %>%
      mutate(across(abscess:weight_loss, ~ replace_na(.x, 0))) %>%
      arrange(num_HC) %>%
      mutate(no_lifetime_HC = if_else(num_HC == 0, 1, 0))
#* Grouping and prevalence
  #+ Prevalence of all conditions
    condition_counts_all <- classes_prevalence %>%
      select(-c(idno,num_HC,no_lifetime_HC)) %>%
      summarise(across(everything(), ~ sum(.))) %>%
      pivot_longer(everything(), names_to = "condition", values_to = "count") %>%
      mutate(pct_of_HCs = count / nrow(healthcard) * 100) %>%
      arrange(desc(count)) %>%
      filter(pct_of_HCs > 0)
    ggplot(condition_counts_all, aes(x = reorder(condition, -pct_of_HCs), y = pct_of_HCs)) +
      geom_bar(stat = "identity", fill = "steelblue", width = 0.8) +
      coord_flip() +
      labs(
        title = "Prevalence of Health Conditions",
        x = "Condition",
        y = "Percentage of Total Health Conditions (%)"
      ) +
      theme_minimal(base_size = 13) +
      theme(axis.text.y = element_text(face = "bold"))
  #+ Grouping conditions
    condition_counts_all_grouped <- condition_counts_all %>%
      mutate(
        condition_group = case_when(
          condition %in% c(
            "fighting", "trauma", "bleed", "flood",
            "blood_in_cage"
          ) ~ "Traumatic/Incidental",
          condition %in% c(
            "dermatitis", "eye_problem",
            "malocclusion", "permanent_defect","alopecia"
          ) ~ "Chronic",
          condition %in% c(
            "swollen_testicle", "ear_problem", "distented_abdomen", "dyspnea",
            "discharge", "abscess", "lesion", "seizure", "cyanotic",
            "paralysis", "hypoglycemic", "dehydration", "low_temp","diarrhea"
          ) ~ "Acute or Transient",
          condition %in% c(
            "hunch", "head_tilt", "lethargy", "nutritional_support",
            "gait", "thin", "skin_tag", "hydrocehpalus","behavior", "red_paws",
            "edema", "mass", "moribund", "prolapse", "urinary", "weight_loss"
          ) ~ "Age-Related Degeneration",
          TRUE ~ "Uncategorized"
        )
      ) %>%
      arrange(condition_group)
#+ Visualize grouping numbers
# Grouping
condition_counts_graph <- condition_counts_all_grouped %>%
  group_by(condition_group) %>%
  arrange(desc(count), .by_group = TRUE) %>%
  ungroup()
# Define custom colors for each condition group
group_colors <- c(
  "Acute or Transient" = "#4db8ff",
  "Age-Related Degeneration" = "#ffa64d",
  "Chronic" = "#99cc33",
  "Traumatic/Incidental" = "#ff6666"
)
condition_counts_all_ordered <- condition_counts_graph %>%
  group_by(condition_group) %>%
  arrange(desc(count), .by_group = TRUE) %>%
  mutate(condition = factor(condition, levels = unique(condition))) %>%
  ungroup()
ggplot(condition_counts_all_ordered, aes(
  y = condition,
  x = count,
  fill = condition_group
)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = group_colors, name = "Condition Group") +
  labs(y = "Condition", x = "Count") +
  theme_minimal(base_family = "Arial") +
  theme(
    axis.title.x = element_text(size = 16, face = "bold"),
    axis.title.y = element_text(size = 16, face = "bold"),
    axis.text.y = element_text(size = 10, hjust = 1, vjust = 0.5),
    axis.text.x = element_text(size = 14),
    legend.title = element_text(size = 14, face = "bold"),
    legend.text = element_text(size = 12),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank()
  )
