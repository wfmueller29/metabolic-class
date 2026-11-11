# We are going to jointly model survival and our outcome variables
#   as a sensitivity analysis for the manuscript

library(consoler)
library(lcmm)
library(survival)
library(parallel)
library(ggplot2)
library(survminer)
library(cowplot)

# read required data ----------------------------------------------------------
bw <- read.csv("../00b_dataset_mods/output/slam_c1-c10/data/slam_bw_og.csv")
fat <- read.csv("../00b_dataset_mods/output/slam_c1-c10/data/slam_fat_og.csv")
adiposity <- read.csv("../00b_dataset_mods/output/slam_c1-c10/data/slam_adiposity_og.csv")
gluc <- read.csv("../00b_dataset_mods/output/slam_c1-c10/data/slam_gluc_og.csv")
surv <- read.csv("../00c_survival_data/output/slam_c1-c10/data/main_cat_surv.csv")


# tmerge variables ------------------------------------------------------------
# bw
bw0 <- bw[, c("idno", "age_wk", "bw")]
bw0$idno <- as.integer(bw0$idno)
bw0$age_wk <- as.numeric(bw0$age_wk)
bw0$bw <- as.numeric(bw0$bw)
bw_covars <- unique(bw[, c("idno", "sex_M", "strain_HET3")])

bw_tm <- tmerge(
  data1 = surv,
  data2 = surv,
  id = idno,
  death = event(le_wk, dead_censor)
)

bw_tm <- tmerge(
  data1 = bw_tm,
  data2 = bw0,
  id = idno,
  bw = tdc(age_wk, bw)
)

bw_tm$age_wk <- bw_tm$tstop
bw_tm$age_wk2 <- bw_tm$age_wk^2

bw_tm <- merge(bw_tm, bw_covars, by = "idno", all.x = TRUE)

bw_tm <- bw_tm[complete.cases(bw_tm[, c(
  "idno", "tstart", "tstop", "death",
  "age_wk", "age_wk2", "bw", "sex_M", "strain_HET3"
)]), ]

# fat
fat0 <- fat[, c("idno", "age_wk", "fat")]
fat0$idno <- as.integer(fat0$idno)
fat0$age_wk <- as.numeric(fat0$age_wk)
fat0$fat <- as.numeric(fat0$fat)
fat_covars <- unique(fat[, c("idno", "sex_M", "strain_HET3")])

fat_tm <- tmerge(
  data1 = surv,
  data2 = surv,
  id = idno,
  death = event(le_wk, dead_censor)
)

fat_tm <- tmerge(
  data1 = fat_tm,
  data2 = fat0,
  id = idno,
  fat = tdc(age_wk, fat)
)

fat_tm$age_wk <- fat_tm$tstop
fat_tm$age_wk2 <- fat_tm$age_wk^2

fat_tm <- merge(fat_tm, fat_covars, by = "idno", all.x = TRUE)

fat_tm <- fat_tm[complete.cases(fat_tm[, c(
  "idno", "tstart", "tstop", "death",
  "age_wk", "age_wk2", "fat", "sex_M", "strain_HET3"
)]), ]

# adiposity
adiposity0 <- adiposity[, c("idno", "age_wk", "adiposity")]
adiposity0$idno <- as.integer(adiposity0$idno)
adiposity0$age_wk <- as.numeric(adiposity0$age_wk)
adiposity0$adiposity <- as.numeric(adiposity0$adiposity)
adiposity_covars <- unique(adiposity[, c("idno", "sex_M", "strain_HET3")])

adiposity_tm <- tmerge(
  data1 = surv,
  data2 = surv,
  id = idno,
  death = event(le_wk, dead_censor)
)

adiposity_tm <- tmerge(
  data1 = adiposity_tm,
  data2 = adiposity0,
  id = idno,
  adiposity = tdc(age_wk, adiposity)
)

adiposity_tm$age_wk <- adiposity_tm$tstop
adiposity_tm$age_wk2 <- adiposity_tm$age_wk^2

adiposity_tm <- merge(adiposity_tm, adiposity_covars, by = "idno", all.x = TRUE)

