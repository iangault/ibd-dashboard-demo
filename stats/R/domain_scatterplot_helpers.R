suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})

# Helper: scatter + smoother coloured by disease status; Spearman ρ in subtitle
plot_scatter <- function(df, x_col, y_col, x_label = x_col, y_label = y_col) {
  plot_data <- df |>
    filter(!is.na(.data[[x_col]]),
           !is.na(.data[[y_col]]))

  fit <- lm(plot_data[[y_col]] ~ plot_data[[x_col]])

  p_value <- summary(fit)$coefficients[2, 4]
  slope <- coef(fit)[2]
  n <- nrow(plot_data)

  subtitle <- paste0(
    "n = ", n,
    " | β = ", round(slope, 3),
    " | p = ", signif(p_value, 3)
  )

  ggplot(
    plot_data,
    aes(
      x = .data[[x_col]],
      y = .data[[y_col]],
      colour = Disease_status
    )
  ) +
    geom_point(size = 2.5) +
    geom_smooth(
      method = "lm",
      se = TRUE,
      aes(group = 1),
      colour = "grey40",
      linewidth = 0.7
    ) +
    labs(
      title = paste(x_label, "×", y_label),
      subtitle = subtitle,
      x = x_label,
      y = y_label
    ) +
    theme_minimal()
}
