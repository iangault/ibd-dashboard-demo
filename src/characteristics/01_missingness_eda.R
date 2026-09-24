# 01_missingness_eda.R
# Summarize and plot missingness in cleaned participant characteristics.
# Input:  data/processed/cleaned_characteristics.csv
# Output: figures/characteristics/missingness_*.png

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(tidyr)
  library(viridisLite)
})

input_path <- file.path("data", "processed", "cleaned_characteristics.csv")
figure_dir <- file.path("figures", "characteristics")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

save_characteristics_plot <- function(plot, filename, width, height) {
  ggsave(
    file.path(figure_dir, filename),
    plot = plot,
    width = width,
    height = height,
    dpi = 300,
    bg = "white"
  )
}

classify_variable_group <- function(column) {
  case_when(
    column %in% c(
      "participant_id", "age", "gender", "gender_code", "ethnicity", "eth_grouped",
      "country_of_origin", "coi_iso3_code", "years_living_in_canada",
      "weight_(lbs)", "height_(cm)", "weight_(lbs).1", "height_(cm).1",
      "bmi_1", "bmi_2", "exercise_history", "comorbidities",
      "family_history_of_ibd", "smoking_status", "alcohol_intake",
      "recreational_drug_use", "event_name"
    ) ~ "Demographics",
    column %in% c(
      "harvey_bradshaw_index", "general_well-being", "abdominal_pain",
      "daily_soft_stools", "advanced_therapy_changes", "weight_change",
      "weight_change_amount", "6_month_weight_change"
    ) ~ "IBD clinical",
    grepl("_frequency$", column) ~ "Symptom frequency",
    grepl("avoidance|excluded_", column) ~ "Food avoidance",
    column %in% c(
      "supp_prebiotics", "probiotics", "postbiotics",
      "brand_prebiotics", "brand_probiotics", "brand_postbiotics",
      "antbiotics_last_2months"
    ) ~ "Supplements / antibiotics",
    grepl("manifestation|arthalgia|uveitis|erythema|aphthous|pyoderma|anal_fissure|new_fistula|abscess", column) ~ "Extra-intestinal manifestations",
    TRUE ~ "Other survey items"
  )
}

df <- read_csv(input_path, show_col_types = FALSE)
miss_tbl <- tibble(
  column = names(df),
  missing_pct = colMeans(is.na(df)) * 100,
  missing_n = colSums(is.na(df))
) |>
  mutate(
    variable_group = classify_variable_group(column),
    missing_bin = cut(
      missing_pct,
      breaks = c(-0.1, 0, 25, 50, 75, 100),
      labels = c("0%", "1–25%", "26–50%", "51–75%", "76–100%"),
      include.lowest = TRUE
    )
  )

theme_missingness <- theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

bin_summary <- miss_tbl |>
  count(missing_bin, name = "n_columns") |>
  mutate(missing_bin = factor(missing_bin, levels = c("0%", "1–25%", "26–50%", "51–75%", "76–100%")))

bin_plot <- ggplot(bin_summary, aes(x = missing_bin, y = n_columns, fill = missing_bin)) +
  geom_col(width = 0.7, show.legend = FALSE) +
  geom_text(aes(label = n_columns), vjust = -0.3, size = 3.5) +
  scale_fill_manual(
    values = viridisLite::cividis(nlevels(bin_summary$missing_bin))
  ) +
  labs(
    title = "Participant characteristics: columns by missingness band",
    subtitle = paste0(nrow(df), " participants, ", ncol(df), " variables"),
    x = "Share of participants with missing values",
    y = "Number of columns"
  ) +
  theme_missingness +
  expand_limits(y = max(bin_summary$n_columns) * 1.1)

save_characteristics_plot(bin_plot, "missingness_column_bins.png", width = 8, height = 5)

cols_with_missing <- miss_tbl |>
  filter(missing_pct > 0) |>
  arrange(desc(missing_pct))

column_plot <- ggplot(cols_with_missing, aes(x = reorder(column, missing_pct), y = missing_pct, fill = variable_group)) +
  geom_col(width = 0.8) +
  coord_flip() +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 25), expand = expansion(mult = c(0, 0.02))) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Missing values by variable",
    subtitle = "Only columns with at least one missing value are shown",
    x = NULL,
    y = "Missing (%)",
    fill = "Variable group"
  ) +
  theme_missingness +
  theme(axis.text.y = element_text(size = 6))

plot_height <- max(8, nrow(cols_with_missing) * 0.12)
save_characteristics_plot(column_plot, "missingness_by_column.png", width = 10, height = plot_height)

participant_missing <- tibble(
  participant_id = df$participant_id,
  missing_pct = rowMeans(is.na(df)) * 100
)

participant_plot <- ggplot(participant_missing, aes(x = missing_pct)) +
  geom_histogram(binwidth = 5, fill = "#4C78A8", color = "white", boundary = 0) +
  labs(
    title = "Per-participant missingness",
    subtitle = "Share of all characteristics variables missing per participant",
    x = "Missing (%) across variables",
    y = "Participants"
  ) +
  theme_missingness

save_characteristics_plot(participant_plot, "participant_missingness_histogram.png", width = 8, height = 5)

core_cols <- intersect(
  c(
    "age", "gender", "ethnicity", "bmi_1", "harvey_bradshaw_index",
    "general_well-being", "abdominal_pain", "daily_soft_stools",
    "fatigue_frequency", "anxiety_frequency", "sleep_difficulty_frequency",
    "abdominal_bloating_frequency", "rectal_bleeding_frequency", "feeling_unwell_frequency"
  ),
  names(df)
)

heatmap_df <- df |>
  select(participant_id, all_of(core_cols)) |>
  mutate(across(-participant_id, as.logical)) |>
  pivot_longer(-participant_id, names_to = "column", values_to = "is_missing") |>
  mutate(
    is_missing = if_else(is_missing, 1, 0),
    column = factor(column, levels = rev(core_cols))
  )

heatmap_plot <- ggplot(heatmap_df, aes(x = participant_id, y = column, fill = factor(is_missing))) +
  geom_tile(color = "white", linewidth = 0.1) +
  scale_fill_manual(
    values = c("0" = "#f0f0f0", "1" = "#d62728"),
    labels = c("Observed", "Missing"),
    name = NULL
  ) +
  labs(
    title = "Missingness map: core clinical and demographic fields",
    x = "Participant",
    y = NULL
  ) +
  theme_missingness +
  theme(
    axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 6),
    axis.text.y = element_text(size = 8),
    panel.grid = element_blank()
  )

save_characteristics_plot(heatmap_plot, "missingness_heatmap_core.png", width = 12, height = 6)

message(
  "01_missingness_eda.R completed: ",
  nrow(cols_with_missing), " columns with missing values plotted; figures saved to ",
  figure_dir, "."
)
