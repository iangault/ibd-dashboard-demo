# 03b_diversity_stats.R: Pre-specified diversity statistics

# ---- Setup ----
suppressPackageStartupMessages({
  library(dplyr)
  library(rstatix)
})


# ---- Load Wrangled Data ----

alpha_long <- readRDS("./data/intermediate/alpha_long.rds")


# ---- Test Diversity Differences by Study Group ----

kw_diversity_group <- alpha_long |>
  group_by(Diversity_metric) |>
  kruskal_test(Value ~ Study_group_new)

cat("\nKW Results for Diversity Metrics by Study Group:\n")
print(kw_diversity_group)


# ---- Test Diversity Differences by Fibre Restricted Diet ----

kw_diversity_fibre <- alpha_long |>
  group_by(Diversity_metric) |>
  kruskal_test(Value ~ Fiber_restriction)

cat("\nKW Results for Diversity Metrics by Fibre Restricted Diet:\n")
print(kw_diversity_fibre)


# ---- Save Pre-specified Diversity Results ----

write.csv(
  kw_diversity_group,
  "./data/processed/KW_diversity_group.csv",
  row.names = FALSE
)
write.csv(
  kw_diversity_fibre,
  "./data/processed/KW_diversity_fibre.csv",
  row.names = FALSE
)

message("03b_diversity_stats.R completed: Pre-specified diversity stats done.")
