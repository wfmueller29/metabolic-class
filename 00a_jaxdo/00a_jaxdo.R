# clean jax do data

jaxdo <- read.csv("data/JAC_DO_phenotypes_compiled_v8.csv")

# drop columns not used -------------------------------------------------------
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

# convert wide to long --------------------------------------------------------

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
na_bw_obs <- sum(is.na(jaxdo_bw$bw))
message("Dropping observations with NA for bw - ", na_bw_obs)
jaxdo_bw <- jaxdo_bw[!is.na(jaxdo_bw$bw), ]


jaxdo_gluc <- reshape(jaxdo,
  direction = "long",
  varying = wide_to_long_gluc,
  timevar = "age_wk",
  times = new_time_gluc,
  v.names = "gluc",
  idvar = "id"
)
na_gluc_obs <- sum(is.na(jaxdo_gluc$gluc))
message("Dropping observations with NA for gluc - ", na_gluc_obs)
jaxdo_gluc <- jaxdo_gluc[!is.na(jaxdo_gluc$gluc), ]

census <- jaxdo[, c("id", "dob", "sex", "generation", "dod", "cod", "lifespan")]
jaxdo <- merge(jaxdo_bw[, c("id", "age_wk", "bw")],
  jaxdo_gluc[, c("id", "age_wk", "gluc")],
  by = c("id", "age_wk"), all = TRUE
)
jaxdo <- merge(census, jaxdo, by = "id")

# create new columns ----------------------------------------------------------
jaxdo$age_wk2 <- jaxdo$age_wk * jaxdo$age_wk
jaxdo$le_wk <- jaxdo$lifespan / 7

ghost_obs <- sum(jaxdo$le_wk <= jaxdo$age_wk)
message("Observations after or on day of death - ", ghost_obs)
jaxdo <- jaxdo[jaxdo$le_wk > jaxdo$age_wk, ]

# make id numeric -------------------------------------------------------------
census <- data.frame(
  old_id = unique(jaxdo$id),
  id = seq_len(length(unique(jaxdo$id)))
)
jaxdo <- merge(census, jaxdo, by.x = "old_id", by.y = "id", all.y = TRUE)


# Create survival dataset -----------------------------------------------------
surv_cols <- c("id", "le_wk", "cod")
surv <- jaxdo[, surv_cols]

found_dead <- c(
  "F.D. (Y)",
  "F.D.",
  "F.D.(Y)",
  "FD",
  "F.D. (Y) para",
  "F.D. (Y)(para)",
  "F.D. (Y) ulcerated leg",
  "F.D>",
  "F.D. (Y) derm",
  "F.D. (Y)-lump on throat"
)

censor <- c(
  "Wrong Sex (N)",
  "MSG",
  "MSH",
  "F.T.R. (Y)",
  "E.S. (Y)",
  "Missing (Y)",
  "F.D.E.(Y)",
  "E.S. (Derm)",
  "Severe Derm",
  "E.S.",
  "ES",
  "M",
  "MISS",
  NA
)

surv$dead_censor <- ifelse(surv$cod %in% found_dead, 1, 0)

surv <- surv[, c("id", "le_wk", "dead_censor")]

# Create main dataset ---------------------------------------------------------
jaxdo_cols <- c(
  "generation", "id", "old_id", "sex", "age_wk", "age_wk2", "bw", "gluc"
)
jaxdo <- jaxdo[, jaxdo_cols]

dir.create("output")
write.csv(surv, "output/jaxdo_surv.csv")
write.csv(jaxdo, "output/jaxdo_bw_gluc.csv")
