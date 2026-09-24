# Nutrient intake × alpha diversity helpers (Spearman, overall + by disease group).
# Source from Quarto: source(here::here("R", "nutrient_association_helpers.R"))

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(ggplot2)
  library(readr)
  library(readxl)
  library(here)
})

ALPHA_METRICS <- c("Shannon", "Simpson", "Chao1")

DIET_PID_COL <- "Participant ID (ESHA ID)"

#' Key nutrients (column name in dietary_cleaned.xlsx → display label).
NUTRIENT_FIELDS <- list(
  "TotFib (g)" = "Total fiber (g/day)",
  "Trp (g)" = "Tryptophan (g/day)",
  "Cals (kcal)" = "Calories (kcal/day)",
  "ArtSw (mg)" = "Artificial sweeteners (mg/day)",
  "Sugar (g)" = "Sugar (g/day)",
  "SugAdd (g)" = "Added sugar (g/day)",
  "Fat (g)" = "Fat (g/day)",
  "Omega3 (g)" = "Omega-3 (g/day)",
  "Omega6 (g)" = "Omega-6 (g/day)",
  "Vit D-mcg (mcg)" = "Vitamin D (mcg/day)",
  "Folate (mcg)" = "Folate (mcg/day)"
)

#' One row per participant: mean nutrient intake across recorded days.
load_dietary_aggregated <- function(
    path = here::here("..", "data", "processed", "dietary_cleaned.xlsx"),
    sheet = "Data"
) {
  if (!file.exists(path)) {
    stop("Missing ", path, ". Run the dietary cleaning pipeline.")
  }

  raw <- read_excel(path, sheet = sheet)
  if (!DIET_PID_COL %in% names(raw)) {
    stop("Expected column ", DIET_PID_COL, " in ", path)
  }

  raw <- raw |>
    mutate(
      participant_id = toupper(trimws(as.character(.data[[DIET_PID_COL]])))
    ) |>
    mutate(across(
      where(is.character) & !any_of(c("participant_id", DIET_PID_COL, "Timepoint", "Day")),
      \(x) suppressWarnings(as.numeric(x))
    ))

  raw |>
    group_by(participant_id) |>
    summarise(
      across(where(is.numeric), \(x) mean(x, na.rm = TRUE)),
      .groups = "drop"
    ) |>
    rename(Participant_ID = participant_id)
}

#' Sample-level alpha diversity (wide) + participant-mean nutrients.
build_sample_nutrient_table <- function(
    alpha_path = here::here("..", "data", "intermediate", "alpha_long.rds"),
    dietary_path = here::here("..", "data", "processed", "dietary_cleaned.xlsx")
) {
  if (!file.exists(alpha_path)) {
    stop("Missing ", alpha_path, ". Run `make wrangle`.")
  }

  alpha_long <- readRDS(alpha_path)
  diet <- load_dietary_aggregated(dietary_path)

  meta_cols <- intersect(
    c("Sample_ID", "Participant_ID", "Sample_type", "Study_group_new", "Fiber_restriction"),
    names(alpha_long)
  )

  alpha_long |>
    filter(Diversity_metric %in% ALPHA_METRICS) |>
    pivot_wider(
      id_cols = all_of(meta_cols),
      names_from = Diversity_metric,
      values_from = Value
    ) |>
    mutate(Participant_ID = toupper(trimws(Participant_ID))) |>
    left_join(diet, by = "Participant_ID", suffix = c("", "_diet"))
}

