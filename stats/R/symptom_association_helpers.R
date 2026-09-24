# Symptom score × mycobiome association helpers (Spearman + PERMANOVA).
# Source from Quarto: source(here::here("R", "symptom_association_helpers.R"))

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(ggplot2)
  library(vegan)
  library(readr)
  library(here)
})

source(here::here("R", "permanova_helpers.R"))

# --- Configuration Lists ---

#' Symptom fields from cleaned characteristics (raw column → parsed score name).
SYMPTOM_FIELDS <- list(
  harvey_bradshaw_index = "Harvey-Bradshaw Index",
  daily_soft_stools = "Daily soft stools",
  abdominal_pain = "Abdominal pain",
  general_well.being = "General well-being",
  fatigue_frequency = "Fatigue frequency",
  anxiety_frequency = "Anxiety frequency",
  abdominal_bloating_frequency = "Abdominal bloating frequency"
)

ALPHA_METRICS <- c("Shannon", "Simpson", "Chao1")

# --- Helper Functions ---

#' Parse numeric symptom scores from raw survey cells.
parse_symptom_score <- function(x) {
  if (is.numeric(x)) {
    return(x)
  }
  x <- as.character(x)
  x[x %in% c("", "NA", "N/A")] <- NA_character_

  num <- suppressWarnings(as.numeric(x))
  if (mean(!is.na(num)) > 0.5) {
    return(num)
  }

  out <- rep(NA_real_, length(x))
  for (i in seq_along(x)) {
    if (is.na(x[i])) {
      next
    }
    if (grepl("=\\s*([0-9]+(?:\\.[0-9]+)?)", x[i], perl = TRUE)) {
      out[i] <- as.numeric(sub(".*=\\s*", "", x[i]))
    } else if (grepl("^\\s*([0-9]+(?:\\.[0-9]+)?)", x[i], perl = TRUE)) {
      out[i] <- as.numeric(sub("^\\s*([0-9]+(?:\\.[0-9]+)?).*", "\\1", x[i]))
    }
  }
  out
}

#' One row per participant with parsed symptom scores.
load_symptom_scores <- function(
    path = here::here("..", "data", "processed", "cleaned_characteristics.csv")
) {
  if (!file.exists(path)) {
    stop("Missing ", path, ". Run the characteristics cleaning pipeline.")
  }

  raw <- read_csv(path, show_col_types = FALSE)

  parsed <- raw |>
    mutate(participant_id = toupper(trimws(participant_id)))

  for (col in names(SYMPTOM_FIELDS)) {
    if (col %in% names(parsed)) {
      parsed[[col]] <- parse_symptom_score(parsed[[col]])
    }
  }

  parsed <- parsed |>
    group_by(participant_id) |>
    summarise(
      across(
        all_of(intersect(names(SYMPTOM_FIELDS), names(parsed))),
        \(x) {
          x <- x[!is.na(x)]
          if (length(x) == 0L) {
            NA_real_
          } else {
            x[[1L]]
          }
        },
        .names = "{.col}"
      ),
      .groups = "drop"
    ) |>
    rename(Participant_ID = participant_id)

  parsed
}

#' Sample-level table: alpha diversity (wide) + parsed symptoms.
build_sample_symptom_table <- function(
    alpha_path = here::here("..", "data", "intermediate", "alpha_long.rds"),
    symptom_path = here::here("..", "data", "processed", "cleaned_characteristics.csv")
) {
  if (!file.exists(alpha_path)) {
    stop("Missing ", alpha_path, ". Run `make wrangle`.")
  }
  if (!file.exists(symptom_path)) {
    stop("Missing ", symptom_path, ". Run the characteristics cleaning pipeline.")
  }

  alpha_long <- readRDS(alpha_path)
  symptoms <- load_symptom_scores(symptom_path)

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
    left_join(symptoms, by = "Participant_ID", suffix = c("", "_survey"))
}

