#* Cage assignments: coverage and cross-check across three sources (2026-10-22)
#! QUESTION. Can more C1-C10 mice be given a cage than the 541 the freezer-search file covers, and do the sources agree where they overlap?
#! SOURCES. (1) frz = config$paths$body_weight_data (Body-weight_freezer-search_2024-12-13.csv; cage_effect_classes.R's cage source until 2026-10-22). (2) cen = the NIH census.csv (one cage per mouse, cohorts 1-13). (3) fc = BW_Temp_FC_All_2021-12-23.csv, whose `cagemates` field is a single-digit COUNT per weighing (found 2026-10-22: 100% numeric, one character), not cage-mate identities; it serves as an independent check on the census cage size and on regrouping.
#! FIRST RUN (2026-10-22): census covers all 1,315 classified mice (1,187 in 416 cages with >= 2 classified); census vs freezer on 581 shared mice: labels 99.8% equal, same-cage pairs 99.2% both ways; no mixed-sex or mixed-background census cage. The first version tried to resolve cagemates tokens to mice: 408 coincidental single-digit idno matches, none reciprocal; that section was replaced by the count check below.
#! PRINTS COUNTS AND SHARES ONLY: no idno, tag, cage label, file name or measurement is printed. Leaves cage_xcheck (a list) in the session; nothing is written to disk. Not sourced by run.R. Needs config: source("R/Scripts/non_pipeline/cage_crosscheck.R").
{
  #+ 0: Inputs
  nih_dir <- path.expand("~/Library/CloudStorage/OneDrive-NationalInstitutesofHealth/Mueller2026_final_data/raw/00a_clean_slam_c1-c10/data")
  cen_path <- file.path(nih_dir, "census.csv"); fc_path <- file.path(nih_dir, "BW_Temp_FC_All_2021-12-23.csv")
  stopifnot(file.exists(cen_path), file.exists(fc_path), file.exists(config$paths$body_weight_data))
  norm <- function(x) { x <- toupper(trimws(as.character(x))); x[x %in% c("", "NA", "N/A", ".", "NULL")] <- NA; x }
  norm_cohort <- function(x) as.character(suppressWarnings(as.integer(gsub("\\D", "", as.character(x)))))
  norm_sex <- function(x) substr(norm(x), 1, 1)
  read_chr <- function(p) { d <- readr::read_csv(p, col_types = readr::cols(.default = "c"), show_col_types = FALSE, name_repair = "unique_quiet"); names(d) <- trimws(names(d)); d }
  cen <- read_chr(cen_path) |> dplyr::mutate(dplyr::across(dplyr::everything(), norm), cohort = norm_cohort(cohort), sex = norm_sex(sex))
  fc  <- read_chr(fc_path) |> dplyr::transmute(idno = norm(idno), cohort = norm_cohort(cohort), source = norm(source), cagemates = suppressWarnings(as.integer(norm(cagemates))),
                                               date = as.Date(lubridate::parse_date_time(date, orders = c("Ymd", "mdY", "mdy", "dmY", "Ymd HMS"), quiet = TRUE)))
  frz <- read_chr(config$paths$body_weight_data) |> dplyr::transmute(idno = norm(idno), cage = norm(cage), sex = norm_sex(sex), strain = norm(strain), cohort = norm_cohort(cohort)) |> dplyr::distinct()
  cen_cage <- cen |> dplyr::filter(!is.na(idno), !is.na(cage)) |> dplyr::mutate(cage = paste(cohort, cage)) |> dplyr::group_by(cage) |> dplyr::mutate(cage_n = dplyr::n_distinct(idno)) |> dplyr::ungroup()
  #+ 1: Census on its own
  {
    cat("== 1. census.csv ==\n")
    dup <- cen_cage |> dplyr::group_by(idno) |> dplyr::summarise(cages = dplyr::n_distinct(cage), rows = dplyr::n()) |> dplyr::filter(rows > 1)
    cat(sprintf("rows %d | distinct idno %d | duplicated idno %d (of which in different cages: %d) | cage missing %d\n", nrow(cen), dplyr::n_distinct(cen$idno), nrow(dup), sum(dup$cages > 1), sum(is.na(cen$cage))))
    cat(sprintf("cohorts present: %s\n", paste(sort(as.integer(unique(cen$cohort))), collapse = ", ")))
    pur <- cen_cage |> dplyr::group_by(cage) |> dplyr::summarise(n = dplyr::n_distinct(idno), sexes = dplyr::n_distinct(sex, na.rm = TRUE), bgs = dplyr::n_distinct(strain, na.rm = TRUE))
    cat(sprintf("cohort+cage groups: %d | mixed sex: %d | mixed genetic background: %d\ncage size distribution:\n", nrow(pur), sum(pur$sexes > 1), sum(pur$bgs > 1)))
    print(table(size = pur$n))
  }
  #+ 2: Freezer file vs census
  {
    cat("\n== 2. freezer-search file vs census ==\n")
    fz <- frz |> dplyr::filter(!is.na(cage)) |> dplyr::distinct(idno, .keep_all = TRUE)
    lab <- dplyr::inner_join(fz |> dplyr::select(idno, cage_f = cage, cohort_f = cohort, sex_f = sex), cen_cage |> dplyr::distinct(idno, .keep_all = TRUE) |> dplyr::select(idno, cage_c = cage, cohort_c = cohort, sex_c = sex), by = "idno")
    cat(sprintf("freezer mice with a cage %d | also in census %d | absent from census %d, by cohort:\n", nrow(fz), nrow(lab), sum(!fz$idno %in% cen$idno)))
    print(table(cohort = fz$cohort[!fz$idno %in% cen$idno]))
    cat(sprintf("label differs: %d mice | cohort differs: %d | sex differs: %d\n", sum(sub("^\\S+ ", "", lab$cage_c) != lab$cage_f), sum(lab$cohort_f != lab$cohort_c, na.rm = TRUE), sum(lab$sex_f != lab$sex_c, na.rm = TRUE)))
  }
  #+ 3: The cagemates count against the census cage size
  {
    cat("\n== 3. BW_Temp_FC cagemates count vs census cage size ==\n")
    cat(sprintf("rows %d | mice %d | source files %d | cagemates present %.1f%% | values seen: %s\n", nrow(fc), dplyr::n_distinct(fc$idno), dplyr::n_distinct(fc$source, na.rm = TRUE),
                100 * mean(!is.na(fc$cagemates)), paste(sort(unique(fc$cagemates)), collapse = ", ")))
    cm <- fc |> dplyr::filter(!is.na(cagemates), !is.na(date)) |> dplyr::inner_join(cen_cage |> dplyr::distinct(idno, .keep_all = TRUE) |> dplyr::select(idno, cage, cage_n), by = "idno")
    per <- cm |> dplyr::arrange(idno, date) |> dplyr::group_by(idno, cage_n) |>
      dplyr::summarise(first = dplyr::first(cagemates), max = max(cagemates), rises = sum(diff(cagemates) > 0), .groups = "drop")
    cat(sprintf("census mice with counts: %d\n", nrow(per)))
    cat("first recorded count vs census cage size (does the count include the mouse itself? equal = yes, size - 1 = no):\n")
    print(table(census_size = per$cage_n, first_count = per$first))
    cat(sprintf("mice whose count ever RISES (a mouse added = regrouping): %d of %d | count above census cage size at any weighing: %d\n", sum(per$rises > 0), nrow(per), sum(per$max > per$cage_n)))
    # within a census cage, mice weighed on the same date should report the same count
    sd_ <- cm |> dplyr::group_by(cage, date) |> dplyr::summarise(k = dplyr::n_distinct(cagemates), mice = dplyr::n(), .groups = "drop") |> dplyr::filter(mice > 1)
    cat(sprintf("census cage x date with >= 2 mice weighed: %d | all report the same count: %.1f%%\n", nrow(sd_), 100 * mean(sd_$k == 1)))
    # and the count should equal the number of census cage-mates weighed that day (plus or minus self)
    alive <- cm |> dplyr::group_by(cage, date) |> dplyr::mutate(weighed = dplyr::n_distinct(idno)) |> dplyr::ungroup()
    cat(sprintf("count == mice of that census cage weighed that day: %.1f%% | == weighed - 1: %.1f%% | other: %.1f%%\n", 100 * mean(alive$cagemates == alive$weighed),
                100 * mean(alive$cagemates == alive$weighed - 1), 100 * mean(!alive$cagemates %in% c(alive$weighed, alive$weighed - 1))))
  }
  #+ 4: Pair agreement and coverage of the classified C1-C10 mice
  {
    cat("\n== 4. coverage of the Chapter 2 classified mice ==\n")
    mc_dir <- if (is.null(config$paths$metabolic_class_dir)) path.expand("~/Desktop/Repos/metabolic-class") else config$paths$metabolic_class_dir
    cls <- readr::read_csv(file.path(mc_dir, "04_create_census/output/slam_c1-c10_age_all_bwfatgluc/complete_census.csv"), show_col_types = FALSE, name_repair = "unique_quiet") |>
      dplyr::transmute(idno = norm(idno)) |> dplyr::distinct()
    parts <- list(freezer = fz |> dplyr::transmute(idno, cage = paste(cohort, cage)), census = cen_cage |> dplyr::distinct(idno, .keep_all = TRUE) |> dplyr::select(idno, cage))
    cov <- dplyr::bind_rows(lapply(names(parts), function(n) {
      d <- parts[[n]] |> dplyr::filter(idno %in% cls$idno); inf <- d |> dplyr::group_by(cage) |> dplyr::filter(dplyr::n() >= 2)
      tibble::tibble(source = n, classified_with_cage = nrow(d), in_cages_with_2plus = nrow(inf), informative_cages = dplyr::n_distinct(inf$cage))
    }))
    cat(sprintf("classified C1-C10 mice: %d\n", nrow(cls))); print(as.data.frame(cov), row.names = FALSE)
  }
  cage_xcheck <- list(parts = parts, coverage = cov, census_cage = cen_cage)
  rm(nih_dir, cen_path, fc_path, norm, norm_cohort, norm_sex, read_chr, cen, fc, frz, cen_cage, dup, pur, fz, lab, cm, per, sd_, alive, mc_dir, cls, parts, cov)
}
