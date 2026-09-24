# characteristics.R: Clean participant characteristics raw data and export CSV

suppressPackageStartupMessages({
  library(countrycode)
  library(dplyr)
  library(readxl)
  library(readr)
  library(readxl)
})

source("src/participant_id.R")

required_output_columns <- c(
  "participant_id",
  "age",
  "gender",
  "ethnicity",
  "country_of_origin",
  "years_living_in_canada",
  "bmi_1",
  "bmi_2",
  "exercise_history",
  "comorbidities",
  "family_history_of_ibd",
  "smoking_status",
  "alcohol_intake",
  "supp_prebiotics",
  "probiotics",
  "harvey_bradshaw_index",
  "general_well-being",
  "abdominal_pain",
  "daily_soft_stools",
  "advanced_therapy_changes",
  "weight_change",
  "fatigue_frequency",
  "anxiety_frequency",
  "sleep_difficulty_frequency",
  "abdominal_bloating_frequency",
  "rectal_bleeding_frequency",
  "feeling_unwell_frequency",
  "fruit_avoidance_active",
  "excluded_fruits_active",
  "vegetable_avoidance_active",
  "excluded_vegetables_active",
  "whole_grain_avoidance_active",
  "excluded_whole_grains_active",
  "nut_seed_avoidance_active",
  "excluded_nuts_seeds_active",
  "lactose_avoidance_active",
  "excluded_lactose_active",
  "gluten_avoidance_active",
  "excluded_gluten_active",
  "spicy_food_avoidance_active",
  "excluded_spicy_foods_active",
  "fat_food_avoidance_active",
  "exclued_fat_foods_active",
  "fruit_avoidance_rem",
  "excluded_fruits_rem",
  "vegetable_avoidance_rem",
  "excluded_vegetables_rem",
  "whole_grain_avoidance_rem",
  "excluded_whole_grains_rem",
  "nut_seed_avoidance_rem",
  "excluded_nuts_seeds_rem",
  "lactose_avoidance_rem",
  "excluded_lactose_rem",
  "gluten_avoidance_rem",
  "excluded_gluten_rem",
  "spicy_food_avoidance_rem",
  "excluded_spicy_foods_rem",
  "fat_food_avoidance_rem",
  "excluded_fat_foods_rem"
)

