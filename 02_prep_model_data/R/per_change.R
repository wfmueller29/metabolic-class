# Purpose: Function that creates 4 variables, percentage change in outcome,
# delta in outcome, delta in age, and outcome veloctiy
# Author: William Mueller
per_change <- function(df, var) {
  var_sym <- as.symbol(var)
  var_delta_sym <- as.symbol(paste0(var, "_delta"))
  df <- df %>%
    group_by(idno) %>%
    arrange(age_wk, .by_group = TRUE) %>%
    mutate("{var}_perx" := (eval(var_sym) / lag(eval(var_sym)) - 1) * 100) %>%
    mutate("{var}_delta" := eval(var_sym) - lag(eval(var_sym)))  %>%
    mutate(age_delta = age_wk - lag(age_wk)) %>%
    mutate("{var}_velocity" := eval(var_delta_sym) / age_delta) %>%
    ungroup()
}
