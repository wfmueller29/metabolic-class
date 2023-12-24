# Purpose: Function that creates 4 variables, percentage change in outcome,
# delta in outcome, delta in age, and outcome veloctiy
# Author: William Mueller
per_change <- function(df, var, age_var, id) {
  var_sym <- as.symbol(var)
  var_delta_sym <- as.symbol(paste0(var, "_delta"))
  age_delta_sym <- as.symbol(paste0(age_var, "_delta"))
  df <- df %>%
    group_by(!!sym(id)) %>%
    arrange(!!sym(age_var), .by_group = TRUE) %>%
    mutate("{var}_perx" := (eval(var_sym) / lag(eval(var_sym)) - 1) * 100) %>%
    mutate("{var}_delta" := eval(var_sym) - lag(eval(var_sym)))  %>%
    mutate("{age_var}_delta" := !!sym(age_var) - lag(!!sym(age_var))) %>%
    mutate("{var}_velocity" := eval(var_delta_sym) / eval(age_delta_sym)) %>%
    ungroup()
}

#' Remove outliers base upon rate of change of outcome
#'
#' Given a dataframe, variable, age variable, subject id, and threshold, we
#' will remove outliers base upon the rate of change between measurements
#' within a subject
#'
#' @param df a dataframe
#' @param var a string designating the varaible that we would like to remove
#' outliers based upon velocity.
#' @param age_var a string designating the age variable used to calculate the
#' velocity measurement
#' @param id a string denoting the name of the subject identifier
#' @param threshold a numeric that gives the threshold for the rate of change
#' in the measurment. The units are in var/age_var
#'
#' @return a dataframe with observations removed based upon rate of change of
#' the var.

remove_velocity_outliers <- function(df, var, age_var, id, threshold) {

  velocity_var <- paste0(var, "_velocity")

  df <- per_change(df, var, age_var, id)

  df <- df %>%
    mutate(threshold = ifelse(abs(!!sym(velocity_var)) > threshold, 1, 0)) %>%
    filter(threshold != 1) %>%
    as.data.frame()

  df

}