validate_required_columns <- function(df) {
  missing <- setdiff(required_output_columns, names(df))
  if (length(missing) > 0) {
    stop(
      "Cleaned characteristics output is missing required downstream columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
}

mangle_duplicate_raw_names <- function(nms) {
  out <- nms
  counts <- list()
  for (i in seq_along(nms)) {
    nm <- nms[i]
    if (is.na(nm) || !nzchar(nm)) {
      out[i] <- paste0("unnamed_column_", i)
      next
    }
    count <- if (is.null(counts[[nm]])) 0L else counts[[nm]]
    if (count == 0L) {
      out[i] <- nm
      counts[[nm]] <- 1L
    } else {
      out[i] <- paste0(nm, ".", count)
      counts[[nm]] <- count + 1L
    }
  }
  out
}

clean_column_names <- function(nms) {
  nms <- gsub("^\\d+\\.\\s*", "", nms, perl = TRUE)
  nms <- trimws(nms)
  nms <- tolower(nms)
  nms <- gsub("\\s+", "_", nms, perl = TRUE)
  nms <- gsub(":", "", nms, fixed = TRUE)
  nms <- gsub("[_\\.]+$", "", nms, perl = TRUE)
  nms
}

apply_renames <- function(df, renames) {
  for (old_name in names(renames)) {
    if (old_name %in% names(df)) {
      names(df)[names(df) == old_name] <- renames[[old_name]]
    }
  }
  df
}

strip_punct_lower <- function(x) {
  x <- as.character(x)
  x <- tolower(trimws(x))
  gsub("[^[:alnum:][:space:]]", "", x, perl = TRUE)
}

to_numeric_coerce <- function(x) {
  suppressWarnings(as.numeric(x))
}

convert_country_iso3 <- function(x) {
  vapply(
    x,
    function(value) {
      if (is.na(value) || !nzchar(trimws(as.character(value)))) {
        return("UNKNOWN")
      }
      label <- tools::toTitleCase(tolower(trimws(as.character(value))))
      code <- countrycode(label, origin = "country.name", destination = "iso3c", warn = FALSE)
      if (is.na(code)) {
        "UNKNOWN"
      } else {
        code
      }
    },
    FUN.VALUE = character(1),
    USE.NAMES = FALSE
  )
}

scrub_impossible_bmi <- function(bmi) {
  impossible <- !is.na(bmi) & (bmi < 10 | bmi > 100)
  violation_count <- sum(impossible)
  if (violation_count > 0) {
    message("WARNING: Scrubbing ", violation_count, " impossible BMI values.")
  }
  bmi[impossible] <- NA_real_
  bmi
}

compute_bmi <- function(weight_lbs, height_cm) {
  weight_kg <- weight_lbs * 0.453592
  height_m <- height_cm / 100
  weight_kg / (height_m^2)
}

characteristics_column_renames <- c(
  "comorbidities_(leave_blank_if_none)" = "comorbidities",
  "smoklng_status" = "smoking_status",
  "have_you_taken_antibiotics_in_the_last_2_months?" = "antbiotics_last_2months",
  "prebiotics_non-digestible_fibres_found_in_supplements_such_as_benefiber,_metamucil,_etc" = "supp_prebiotics",
  "probiotics_live_microorganisms,_like_bacteria_or_yeast,_taken_in_powder_or_capsule_form_such_as_visbiome,_florastor,_etc" = "probiotics",
  "postbiotics_molecules/chemicals_produced_by_probiotics_when_they_ferment_prebiotics_such_as_butyrate,_etc" = "postbiotics",
  "if_yes,_please_specify_pre-biotics_used" = "brand_prebiotics",
  "if_yes,_please_specify_pro-biotics_used" = "brand_probiotics",
  "if_yes,_please_specify_post-biotic_used" = "brand_postbiotics",
  "participant_id.1" = "participant_id_2",
  "general_well-being_(see_descriptors_at_the_end)" = "general_well-being",
  "abdominal_pain_(see_descriptors)" = "abdominal_pain",
  "number_of_liquid_or_soft_stools_per_day_(yesterday)" = "daily_soft_stools",
  "additional_manifestations_(choice=none_=_0)" = "no_additional_manifestations",
  "additional_manifestations_(choice=arthalgia_=_1)" = "arthalgia",
  "additional_manifestations_(choice=uveitis_=_1)" = "uveitis",
  "additional_manifestations_(choice=erythema_nodosum_=_1)" = "erythema_nodosum",
  "additional_manifestations_(choice=aphthous_ulcer_=_1)" = "aphthous_ulcer",
  "additional_manifestations_(choice=pyoderma_gangrenosum_=_1)" = "pyoderma_gangrenosum",
  "additional_manifestations_(choice=anal_fissure_=_1)" = "anal_fissure",
  "additional_manifestations_(choice=new_fistula_=_1)" = "new_fistula",
  "additional_manifestations_(choice=abscess_=_1)" = "abscess",
  "total_harvey_bradshaw_index_score_[sum_of_all_the_above_items]" = "harvey_bradshaw_index",
  "changes_in_advanced_therapy_since_the_last_visit" = "advanced_therapy_changes",
  "have_you_experienced_gastroenteritis_or_traveled_outside_of_canada_(excluding_the_united_states)_in_the_last_month?_gastroenteritis_inflammation_of_the_stomach_and_intestines,_characterized_by_symptoms_such_as_diarrhea_and_vomiting,_often_caused_by_viral_or_bacterial_infections" = "gastroenteritis_outside_canada",
  "are_you_pregnant_or_breastfeeding?" = "pregnant_or_breastfeeding",
  "are_you_currently_using_contraception?" = "contraception",
  "if_yes,_please_specify_the_method_of_contraception_being_used_(choice=condoms)" = "condom_contraceptive",
  "if_yes,_please_specify_the_method_of_contraception_being_used_(choice=oral_contraceptives_(e.g.,_birth_control_pills))" = "oral_contraceptive",
  "if_yes,_please_specify_the_method_of_contraception_being_used_(choice=implants_(e.g.,_nexplanon))" = "implant_contraceptive",
  "if_yes,_please_specify_the_method_of_contraception_being_used_(choice=intrauterine_(iu)_contraception_(e.g.,_iud))" = "intrauterine_contraceptive",
  "is_the_patient_meeting_the_inclusion_and_exclusion_criteria?" = "inclusion_exclusion_criteria",
  "how_would_you_describe_your_gender_identity?_for_example,_some_people_identify_as_a_woman,_a_trans_man,_genderqueer,_etc" = "gender_identity",
  "have_you_experienced_an_increase_or_decrease_in_weight_over_the_last_6_months?" = "6_month_weight_change",
  "if_you_have_experienced_a_change_in_weight,_please_specify_the_amount_(lbs)" = "weight_change_amount",
  "have_you_experienced_reduced_oral_intake_over_the_last_month?" = "reduced_oral_intake",
  "when_was_your_last_menstrual_cycle_(first_day_of_your_last_period)?_(mm/dd/yy)" = "last_menstrual_cycle",
  "if_applicable,_do_gastrointestinal_symptoms,_such_as_pain,_bloating,_diarrhoea_etc.,_worsen_around_the_time_of_your_menstrual_cycle?" = "cycle_worsens_symptoms",
  "have_you_ever_tried_modifying_the_texture_of_your_foods_during_a_flare-up?_(e.g.,_blending_solid_foods_such_as_blueberries_into_a_smoothie_instead)" = "modifying_food_texture",
  "if_answered_yes_to_the_previous_question,_did_you_find_this_strategy_helpful_in_relieving_some_of_your_flare-up_symptoms?" = "modifying_food_texture_helps",
  "fruits_(e.g.,_apples,_oranges)" = "fruit_avoidance_active",
  "specify_excluded_fruits_(separate_each_with_a_comma)" = "excluded_fruits_active",
  "vegetables_(e.g.,_cabbage,_cauliflower)" = "vegetable_avoidance_active",
  "specify_excluded_vegetables_(separate_each_with_a_comma)" = "excluded_vegetables_active",
  "whole_grains_(e.g.,_wheat,_oats)" = "whole_grain_avoidance_active",
  "specify_excluded_whole_grains_(separate_each_with_a_comma)" = "excluded_whole_grains_active",
  "nuts_and_seeds_(e.g.,_cashews,_sesame_seeds)" = "nut_seed_avoidance_active",
  "specify_excluded_nuts_and_seeds_(separate_each_with_a_comma)" = "excluded_nuts_seeds_active",
  "lactose-containing_foods_(e.g.,_ice_cream,_cheese)" = "lactose_avoidance_active",
  "specify_excluded_lactose-containing_foods_(separate_each_with_a_comma)" = "excluded_lactose_active",
  "gluten-containing_foods_(e.g.,_bread,_pasta)" = "gluten_avoidance_active",
  "specify_excluded_gluten-containing_foods_(separate_each_with_a_comma)" = "excluded_gluten_active",
  "spicy_foods_(e.g.,_chili_peppers,_hot_sauces)" = "spicy_food_avoidance_active",
  "specify_excluded_spicy_foods_(separate_each_with_a_comma)" = "excluded_spicy_foods_active",
  "high_fat_foods_(e.g.,_deep-fried_items,_fatty_cuts_of_meat)" = "fat_food_avoidance_active",
  "specify_excluded_high-fat_foods_(separate_each_with_a_comma)" = "exclued_fat_foods_active",
  "fruits_(e.g.,_apples,_citrus_fruits)" = "fruit_avoidance_rem",
  "specify_excluded_fruits_(separate_each_with_a_comma).1" = "excluded_fruits_rem",
  "vegetables_(e.g.,_cabbage,_cauliflower).1" = "vegetable_avoidance_rem",
  "specify_excluded_vegetables_(separate_each_with_a_comma).1" = "excluded_vegetables_rem",
  "whole_grains_(e.g.,_wheat,_oats).1" = "whole_grain_avoidance_rem",
  "specify_excluded_whole_grains_(separate_each_with_a_comma).1" = "excluded_whole_grains_rem",
  "nuts_and_seeds_(e.g.,_cashews,_sesame_seeds).1" = "nut_seed_avoidance_rem",
  "specify_excluded_nuts_and_seeds_(separate_each_with_a_comma).1" = "excluded_nuts_seeds_rem",
  "lactose-containing_foods_(e.g.,_ice_cream,_cheese).1" = "lactose_avoidance_rem",
  "specify_excluded_lactose-containing_foods_(separate_each_with_a_comma).1" = "excluded_lactose_rem",
  "gluten-containing_foods_(e.g.,_bread,_pasta).1" = "gluten_avoidance_rem",
  "specify_excluded_gluten-containing_foods_(separate_each_with_a_comma).1" = "excluded_gluten_rem",
  "spicy_foods_(e.g.,_chili_peppers,_hot_sauces).1" = "spicy_food_avoidance_rem",
  "specify_excluded_spicy_foods_(separate_each_with_a_comma).1" = "excluded_spicy_foods_rem",
  "high_fat_foods_(e.g.,_deep-fried_items,_fatty_cuts_of_meat).1" = "fat_food_avoidance_rem",
  "specify_excluded_high-fat_foods_(separate_each_with_a_comma).1" = "excluded_fat_foods_rem",
  "i_am_a_picky_eater" = "picky_eater",
  "i_dislike_most_of_the_foods_that_other_people_like" = "dislike_liked_foods",
  "the_list_of_foods_that_i_like_and_will_eat_is_shorter_than_the_list_of_foods_i_won't_eat" = "like_few_foods",
  "i_am_not_very_interested_in_eating_i_seem_to_have_a_smaller_appetite_than_other_people" = "small_appetite",
  "i_have_to_push_myself_to_eat_regular_meals_throughout_the_day,_or_to_eat_a_large_enough_amount_of_food_at_meals" = "difficulty_eating_regularly",
  "even_when_i_am_eating_a_food_i_really_like,_it_is_hard_for_me_to_eat_a_large_enough_volume_at_meals" = "difficulty_eating_high_volumes",
  "i_avoid_or_put_off_eating_because_i_am_afraid_of_gi_discomfort,_chocking_or,_vomiting" = "avoid_eating",
  "i_restrict_myself_to_certain_foods_because_i_am_afraid_that_other_foods_will_cause_gi_discomfort,_chocking,_or_vomiting" = "restrict_certain_foods",
  "i_eat_small_portions_because_i_am_afraid_of_gi_discomfort,_chocking,_or_vomiting" = "eat_small_portions",
  "example_how_often_have_you_felt_unwell_as_a_result_of_your_bowel_problem_in_the_past_2_weeks?" = "bowel_ailment_frequency",
  "how_frequent_have_your_bowel_movements_been_during_the_last_two_weeks?_please_indicate_how_frequent_your_bowel_movements_have_been_during_the_last_two_weeks_by_picking_one_of_the_options_from" = "bowel_movement_frequency",
  "how_often_has_the_feeling_of_fatigue_or_of_being_tired_and_worn_out_been_a_problem_for_you_during_the_last_2_weeks?_please_indicate_how_often_the_feeling_of_fatigue_or_tiredness_has_been_a_problem_for_you_during_the_last_2_weeks_by_picking_one_of_the_options_from" = "fatigue_frequency",
  "how_often_during_the_last_2_weeks_have_you_felt_frustrated,_impatient,_or_restless?_please_choose_an_option_from" = "frustration_frequency",
  "how_often_during_the_last_2_weeks_have_you_been_unable_to_attend_school_or_do_your_work_because_of_your_bowel_problem?_please_choose_an_option_from" = "work_absence_frequency",
  "how_much_of_the_time_during_the_last_2_weeks_have_your_bowel_movements_been_loose?_please_choose_an_option_from" = "loose_movement_frequency",
  "how_much_energy_have_you_had_during_the_last_2_weeks?_please_choose_an_option_from" = "energy_level",
  "how_often_during_the_last_2_weeks_did_you_feel_worried_about_the_possibility_of_needing_to_have_surgery_because_of_your_bowel_problem?_please_choose_an_option_from" = "surgery_concern_frequency",
  "how_often_during_the_last_2_weeks_have_you_had_to_delay_or_cancel_a_social_engagement_because_of_your_bowel_problem?_please_choose_an_option_from" = "social_absence_frequency",
  "how_often_during_the_last_2_weeks_have_you_been_troubled_by_cramps_in_your_abdomen?_please_choose_an_option_from" = "abdomen_cramp_frequency",
  "how_often_during_the_last_2_weeks_have_you_felt_generally_unwell?_please_choose_an_option_from" = "feeling_unwell_frequency",
  "how_often_during_the_last_2_weeks_have_you_been_troubled_because_of_fear_of_not_finding_a_washroom?_please_choose_an_option_from" = "washroom_concern_frequency",
  "how_much_difficulty_have_you_had,_as_a_result_of_your_bowel_problems,_doing_leisure_or_sports_activities_you_would_have_liked_to_have_done_during_the_last_2_weeks?_please_choose_an_option_from" = "sport_difficulty_frequency",
  "how_often_during_the_last_2_weeks_have_you_been_troubled_by_pain_in_the_abdomen?_please_choose_an_option_from" = "abdomen_pain_frequency",
  "how_often_during_the_last_2_weeks_have_you_had_problems_getting_a_good_night's_sleep,_or_been_troubled_by_waking_up_during_the_night?_please_choose_an_option_from" = "sleep_difficulty_frequency",
  "how_often_during_the_last_2_weeks_have_you_felt_depressed_or_discouraged?_please_choose_an_option_from" = "depressed_dscouraged_frequency",
  "how_often_during_the_last_2_weeks_have_you_had_to_avoid_attending_events_where_there_was_no_washroom_close_at_hand?_please_choose_an_option_from" = "avoid_no_washroom_frequency",
  "overall,_in_the_last_2_weeks,_how_much_of_a_problem_have_you_had_with_passing_large_amounts_of_gas?_please_choose_an_option_from" = "excess_gas_frequency",
  "overall,_in_the_last_2_weeks,_how_much_of_a_problem_have_you_had_maintaining_or_getting_to,_the_weight_you_would_like_to_be_at?_please_choose_an_option_from" = "desired_weight_challenge_frequency",
  "many_patients_with_bowel_problems_often_have_worries_and_anxieties_related_to_their_illness._these_include_worries_about_getting_cancer,_worries_about_never_feeling_any_better,_and_worries_about_having_a_relapse._in_general,_how_often_during_the_last_2_weeks_have_you_felt_worried_or_anxious?_please_choose_an_option_from" = "anxiety_frequency",
  "how_much_of_the_time_during_the_last_2_weeks_have_you_been_troubled_by_a_feeling_of_abdominal_bloating?_please_choose_an_option_from" = "abdominal_bloating_frequency",
  "how_often_during_the_last_2_weeks_have_you_felt_relaxed_and_free_of_tension?_please_choose_an_option_from" = "relaxed_frequency",
  "how_much_of_the_time_during_the_last_2_weeks_have_you_had_a_problem_with_rectal_bleeding_with_your_bowel_movements?_please_choose_an_option_from" = "rectal_bleeding_frequency",
  "how_much_of_the_time_during_the_last_2_weeks_have_you_felt_embarrassed_as_a_result_of_your_bowel_problem?_please_choose_an_option_from" = "embarrassment_frequency",
  "how_much_of_the_time_during_the_last_2_weeks_have_you_been_troubled_by_a_feeling_of_having_to_go_to_the_bathroom_even_though_your_bowels_were_empty?_please_choose_an_option_from" = "empty_bowel_bathroom_trips",
  "how_much_of_the_time_during_the_last_2_weeks_have_you_felt_tearful_or_upset?_please_choose_an_option_from" = "upset_frequency",
  "how_much_of_the_time_during_the_last_2_weeks_have_you_been_troubled_by_accidental_soiling_of_your_underpants?_please_choose_an_option_from" = "accidental_soiling_frequency",
  "how_much_of_the_time_during_the_last_2_weeks_have_you_felt_angry_as_a_result_of_your_bowel_problem?_please_choose_an_option_from" = "anger_frequency",
  "to_what_extent_has_your_bowel_problem_limited_sexual_activity_during_the_last_2_weeks?_please_choose_an_option_from" = "limit_sex_frequency",
  "how_much_of_the_time_during_the_last_2_weeks_have_you_been_troubled_by_nausea_or_feeling_sick_to_your_stomach?_please_choose_an_option_from" = "nausea_frequeuncy",
  "how_much_of_the_time_during_the_last_2_weeks_have_you_felt_irritable?_please_choose_an_option_from" = "irritation_frequency",
  "how_often_during_the_past_2_weeks_have_you_felt_a_lack_of_understanding_from_others?_please_choose_an_option_from" = "lack_of_understanding",
  "how_satisfied,_happy,_or_pleased_have_you_been_with_your_personal_life_during_the_past_2_weeks?_please_choose_one_of_the_following_options_from" = "happiness_satisfaction_frequency"
)

project_root <- normalizePath(".", winslash = "/", mustWork = TRUE)
xlsx_path <- file.path(project_root, "data", "raw", "SYN_Participant Characteristics.xlsx")
csv_path  <- file.path(project_root, "data", "raw", "SYN_Participant Characteristics(Sheet1).csv")
output_path <- file.path(project_root, "data", "processed", "cleaned_characteristics.csv")

# Prefer the Excel file; fall back to the CSV export
if (file.exists(xlsx_path)) {
  message("Reading characteristics from Excel: ", xlsx_path)
  df <- as.data.frame(
    suppressMessages(readxl::read_excel(xlsx_path, sheet = 1, na = c("", "NA"))),
    stringsAsFactors = FALSE
  )
  # readxl auto-deduplicates with ...N suffixes; strip them so the downstream
  # name-mangling pipeline (mangle_duplicate_raw_names) handles duplicates
  # the same way it does for the CSV path.
  names(df) <- sub("\\.{3}\\d+$", "", names(df))
} else if (file.exists(csv_path)) {
  message("Excel not found; reading characteristics from CSV: ", csv_path)
  df <- readr::read_csv(csv_path, na = c("", "NA"))
} else {
  stop(
    "Raw characteristics file not found. Expected:\n",
    "  XLSX: ", xlsx_path, "\n",
    "  CSV:  ", csv_path,
    call. = FALSE
  )
}

# Resolve non-breaking space in the active vegetable column before other name fixes
veg_active <- "Vegetables (e.g., cabbage, cauliflower):"
veg_nbsp <- paste0("Vegetables", "\u00a0", "(e.g., cabbage, cauliflower):")
if (veg_active %in% names(df)) {
  names(df)[names(df) == veg_active] <- paste0(veg_active, ".1")
}
if (veg_nbsp %in% names(df)) {
  names(df)[names(df) == veg_nbsp] <- veg_active
}

names(df) <- gsub("\u00a0", " ", names(df), fixed = TRUE)

names(df) <- mangle_duplicate_raw_names(names(df))
names(df) <- clean_column_names(names(df))

df$participant_id <- normalize_participant_id(
  strip_punct_lower(df$participant_id)
)

df$event_name <- toupper(trimws(df$event_name))
df$event_name[is.na(df$event_name) | !nzchar(df$event_name)] <- "MISSING"

df$age <- to_numeric_coerce(df$age)
df$age[df$age < 0] <- NA_real_
median_age <- stats::median(df$age, na.rm = TRUE)
df$age[is.na(df$age)] <- median_age
df$age <- as.integer(df$age)

df$gender <- tolower(trimws(df$gender))
df$gender[is.na(df$gender)] <- "unknown"
df$gender_code <- ifelse(df$gender == "male", 0L, ifelse(df$gender == "female", 1L, NA_integer_))

df$ethnicity <- strip_punct_lower(df$ethnicity)
df$ethnicity[is.na(df$ethnicity) | !nzchar(df$ethnicity)] <- "missing"

similar_map <- c(
  "caucasian" = "white",
  "icelandicscottish" = "white",
  "european" = "white",
  "irish" = "white",
  "canadianjewish" = "white",
  "caucasien" = "white",
  "african american" = "black",
  "afr am" = "black",
  "b" = "black",
  "latino" = "hispanic",
  "latina" = "hispanic",
  "latinx" = "hispanic",
  "first nations" = "indigenous",
  "metis" = "indigenous",
  "inuit" = "indigenous"
)
df$eth_grouped <- ifelse(
  df$ethnicity %in% names(similar_map),
  unname(similar_map[df$ethnicity]),
  df$ethnicity
)

df$country_of_origin <- tolower(trimws(df$country_of_origin))
df$coi_iso3_code <- convert_country_iso3(df$country_of_origin)

df$years_living_in_canada <- to_numeric_coerce(df$years_living_in_canada)
impossible_timeline <- !is.na(df$years_living_in_canada) &
  !is.na(df$age) &
  df$years_living_in_canada > df$age
violation_count <- sum(impossible_timeline)
if (violation_count > 0) {
  message(
    "WARNING: Found ", violation_count,
    " rows where years in Canada > age. Setting to NaN."
  )
}
df$years_living_in_canada[impossible_timeline] <- NA_real_

df$`weight_(lbs)` <- to_numeric_coerce(df$`weight_(lbs)`)
df$`height_(cm)` <- to_numeric_coerce(df$`height_(cm)`)
df$`height_(cm)`[df$`height_(cm)` <= 0] <- NA_real_
df$bmi_1 <- suppressMessages(scrub_impossible_bmi(compute_bmi(df$`weight_(lbs)`, df$`height_(cm)`)))

exercise_map <- c(
  "sedentary lifestyle  - (little to no regular physical activity, spending a significant amount of inactive throughout the day)" = "sedentary",
  "irregular exercise - (engages in physical activity on a sporadic or inconsistent basis)" = "irregular",
  "regular exercise - (at least 150 minutes of moderate to vigorous-intensity aerobic physical activity per week)" = "regular"
)
df$exercise_history <- tolower(trimws(df$exercise_history))
df$exercise_history <- ifelse(
  df$exercise_history %in% names(exercise_map),
  unname(exercise_map[df$exercise_history]),
  df$exercise_history
)

df <- apply_renames(df, c("comorbidities_(leave_blank_if_none)" = "comorbidities"))
df$comorbidities <- tolower(trimws(df$comorbidities))
df$comorbidities[is.na(df$comorbidities)] <- "none"

binary_map <- c("yes" = 1L, "no" = 0L)

df$family_history_of_ibd <- tolower(trimws(df$family_history_of_ibd))
df$family_history_of_ibd <- ifelse(
  df$family_history_of_ibd %in% names(binary_map),
  unname(binary_map[df$family_history_of_ibd]),
  NA_integer_
)

df <- apply_renames(df, c("smoklng_status" = "smoking_status"))
df$smoking_status <- tolower(trimws(df$smoking_status))
df$smoking_status <- gsub("non[\\s_]smoker", "non-smoker", df$smoking_status, perl = TRUE)
df$smoking_status <- factor(
  df$smoking_status,
  levels = c("non-smoker", "former smoker", "current smoker"),
  ordered = TRUE
)

alcohol_ordinal_map <- c(
  "non-drinker" = "non-drinker",
  "social drinker (occasional or moderate alcohol consumption in social settings)" = "social drinker",
  "regular drinker (consistent and frequent alcohol consumption)" = "regular drinker"
)
df$alcohol_intake <- tolower(trimws(df$alcohol_intake))
df$alcohol_intake <- ifelse(
  df$alcohol_intake %in% names(alcohol_ordinal_map),
  unname(alcohol_ordinal_map[df$alcohol_intake]),
  df$alcohol_intake
)

map_binary_column <- function(x) {
  x <- tolower(trimws(x))
  ifelse(x %in% names(binary_map), unname(binary_map[x]), NA_integer_)
}

df$recreational_drug_use <- map_binary_column(df$recreational_drug_use)

df <- apply_renames(df, c(
  "have_you_taken_antibiotics_in_the_last_2_months?" = "antbiotics_last_2months",
  "prebiotics_non-digestible_fibres_found_in_supplements_such_as_benefiber,_metamucil,_etc" = "supp_prebiotics",
  "probiotics_live_microorganisms,_like_bacteria_or_yeast,_taken_in_powder_or_capsule_form_such_as_visbiome,_florastor,_etc" = "probiotics",
  "postbiotics_molecules/chemicals_produced_by_probiotics_when_they_ferment_prebiotics_such_as_butyrate,_etc" = "postbiotics",
  "if_yes,_please_specify_pre-biotics_used" = "brand_prebiotics",
  "if_yes,_please_specify_pro-biotics_used" = "brand_probiotics",
  "if_yes,_please_specify_post-biotic_used" = "brand_postbiotics"
))

df$antbiotics_last_2months <- map_binary_column(df$antbiotics_last_2months)
df$supp_prebiotics <- map_binary_column(df$supp_prebiotics)
df$probiotics <- map_binary_column(df$probiotics)
df$postbiotics <- map_binary_column(df$postbiotics)

df$brand_prebiotics[df$supp_prebiotics == 0L] <- "none"
df$brand_probiotics[df$probiotics == 0L] <- "none"
df$brand_postbiotics[df$postbiotics == 0L] <- "none"

df$brand_prebiotics <- tolower(trimws(df$brand_prebiotics))
df$brand_probiotics <- tolower(trimws(df$brand_probiotics))
df$brand_postbiotics <- tolower(trimws(df$brand_postbiotics))

df <- apply_renames(df, characteristics_column_renames)

df$`general_well-being` <- dplyr::recode(
  df$`general_well-being`,
  "Poor = 2" = "Poor = 0",
  "Slightly below Par = 1" = "Below Par = 1",
  "Very well = 0" = "Very Well = 2",
  .default = df$`general_well-being`
)

manifestation_cols <- c(
  "no_additional_manifestations",
  "arthalgia",
  "uveitis",
  "erythema_nodosum",
  "aphthous_ulcer",
  "pyoderma_gangrenosum",
  "anal_fissure",
  "new_fistula",
  "abscess"
)
manifestation_map <- c("Unchecked" = 0L, "Checked" = 1L)
for (col in manifestation_cols) {
  if (col %in% names(df)) {
    df[[col]] <- ifelse(df[[col]] %in% names(manifestation_map), unname(manifestation_map[df[[col]]]), NA_integer_)
  }
}

yes_no_cols <- c(
  "gastroenteritis_outside_canada",
  "pregnant_or_breastfeeding",
  "contraception",
  "inclusion_exclusion_criteria",
  "reduced_oral_intake",
  "modifying_food_texture",
  "modifying_food_texture_helps"
)
yes_no_map <- c("No" = 0L, "Yes" = 1L)
for (col in yes_no_cols) {
  if (col %in% names(df)) {
    df[[col]] <- ifelse(df[[col]] %in% names(yes_no_map), unname(yes_no_map[df[[col]]]), NA_integer_)
  }
}

df$`weight_(lbs).1` <- to_numeric_coerce(df$`weight_(lbs).1`)
df$`height_(cm).1` <- to_numeric_coerce(df$`height_(cm).1`)
df$`height_(cm).1`[df$`height_(cm).1` <= 0] <- NA_real_
df$bmi_2 <- suppressMessages(scrub_impossible_bmi(compute_bmi(df$`weight_(lbs).1`, df$`height_(cm).1`)))

df$weight_change_amount <- to_numeric_coerce(df$weight_change_amount)
df$weight_change <- dplyr::case_when(
  df$`6_month_weight_change` == "Increase" ~ df$weight_change_amount,
  df$`6_month_weight_change` == "Decrease" ~ -df$weight_change_amount,
  df$`6_month_weight_change` == "No change" ~ 0,
  TRUE ~ NA_real_
)

validate_required_columns(df)

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
readr::write_csv(df, output_path)

message("characteristics.R completed: cleaned data saved to ", output_path, ".")
