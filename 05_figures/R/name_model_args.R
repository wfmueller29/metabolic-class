# Purpose to name the arguments of each model call
# Author: William Mueller

final_models <- final_models %>%
  mutate(oc_name = ifelse(oc == "bw", "Body Weight",
    ifelse(oc == "gluc", "Glucose",
      ifelse(oc == "fat", "Body Fat",
        ifelse(oc == "lean", "Lean Mass",
          ifelse(oc == "bw_per_x_bl30", "Body Weight PXB", NA)
        )
      )
    )
  )) %>%
  mutate(oc_units = ifelse(oc == "bw" | oc == "fat" | oc == "lean", "(g)",
    ifelse(oc == "gluc", "(mg/dL)",
      ifelse(oc == "bw_per_x_bl30", "(% change)", NA)
    )
  )) %>%
  mutate(age_var_name = ifelse(age_var == "age_wk", "Age",
    ifelse(age_var == "per_age_wk", "Relative Age", NA)
  )) %>%
  mutate(age_var_units = ifelse(age_var == "age_wk", "(weeks)",
    ifelse(age_var == "per_age_wk", "(%)", NA)
  ))

final_models$xvout <- grepl(pattern = "_xvout", x = final_models$data)

final_models <- final_models %>%
  mutate(data_name = ifelse(xvout == TRUE, paste(oc_name,
    "Velocity Outliers Removed",
    sep = " "
  ),
  oc_name
  ))
