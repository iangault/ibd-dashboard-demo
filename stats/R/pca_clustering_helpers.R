# PCA + clustering on combined diet and mycobiome features.
# Source from Quarto: source(here::here("R", "pca_clustering_helpers.R"))

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(ggplot2)
  library(scales)
  library(here)
  library(viridisLite)
})

source(here::here("R", "permanova_helpers.R"))
source(here::here("R", "nutrient_association_helpers.R"))

META_PARTICIPANT <- c("Participant_ID", "Study_group_new")

#' Participant-level table: mean genus abundance + mean nutrient intake.
build_participant_feature_table <- function(
    genus_level = "genus",
    data_dir = here::here("..", "data", "processed"),
    dietary_path = here::here("..", "data", "processed", "dietary_cleaned.xlsx")
) {
  genus_wide <- load_taxa_wide(genus_level, data_dir)
  prefix <- TAXA_LEVELS[[genus_level]]$prefix

  taxa_participant <- genus_wide |>
    mutate(Participant_ID = toupper(trimws(Participant_ID))) |>
    group_by(Participant_ID, Study_group_new) |>
    summarise(
      across(starts_with(prefix), \(x) mean(x, na.rm = TRUE)),
      .groups = "drop"
    )

  diet <- load_dietary_aggregated(dietary_path)

  taxa_participant |>
    left_join(diet, by = "Participant_ID", suffix = c("", "_diet"))
}

#' Matrix for PCA: variance-filtered nutrients + genus columns (participants × features).
prepare_clustering_features <- function(
    participant_df,
    min_sd = 0,
    nutrient_cols = intersect(names(NUTRIENT_FIELDS), names(participant_df))
) {
  taxa_cols <- names(participant_df)[grepl("^g__", names(participant_df))]
  feature_cols <- unique(c(nutrient_cols, taxa_cols))
  feature_cols <- feature_cols[feature_cols %in% names(participant_df)]

  has_variation <- vapply(
    participant_df[feature_cols],
    \(x) {
      if (!is.numeric(x)) {
        return(FALSE)
      }
      s <- sd(x, na.rm = TRUE)
      !is.na(s) && s > min_sd
    },
    logical(1)
  )
  feature_cols <- feature_cols[has_variation]

  if (length(feature_cols) < 2L) {
    stop("Fewer than 2 features with variation for PCA.")
  }

  meta <- participant_df |> select(any_of(META_PARTICIPANT))
  X <- participant_df |>
    select(all_of(feature_cols)) |>
    mutate(across(everything(), \(x) replace(x, is.na(x), 0)))

  list(
    meta = meta,
    features = feature_cols,
    n_nutrients = sum(feature_cols %in% nutrient_cols),
    n_taxa = sum(feature_cols %in% taxa_cols),
    X = as.matrix(X)
  )
}

#' PCA on scaled features (participants as rows).
run_feature_pca <- function(feature_list) {
  pca <- prcomp(feature_list$X, center = TRUE, scale. = TRUE)

  variance <- pca$sdev^2 / sum(pca$sdev^2)
  variance_df <- tibble(
    PC = paste0("PC", seq_along(variance)),
    Component = seq_along(variance),
    Variance = variance,
    Cumulative = cumsum(variance)
  )

  scores <- as_tibble(pca$x[, seq_len(min(3L, ncol(pca$x))), drop = FALSE]) |>
    bind_cols(feature_list$meta) |>
    mutate(Participant_ID = toupper(trimws(Participant_ID)))

  loadings <- as_tibble(pca$rotation[, seq_len(min(3L, ncol(pca$rotation))), drop = FALSE]) |>
    mutate(feature = feature_list$features) |>
    pivot_longer(
      -feature,
      names_to = "PC",
      values_to = "loading"
    ) |>
    mutate(abs_loading = abs(loading))

  list(
    pca = pca,
    variance_df = variance_df,
    scores = scores,
    loadings = loadings
  )
}

#' Hierarchical clustering on scaled features; assign k = 2 and k = 3.
run_hclust_clusters <- function(feature_list, k_values = c(2L, 3L)) {
  X <- feature_list$X
  rownames(X) <- feature_list$meta$Participant_ID
  d <- dist(scale(X))
  hc <- hclust(d, method = "ward.D2")

  k_values <- sort(unique(k_values[k_values >= 2L & k_values < nrow(feature_list$X)]))
  if (length(k_values) == 0L) {
    stop("Need at least 3 participants for clustering with k >= 2.")
  }

  clusters <- lapply(k_values, \(k) cutree(hc, k = k))
  names(clusters) <- paste0("k", k_values)

  list(
    hclust = hc,
    dist = d,
    clusters = clusters
  )
}

