suppressPackageStartupMessages({
  library(shiny)
  library(ggplot2)
  library(plotly)
  library(dplyr)
  library(tidyr)
})

source(file.path("R", "cards.R"), local = TRUE)
source(file.path("R", "plots.R"), local = TRUE)

# --- Input ----

# Mycobome + Diversity + Characteristics + Diet
# Only for patients with mycobiome data
merged_lowercase <- read.csv("data/merged.csv", stringsAsFactors = FALSE)

merged <- merged_lowercase |>
  rename(
    Participant_ID = participant_id,
    Sample_ID = sample_id
  )

# All participants: Characteristics + Diet, has_mycobiome flags sequencing availability
participants_all <- read.csv("data/participants_all.csv", stringsAsFactors = FALSE)

# Inflammatory markers (fecal calprotectin, CRP)
inflam <- readRDS("data/inflammatory_markers.rds")

# Sample-level scatter data: both replicates kept
sample_df <- merged_lowercase |>
  rename(
    Disease_status   = Study_group_new,
    `Fiber (g)`      = TotFib..g.,
    `Tryptophan (g)` = Trp..g.,
    Age              = age,
    BMI              = bmi_1,
    HBI              = harvey_bradshaw_index
  )

# Participant-level scatter data: numeric columns averaged across samples,
# non-numeric columns taken from first row. Use when CRP or Fecal Calprotectin selected.
# In our merged data, the diet and characteristics were duplicated for each sample,
# So this is just making those observations not redundant in participant_df
participant_df <- sample_df |>
  group_by(participant_id) |>
  summarise(
    across(where(is.numeric), function(x) mean(x, na.rm = TRUE)),
    across(where(is.character), first),
    .groups = "drop"
  ) |>
  left_join(
    inflam |> select(Participant_ID, fecal_calprotectin, crp),
    by = c("participant_id" = "Participant_ID")
  ) |>
  rename(
    `Fecal Calprotectin` = fecal_calprotectin,
    CRP                  = crp
  )

scatter_y_choices <- c(
  "Shannon", "Simpson", "Chao1",
  "Fecal Calprotectin", "CRP"
)

scatter_x_choices <- c(
  "Fiber (g)", "Tryptophan (g)",
  "Age", "BMI",
  "HBI", "QoL Score"
)

# ---  Derive individual taxa for plots ---

meta_cols <- c("Sample_ID", "Participant_ID", "Sample_type", "Study_group_new", "Fiber_restriction")

phylum <- merged[, c(meta_cols, grep("^p__", names(merged), value = TRUE))]
names(phylum) <- sub("^p__", "", names(phylum))
names(phylum)[names(phylum) == "Other"] <- "Unclassified"

family <- merged[, c(meta_cols, grep("^f__", names(merged), value = TRUE))]
names(family) <- sub("^f__", "", names(family))
names(family)[names(family) == "NA"] <- "Unclassified"

genus <- merged[, c(meta_cols, grep("^g__", names(merged), value = TRUE))]
names(genus) <- sub("^g__", "", names(genus))
names(genus)[names(genus) == "NA"] <- "Unclassified"

species <- merged[, c(meta_cols, grep("^s__", names(merged), value = TRUE))]
names(species) <- sub("^s__", "", names(species))
names(species)[names(species) == "NA"] <- "Unclassified"

# --- Wrangling ---

# One row per participant — characteristics + dietary columns from merged
participant_data <- merged_lowercase |>
  distinct(participant_id, .keep_all = TRUE) |>
  left_join(
    inflam |>
      select(Participant_ID, fecal_calprotectin, crp) |>
      rename(participant_id = Participant_ID),
    by = "participant_id"
  )

total_sugar_columns <- c(
  "Sugar..g.",
  "SugAdd..g.",
  "MonSac..g.",
  "Gluc..g.",
  "Fruct..g.",
  "Disacc..g.",
  "Lact..g.",
  "Sucr..g.",
  "SugAl..g.",
  "Eryth..g.",
  "Glyc..g.",
  "Inos..g.",
  "Lacti..g.",
  "Malti..g.",
  "Mann..g.",
  "Sorb..g.",
  "Xylit..g."
)