#' Spearman correlations between each symptom and alpha metric (complete cases).
spearman_symptom_alpha <- function(sample_df) {
  symptom_cols <- intersect(names(SYMPTOM_FIELDS), names(sample_df))

  grid <- expand_grid(
    symptom = symptom_cols,
    metric = ALPHA_METRICS
  )

  # pmap inside mutate() fails because dplyr looks up `symptom` / `metric` in the
  # data mask; row-wise loop avoids that.
  results <- vector("list", nrow(grid))
  for (i in seq_len(nrow(grid))) {
    s <- grid$symptom[i]
    m <- grid$metric[i]
    d <- sample_df |>
      filter(!is.na(.data[[s]]), !is.na(.data[[m]]))
    n <- nrow(d)
    if (n < 4L) {
      results[[i]] <- tibble(n = n, rho = NA_real_, p = NA_real_)
    } else {
      ct <- cor.test(d[[s]], d[[m]], method = "spearman", exact = FALSE)
      results[[i]] <- tibble(
        n = n,
        rho = unname(ct$estimate),
        p = ct$p.value
      )
    }
  }

  bind_cols(grid, bind_rows(results)) |>
    mutate(
      symptom_label = unname(SYMPTOM_FIELDS[symptom]),
      p_adj = p.adjust(p, method = "BH")
    )
}

#' Bray–Curtis PERMANOVA of composition ~ continuous symptom score.
run_permanova_symptom <- function(
    wide_df,
    prefix,
    symptom_col = "harvey_bradshaw_index"
) {
  if (!symptom_col %in% names(wide_df)) {
    stop("Column not found: ", symptom_col)
  }

  clean_df <- wide_df |>
    filter(!is.na(.data[[symptom_col]])) |>
    column_to_rownames(var = "Sample_ID")

  # Dynamic isolation: Drop taxon columns to safely isolate clinical/metadata columns
  metadata <- clean_df |>
    select(!starts_with(prefix))

  taxa <- clean_df |>
    select(starts_with(prefix))

  if (nrow(taxa) < 4L) {
    stop("Fewer than 4 samples with non-missing ", symptom_col)
  }
  if (ncol(taxa) < 2L) {
    stop("Fewer than 2 taxon columns with prefix ", prefix)
  }

  dist_matrix <- vegdist(taxa, method = "bray")
  fml <- as.formula(paste("dist_matrix ~", symptom_col))
  set.seed(PERMANOVA_SEED)

  list(
    dist = dist_matrix,
    metadata = metadata,
    symptom_col = symptom_col,
    permanova = adonis2(
      fml,
      data = metadata,
      permutations = 999
    )
  )
}

#' Scatter of one symptom vs one alpha metric with Spearman annotation.
plot_symptom_alpha_scatter <- function(
    sample_df,
    symptom_col = "harvey_bradshaw_index",
    metric = "Shannon"
) {
  label <- unlist(SYMPTOM_FIELDS[symptom_col])
  d <- sample_df |>
    filter(!is.na(.data[[symptom_col]]), !is.na(.data[[metric]]))

  rho <- NA_real_
  p_val <- NA_real_
  if (nrow(d) >= 4L) {
    ct <- cor.test(d[[symptom_col]], d[[metric]], method = "spearman", exact = FALSE)
    rho <- unname(ct$estimate)
    p_val <- ct$p.value
  }

  ggplot(d, aes(x = .data[[symptom_col]], y = .data[[metric]], colour = Study_group_new)) +
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
      y = metric,
      colour = "Study group"
    ) +
    theme_minimal()
}

#' PCoA coloured by continuous symptom score.
plot_pcoa_symptom <- function(
    permanova_output, 
    level_label,
    symptom_label = unlist(SYMPTOM_FIELDS[permanova_output$symptom_col])
) {
  dist_matrix <- permanova_output$dist
  metadata <- permanova_output$metadata
  symptom_col <- permanova_output$symptom_col
  permanova_res <- permanova_output$permanova

  pcoa_calc <- cmdscale(dist_matrix, k = 2, eig = TRUE)
  pcoa_coords <- as.data.frame(pcoa_calc$points)
  colnames(pcoa_coords) <- c("PCoA1", "PCoA2")

  variance_explained <- round(pcoa_calc$eig / sum(pcoa_calc$eig) * 100, 1)
  plot_data <- bind_cols(pcoa_coords, metadata)

  ggplot(plot_data, aes(x = PCoA1, y = PCoA2, colour = .data[[symptom_col]])) +
    geom_point(size = 3, alpha = 0.9) +
    scale_colour_viridis_c(option = "plasma", name = symptom_label) +
    labs(
      title = paste0(level_label, " beta diversity vs ", symptom_label),
      subtitle = sprintf(
        "PERMANOVA: R² = %.3f, p = %.4f (999 permutations)",
        permanova_res$R2[1],
        permanova_res$`Pr(>F)`[1]
      ),
      x = paste0("PCoA 1 (", variance_explained[1], "%)"),
      y = paste0("PCoA 2 (", variance_explained[2], "%)")
    ) +
    theme_minimal()
}