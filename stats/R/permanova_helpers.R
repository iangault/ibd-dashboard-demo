# Shared PERMANOVA + PCoA helpers for stats blog posts.
# Source from Quarto: source(here::here("R", "permanova_helpers.R"))

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(ggplot2)
  library(vegan)
  library(readr)
})

# Fixed seed so permutation p-values are the same on every run and across posts
PERMANOVA_SEED <- 2026

TAXA_LEVELS <- list(
  phylum = list(
    file = "phylum.csv",
    tax_col = "Phylum",
    prefix = "p__",
    label = "Phylum"
  ),
  family = list(
    file = "family.csv",
    tax_col = "Family",
    prefix = "f__",
    label = "Family"
  ),
  genus = list(
    file = "genus.csv",
    tax_col = "Genus",
    prefix = "g__",
    label = "Genus"
  ),
  species = list(
    file = "species.csv",
    tax_col = "Species",
    prefix = "s__",
    label = "Species"
  )
)

META_COLS <- c(
  "Sample_ID", "Participant_ID", "Sample_type",
  "Study_group_new", "Fiber_restriction"
)

#' Load processed taxa as a wide table (samples x prefixed taxon columns).
load_taxa_wide <- function(level, data_dir = here::here("..", "data", "processed")) {
  if (!level %in% names(TAXA_LEVELS)) {
    stop("Unknown level: ", level, ". Choose: ", paste(names(TAXA_LEVELS), collapse = ", "))
  }
  cfg <- TAXA_LEVELS[[level]]
  path <- file.path(data_dir, cfg$file)
  if (!file.exists(path)) {
    stop("Missing ", path, ". Run `make save` after `make wrangle`.")
  }

  df <- read_csv(path, show_col_types = FALSE)

  if (cfg$tax_col %in% names(df) && "Value" %in% names(df)) {
    tax_col <- cfg$tax_col
    df <- df |>
      mutate(
        !!tax_col := paste0(cfg$prefix, .data[[tax_col]])
      ) |>
      pivot_wider(
        id_cols = any_of(META_COLS),
        names_from = all_of(tax_col),
        values_from = Value,
        values_fill = 0
      )
    return(df)
  }

  if (!"Sample_ID" %in% names(df)) {
    stop("Expected long (", cfg$tax_col, ", Value) or wide format with Sample_ID in ", path)
  }
  df
}

#' Bray–Curtis PERMANOVA of community composition ~ Study_group_new.
run_permanova_study_group <- function(wide_df, prefix) {
  clean_df <- wide_df |>
    column_to_rownames(var = "Sample_ID")

  metadata <- clean_df |>
    select(any_of(META_COLS[-1]))

  taxa <- clean_df |>
    select(starts_with(prefix))

  if (ncol(taxa) < 2L) {
    stop("Fewer than 2 taxon columns with prefix ", prefix)
  }

  dist_matrix <- vegdist(taxa, method = "bray")
  set.seed(PERMANOVA_SEED)

  list(
    dist = dist_matrix,
    metadata = metadata,
    permanova = adonis2(
      dist_matrix ~ Study_group_new,
      data = metadata,
      permutations = 999
    )
  )
}

#' Format adonis2 output as a data frame for knitr::kable.
permanova_to_df <- function(permanova_result) {
  out <- as.data.frame(permanova_result)
  out$Term <- rownames(out)
  rownames(out) <- NULL
  out |>
    select(Term, Df, SumOfSqs, R2, F, `Pr(>F)`)
}

#' PCoA plot coloured by study group with PERMANOVA subtitle.
plot_pcoa_study_group <- function(
    dist_matrix,
    metadata,
    permanova_result,
    level_label,
    ellipse_level = 0.95
) {
  pcoa_calc <- cmdscale(dist_matrix, k = 2, eig = TRUE)
  pcoa_coords <- as.data.frame(pcoa_calc$points)
  colnames(pcoa_coords) <- c("PCoA1", "PCoA2")

  variance_explained <- round(
    pcoa_calc$eig / sum(pcoa_calc$eig) * 100,
    1
  )

  plot_data <- bind_cols(pcoa_coords, metadata)

  ggplot(plot_data, aes(x = PCoA1, y = PCoA2, color = Study_group_new)) +
    geom_point(size = 3, alpha = 0.8) +
    stat_ellipse(level = ellipse_level, linetype = "dashed") +
    labs(
      # title = paste0(level_label, " beta diversity"),
      subtitle = sprintf(
        "PERMANOVA: R² = %.3f, p = %.4f (999 permutations)",
        permanova_result$R2[1],
        permanova_result$`Pr(>F)`[1]
      ),
      x = paste0("PCoA 1 (", variance_explained[1], "%)"),
      y = paste0("PCoA 2 (", variance_explained[2], "%)"),
      color = "Study group"
    ) +
    theme_minimal() +
    theme(legend.position = "right")
}

#' One-line narrative summary for the grouping term.
permanova_summary_text <- function(permanova_result, level_label) {
  r2 <- permanova_result$R2[1]
  p <- permanova_result$`Pr(>F)`[1]
  sprintf(
    "**Study group** explained **%.1f%%** of variance in %s composition (R² = %.3f; pseudo-F = %.2f; p = %.4f, 999 permutations).",
    100 * r2,
    level_label,
    r2,
    permanova_result$F[1],
    p
  )
}
