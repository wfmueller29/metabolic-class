#* Setup, Functions, Configuration
  #+ Set Raw Data Path
    #! Laptop
    raw_path <- "/Users/jdp2019/Library/CloudStorage/Box-Box/metabolic-class-ITP/hevolution_raw_data"
    #! Desktop
    raw_path <-"/Users/JoshsMacbook2015/Library/CloudStorage/Box-Box/metabolic-class-ITP/hevolution_raw_data/HEV 1"
  #+ Configure Package Preferences
    conflicts_prefer(readxl::read_xlsx)
  #+ Get File List
    all_files <- list.files(raw_path, pattern = "\\.xlsx$", full.names = TRUE, recursive = TRUE)
    all_files <- all_files[!grepl("HEV MASTER CHIP SHEET", all_files, ignore.case = TRUE)]
  #+ Pull in DOB info
    #! Laptop
    DOB_data <- read_xlsx("/Users/jdp2019/Library/CloudStorage/Box-Box/metabolic-class-ITP/hevolution_raw_data/HEV 1/HEV MASTER CHIP SHEET_051525v3.xlsx")
    #! Desktop
    DOB_data <- read_xlsx("/Users/JoshsMacbook2015/Library/CloudStorage/Box-Box/metabolic-class-ITP/hevolution_raw_data/HEV 1/HEV MASTER CHIP SHEET_051525v3.xlsx")
  #+ Define File Import Function
    import_file <- function(file_path) {
      #- Extract Metadata from File Path
        #_Extract sex from directory path
        sex <- if (grepl("/Female/", file_path)) "F" else "M"
        #_Extract date from filename (remove .xlsx extension)
        date <- tools::file_path_sans_ext(basename(file_path))
      #- Read and Process Excel Data
        data <- read_xlsx(file_path) %>%
          select(Tag, BW) %>%
          mutate(
            #_Clean Tag: convert to uppercase
            Tag = str_to_upper(Tag),
            #_Clean BW: remove whitespace, remove g/G, convert to numeric
            BW = as.numeric(str_remove_all(str_trim(BW), "[gG?]")),
            #_Add Sex and Date columns
            Sex = sex,
            Date = as.Date(date, format = "%m-%d-%Y"),
            .after = 2
          )
      return(data)
    }
#* Data Processing
  #+ Import All Files
    all_tibbles <- map(all_files, import_file)
  #+ Format DOB and other metadata
    DOB_data_clean <- DOB_data %>%
      select(Cohort, Animal_ID, Tag, dob, status) %>%
      mutate(dob = as.Date(dob))
  #+ Combine and Process Master Dataset, Join with DOB
    #- Import, clean, join
      master_data <- bind_rows(all_tibbles) %>%
        mutate(Tag = if_else(Tag == "HEV0341", "HEV00341", Tag)) %>% #! Mouse mislabeled in baseline which is in cage 70.... cage 70 subsequents are 000341 so just a mistake
        mutate(Tag = if_else(Tag == "HEV0004", "HEV00004", Tag)) %>% #! Mouse mislabeled in longitudinal which is in cage 1... cage 1 previous and subsequents are 00004 so just a mistake
        mutate(
          Strain = "HET3", 
          Study = "HEV 1",
          #_Add measure_type based on baseline dates
          measure_type = case_when(
            Date == as.Date("2025-03-17") | Date == as.Date("2025-03-18") ~ "baseline",
            TRUE ~ "longitudinal"
          )
        ) %>%
        #_Filter out rows where BOTH Tag AND BW are NA
        filter(!(is.na(Tag) & is.na(BW))) %>%
        mutate(Date = as.Date(Date)) %>%
        left_join(DOB_data_clean, by = c("Tag")) %>%
        mutate(
          status = case_when(
            status %in% c("FOUND DEAD", "CULLED FW GENITALS") ~ "DEAD",
            status == "NOT DEAD" ~ NA_character_,
            TRUE ~ status
          )
        ) %>% #! Cleaning up inconsistent value entries for status
        mutate(status = as.factor(status)) %>%
        rename(BW_measure_date = Date) %>%
        mutate(
          dob = if_else(
            dob == as.Date("2025-12-10"),
            as.Date("2024-12-10"),
            dob
          )
        ) %>%
        mutate(
          age_days = as.numeric(difftime(BW_measure_date, dob, units = "days")),
          age_wk   = age_days / 7
        ) %>%
        select(Study, Cohort, Animal_ID, Tag, Sex, Strain, dob, status, measure_type, BW_measure_date, age_days, age_wk, BW)
    #- Check to ensure no NAs
      master_data %>%
        filter(is.na(dob))
    #- Export as CSV
      write_csv(master_data, "HEV_CR_BW_master_clean_8_12_25.csv")