available_total_sugar_columns <- intersect(total_sugar_columns, names(participant_data))

participant_data <- participant_data %>%
  mutate(
    TotalSugar..g. = if (length(available_total_sugar_columns) == 0) {
      NA_real_
    } else {
      sugar_values <- across(all_of(available_total_sugar_columns), ~ suppressWarnings(as.numeric(.x)))
      sugar_total <- rowSums(sugar_values, na.rm = TRUE)
      sugar_total[rowSums(!is.na(sugar_values)) == 0] <- NA_real_
      sugar_total
    }
  )

# Diet lookup covering all participants (not just those with mycobiome data)
available_total_sugar_columns_all <- intersect(total_sugar_columns, names(participants_all))

# Sums up total sugar, but also will be used as a filter in individual_server.R
# so diet data can be shown for any participant, including those without mycobiome
diet_lookup <- participants_all |>
  distinct(participant_id, .keep_all = TRUE) |>
  mutate(
    TotalSugar..g. = if (length(available_total_sugar_columns_all) == 0) {
      NA_real_
    } else {
      sugar_values <- across(all_of(available_total_sugar_columns_all), ~ suppressWarnings(as.numeric(.x)))
      sugar_total <- rowSums(sugar_values, na.rm = TRUE)
      sugar_total[rowSums(!is.na(sugar_values)) == 0] <- NA_real_
      sugar_total
    }
  )

participants <- participants_all |>
  left_join(
    inflam |>
      select(Participant_ID, fecal_calprotectin, crp) |>
      rename(participant_id = Participant_ID),
    by = "participant_id"
  ) |>
  transmute(
    ID = participant_id,
    Has_Mycobiome = has_mycobiome,
    Has_Diet      = has_diet,
    Age = age,
    Sex = gender,
    Ethnicity = ethnicity,
    Country_of_Origin = country_of_origin,
    Years_Living_in_Canada = years_living_in_canada,
    BMI = coalesce(bmi_1, bmi_2),
    Study_Group = Study_group_new,
    Exercise_History = exercise_history,
    Comorbidities = comorbidities,
    Family_History_of_IBD = family_history_of_ibd,
    Smoking_Status = smoking_status,
    Alcohol_Intake = alcohol_intake,
    Prebiotics = supp_prebiotics,
    Probiotics = probiotics,
    Harvey_Bradshaw_Index = harvey_bradshaw_index,
    CRP = crp,
    Fecal_Calprotectin = fecal_calprotectin,
    General_Well_Being = general_well.being,
    Abdominal_Pain = abdominal_pain,
    Daily_Soft_Stools = daily_soft_stools,
    Advanced_Therapy_Changes = advanced_therapy_changes,
    Weight_Change = weight_change,
    Fatigue_Frequency = fatigue_frequency,
    Anxiety_Frequency = anxiety_frequency,
    Sleep_Difficulty_Frequency = sleep_difficulty_frequency,
    Abdominal_Bloating_Frequency = abdominal_bloating_frequency,
    Rectal_Bleeding_Frequency = rectal_bleeding_frequency,
    Feeling_Unwell_Frequency = feeling_unwell_frequency,
    Fruit_Avoidance_Active = fruit_avoidance_active,
    Excluded_Fruits_Active = excluded_fruits_active,
    Vegetable_Avoidance_Active = vegetable_avoidance_active,
    Excluded_Vegetables_Active = excluded_vegetables_active,
    Whole_Grain_Avoidance_Active = whole_grain_avoidance_active,
    Excluded_Whole_Grains_Active = excluded_whole_grains_active,
    Nut_Seed_Avoidance_Active = nut_seed_avoidance_active,
    Excluded_Nuts_Seeds_Active = excluded_nuts_seeds_active,
    Lactose_Avoidance_Active = lactose_avoidance_active,
    Excluded_Lactose_Active = excluded_lactose_active,
    Gluten_Avoidance_Active = gluten_avoidance_active,
    Excluded_Gluten_Active = excluded_gluten_active,
    Spicy_Food_Avoidance_Active = spicy_food_avoidance_active,
    Excluded_Spicy_Foods_Active = excluded_spicy_foods_active,
    Fat_Food_Avoidance_Active = fat_food_avoidance_active,
    Excluded_Fat_Foods_Active = exclued_fat_foods_active,
    Fruit_Avoidance_Remission = fruit_avoidance_rem,
    Excluded_Fruits_Remission = excluded_fruits_rem,
    Vegetable_Avoidance_Remission = vegetable_avoidance_rem,
    Excluded_Vegetables_Remission = excluded_vegetables_rem,
    Whole_Grain_Avoidance_Remission = whole_grain_avoidance_rem,
    Excluded_Whole_Grains_Remission = excluded_whole_grains_rem,
    Nut_Seed_Avoidance_Remission = nut_seed_avoidance_rem,
    Excluded_Nuts_Seeds_Remission = excluded_nuts_seeds_rem,
    Lactose_Avoidance_Remission = lactose_avoidance_rem,
    Excluded_Lactose_Remission = excluded_lactose_rem,
    Gluten_Avoidance_Remission = gluten_avoidance_rem,
    Excluded_Gluten_Remission = excluded_gluten_rem,
    Spicy_Food_Avoidance_Remission = spicy_food_avoidance_rem,
    Excluded_Spicy_Foods_Remission = excluded_spicy_foods_rem,
    Fat_Food_Avoidance_Remission = fat_food_avoidance_rem,
    Excluded_Fat_Foods_Remission = excluded_fat_foods_rem
  ) %>%
  distinct(ID, .keep_all = TRUE)

