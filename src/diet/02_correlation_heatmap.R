# 02_correlation_heatmap.R
# Create a correlation heatmap across continuous dietary variables.
# Input: `data/intermediate/diet_eda_inputs.rds`
# Output: `figures/diet/correlation_matrix_nutritional_columns.png`

source("src/diet/00_functions.R")

eda_inputs <- readRDS(diet_intermediate_path("diet_eda_inputs.rds"))
df <- eda_inputs$dietary

numeric_cols <- get_diet_numeric_cols(df, start_col = 4)
correlation_matrix <- stats::cor(df[, numeric_cols, drop = FALSE], use = "pairwise.complete.obs")

correlation_long <- as.data.frame(as.table(correlation_matrix)) |>
  rename(Var1 = 1, Var2 = 2, Correlation = 3)

plot <- ggplot(correlation_long, aes(x = Var1, y = Var2, fill = Correlation)) +
  geom_tile(color = "white", linewidth = 0.15) +
  scale_fill_gradient2(
    low = "#3b4cc0",
    mid = "#f7f7f7",
    high = "#b40426",
    midpoint = 0,
    limits = c(-1, 1)
  ) +
  labs(
    title = "Correlation Matrix of Nutritional Columns",
    x = NULL,
    y = NULL,
    fill = "r"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 7),
    axis.text.y = element_text(size = 7),
    panel.grid = element_blank()
  ) +
  coord_fixed()

save_diet_plot(plot, "correlation_matrix_nutritional_columns.png", width = 12, height = 10)

message("02_correlation_heatmap.R completed: figure saved.")
