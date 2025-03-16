# clean jax do data


jaxdo <- read.csv("data/JAC_DO_phenotypes_compiled_v8.csv")



keep_cols <- c(
  id = "Mouse.ID",
  dob = "DOB",
  sex = "Sex",
  generation = "Generation",
  dod = "Death.date",
  cod = "Death.type",
  "lifespan",
  "bw.29",
  "bw.55",
  "bw.81",
  "bw.31",
  "bw.57",
  "bw.83",
  "bw.33",
  "bw.59",
  "bw.85",
  "bw.104",
  "bw.130",
  gluc.26 = "gluc.6",
  gluc.52 = "gluc.12",
  gluc.72 = "gluc.18"
)

jaxdo <- jaxdo[, keep_cols]

jaxdo <- consoler::rename(jaxdo, keep_cols)

wide_to_long_bw <- c(
  "bw.29", "bw.55", "bw.81", "bw.31", "bw.57", "bw.83",
  "bw.33", "bw.59", "bw.85", "bw.104", "bw.130"
)
wide_to_long_gluc <- c("gluc.26", "gluc.52", "gluc.72")

wide_to_long_vars <- list(bw = wide_to_long_bw, gluc = wide_to_long_gluc)
new_time_bw <- as.numeric(gsub("bw\\.|gluc\\.", "", wide_to_long_bw))
new_time_gluc <- as.numeric(gsub("bw\\.|gluc\\.", "", wide_to_long_gluc))

jaxdo_bw <- reshape(jaxdo,
  direction = "long",
  varying = wide_to_long_bw,
  timevar = "age_wk",
  times = new_time_bw,
  v.names = "bw",
  idvar = "id"
)

jaxdo_gluc <- reshape(jaxdo,
  direction = "long",
  varying = wide_to_long_gluc,
  timevar = "age_wk",
  times = new_time_gluc,
  v.names = "gluc",
  idvar = "id"
)

census <- jaxdo[, c("id", "dob", "sex", "generation", "dod", "cod", "lifespan")]
jaxdo <- merge(jaxdo_bw[, c("id", "age_wk", "bw")],
  jaxdo_gluc[, c("id", "age_wk", "gluc")],
  by = c("id", "age_wk"), all = TRUE
)
jaxdo <- merge(census, jaxdo, by = "id")
peek(jaxdo)