# Flags for mycobiome and diet
participant_choices <- list(
  "Has Mycobiome Data"    = sort(participants$ID[participants$Has_Mycobiome]),
  "Diet Data Only"        = sort(participants$ID[!participants$Has_Mycobiome & participants$Has_Diet]),
  "Characteristics Only"  = sort(participants$ID[!participants$Has_Mycobiome & !participants$Has_Diet])
)

score_columns <- c(
  "MPGrain..oz.eq.",
  "MPVeg..c.eq.",
  "MPFruit..c.eq.",
  "MPDairy..c.eq.",
  "MPProt..oz.eq.",
  "TotFib..g."
)

cfg_targets <- c(
  "MPGrain..oz.eq." = 5.0,
  "MPVeg..c.eq." = 2.5,
  "MPFruit..c.eq." = 2.0,
  "MPDairy..c.eq." = 2.0,
  "MPProt..oz.eq." = 5.5
)

key_vitamin_columns <- c(
  "Vitamin A (IU)" = make.names("Vit A-IU (IU)"),
  "Vitamin B1 (mg)" = make.names("Vit B1 (mg)"),
  "Vitamin B2 (mg)" = make.names("Vit B2 (mg)"),
  "Vitamin B3 (mg)" = make.names("Vit B3 (mg)"),
  "Vitamin B6 (mg)" = make.names("Vit B6 (mg)"),
  "Vitamin B12 (mcg)" = make.names("Vit B12 (mcg)"),
  "Vitamin C (mg)" = make.names("Vit C (mg)"),
  "Vitamin D (mcg)" = make.names("Vit D-mcg (mcg)"),
  "Vitamin E (IU)" = make.names("Vit E-IU (IU)"),
  "Folate (mcg)" = make.names("Folate (mcg)"),
  "Vitamin K (mcg)" = make.names("Vit K (mcg)")
)

