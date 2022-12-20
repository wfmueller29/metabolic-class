#' Creates a Percent Change from Baseline column
#'
#' Given a dataframe, variable, age variable, subject id, target baseline,
#' lower bound for baseline, and upper bound for baseline, this function will
#' create a percent change from baseline variable. As well as remove any
#' individuals from the dataframe that do not have a baseline measurement
#' according to the criteria lower, upper, and target.
#'
#' @param df is the dataframe
#' @param var is the variable that we are going to create a percent chagne from
#' baseline. This should be a string.
#' @param age_var is the age variable. This should be a string.
#' @param id is the subject identifier. This should be a string.
#' @param target the ideal age for the baseline measurement. A numeric
#' @param lower the lower bound for the baseline measurement. A numeric.
#' @param upper the upper bound for the baseline measurement. A numeric.
#' @param keep_before a boolean indicating whether values before baseline
#' should be included
#'
#' @return a dataframe with a new percent change from baseline variable
#'
#' @author William Mueller
#'
#'


percent_change_baseline <- function(df,
                                    var,
                                    age_var,
                                    id,
                                    target,
                                    lower,
                                    upper,
                                    keep_before) {
  # 1. we need to order the observations for each subject by distance from
  # the target baseline

  df <- df %>%
    mutate(dif_target = abs(!!sym(age_var) - target)) %>%
    group_by(!!sym(id)) %>%
    arrange(!!sym(id), dif_target)

  # 2. we need set the measurment closest to the target time as the baseline
  # and store the values of age and outcome variable at baseline

  df <- df %>%
    mutate(baseline = ifelse(dif_target == min(dif_target), 1, 0)) %>%
    mutate(
      baseline_age = first(!!sym(age_var)),
      baseline_outcome = first(!!sym(var))
    )

  # 3. either keep or remove measurements before baseline

  if (!keep_before) {
    df <- df %>%
      filter(!!sym(age_var) > baseline_age)
  }

  # 4. we need lower and upper bounds on measurements that can be considered
  # baseline. Remove any observations where baseline age is outside the range
  # set by the lower and upper bounds for baseline.

  df <- df %>%
    filter(baseline_age > lower) %>%
    filter(baseline_age < upper)

  # 6. given this new baseline measurement we need to calculate the percent
  # change from baseline for variable

  df <- df %>%
    mutate(pbx = (!!sym(var) - baseline_outcome) / baseline_outcome * 100) %>%
    rename("{var}_percent_change_baseline" := pbx) %>%
    ungroup() %>%
    as.data.frame()

  # return df

  df
}