#' Attach cluster labels to PCA scores (one column per k).
add_clusters_to_scores <- function(scores, cluster_result) {
  out <- scores
  for (nm in names(cluster_result$clusters)) {
    cl_vec <- cluster_result$clusters[[nm]]
    out[[nm]] <- factor(cl_vec[out$Participant_ID])
  }
  out
}

#' Cross-tabulation of discovered clusters vs study group.
cluster_study_group_table <- function(scores, cluster_col) {
  if (!cluster_col %in% names(scores)) {
    stop("Column not found: ", cluster_col)
  }
  scores |>
    transmute(
      cluster = .data[[cluster_col]],
      Study_group_new
    ) |>
    count(cluster, Study_group_new) |>
    pivot_wider(
      names_from = Study_group_new,
      values_from = n,
      values_fill = 0
    )
}

#' Top absolute loadings for one PC.
plot_top_pca_loadings <- function(loadings, pc = "PC1", n_top = 10L) {
  loadings |>
    filter(PC == pc) |>
    slice_max(abs_loading, n = n_top) |>
    mutate(
      feature_label = vapply(feature, \(f) {
        if (f %in% names(NUTRIENT_FIELDS)) {
          NUTRIENT_FIELDS[[f]]
        } else {
          sub("^g__", "", f)
        }
      }, character(1))
    ) |>
    ggplot(aes(x = abs_loading, y = reorder(feature_label, abs_loading), fill = loading > 0)) +
    geom_col(show.legend = FALSE) +
    scale_fill_manual(values = c("#F28E2B", "#4E79A7")) +
    labs(
      x = "Absolute loading",
      y = NULL
    ) +
    theme_minimal()
}

#' PCA scatter (PC1 vs PC2) coloured by metadata or cluster.
plot_pca_scores <- function(
    scores,
    colour_col = "Study_group_new",
    shape_col = NULL,
    variance_df = NULL,
    title = "PCA: combined nutrients + genus"
) {
  if (!colour_col %in% names(scores)) {
    stop("Column not found: ", colour_col)
  }

  xlab <- "PC1"
  ylab <- "PC2"
  if (!is.null(variance_df) && nrow(variance_df) >= 2L) {
    xlab <- paste0("PC1 (", round(variance_df$Variance[1] * 100, 1), "%)")
    ylab <- paste0("PC2 (", round(variance_df$Variance[2] * 100, 1), "%)")
  }

  n_groups <- length(unique(scores[[colour_col]]))

  p <- ggplot(scores, aes(x = PC1, y = PC2, colour = .data[[colour_col]])) +
    geom_point(size = 4, alpha = 0.9) +
    geom_text(aes(label = Participant_ID), hjust = -0.2, vjust = 0.5, size = 3, show.legend = FALSE) +
    scale_colour_manual(
      values = viridis(n_groups)
    ) +
    labs(
      title = title,
      x = xlab,
      y = ylab,
      colour = colour_col
    ) +
    theme_minimal()

  if (!is.null(shape_col) && shape_col %in% names(scores)) {
    p <- p + aes(shape = .data[[shape_col]])
  }

  p
}

#' Scree / cumulative variance for first n PCs.
plot_pca_variance <- function(variance_df, max_pc = 10L) {
  variance_df |>
    filter(Component <= max_pc) |>
    ggplot(aes(x = Component, y = Cumulative)) +
    geom_line(colour = "#4E79A7") +
    geom_point(colour = "#4E79A7", size = 2) +
    scale_x_continuous(breaks = seq_len(max_pc), labels = paste0("PC", seq_len(max_pc))) +
    scale_y_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0, 1)) +
    labs(
      title = "Cumulative variance explained (PCA)",
      x = "Principal component",
      y = "Cumulative variance"
    ) +
    theme_minimal()
}

#' Draw hierarchical clustering dendrogram (base graphics).
plot_cluster_dendrogram <- function(cluster_result, main = NULL) {
  plot(cluster_result$hclust, main = main, xlab = "", sub = "")
}
