# 04_group_kde_plots.R
# Create study-group density plots for a curated subset of dietary variables.
# Input: `data/intermediate/diet_eda_inputs.rds`
# Output: `figures/diet/kde_numerical_columns_by_study_group.png`

source("src/diet/00_functions.R")

eda_inputs <- readRDS(diet_intermediate_path("diet_eda_inputs.rds"))
merged_df <- eda_inputs$merged

numeric_cols <- get_diet_numeric_cols(merged_df, start_col = 4)
numeric_cols <- numeric_cols[vapply(merged_df[, numeric_cols, drop = FALSE], function(x) dplyr::n_distinct(x, na.rm = TRUE) > 1, logical(1))]

# Keep the presentation figure focused and small enough to render reliably.
preferred_cols <- c(
  "Cals (kcal)",
  "TotFib (g)",
  "Sugar (g)",
  "SugAdd (g)",
  "Fat (g)",
  "Omega3 (g)",
  "Omega6 (g)",
  "Trp (g)",
  "Vit D-mcg (mcg)",
  "Folate (mcg)",
  "MPGrain (oz-eq)",
  "MPVeg (c-eq)",
  "MPFruit (c-eq)",
  "MPDairy (c-eq)",
  "MPProt (oz-eq)"
)
numeric_cols <- intersect(preferred_cols, numeric_cols)

plot_df <- merged_df |>
  select(`Participant ID (ESHA ID)`, Study_group_new, all_of(numeric_cols)) |>
  filter(!is.na(Study_group_new)) |>
  pivot_longer(
    cols = all_of(numeric_cols),
    names_to = "Measure",
    values_to = "Value"
  )

if (length(numeric_cols) == 0 || nrow(plot_df) == 0 || dplyr::n_distinct(plot_df$Measure) == 0) {
  message("04_group_kde_plots.R skipped: no plottable dietary variables with study-group metadata.")
  quit(save = "no")
}

plot <- ggplot(plot_df, aes(x = Value, fill = Study_group_new, color = Study_group_new)) +
  geom_density(alpha = 0.25, linewidth = 0.6, adjust = 1) +
  facet_wrap(~Measure, scales = "free", ncol = 3) +
  scale_fill_viridis_d(option = "D", end = 0.9) +
  scale_color_viridis_d(option = "D", end = 0.9) +
  labs(
    title = "KDE Plots of Numerical Dietary Columns by Study Group",
    x = NULL,
    y = "Density",
    fill = "Study Group",
    color = "Study Group"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    strip.text = element_text(size = 8),
    legend.position = "top"
  )

n_rows <- ceiling(length(unique(plot_df$Measure)) / 3)
save_diet_plot(
  plot,
  "kde_numerical_columns_by_study_group.png",
  width = 16,
  height = min(24, max(8, n_rows * 3.5))
)

message("04_group_kde_plots.R completed: figure saved.")
