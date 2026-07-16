#' Sample variable at 3 month intervals
#'
#' Purpose: Take the closest measurement to three month intervals
#'
#' @param data the dataframe that we would like to sample from
#' @param age_var the age variable that we would like to use to sample. This
#' variable should be in the units weeks.
#' @param interval the number of months that we would like to sample
#' @return a dataframe with the column
#'
#' @author William Mueller

sample_monthwise <- function(data, age_var, interval, id) {

  data[, "age_m"] <- round(data[, age_var] * 0.230137 / interval) * interval
  data[, "age_wk_m"] <- data$age_m / 0.230137
  data[, "dif"] <- abs(data$age_wk_m - data$age_wk)

  data <- data %>%
    dplyr::group_by(!!sym(id), age_m) %>%
    dplyr::mutate(min_dif = min(dif)) %>%
    dplyr::ungroup() %>%
    dplyr::filter(dif == min_dif)

  data

}

