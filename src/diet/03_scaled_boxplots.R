# 03_scaled_boxplots.R
# Create boxplots of dietary numeric variables after min-max scaling.
# Input: `data/intermediate/diet_eda_inputs.rds`
# Output: `figures/diet/scaled_boxplots_numerical_columns.png`
# Scaling allows variables in different units to be compared on one figure while
# preserving each variable's within-column distribution.

source("src/diet/00_functions.R")

eda_inputs <- readRDS(diet_intermediate_path("diet_eda_inputs.rds"))
df <- eda_inputs$dietary

numeric_cols <- get_diet_numeric_cols(df, start_col = 4)
plot_df <- df[, c("Participant ID (ESHA ID)", numeric_cols), drop = FALSE]

scaled_df <- plot_df
for (col in numeric_cols) {
  if (dplyr::n_distinct(plot_df[[col]], na.rm = TRUE) > 1) {
    scaled_df[[col]] <- rescale_minmax(plot_df[[col]])
  }
}

long_df <- scaled_df |>
  pivot_longer(
    cols = all_of(numeric_cols),
    names_to = "Numerical_Column",
    values_to = "Scaled_Value"
  )

ordered_columns <- long_df |>
  group_by(Numerical_Column) |>
  summarise(median_scaled = stats::median(Scaled_Value, na.rm = TRUE), .groups = "drop") |>
  arrange(desc(median_scaled)) |>
  pull(Numerical_Column)

long_df <- long_df |>
  mutate(Numerical_Column = factor(Numerical_Column, levels = ordered_columns))

palette_vals <- grDevices::rainbow(length(ordered_columns))
names(palette_vals) <- ordered_columns

plot <- ggplot(long_df, aes(x = Numerical_Column, y = Scaled_Value, fill = Numerical_Column)) +
  geom_boxplot(outlier.alpha = 0.25, linewidth = 0.25) +
  scale_fill_manual(values = palette_vals, guide = "none") +
  labs(
    title = "Scaled Boxplots of Numerical Dietary Columns",
    x = NULL,
    y = "Scaled Value"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 7),
    panel.grid.major.x = element_blank()
  )

save_diet_plot(plot, "scaled_boxplots_numerical_columns.png", width = 14, height = 8)

message("03_scaled_boxplots.R completed: figure saved.")
