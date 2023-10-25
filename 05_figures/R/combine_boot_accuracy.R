# Purpose: Create dataframe from boostrapped accuracy within single type of
# missing data simulatin
# Author: William Mueller
combine_boot_accuracy <- function(boot_accuracy_list) {
  names <- names(boot_accuracy_list)
  df <- data.frame(dataset = names)
  df$boot_accuracy <- boot_accuracy_list
  df
}

combine_boot_accuracy_list <- function(boot_accuracy_list_list) {
  lapply(boot_accuracy_list_list,
         combine_boot_accuracy)

}
