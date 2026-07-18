# Test ln vs quadratic functional form for all of our variables

library(lme4)
library(flextable)
library(officer)

bw <- read.csv("../00b_dataset_mods/output/slam_c1-c10/data/slam_bw_og.csv")
fat <- read.csv("../00b_dataset_mods/output/slam_c1-c10/data/slam_fat_og.csv")
gluc <- read.csv("../00b_dataset_mods/output/slam_c1-c10/data/slam_gluc_og.csv")


# Make sure categorical variables are factors
bw$sex <- factor(bw$sex)
bw$strain <- factor(bw$strain)

fat$sex <- factor(fat$sex)
fat$strain <- factor(fat$strain)

gluc$sex <- factor(gluc$sex)
gluc$strain <- factor(gluc$strain)


compare_age_forms <- function(data, outcome) {
  # Candidate 1: quadratic age
  f_quad <- as.formula(
    paste0(outcome, " ~ age_wk + age_wk2 + sex * strain + (1 | idno)")
  )

  # Candidate 2: linear age + log age
  f_log <- as.formula(
    paste0(outcome, " ~ age_wk + ln_age_wk + sex * strain + (1 | idno)")
  )

  # Fit with ML, not REML, for fixed-effect comparison
  m_quad <- lmer(f_quad, data = data, REML = FALSE)
  m_log <- lmer(f_log, data = data, REML = FALSE)

  out <- data.frame(
    outcome = outcome,
    model = c("age_wk + age_wk2", "age_wk + ln_age_wk"),
    AIC = c(AIC(m_quad), AIC(m_log)),
    BIC = c(BIC(m_quad), BIC(m_log)),
    logLik = c(as.numeric(logLik(m_quad)), as.numeric(logLik(m_log)))
  )

  out$delta_AIC <- out$AIC - min(out$AIC)
  out$delta_BIC <- out$BIC - min(out$BIC)

  out <- out[order(out$AIC), ]

  list(
    comparison = out,
    quad_model = m_quad,
    log_model = m_log
  )
}


bw_compare <- compare_age_forms(bw, "bw")
fat_compare <- compare_age_forms(fat, "fat")
gluc_compare <- compare_age_forms(gluc, "gluc")

bw_compare$comparison
fat_compare$comparison
gluc_compare$comparison


# Combine model comparison results
model_comparison_table <- do.call(
  rbind,
  list(
    bw_compare$comparison,
    fat_compare$comparison,
    gluc_compare$comparison
  )
)

# Nicer outcome labels
model_comparison_table$outcome_label <- ifelse(
  model_comparison_table$outcome == "bw", "Body weight",
  ifelse(
    model_comparison_table$outcome == "fat", "Fat mass",
    ifelse(model_comparison_table$outcome == "gluc", "Fasting glucose", model_comparison_table$outcome)
  )
)

# Nicer model labels
model_comparison_table$model_label <- ifelse(
  model_comparison_table$model == "age_wk + age_wk2",
  "Linear + quadratic age",
  "Linear + log-transformed age"
)

# Indicator for best-fitting model within each outcome
model_comparison_table$best_model <- ave(
  model_comparison_table$AIC,
  model_comparison_table$outcome,
  FUN = function(x) ifelse(x == min(x), "Best fit", "")
)

# Order rows
model_comparison_table$outcome_label <- factor(
  model_comparison_table$outcome_label,
  levels = c("Body weight", "Fat mass", "Fasting glucose")
)

model_comparison_table <- model_comparison_table[
  order(model_comparison_table$outcome_label, model_comparison_table$AIC),
]

# Table display dataset
table_display <- data.frame(
  Outcome = model_comparison_table$outcome_label,
  Age_form = model_comparison_table$model_label,
  AIC = round(model_comparison_table$AIC, 2),
  BIC = round(model_comparison_table$BIC, 2),
  Log_likelihood = round(model_comparison_table$logLik, 2),
  Delta_AIC = round(model_comparison_table$delta_AIC, 2),
  Delta_BIC = round(model_comparison_table$delta_BIC, 2),
  Best_fit = model_comparison_table$best_model,
  check.names = FALSE
)

# Create flextable
ft_model_comparison <- flextable(table_display)

ft_model_comparison <- ft_model_comparison |>
  set_header_labels(
    Outcome = "Outcome",
    Age_form = "Age functional form",
    AIC = "AIC",
    BIC = "BIC",
    Log_likelihood = "Log-likelihood",
    Delta_AIC = "ΔAIC",
    Delta_BIC = "ΔBIC",
    Best_fit = ""
  ) |>
  merge_v(j = "Outcome") |>
  valign(j = "Outcome", valign = "top") |>
  bold(part = "header") |>
  bold(i = ~ Delta_AIC == 0, bold = TRUE) |>
  bold(i = ~ Delta_BIC == 0, bold = TRUE) |>
  bold(i = ~ Best_fit == "Best fit", bold = TRUE) |>
  align(align = "center", part = "all") |>
  align(j = c("Outcome", "Age_form"), align = "left", part = "all") |>
  colformat_num(
    j = c("AIC", "BIC", "Log_likelihood", "Delta_AIC", "Delta_BIC"),
    digits = 2
  ) |>
  autofit() |>
  add_footer_lines(
    values = "Models were fit by maximum likelihood and included sex, strain, and the sex-by-strain interaction as fixed effects, with animal ID included as a random intercept. Lower AIC and BIC values indicate better model fit. ΔAIC and ΔBIC are relative to the best-fitting model within each outcome."
  ) |>
  fontsize(size = 10, part = "all") |>
  fontsize(size = 9, part = "footer") |>
  font(fontname = "Arial", part = "all") |>
  border_remove() |>
  hline_top(part = "header", border = fp_border(width = 1.5)) |>
  hline_bottom(part = "header", border = fp_border(width = 1)) |>
  hline_bottom(part = "body", border = fp_border(width = 1.5)) |>
  hline_top(part = "footer", border = fp_border(width = 1))

ft_model_comparison

save_as_docx(
  "Table 1. Comparison of age functional forms in longitudinal mixed-effects models" = ft_model_comparison,
  path = "model_comparison_table.docx"
)