#' Run Spearman grid for one subset of samples.
.spearman_grid_one_stratum <- function(sample_df, stratum_label) {
  nutrient_cols <- intersect(names(NUTRIENT_FIELDS), names(sample_df))

  grid <- expand_grid(
    nutrient = nutrient_cols,
    metric = ALPHA_METRICS
  )

  results <- vector("list", nrow(grid))
  for (i in seq_len(nrow(grid))) {
    n_col <- grid$nutrient[i]
    m_col <- grid$metric[i]
    d <- sample_df |>
      filter(!is.na(.data[[n_col]]), !is.na(.data[[m_col]]))
    n <- nrow(d)
    if (n < 4L) {
      results[[i]] <- tibble(n = n, rho = NA_real_, p = NA_real_)
    } else {
      ct <- cor.test(d[[n_col]], d[[m_col]], method = "spearman", exact = FALSE)
      results[[i]] <- tibble(
        n = n,
        rho = unname(ct$estimate),
        p = ct$p.value
      )
    }
  }

  bind_cols(grid, bind_rows(results)) |>
    mutate(
      stratum = stratum_label,
      nutrient_label = unname(NUTRIENT_FIELDS[nutrient])
    )
}

#' Spearman correlations: overall and stratified by disease group (Study_group_new).
spearman_nutrient_alpha <- function(
    sample_df,
    include_overall = TRUE,
    stratify_by = "Study_group_new"
) {
  pieces <- list()

  if (include_overall) {
    pieces[["Overall"]] <- .spearman_grid_one_stratum(sample_df, "Overall")
  }

  if (!is.null(stratify_by) && stratify_by %in% names(sample_df)) {
    groups <- sort(unique(sample_df[[stratify_by]]))
    groups <- groups[!is.na(groups)]
    for (g in groups) {
      d <- sample_df |> filter(.data[[stratify_by]] == g)
      pieces[[as.character(g)]] <- .spearman_grid_one_stratum(d, as.character(g))
    }
  }

  bind_rows(pieces) |>
    group_by(stratum) |>
    mutate(p_adj = p.adjust(p, method = "BH")) |>
    ungroup()
}

#' Scatter of nutrient vs alpha diversity, optionally faceted by study group.
plot_nutrient_alpha_scatter <- function(
    sample_df,
    nutrient_col = "TotFib (g)",
    metric = "Shannon",
    facet_by = "Study_group_new"
) {
  label <- NUTRIENT_FIELDS[[nutrient_col]]
  if (is.null(label)) {
    label <- nutrient_col
  }

  d <- sample_df |>
    filter(!is.na(.data[[nutrient_col]]), !is.na(.data[[metric]]))

  rho <- NA_real_
  p_val <- NA_real_
  if (nrow(d) >= 4L) {
    ct <- cor.test(d[[nutrient_col]], d[[metric]], method = "spearman", exact = FALSE)
    rho <- unname(ct$estimate)
    p_val <- ct$p.value
  }

  if (!is.null(facet_by) && facet_by %in% names(d)) {
    ggplot(d, aes(
      x = .data[[nutrient_col]],
      y = .data[[metric]],
      colour = .data[[facet_by]]
    )) +
      geom_point(size = 3, alpha = 0.85) +
      facet_wrap(as.formula(paste("~", facet_by))) +
      labs(
        title = paste0(label, " vs ", metric, " diversity"),
        subtitle = sprintf(
          "Overall Spearman rho = %s, p = %s, n = %d samples",
          ifelse(is.na(rho), "NA", sprintf("%.3f", rho)),
          ifelse(is.na(p_val), "NA", sprintf("%.4f", p_val)),
          nrow(d)
        ),
        x = label,
        y = metric,
        colour = "Study group"
      ) +
      theme_minimal() +
      theme(legend.position = "none")
  } else {
    ggplot(d, aes(x = .data[[nutrient_col]], y = .data[[metric]])) +
      geom_point(size = 3, alpha = 0.85) +
      labs(
        title = paste0(label, " vs ", metric, " diversity"),
        subtitle = sprintf(
          "Spearman rho = %s, p = %s, n = %d samples",
          ifelse(is.na(rho), "NA", sprintf("%.3f", rho)),
          ifelse(is.na(p_val), "NA", sprintf("%.4f", p_val)),
          nrow(d)
        ),
        x = label,
        y = metric
      ) +
      theme_minimal()
  }
}