additional_dietary_columns <- c(
  "Total Soluble Fibre (g)" = make.names("TotSolFib (g)"),
  "Total Insoluble Fibre (g)" = make.names("TotInsolFib (g)"),
  "Soluble Fibre (g)" = make.names("SolFib(16) (g)"),
  "Insoluble Fibre (g)" = make.names("InsolFib(16) (g)"),
  "Soluble Non-Digest Carbs (g)" = make.names("Sol Non-Digest Carb (g)"),
  "Insoluble Non-Digest Carbs (g)" = make.names("Insol Non-Digest Carb (g)"),
  "Fat (g)" = make.names("Fat (g)"),
  "Saturated Fat (g)" = make.names("SatFat (g)"),
  "Monounsaturated Fat (g)" = make.names("MonoFat (g)"),
  "Polyunsaturated Fat (g)" = make.names("PolyFat (g)"),
  "Trans Fat (g)" = make.names("TransFat (g)"),
  "Cholesterol (mg)" = make.names("Chol (mg)"),
  "Omega-3 (g)" = make.names("Omega3 (g)"),
  "Omega-6 (g)" = make.names("Omega6 (g)"),
  "Phe (g)" = make.names("Phe (g)"),
  "Trp (g)" = make.names("Trp (g)"),
  "Tyr (g)" = make.names("Tyr (g)"),
  "Alcohol (g)" = make.names("Alc (g)"),
  "Caffeine (mg)" = make.names("Caff (mg)"),
  "Artificial Sweeteners (mg)" = make.names("ArtSw (mg)"),
  "Aspartame (mg)" = make.names("Aspar (mg)"),
  "Saccharin (mg)" = make.names("Sacch (mg)"),
  "Sugar Alcohols (g)" = make.names("SugAl (g)"),
  "Erythritol (g)" = make.names("Eryth (g)"),
  "Glycerol (g)" = make.names("Glyc (g)"),
  "Inositol (g)" = make.names("Inos (g)"),
  "Lactitol (g)" = make.names("Lacti (g)"),
  "Maltitol (g)" = make.names("Malti (g)"),
  "Mannitol (g)" = make.names("Mann (g)"),
  "Sorbitol (g)" = make.names("Sorb (g)"),
  "Xylitol (g)" = make.names("Xylit (g)")
)

additional_dietary_groups <- list(
  "Fibre and Carbs" = c(
    "Total Soluble Fibre (g)",
    "Total Insoluble Fibre (g)",
    "Soluble Fibre (g)",
    "Insoluble Fibre (g)",
    "Soluble Non-Digest Carbs (g)",
    "Insoluble Non-Digest Carbs (g)"
  ),
  "Fats and Lipids" = c(
    "Fat (g)",
    "Saturated Fat (g)",
    "Monounsaturated Fat (g)",
    "Polyunsaturated Fat (g)",
    "Trans Fat (g)",
    "Cholesterol (mg)",
    "Omega-3 (g)",
    "Omega-6 (g)"
  ),
  "Amino Acids and Other Compounds" = c(
    "Phe (g)",
    "Trp (g)",
    "Tyr (g)",
    "Alcohol (g)",
    "Caffeine (mg)"
  ),
  "Sugars" = c(
    "Artificial Sweeteners (mg)",
    "Aspartame (mg)",
    "Saccharin (mg)",
    "Sugar Alcohols (g)",
    "Erythritol (g)",
    "Glycerol (g)",
    "Inositol (g)",
    "Lactitol (g)",
    "Maltitol (g)",
    "Mannitol (g)",
    "Sorbitol (g)",
    "Xylitol (g)"
  )
)

format_prevalence <- function(value) {
  if (is.null(value) || length(value) == 0 || is.na(value)) {
    return("NA")
  }
  if (value %in% c(1, "1")) {
    return("Yes")
  }
  if (value %in% c(0, "0")) {
    return("No")
  }
  as.character(value)
}

get_fibre_target <- function(sex_value) {
  sex_clean <- ""
  if (!is.null(sex_value) && length(sex_value) > 0 && !is.na(sex_value[1])) {
    sex_clean <- tolower(trimws(as.character(sex_value[1])))
  }
  if (sex_clean %in% c("female", "woman", "f")) {
    return(25.0)
  }
  if (sex_clean %in% c("male", "man", "m")) {
    return(38.0)
  }
  NA_real_
}

