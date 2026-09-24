# 03_diversity_analysis.R: Diversity plots

# ---- Setup ----
suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(grid)
})

source("src/mycobiome/00_functions.R")


# ---- Load Wrangled Data ----

alpha_long <- readRDS("./data/intermediate/alpha_long.rds")
meta_data <- readRDS("./data/intermediate/meta_data.rds")


# ---- Plot Alpha Diversity by Study Group ----

# Sample sizes for plot labels
n_df <- alpha_long |>
  group_by(Diversity_metric, Study_group_new) |>
  summarise(n = n(), .groups = "drop")

div_study <- ggplot(alpha_long, aes(
  x = Study_group_new,
  y = Value, fill = Study_group_new
)) +
  geom_boxplot(alpha = 0.7, outlier.size = 0.8) +
  facet_wrap(~Diversity_metric, ncol = 1, scales = "free_y") +
  geom_text(
    data = n_df,
    aes(x = Study_group_new, y = Inf, label = paste0("n=", n)),
    vjust = 1.4,
    size = 3.2,
    inherit.aes = FALSE
  ) +
  scale_y_continuous(
    limits = c(0, NA),
    expand = expansion(mult = c(0.05, 0.25))
  ) +
  labs(
    title = "Alpha Diversity by Study Group",
    x = "Study Group",
    y = "Diversity Value",
    fill = "Study Groups"
  ) +
  theme_micro() +
  theme(legend.position = "none")

ggsave(
  file = "./figures/mycobiome/diversity_study_group.png",
  div_study,
  width = 6,
  height = 7,
  dpi = 300
)
cat("\nCreated Diversity Metrics Plot\n")

# ---- Plot Alpha Diversity by Fiber Restriction ----

# Sample sizes for plot labels
n_df <- alpha_long |>
  group_by(Diversity_metric, Fiber_restriction) |>
  summarise(n = n(), .groups = "drop")

div_fiber <- ggplot(
  alpha_long,
  aes(
    x = Fiber_restriction, y = Value,
    fill = Fiber_restriction
  )
) +
  geom_boxplot(alpha = 0.7, outlier.size = 0.8) +
  facet_wrap(~Diversity_metric, ncol = 1, scales = "free_y") +
  geom_text(
    data = n_df,
    aes(x = Fiber_restriction, y = Inf, label = paste0("n=", n)),
    vjust = 1.4,
    size = 3.2,
    inherit.aes = FALSE
  ) +
  scale_x_discrete(limits = c("None", "Low", "Mid", "High")) +
  scale_y_continuous(
    limits = c(0, NA),
    expand = expansion(mult = c(0.05, 0.25))
  ) +
  labs(
    title = "Alpha Diversity by Fiber Restricted Diet",
    x = "Study Group",
    y = "Diversity value"
  ) +
  theme_micro() +
  theme(legend.position = "none")

ggsave(
  file = "./figures/mycobiome/diversity_fiber.png",
  div_fiber,
  width = 6,
  height = 7,
  dpi = 300
)
cat("\nCreated Fiber Plot\n")


message("03_diversity_analysis.R completed: Diversity plots done.")