adiposity_tm <- adiposity_tm[complete.cases(adiposity_tm[, c(
  "idno", "tstart", "tstop", "death",
  "age_wk", "age_wk2", "adiposity", "sex_M", "strain_HET3"
)]), ]

# gluc
gluc0 <- gluc[, c("idno", "age_wk", "gluc")]
gluc0$idno <- as.integer(gluc0$idno)
gluc0$age_wk <- as.numeric(gluc0$age_wk)
gluc0$gluc <- as.numeric(gluc0$gluc)
gluc_covars <- unique(gluc[, c("idno", "sex_M", "strain_HET3")])

gluc_tm <- tmerge(
  data1 = surv,
  data2 = surv,
  id = idno,
  death = event(le_wk, dead_censor)
)

gluc_tm <- tmerge(
  data1 = gluc_tm,
  data2 = gluc0,
  id = idno,
  gluc = tdc(age_wk, gluc)
)

gluc_tm$age_wk <- gluc_tm$tstop
gluc_tm$age_wk2 <- gluc_tm$age_wk^2

gluc_tm <- merge(gluc_tm, gluc_covars, by = "idno", all.x = TRUE)

gluc_tm <- gluc_tm[complete.cases(gluc_tm[, c(
  "idno", "tstart", "tstop", "death",
  "age_wk", "age_wk2", "gluc", "sex_M", "strain_HET3"
)]), ]

# jointly model each ----------------------------------------------------------

# create cluster
n_cores <- 8

cl <- makeCluster(n_cores)

clusterEvalQ(cl, {
  library(lcmm)
  library(survival)
})

# seed the master and the parallel workers so the refit is reproducible
set.seed(94)
clusterSetRNGStream(cl, iseed = 94)

# bw --------------------------------------------------------------------------
# NOTE: BW 1 class model did not converge with random~age_wk + age_wk2
# NOTE: We are going to use just age_wk for the random effect
bw_jm1 <- Jointlcmm(
  fixed = bw ~ age_wk + age_wk2 + sex_M * strain_HET3,
  random = ~age_wk,
  subject = "idno",
  survival = Surv(tstart, tstop, death) ~ 1,
  hazard = "Weibull",
  ng = 1,
  data = bw_tm,
  maxiter = 200
)

bw_jm1$conv

bw_jm3 <- gridsearch(
  rep = 50,
  maxiter = 30,
  minit = bw_jm1,
  cl = cl,
  Jointlcmm(
    fixed = bw ~ age_wk + age_wk2 + sex_M * strain_HET3,
    mixture = ~ age_wk + age_wk2,
    random = ~age_wk,
    subject = "idno",
    survival = Surv(tstart, tstop, death) ~ 1,
    hazard = "Weibull",
    ng = 3,
    data = bw_tm
  )
)

bw_jm3$conv

# fat -------------------------------------------------------------------------
fat_jm1 <- Jointlcmm(
  fixed = fat ~ age_wk + age_wk2 + sex_M * strain_HET3,
  random = ~age_wk,
  subject = "idno",
  survival = Surv(tstart, tstop, death) ~ 1,
  hazard = "Weibull",
  ng = 1,
  data = fat_tm,
  maxiter = 200
)

fat_jm1$conv

fat_jm3 <- gridsearch(
  rep = 50,
  maxiter = 30,
  minit = fat_jm1,
  cl = cl,
  Jointlcmm(
    fixed = fat ~ age_wk + age_wk2 + sex_M * strain_HET3,
    mixture = ~ age_wk + age_wk2,
    random = ~age_wk,
    subject = "idno",
    survival = Surv(tstart, tstop, death) ~ 1,
    hazard = "Weibull",
    ng = 3,
    data = fat_tm
  )
)

fat_jm3$conv

# adiposity -------------------------------------------------------------------
adiposity_jm1 <- Jointlcmm(
  fixed = adiposity ~ age_wk + age_wk2 + sex_M * strain_HET3,
  random = ~age_wk,
  subject = "idno",
  survival = Surv(tstart, tstop, death) ~ 1,
  hazard = "Weibull",
  ng = 1,
  data = adiposity_tm,
  maxiter = 200
)

adiposity_jm1$conv

