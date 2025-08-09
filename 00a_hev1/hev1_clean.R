raw_path <- "/Users/jdp2019/Library/CloudStorage/Box-Box/metabolic-class-ITP/hevolution_raw_data"
conflicts_prefer(readxl::read_xlsx)
# Get all Excel files with full paths
all_files <- list.files(raw_path, pattern = "\\.xlsx$", full.names = TRUE, recursive = TRUE)

# Function to import a single Excel file with Sex and Date columns
import_file <- function(file_path) {
  # Extract sex from directory path
  sex <- if (grepl("/Female/", file_path)) "F" else "M"
  # Extract date from filename (remove .xlsx extension)
  date <- tools::file_path_sans_ext(basename(file_path))
  
  # Read the Excel file and select only Tag and BW columns
  data <- read_xlsx(file_path) %>%
    select(Tag, BW) %>%
    mutate(
      # Clean Tag: convert to uppercase
      Tag = str_to_upper(Tag),
      # Clean BW: remove whitespace, remove g/G, convert to numeric
      BW = as.numeric(str_remove_all(str_trim(BW), "[gG?]")),
      # Add Sex and Date columns
      Sex = sex,
      Date = as.Date(date, format = "%m-%d-%Y"),
      .after = 2  # Add these columns after the second column
    )
  
  return(data)
}

# Import all files as a list of tibbles
all_tibbles <- map(all_files, import_file)

# Combine all tibbles into one master tibble
master_data <- bind_rows(all_tibbles) %>%
  mutate(
    Strain = "HET3", 
    Study = "HEV 1",
    # Add measure_type based on baseline dates
    measure_type = case_when(
      Date == as.Date("2025-03-17") | Date == as.Date("2025-03-18") ~ "baseline",
      TRUE ~ "longitudinal"
    )
  ) %>%
  # Filter out rows where BOTH Tag AND BW are NA
  filter(!(is.na(Tag) & is.na(BW)))