# Figures ---------------------------------------------------------------------
setwd("99_pub_ready_figs/")
ecode <- system2("Rscript", "pub_ready_figs.R")
if (ecode != 0) stop(paste("Error in pub_ready_figs.R"))
setwd("..")

rmarkdown::render("figures/final_figure_deck.Rmd")
