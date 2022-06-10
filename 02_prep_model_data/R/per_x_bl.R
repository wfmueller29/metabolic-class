create_bl <- function(df, id, age_var, var, cutoff) {
  ## Create wave variable
  df_wave <- df %>%
    group_by(!!sym(id)) %>%
    arrange(!!sym(age_var)) %>%
    mutate(wave = row_number()) %>%
    ungroup()

  ## histogram of age_wk of first measurment before cutoff
  hist(filter(df_wave, wave == 1)[[age_var]])

  df_wave <- df_wave %>%
    # if first measurement is before 20 weeks, bl
    mutate(bl = ifelse(wave == 1 & !!sym(age_var) <= cutoff, 1,
      # if first measuremnent is after 20 weeks, not baseline
      ifelse(wave == 1 & !!sym(age_var) > cutoff, 0,
        ifelse(wave != 1, NA, NA)
      )
    )) # if not first measurement NA

  # histogram of age_wk of first measurment after cutoff
  hist(filter(df_wave, bl == 1)[[age_var]])

  df_wave_keep_idno <- df_wave %>%
    filter(bl == 1) %>%
    select(idno, var, age_var) %>%
    rename("{var}_bl" := var, "{var}_bl_age" := age_var)
  df_wave <- df_wave_keep_idno %>%
    left_join(df_wave, by = id)

  return(df_wave)
}

## this function creates new column var_per_x_bl given a df, var, bl, and wave
per_x_bl <- function(df, id, var, bl_name, wave) {
  df <- df %>%
    group_by(!!sym(id)) %>%
    mutate("{var}_per_x_bl" := ifelse(!!sym(wave) == 1,
      0,
      (!!sym(var) - !!sym(bl_name)) / !!sym(bl_name)
    ) * 100)
  return(df)
}
