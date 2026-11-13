# =============================================================================
# data_s1.R -- builds "Data S1 – Source Data.xlsx", the values behind every
# graph panel
#
# Run from the repo root AFTER rendering the deck:
#   Rscript figures/data_s1.R
#
# Journal asks for one Excel file with the values used to create all
# graphs. Tables placed in figures are listed in the Index without a sheet,
# since their values are printed. Layout: an Index sheet, then one sheet per
# graph panel, named by its label ("1B", "S1A"). Labels come from
# figures/output/panel_index.csv, which the deck writes from figure_spec.R, so
# the sheets follow any renumbering.
#
# Each panel's values are the .csv its stage writes beside the PNG, with the
# helpers in figures/source_data.R. Panels whose PNG comes straight from stage
# 07 are the exception: 99 rebuilds their values and writes them under
# 99_pub_ready_figs/output/source_data_07/, mirroring the 07 path. This script
# only collects the files; it computes nothing.
#
# Values are read as text. A column becomes numeric only when every value reads
# back exactly as written, so a printed label keeps its form and graph values
# stay numbers.
#
# FIGS_STRICT=1 turns every missing or stale panel into an error, as in 99.
# =============================================================================

STRICT <- nzchar(Sys.getenv("FIGS_STRICT"))

# The panel files are UTF-8; read them in a UTF-8 locale
if (!l10n_info()$`UTF-8` && !nzchar(suppressWarnings(Sys.setlocale("LC_CTYPE", "en_US.UTF-8")))) {
  stop("cannot switch to a UTF-8 locale to read the panel files")
}
OUT <- file.path("figures", "output", "Data S1 – Source Data.xlsx")
INDEX <- file.path("figures", "output", "panel_index.csv")
SPEC <- file.path("figures", "figure_spec.R")

# ---- panel index ------------------------------------------------------------
if (!file.exists(INDEX)) stop("no panel index -- render the deck first")
if (file.mtime(INDEX) < file.mtime(SPEC)) stop("panel_index.csv is older than figure_spec.R -- re-render the deck first")

idx <- utils::read.csv(INDEX, stringsAsFactors = FALSE)
idx <- idx[idx$panel != "GA", ]

# ---- classify each panel ----------------------------------------------------
TABLE_PATTERNS <- c("/tables/", "itp_geno_demographics", "ari_matrix", "km_high_risk_burden_hr")
SD07_PREFIX <- "../07_display_figures/output/"
SD07_ROOT <- file.path("99_pub_ready_figs", "output", "source_data_07")

src <- file.path("figures", idx$source)
is_07 <- startsWith(idx$source, SD07_PREFIX)
csv <- ifelse(is_07, file.path(SD07_ROOT, substring(idx$source, nchar(SD07_PREFIX) + 1)), src)
csv <- sub("\\.(png|jpg|jpeg)$", ".csv", csv)
is_schematic <- startsWith(idx$source, "images/")
# Tables placed in figures (1N, 2I, 5D, ...) print their values, and several
# were retyped in the composite, so they are listed in the Index without a sheet
is_table <- grepl(paste(TABLE_PATTERNS, collapse = "|"), idx$source)
has_csv <- file.exists(csv)
is_stale <- has_csv & file.exists(src) & file.mtime(csv) < file.mtime(src)

idx$status <- ifelse(is_schematic, "Schematic; no data",
              ifelse(is_table, "Table; values are shown in the figure",
              ifelse(is_stale, "STALE: PNG is newer than its data",
              ifelse(has_csv, "Source data", "MISSING: no data file"))))

# ---- sheets -----------------------------------------------------------------
read_panel <- function(f) {
  df <- utils::read.csv(f, check.names = FALSE, colClasses = "character",
                        na.strings = character(0), fileEncoding = "UTF-8")
  if (!ncol(df)) stop("no columns in ", f)
  for (j in seq_along(df)) {
    x <- df[[j]]
    filled <- nzchar(x)
    num <- suppressWarnings(as.numeric(x[filled]))
    if (any(filled) && !anyNA(num) && identical(as.character(num), x[filled])) {
      y <- rep(NA_real_, length(x))
      y[filled] <- num
      df[[j]] <- y
    }
  }
  df
}

# A data file that cannot be read (empty, or not readable) is a problem, not a crash
readable <- vapply(seq_along(csv), function(i) {
  if (idx$status[i] != "Source data") return(TRUE)
  ok <- tryCatch({ read_panel(csv[i]); TRUE }, error = function(e) {
    message("cannot read ", csv[i], ": ", conditionMessage(e))
    FALSE
  })
  ok
}, logical(1))
idx$status[!readable] <- "UNREADABLE: data file is empty or cannot be read"

idx$sheet <- ifelse(idx$status == "Source data", idx$panel, "")
sheets <- lapply(csv[idx$sheet != ""], read_panel)
names(sheets) <- idx$sheet[idx$sheet != ""]

# Text escaped by a non-UTF-8 locale ("<e2><89><a5>", "<U+2265>") is a problem
ESCAPED <- "<U\\+[0-9A-Fa-f]{4,}>|<[0-9a-f]{2}>"
mangled <- vapply(sheets, function(df) {
  txt <- c(names(df), unlist(lapply(df, function(x) if (is.character(x)) x)))
  any(grepl(ESCAPED, txt))
}, logical(1))
idx$status[match(names(sheets)[mangled], idx$sheet)] <- "MANGLED: text escaped by a non-UTF-8 locale"

idx$rows <- vapply(idx$sheet, function(s) if (nzchar(s)) nrow(sheets[[s]]) else NA_integer_, integer(1))
idx$columns <- vapply(idx$sheet, function(s) if (nzchar(s)) paste(names(sheets[[s]]), collapse = "; ") else "", character(1))

index_sheet <- data.frame(
  Figure = paste("Figure", sub("[A-Z]$", "", idx$panel)),
  Panel = idx$panel,
  Contents = idx$status,
  Rows = idx$rows,
  Columns = idx$columns,
  check.names = FALSE
)

# ---- checks -----------------------------------------------------------------
problems <- idx[grepl("^(MISSING|STALE|MANGLED|UNREADABLE)", idx$status), c("panel", "status", "source")]
if (nrow(problems)) {
  message(nrow(problems), " panel(s) without current data:")
  print(problems, row.names = FALSE)
  if (STRICT) stop("FIGS_STRICT: every graph panel must have current data")
}
if (anyDuplicated(names(sheets))) stop("duplicate sheet names")
if (any(nchar(names(sheets)) > 31)) stop("a sheet name is over Excel's 31 characters")

# ---- write ------------------------------------------------------------------
# Column width = longest header or cell in that column, in characters, capped at 80
all_sheets <- c(list(Index = index_sheet), sheets)
wb <- openxlsx::createWorkbook()
for (s in names(all_sheets)) {
  df <- all_sheets[[s]]
  cell_chars <- vapply(df, function(x) max(0, nchar(as.character(x)), na.rm = TRUE), numeric(1))
  widths <- pmin(pmax(nchar(names(df)), cell_chars) + 2, 80)
  openxlsx::addWorksheet(wb, s)
  openxlsx::writeData(wb, s, df, headerStyle = openxlsx::createStyle(textDecoration = "bold"))
  openxlsx::freezePane(wb, s, firstRow = TRUE)
  openxlsx::setColWidths(wb, s, cols = seq_along(df), widths = widths)
}
openxlsx::saveWorkbook(wb, OUT, overwrite = TRUE)
message("wrote ", OUT, ": ", length(sheets), " panel sheets, ", nrow(problems), " panel(s) missing or stale")
