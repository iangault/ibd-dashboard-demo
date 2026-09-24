# 01_prepare_eda_data.R
# Prepare the shared dietary EDA input object consumed by the figure scripts.
# Input:
#   - `data/processed/dietary_cleaned.xlsx`
#   - metadata from `load_mycobiome_meta()`
# Output:
#   - `data/intermediate/diet_eda_inputs.rds`
# The saved RDS contains both the cleaned dietary table and a version merged to
# study-group metadata so downstream scripts do not need to repeat the join.

source("src/diet/00_functions.R")

ensure_diet_dirs()

dietary_df <- suppressMessages(load_dietary_cleaned())
meta_df <- load_mycobiome_meta() |>
  transmute(
    `Participant ID (ESHA ID)` = normalize_participant_id(Participant_ID),
    Study_group_new,
    Fiber_restriction
  ) |>
  distinct()

merged_df <- dietary_df |>
  mutate(`Participant ID (ESHA ID)` = normalize_participant_id(`Participant ID (ESHA ID)`)) |>
  left_join(meta_df, by = "Participant ID (ESHA ID)")

saveRDS(
  list(
    dietary = dietary_df,
    merged = merged_df
  ),
  diet_intermediate_path("diet_eda_inputs.rds")
)

message("01_prepare_eda_data.R completed: dietary EDA inputs saved.")