format_missing <- function(value) {
  if (is.null(value) || length(value) == 0 || is.na(value) || trimws(as.character(value)) == "") {
    return("NA")
  }
  as.character(value)
}

to_display_case <- function(value) {
  text <- format_missing(value)
  if (identical(text, "NA")) {
    return(text)
  }

  parts <- strsplit(tolower(text), "(?<=[[:alpha:]])(?=[[:upper:]])|[[:space:]]+", perl = TRUE)[[1]]
  parts <- parts[nzchar(parts)]
  formatted <- vapply(
    parts,
    function(part) paste0(toupper(substr(part, 1, 1)), substr(part, 2, nchar(part))),
    character(1)
  )
  display_text <- paste(formatted, collapse = " ")
  display_text <- gsub("\\bIbs\\b", "IBS", display_text)
  display_text <- gsub("\\bIbd\\b", "IBD", display_text)
  display_text
}

strip_scale_prefix <- function(value) {
  text <- format_missing(value)
  if (identical(text, "NA")) {
    return(text)
  }

  cleaned <- sub("^\\s*\\d+\\s+", "", text)
  cleaned_lower <- tolower(cleaned)
  paste0(toupper(substr(cleaned_lower, 1, 1)), substr(cleaned_lower, 2, nchar(cleaned_lower)))
}

extract_scale_score <- function(value) {
  text <- format_missing(value)
  if (identical(text, "NA")) {
    return(NA_real_)
  }

  score <- suppressWarnings(as.numeric(sub("^\\s*(\\d+).*$", "\\1", text)))
  if (is.na(score)) {
    return(NA_real_)
  }
  score
}

calculate_qol_burden <- function(values) {
  raw_scores <- vapply(values, extract_scale_score, numeric(1))
  if (all(is.na(raw_scores))) {
    return(NA_real_)
  }

  sum(pmax(0, 7 - raw_scores), na.rm = TRUE)
}

has_qol_data_access <- function(study_group_value) {
  if (is.null(study_group_value) || length(study_group_value) == 0 || is.na(study_group_value[1])) {
    return(FALSE)
  }

  study_group_clean <- tolower(trimws(as.character(study_group_value[1])))
  !study_group_clean %in% c("non-ibd", "non ibd", "non_ibd")
}

participant_df <- participant_df |>
  rowwise() |>
  mutate(
    `QoL Score` = calculate_qol_burden(c(
      fatigue_frequency, anxiety_frequency, sleep_difficulty_frequency,
      abdominal_bloating_frequency, rectal_bleeding_frequency, feeling_unwell_frequency
    ))
  ) |>
  ungroup()

qol_burden_total <- function(n_items) {
  n_items * 6
}

qol_position_pct <- function(score, total) {
  if (is.na(score) || is.na(total) || total <= 0) {
    return(NA_real_)
  }

  pmax(0, pmin(100, (score / total) * 100))
}

format_weight_change <- function(value) {
  if (is.null(value) || length(value) == 0 || is.na(value) || !is.finite(as.numeric(value))) {
    return("NA")
  }

  numeric_value <- as.numeric(value)
  if (numeric_value > 0) {
    return(paste0("+", format_numeric(numeric_value, digits = 0), " lbs"))
  }
  if (numeric_value < 0) {
    return(paste0(format_numeric(numeric_value, digits = 0), " lbs"))
  }
  "No change"
}

format_numeric <- function(value, digits = 2) {
  if (is.null(value) || length(value) == 0 || is.na(value) || !is.finite(value)) {
    return("NA")
  }
  sprintf(paste0("%.", digits, "f"), value)
}

format_avoidance_detail <- function(summary_value, excluded_value) {
  summary_text <- format_missing(summary_value)
  excluded_text <- format_missing(excluded_value)
  if (excluded_text == "NA" || identical(summary_text, "No avoidance")) {
    return(summary_text)
  }
  paste0(summary_text, " (", excluded_text, ")")
}