adiposity_jm3 <- gridsearch(
  rep = 50,
  maxiter = 50,
  minit = adiposity_jm1,
  cl = cl,
  Jointlcmm(
    fixed = adiposity ~ age_wk + age_wk2 + sex_M * strain_HET3,
    mixture = ~age_wk,
    random = ~age_wk,
    subject = "idno",
    survival = Surv(tstart, tstop, death) ~ 1,
    hazard = "Weibull",
    ng = 2,
    data = adiposity_tm
  )
)

adiposity_jm3$conv

# gluc ------------------------------------------------------------------------
gluc_jm1 <- Jointlcmm(
  fixed = gluc ~ age_wk + age_wk2 + sex_M * strain_HET3,
  random = ~age_wk,
  subject = "idno",
  survival = Surv(tstart, tstop, death) ~ 1,
  hazard = "Weibull",
  ng = 1,
  data = gluc_tm,
  maxiter = 200
)

gluc_jm1$conv

gluc_jm3 <- gridsearch(
  rep = 50,
  maxiter = 30,
  minit = gluc_jm1,
  cl = cl,
  Jointlcmm(
    fixed = gluc ~ age_wk + age_wk2 + sex_M * strain_HET3,
    mixture = ~ age_wk + age_wk2,
    random = ~age_wk,
    subject = "idno",
    survival = Surv(tstart, tstop, death) ~ 1,
    hazard = "Weibull",
    ng = 2,
    data = gluc_tm
  )
)

gluc_jm3$conv

# save fitted models ----------------------------------------------------------

dir.create("output", showWarnings = FALSE)
saveRDS(
  list(bw_jm1 = bw_jm1, bw_jm3 = bw_jm3, fat_jm1 = fat_jm1, fat_jm3 = fat_jm3,
       adiposity_jm1 = adiposity_jm1, adiposity_jm3 = adiposity_jm3,
       gluc_jm1 = gluc_jm1, gluc_jm3 = gluc_jm3),
  file.path("output", "models.rds")
)

# reorder class ---------------------------------------------------------------

i <- 0
bw_prob <- bw_jm3$pprob
i <- length(unique(bw_prob$class))
fat_prob <- fat_jm3$pprob
fat_prob$class <- fat_prob$class + i
i <- i + length(unique(fat_prob$class))
adiposity_prob <- adiposity_jm3$pprob
adiposity_prob$class <- adiposity_prob$class + i
i <- i + length(unique(adiposity_prob$class))
gluc_prob <- gluc_jm3$pprob
gluc_prob$class <- gluc_prob$class + i

# line width by class size
n <- ave(bw_prob[["idno"]], bw_prob[["class"]], FUN = length)
bw_prob$n <- 2 * (n / max(n)) + 1
n <- ave(fat_prob[["idno"]], fat_prob[["class"]], FUN = length)
fat_prob$n <- 2 * (n / max(n)) + 1
n <- ave(adiposity_prob[["idno"]], adiposity_prob[["class"]], FUN = length)
adiposity_prob$n <- 2 * (n / max(n)) + 1
n <- ave(gluc_prob[["idno"]], gluc_prob[["class"]], FUN = length)
gluc_prob$n <- 2 * (n / max(n)) + 1

# match class numbers and colors to figure 1
bw_prob$class <- factor(c(2, 3, 1)[bw_prob$class], levels = 1:3,
  labels = c("1 (Early-peak)", "2 (Stable)", "3 (Late-peak)"))
fat_prob$class <- factor(c(5, 6, 4)[fat_prob$class - 3], levels = 4:6,
  labels = c("4 (Early-peak)", "5 (Stable)", "6 (Late-peak)"))
gluc_prob$class <- factor(c(7, 8)[gluc_prob$class - 8], levels = 7:8,
  labels = c("7 (Decline)", "8 (Stable)"))
bw_pal <- c("#000000", "#ff2500", "#a144ff")
fat_pal <- c("#0e33ff", "#00cfd2", "#ff41ff")
gluc_pal <- c("#ff9f23", "#b8b8b8")


# merge  ----------------------------------------------------------------------

