# conduct strain analysis
# Author: William Mueller

library(yaml)
library(lmerTest)
library(lcmm)
library(consoler)

# Read all data
all_yaml <- yaml::read_yaml("../../pipeline/06_create_figures/output/slam_c1-c10_age_all_bwfatgluc.yaml")
load("../../pipeline/07_display_figures/output/slam_c1-c10_age_all_bwfatgluc/workspace.RDATA")
load(all_yaml$final_models_path)
all_final_models <- final_models

# Read b6 data
b6_yaml <- yaml::read_yaml("../../pipeline/06_create_figures/output/slam_c1-c10_age_b6_bwfatgluc.yaml")
load("../../pipeline/07_display_figures/output/slam_c1-c10_age_b6_bwfatgluc/workspace.RDATA")
load(b6_yaml$final_models_path)
b6_final_models <- final_models

# Read het3 data
het3_yaml <- yaml::read_yaml("../../pipeline/06_create_figures/output/slam_c1-c10_age_het3_bwfatgluc.yaml")
load("../../pipeline/07_display_figures/output/slam_c1-c10_age_het3_bwfatgluc/workspace.RDATA")
load(het3_yaml$final_models_path)
het3_final_models <- final_models
rm(final_models)


b6_bw_final_model <- b6_final_models$final_model[[1]]
fixcov <- b6_final_models$fixcov[[1]]
data <- b6_final_models$dfs[[1]]
b6_bw_final_model$data <- b6_final_models$dfs[[1]]

plot(b6_bw_final_model, lty = 2, lwd = 2, type = "l", col = 1:2, var.time = "age_wk")


df <- data
mo <- b6_bw_final_model
age_var <- "age_wk"
y_var <- "bw"
age_vars <- c(age_var, paste0(age_var, 2))

fixcov_names <- b6_final_models$fixcov[[1]]
fixcov <- rep(0, length(b6_final_models$fixcov[[1]]))
names(fixcov) <- fixcov_names

traj_plot <- function(df,
                      mo,
                      age_var,
                      fixcov,
                      y_var,
                      draws = FALSE,
                      title = " ",
                      xlab = " ",
                      ylab = " ") {
  ## Create legend using create_legend function

  ## Create Prediction DF using lcpred
  pred <- helphlme::create_pred_df(
    df = df,
    age_vars = c(age_var, paste0(age_var, 2)),
    fixcov = fixcov
  )

  # Determine ymax by maximum predicted value
  predY <- lcmm::predictY(mo, pred, var.time = paste0(age_var, "_ns"), draws = draws)
  ymax <- max(predY$pred)

  # Determine ymin by either taking minimum predicted value or
  # minimum absoluate value
  abs_min <- min(df[[y_var]])
  pred_min <- min(predY$pred)
  if (pred_min <= abs_min) {
    ymin <- abs_min
  } else {
    ymin <- pred_min
  }

  ## Set graphical parameters
  par(mar = c(4, 4, 2, 2), mgp = c(2, 1, 0))

  ## Create Plot
  helphlme::plot_hlme(
    df = pred,
    model = mo,
    age = age_var,
    lwd = 3,
    lty = c(1, 1),
    main = title,
    xlab = xlab,
    ylab = ylab,
    cex = .7,
    ylim = c(ymin, 1.1 * ymax),
    legend = NULL
  )
  lines(df$age_wk_ns, pred$pred_2.5, col = "blue", lty = 2)
  lines(df$age_wk_ns, pred$pred_97.5, col = "blue", lty = 2)
}


traj_plot(
  df = data,
  mo = b6_bw_final_model,
  age_var = "age_wk",
  fixcov = fixcov, y_var = "bw"
)


helphlme::hlme2()
