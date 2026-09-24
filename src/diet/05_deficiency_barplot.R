# 05_deficiency_barplot.R
# Create a participant-level deficiency summary relative to selected dietary
# guideline targets.
# Input: `data/intermediate/diet_eda_inputs.rds`
# Output: `figures/diet/total_dietary_deficiency_score_per_participant.png`
# The score sums only negative deviations, so more negative values indicate a
# larger shortfall relative to the configured targets in `00_functions.R`.

source("src/diet/00_functions.R")

eda_inputs <- readRDS(diet_intermediate_path("diet_eda_inputs.rds"))
df <- eda_inputs$dietary

score_columns <- names(cfg_targets)

participant_scores <- df |>
  group_by(`Participant ID (ESHA ID)`) |>
  summarise(
    across(all_of(score_columns), ~ mean(as.numeric(.x), na.rm = TRUE)),
    .groups = "drop"
  )

participant_deviations <- participant_scores
for (col in score_columns) {
  participant_deviations[[col]] <- participant_deviations[[col]] - cfg_targets[[col]]
}

participant_deviations$Total_Deficiency_Score <- apply(
  participant_deviations[, score_columns, drop = FALSE],
  1,
  function(row) sum(row[row < 0], na.rm = TRUE)
)

participant_deviations <- participant_deviations |>
  arrange(Total_Deficiency_Score) |>
  mutate(`Participant ID (ESHA ID)` = factor(`Participant ID (ESHA ID)`, levels = `Participant ID (ESHA ID)`))

plot <- ggplot(
  participant_deviations,
  aes(x = `Participant ID (ESHA ID)`, y = Total_Deficiency_Score, fill = Total_Deficiency_Score)
) +
  geom_col() +
  scale_fill_gradient2(low = "#b40426", mid = "#f7f7f7", high = "#2f9e44", midpoint = 0) +
  labs(
    title = "Total Dietary Deficiency Score per Participant",
    x = "Participant ID",
    y = "Total Deficiency Score"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "none"
  )

save_diet_plot(plot, "total_dietary_deficiency_score_per_participant.png", width = 12, height = 6)

message("05_deficiency_barplot.R completed: figure saved.")