bw_class <- merge(bw_tm, bw_prob, by = "idno", all.x = TRUE)
surv_bw_class <- merge(surv, bw_prob, by = "idno", all.x = TRUE)

fat_class <- merge(fat_tm, fat_prob, by = "idno", all.x = TRUE)
surv_fat_class <- merge(surv, fat_prob, by = "idno", all.x = TRUE)

adiposity_class <- merge(adiposity_tm, adiposity_prob, by = "idno", all.x = TRUE)
surv_adiposity_class <- merge(surv, adiposity_prob, by = "idno", all.x = TRUE)

gluc_class <- merge(gluc_tm, gluc_prob, by = "idno", all.x = TRUE)
surv_gluc_class <- merge(surv, gluc_prob, by = "idno", all.x = TRUE)

# plot ------------------------------------------------------------------------


source("R/plot_observed.R")
source("R/plot_km.R")


# bw --------------------------------------------------------------------------

p_bw_obs <- plot_observed_classes(
  data = bw_class,
  x = age_wk,
  y = bw,
  class = class,
  title = NULL,
  x_label = "Age (weeks)",
  y_label = "Body weight (g)",
  class_label = "BW class",
  palette = bw_pal
)

p_bw_km <- plot_km_classes(
  data = surv_bw_class,
  time = le_wk,
  event = dead_censor,
  class = class,
  title = NULL,
  x_label = "Age (weeks)",
  y_label = "Survival probability",
  class_label = "BW class",
  palette = bw_pal
)


# fat -------------------------------------------------------------------------

p_fat_obs <- plot_observed_classes(
  data = fat_class,
  x = age_wk,
  y = fat,
  class = class,
  title = NULL,
  x_label = "Age (weeks)",
  y_label = "Fat mass (g)",
  class_label = "FM class",
  palette = fat_pal
)

p_fat_km <- plot_km_classes(
  data = surv_fat_class,
  time = le_wk,
  event = dead_censor,
  class = class,
  title = NULL,
  x_label = "Age (weeks)",
  y_label = "Survival probability",
  class_label = "FM class",
  palette = fat_pal
)


# adiposity -------------------------------------------------------------------

p_adiposity_obs <- plot_observed_classes(
  data = adiposity_class,
  x = age_wk,
  y = adiposity,
  class = class,
  title = NULL,
  x_label = "Age (weeks)",
  y_label = "Adiposity (%)",
  class_label = "Adiposity class"
)

p_adiposity_km <- plot_km_classes(
  data = surv_adiposity_class,
  time = le_wk,
  event = dead_censor,
  class = class,
  title = NULL,
  x_label = "Age (weeks)",
  y_label = "Survival probability",
  class_label = "Adiposity class"
)


# gluc ------------------------------------------------------------------------

p_gluc_obs <- plot_observed_classes(
  data = gluc_class,
  x = age_wk,
  y = gluc,
  class = class,
  title = NULL,
  x_label = "Age (weeks)",
  y_label = "Blood glucose (mg/dL)",
  class_label = "FBG class",
  palette = gluc_pal
)

p_gluc_km <- plot_km_classes(
  data = surv_gluc_class,
  time = le_wk,
  event = dead_censor,
  class = class,
  title = NULL,
  x_label = "Age (weeks)",
  y_label = "Survival probability",
  class_label = "FBG class",
  palette = gluc_pal
)


# combined panel --------------------------------------------------------------

class_panel <- plot_grid(
  p_bw_obs,        p_bw_km$plot,
  p_fat_obs,       p_fat_km$plot,
  p_adiposity_obs, p_adiposity_km$plot,
  p_gluc_obs,      p_gluc_km$plot,
  ncol = 2,
  align = "hv",
  labels = c("A", "B", "C", "D", "E", "F", "G", "H"),
  label_size = 12
)

class_panel

# create output folder
if (!dir.exists(file.path("output", "panel"))) {
  dir.create(file.path("output", "panel"), recursive = TRUE)
}

# save combined panel
ggsave(
  filename = file.path("output", "panel", "class_panel.png"),
  plot = class_panel,
  width = 14,
  height = 18,
  dpi = 300,
  bg = "white"
)

