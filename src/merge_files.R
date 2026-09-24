# merge_files.R
# Merge clean characteristics and diet files to the mycobiome data
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(readxl)
  library(here)
})

source(here("src", "participant_id.R"))

# ── Paths ────────────────────────────────────────────────────────────
# Set up directories
intermediate_dir <- here("data", "intermediate")
processed_dir <- here("data", "processed")
dir.create(processed_dir, showWarnings = FALSE, recursive = TRUE)

# Meta Columns
meta_cols <- c(
  "Sample_ID", "Participant_ID", "Sample_type",
  "Study_group_new", "Fiber_restriction"
)

# ── Loaders ──────────────────────────────────────────────────────────

# Load the characteristics files
load_characteristics <- function(path) {
  read_csv(path, show_col_types = FALSE)
}

# Load the dietary file
load_dietary <- function(path) {
  df <- suppressMessages(read_excel(path))
  df$participant_id <- df[["Participant ID (ESHA ID)"]]
  # Coerce any character columns that should be numeric (e.g. "--" for missing)
  df <- df |>
    mutate(across(
      where(is.character) & !any_of(c(
        "participant_id", "Participant ID (ESHA ID)", "Timepoint", "Day"
      )),
      \(x) suppressWarnings(as.numeric(x))
    ))
  df
}

# ── Helpers ──────────────────────────────────────────────────────────

# Pivot one taxa level from long to wide, prefixing taxon column names.
# Currently, taxa levels are imported as a list
# e.g. "Ascomycota" → "p__Ascomycota" with one row per Sample_ID.
pivot_taxa <- function(taxa_long, prefix) {
  taxon_col <- setdiff(names(taxa_long), c(meta_cols, "Value"))
  taxa_long |>
    mutate(
      across(all_of(taxon_col), \(x) paste0(prefix, x))
    ) |>
    pivot_wider(
      id_cols     = all_of(meta_cols),
      names_from  = all_of(taxon_col),
      values_from = Value,
      values_fill = 0
    )
}

# Aggregate dietary to one row per participant (mean numeric cols across days).
aggregate_dietary <- function(dietary) {
  dietary |>
    group_by(participant_id) |>
    summarise(
      across(where(is.numeric), \(x) mean(x, na.rm = TRUE)),
      .groups = "drop"
    )
}


# ── Main ──────────────────────────────────────────────────────────────

# Defensive programming
required_files <- c(
  taxa            = file.path(intermediate_dir, "taxa_long_list.rds"),
  alpha           = file.path(intermediate_dir, "alpha_long.rds"),
  characteristics = file.path(processed_dir, "cleaned_characteristics.csv"),
  dietary         = file.path(processed_dir, "dietary_cleaned.xlsx")
)
missing <- required_files[!file.exists(required_files)]
if (length(missing)) {
  stop(
    "Missing input files:\n",
    paste(names(missing), missing, sep = " → ", collapse = "\n")
  )
}

# Load
taxa_list   <- readRDS(required_files["taxa"])
alpha_wide  <- readRDS(required_files["alpha"]) |>
  pivot_wider(
    id_cols     = Sample_ID,
    names_from  = Diversity_metric,
    values_from = Value
  )
chars       <- load_characteristics(required_files["characteristics"])
dietary_agg <- aggregate_dietary(load_dietary(required_files["dietary"]))

# Pivot each taxa level to wide and left-join on meta columns so no
# samples are dropped if a level is missing a taxon.
taxa_wide <- pivot_taxa(taxa_list[["phylum"]], "p__") |>
  left_join(pivot_taxa(taxa_list[["family"]], "f__"), by = meta_cols) |>
  left_join(pivot_taxa(taxa_list[["genus"]], "g__"), by = meta_cols) |>
  left_join(pivot_taxa(taxa_list[["species"]], "s__"), by = meta_cols)

# ── Match diagnostics (mycobiome as limiting dataset) ─────────────────────

myco_ids <- unique(taxa_wide$Participant_ID)
char_ids <- unique(chars$participant_id)
diet_ids <- unique(dietary_agg$participant_id)

report_match <- function(myco, other, label) {
  matched <- intersect(myco, other)
  myco_only <- setdiff(myco, other)
  other_only <- setdiff(other, myco)
  message(
    "\n",
    label, " match:\n",
    "  matched:        ", length(matched), " / ",
    length(myco), " mycobiome participants\n",
    "  missing in ", label, ": ",
    if (length(myco_only) == 0) {
      "none"
    } else {
      paste(myco_only, collapse = ", ")
    }
  )
}

report_match(myco_ids, char_ids, "characteristics")
report_match(myco_ids, diet_ids, "dietary")

# Among participants with NO mycobiome data, how well do chars and diet align?
no_myco_char_ids <- setdiff(char_ids, myco_ids)
no_myco_diet_ids <- setdiff(diet_ids, myco_ids)
no_myco_both     <- intersect(no_myco_char_ids, no_myco_diet_ids)
no_myco_char_only <- setdiff(no_myco_char_ids, no_myco_diet_ids)
no_myco_diet_only <- setdiff(no_myco_diet_ids, no_myco_char_ids)
message(
  "\n",
  "Non-mycobiome participants — chars vs diet match:\n",
  "  chars (no myco):  ", length(no_myco_char_ids), "\n",
  "  diet  (no myco):  ", length(no_myco_diet_ids), "\n",
  "  both:             ", length(no_myco_both), "\n",
  "  chars only:       ",
  if (length(no_myco_char_only) == 0) "none" else paste(no_myco_char_only, collapse = ", "), "\n",
  "  diet only:        ",
  if (length(no_myco_diet_only) == 0) "none" else paste(no_myco_diet_only, collapse = ", ")
)

# One wide table: taxa is the anchor — alpha, chars, and dietary are left-joined
# so mycobiome samples are never dropped when other data is missing.
merged <- taxa_wide |>
  left_join(alpha_wide, by = "Sample_ID") |>
  left_join(chars, by = c("Participant_ID" = "participant_id")) |>
  left_join(dietary_agg, by = c("Participant_ID" = "participant_id"))

merged <- merged |> rename(sample_id = Sample_ID, participant_id = Participant_ID)

out_path <- file.path(processed_dir, "merged.csv")
write_csv(merged, out_path)
message(
  "\n",
  "Saved: ", out_path,
  "\n",
  nrow(merged), " rows x ", ncol(merged), " cols"
)

# ── All participants (chars as anchor) ────────────────────────────────────────
# Includes everyone regardless of mycobiome status; has_mycobiome flags who has
# sequencing data so the dashboard can indicate availability.
# Study_group_new and Fiber_restriction live only in the taxa metadata, so pull
# them via a lookup from taxa_wide for participants who have mycobiome data.
study_group_lookup <- taxa_wide |>
  distinct(Participant_ID, Study_group_new, Fiber_restriction) |>
  rename(participant_id = Participant_ID)

participants_all <- chars |>
  left_join(dietary_agg, by = "participant_id") |>
  left_join(study_group_lookup, by = "participant_id") |>
  mutate(
    has_mycobiome = participant_id %in% myco_ids,
    has_diet      = participant_id %in% diet_ids
  )

out_path_all <- file.path(processed_dir, "participants_all.csv")
write_csv(participants_all, out_path_all)
message(
  "\n",
  "Saved: ", out_path_all,
  "\n",
  nrow(participants_all), " rows x ", ncol(participants_all), " cols",
  " (", sum(participants_all$has_mycobiome), " with mycobiome data)",
  "\n"
)
