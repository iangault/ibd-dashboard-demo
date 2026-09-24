# 01_data_import.R: Setup, libraries, data import, and theme

# ---- Setup ----

rm(list = ls())

suppressPackageStartupMessages({
  library(readxl)
  library(janitor)
})


# ---- Import Raw Mycobiome Tables ----

file_path <- "./data/raw/SYN_stool mycobiota relative abund.xlsx"
sheets <- excel_sheets(file_path)
data_list <- setNames(
  lapply(sheets, function(s) {
    read_excel(file_path, sheet = s)
  }),
  make_clean_names(sheets)
)

meta_raw <- read_excel("./data/raw/SYN_MBI sample IDs meta.xlsx")

# Normalize participant ID's across domains
source(file.path("src", "participant_id.R"))
meta_raw$`Participant ID` <- normalize_participant_id(meta_raw$`Participant ID`)

# ---- Save Imported Data ----

saveRDS(data_list, "./data/intermediate/data_list.rds")
saveRDS(meta_raw, "./data/intermediate/meta_raw.rds")

message("01_data_import.R completed: Data imported and saved.")
