
.make_wave <- function(data, id, age_var) {
  data <- data %>%
    dplyr::group_by(!!sym(id)) %>%
    dplyr::arrange(!!sym(age_var)) %>%
    dplyr::mutate(wave = dplyr::row_number()) %>%
    dplyr::mutate(dif_time = !!sym(age_var) - lag(!!sym(age_var))) %>%
    dplyr::ungroup() %>%
    as.data.frame()
  
  data
}

.resample_frequency <- function(data, id, age_var, fraction) {
 data <- .make_wave(data, id, age_var) 
 average_dif <- mean(data$dif_time, na.rm = TRUE)
 average_start <- mean(data[data$wave == 1, age_var])
 new_dif <- average_dif / fraction
 
 print(paste0("Average frequency: ", as.character(average_dif)))
 print(paste0("Average start: ", as.character(average_start)))
 
 # we need to make new time unit such that the average start is zero and the 
 # conversion is the new_dif. This way we can round our measurements to the 
 # new_time integer and remove duplicates with the same new time integer. This
 # is a crafty way to resample our data based on some fraction of our current
 # sampling frequency
 
 data <- data %>%
   mutate(new_time = (!!sym(age_var) - average_start) / new_dif ) %>%
   mutate(round_new_time = round(new_time)) %>%
   mutate(dif_round_new = abs(new_time - round_new_time)) %>%
   group_by(!!sym(id)) %>%
   arrange(dif_round_new) %>%
   distinct(round_new_time, .keep_all = TRUE) %>%
   ungroup() %>%
   as.data.frame()
 
 data
 
}

.resample_frequency_across <- function(data, id, age_var, fraction_vector) {
  
  subset_data_list <- list()
  for (fraction in fraction_vector) {
    new_name <- as.character(fraction)
    new_names <- c(names(subset_data_list), new_name)
    
    new_data <- .resample_frequency(data, id, age_var, fraction)
    
    subset_data_list <- c(subset_data_list, list(new_data))
    names(subset_data_list) <- new_names
  }
  
  subset_data_list
}

.resample_frequency_across_apply <- function(data_list,
                                             id, 
                                             age_var,
                                             fraction_vector) {
  data_list <- lapply(data_list,
                      .resample_frequency_across, 
                      id = id, 
                      age_var = age_var,
                      fraction_vector = fraction_vector)
  
  data_list
}

resample_frequency <- function(data_list, id, age_var, fraction_vector) {
  .resample_frequency_across_apply(data_list, id, age_var, fraction_vector)
}

# make these for datasets -----------------------------------------------------

.resample_frequency_across_dataset <- function(dataset, fraction_vector) {
  data <- dataset$data
  id <- dataset$id
  age_var <- dataset$prediction_data$resample$age_var
  fraction_vector <- dataset$prediction_data$resample$fraction_vector
  if (length(age_var) > 1) {
    age_var <- age_var[1]
  }
  dataset$resampled_data <- .resample_frequency_across(data,
                                                       id,
                                                       age_var,
                                                       fraction_vector)
  
  dataset
  
}

.resample_frequency_across_dataset_apply <- function(datasets) {
  datasets <- lapply(datasets, .resample_frequency_across_dataset)
  datasets
}

resample_frequency_dataset <- function(datasets) {
  datasets <- .resample_frequency_across_dataset_apply(datasets)
  
  datasets
}
