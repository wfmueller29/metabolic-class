# Purpose: Create dataframe from boostrapped accuracy within single type of
# missing data simulatin
# Author: William Mueller
combine_boot_accuracies <- function(boot_accuracy_lol) {
  lapply(boot_accuracy_lol, function(boot_accuracy_list) {
    names <- names(boot_accuracy_list)
    df <- data.frame(dataset = names)
    df$boot_accuracy <- boot_accuracy_list
    df
  })
}