# save individual panels
ggsave(
  filename = file.path("output", "panel", "A_bw_observed.png"),
  plot = p_bw_obs,
  width = 7,
  height = 4.5,
  dpi = 300,
  bg = "white"
)

ggsave(
  filename = file.path("output", "panel", "B_bw_km.png"),
  plot = p_bw_km$plot,
  width = 7,
  height = 4.5,
  dpi = 300,
  bg = "white"
)

ggsave(
  filename = file.path("output", "panel", "C_fat_observed.png"),
  plot = p_fat_obs,
  width = 7,
  height = 4.5,
  dpi = 300,
  bg = "white"
)

ggsave(
  filename = file.path("output", "panel", "D_fat_km.png"),
  plot = p_fat_km$plot,
  width = 7,
  height = 4.5,
  dpi = 300,
  bg = "white"
)

ggsave(
  filename = file.path("output", "panel", "E_adiposity_observed.png"),
  plot = p_adiposity_obs,
  width = 7,
  height = 4.5,
  dpi = 300,
  bg = "white"
)

ggsave(
  filename = file.path("output", "panel", "F_adiposity_km.png"),
  plot = p_adiposity_km$plot,
  width = 7,
  height = 4.5,
  dpi = 300,
  bg = "white"
)

ggsave(
  filename = file.path("output", "panel", "G_glucose_observed.png"),
  plot = p_gluc_obs,
  width = 7,
  height = 4.5,
  dpi = 300,
  bg = "white"
)

ggsave(
  filename = file.path("output", "panel", "H_glucose_km.png"),
  plot = p_gluc_km$plot,
  width = 7,
  height = 4.5,
  dpi = 300,
  bg = "white"
)

# figure 1 size panels --------------------------------------------------------

# same size as 99_pub_ready_figs define_class panels, legends saved separately
if (!dir.exists(file.path("output", "panel_fig1_size"))) {
  dir.create(file.path("output", "panel_fig1_size"), recursive = TRUE)
}

ggsave(
  filename = file.path("output", "panel_fig1_size", "S2A.png"),
  plot = p_bw_obs + theme(legend.position = "none"),
  width = 4,
  height = 5,
  dpi = 600,
  bg = "white"
)

ggsave(
  filename = file.path("output", "panel_fig1_size", "S2B.png"),
  plot = p_bw_km$plot + theme(legend.position = "none"),
  width = 4,
  height = 5,
  dpi = 600,
  bg = "white"
)

ggsave(
  filename = file.path("output", "panel_fig1_size", "S2C.png"),
  plot = p_fat_obs + theme(legend.position = "none"),
  width = 4,
  height = 5,
  dpi = 600,
  bg = "white"
)

ggsave(
  filename = file.path("output", "panel_fig1_size", "S2D.png"),
  plot = p_fat_km$plot + theme(legend.position = "none"),
  width = 4,
  height = 5,
  dpi = 600,
  bg = "white"
)

ggsave(
  filename = file.path("output", "panel_fig1_size", "S2E.png"),
  plot = p_gluc_obs + theme(legend.position = "none"),
  width = 4,
  height = 5,
  dpi = 600,
  bg = "white"
)

ggsave(
  filename = file.path("output", "panel_fig1_size", "S2F.png"),
  plot = p_gluc_km$plot + theme(legend.position = "none"),
  width = 4,
  height = 5,
  dpi = 600,
  bg = "white"
)

ggsave(
  filename = file.path("output", "panel_fig1_size", "legend_bw.png"),
  plot = ggdraw(get_legend(p_bw_km$plot + theme(legend.position = "right"))),
  width = 3,
  height = 3,
  dpi = 600,
  bg = "white"
)

ggsave(
  filename = file.path("output", "panel_fig1_size", "legend_fm.png"),
  plot = ggdraw(get_legend(p_fat_km$plot + theme(legend.position = "right"))),
  width = 3,
  height = 3,
  dpi = 600,
  bg = "white"
)

ggsave(
  filename = file.path("output", "panel_fig1_size", "legend_fbg.png"),
  plot = ggdraw(get_legend(p_gluc_km$plot + theme(legend.position = "right"))),
  width = 3,
  height = 3,
  dpi = 600,
  bg = "white"
)
