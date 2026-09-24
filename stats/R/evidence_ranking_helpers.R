# Evidence-ranking matrix: synthesize study-group findings across domains.
# Source from Quarto: source(here::here("R", "evidence_ranking_helpers.R"))

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(ggplot2)
  library(rstatix)
  library(here)
})

source(here::here("R", "permanova_helpers.R"))
source(here::here("R", "nutrient_association_helpers.R"))
source(here::here("R", "symptom_association_helpers.R"))

GROUP_VAR <- "Study_group_new"

.kw_formula <- function(y_col, x_col) {
  as.formula(paste0("`", y_col, "` ~ `", x_col, "`"))
}

#' One row per participant with study group (from mycobiome metadata).
.participant_group_table <- function() {
  alpha_path <- here::here("..", "data", "intermediate", "alpha_long.rds")
  if (!file.exists(alpha_path)) {
    stop("Missing ", alpha_path, ". Run `make wrangle`.")
  }
  readRDS(alpha_path) |>
    mutate(Participant_ID = toupper(trimws(Participant_ID))) |>
    distinct(Participant_ID, .data[[GROUP_VAR]]) |>
    rename(study_group = all_of(GROUP_VAR))
}

#' PERMANOVA (Bray–Curtis) of taxonomic composition ~ study group.
.collect_permanova_findings <- function() {
  rows <- lapply(names(TAXA_LEVELS), \(lvl) {
    cfg <- TAXA_LEVELS[[lvl]]
    wide <- load_taxa_wide(lvl)
    fit <- run_permanova_study_group(wide, cfg$prefix)
    res <- fit$permanova
    tibble(
      domain = "Mycobiome (beta diversity)",
      feature = as.character(paste0(cfg$label, " composition")),
      comparison = GROUP_VAR,
      test = "PERMANOVA (Bray–Curtis)",
      effect = res$R2[1],
      effect_label = sprintf("R\u00b2 = %.3f", res$R2[1]),
      statistic = res$F[1],
      p = res$`Pr(>F)`[1],
      n = nrow(fit$metadata),
      source_post = paste0("2026-05-19-permanova-", lvl, "-beta-diversity")
    )
  })
  bind_rows(rows)
}

#' Kruskal–Wallis of alpha diversity metrics ~ study group.
.collect_alpha_kw_findings <- function() {
  alpha_path <- here::here("..", "data", "intermediate", "alpha_long.rds")
  alpha_long <- readRDS(alpha_path)

  alpha_fml <- as.formula(paste("Value ~", GROUP_VAR))

  kw <- alpha_long |>
    filter(Diversity_metric %in% ALPHA_METRICS) |>
    group_by(Diversity_metric) |>
    kruskal_test(alpha_fml) |>
    ungroup()

  eff <- alpha_long |>
    filter(Diversity_metric %in% ALPHA_METRICS) |>
    group_by(Diversity_metric) |>
    kruskal_effsize(alpha_fml) |>
    ungroup()

  kw |>
    left_join(eff |> select(Diversity_metric, effsize), by = "Diversity_metric") |>
    transmute(
      domain = "Mycobiome (alpha diversity)",
      feature = as.character(paste0(Diversity_metric, " diversity")),
      comparison = GROUP_VAR,
      test = "Kruskal–Wallis",
      effect = effsize,
      effect_label = sprintf("\u03b7\u00b2[H] = %.3f", effsize),
      statistic = statistic,
      p = p,
      n = n,
      source_post = "2026-05-19-alpha-diversity-kruskal-wallis"
    )
}

#' Kruskal–Wallis of nutrient intake ~ study group (participant level).
.collect_nutrient_kw_findings <- function() {
  participants <- build_sample_nutrient_table() |>
    distinct(Participant_ID, .keep_all = TRUE)

  nutrient_cols <- intersect(names(NUTRIENT_FIELDS), names(participants))
  rows <- lapply(nutrient_cols, \(col) {
    d <- participants |>
      filter(!is.na(.data[[col]]), !is.na(.data[[GROUP_VAR]]))
    if (nrow(d) < 4L || n_distinct(d[[GROUP_VAR]]) < 2L) {
      return(NULL)
    }
    fml <- .kw_formula(col, GROUP_VAR)
    kw <- kruskal_test(d, formula = fml)
    eff <- tryCatch(
      kruskal_effsize(d, formula = fml),
      error = \(e) tibble(effsize = NA_real_)
    )
    tibble(
      domain = "Diet (nutrients)",
      feature = as.character(NUTRIENT_FIELDS[[col]]),
      comparison = GROUP_VAR,
      test = "Kruskal–Wallis",
      effect = eff$effsize[1],
      effect_label = if (is.na(eff$effsize[1])) {
        "NA"
      } else {
        sprintf("\u03b7\u00b2[H] = %.3f", eff$effsize[1])
      },
      statistic = kw$statistic,
      p = kw$p,
      n = kw$n,
      source_post = "2026-05-29-nutrients-diversity-disease-group"
    )
  })
  bind_rows(rows)
}

#' Kruskal–Wallis of symptom scores ~ study group (participant level).
.collect_symptom_kw_findings <- function() {
  symptoms <- load_symptom_scores()
  groups <- .participant_group_table()

  participants <- symptoms |>
    left_join(groups, by = "Participant_ID")

  symptom_cols <- intersect(names(SYMPTOM_FIELDS), names(participants))
  rows <- lapply(symptom_cols, \(col) {
    d <- participants |>
      filter(!is.na(.data[[col]]), !is.na(study_group))
    if (nrow(d) < 4L || n_distinct(d$study_group) < 2L) {
      return(NULL)
    }
    fml <- .kw_formula(col, "study_group")
    kw <- kruskal_test(d, formula = fml)
    eff <- tryCatch(
      kruskal_effsize(d, formula = fml),
      error = \(e) tibble(effsize = NA_real_)
    )
    tibble(
      domain = "Symptoms (survey)",
      feature = as.character(SYMPTOM_FIELDS[[col]]),
      comparison = GROUP_VAR,
      test = "Kruskal–Wallis",
      effect = eff$effsize[1],
      effect_label = if (is.na(eff$effsize[1])) {
        "NA"
      } else {
        sprintf("\u03b7\u00b2[H] = %.3f", eff$effsize[1])
      },
      statistic = kw$statistic,
      p = kw$p,
      n = kw$n,
      source_post = "2026-05-22-symptoms-fungal-composition"
    )
  })
  bind_rows(rows)
}

#' Assemble all study-group comparison results from processed pipeline outputs.
collect_study_group_findings <- function() {
  bind_rows(
    .collect_permanova_findings(),
    .collect_alpha_kw_findings(),
    .collect_nutrient_kw_findings(),
    .collect_symptom_kw_findings()
  ) |>
    mutate(
      p = as.numeric(p),
      effect = as.numeric(effect)
    )
}

#' Rank findings for validation priority.
rank_evidence <- function(findings) {
  ranked <- findings |>
    mutate(
      neglog10_p = -log10(pmax(p, 1e-10, na.rm = TRUE)),
      effect_scaled = case_when(
        is.na(effect) ~ 0,
        effect < 0 ~ 0,
        domain == "Mycobiome (beta diversity)" ~ effect,
        TRUE ~ pmin(effect, 1)
      ),
      evidence_score = neglog10_p * (0.5 + 0.5 * effect_scaled)
    ) |>
    arrange(desc(evidence_score), p) |>
    mutate(rank = row_number())

  sig_scores <- ranked$evidence_score[!is.na(ranked$p) & ranked$p < 0.05]
  high_cutoff <- if (length(sig_scores) >= 2L) {
    quantile(sig_scores, 0.75, na.rm = TRUE)
  } else if (length(sig_scores) == 1L) {
    sig_scores[[1]]
  } else {
    Inf
  }

  ranked |>
    mutate(
      validation_tier = case_when(
        !is.na(p) & p < 0.05 & evidence_score >= high_cutoff ~ "High",
        !is.na(p) & p < 0.05 ~ "Medium",
        !is.na(p) & p < 0.10 ~ "Suggestive",
        TRUE ~ "Low"
      )
    )
}

#' Wide matrix view: domain × feature with evidence score.
evidence_matrix_wide <- function(ranked) {
  ranked |>
    select(domain, feature, evidence_score, validation_tier, p, effect_label) |>
    mutate(feature = paste0(feature, " (", effect_label, ")"))
}

#' Heatmap of evidence scores for top findings.
plot_evidence_heatmap <- function(ranked, top_n = 20L) {
  plot_df <- ranked |>
    slice_head(n = top_n) |>
    mutate(
      feature_short = paste0(rank, ". ", feature),
      feature_short = reorder(feature_short, -rank),
      text_colour = ifelse(
        evidence_score < 0.5,
        "white",
        "black"
      )
    )

  ggplot(plot_df, aes(x = domain, y = feature_short, fill = evidence_score)) +
    geom_tile(colour = "white", linewidth = 0.4) +
    geom_text(
      aes(
        label = sprintf("%.2f", evidence_score),
        colour = text_colour
      ),
      size = 3
    ) +
    scale_fill_viridis_c(option = "plasma", name = "Evidence\nscore") +
    labs(
      subtitle = "Score = \u2212log10(p) \u00d7 (0.5 + 0.5 \u00d7 effect); higher = stronger validation candidate",
      x = NULL,
      y = NULL
    ) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 30, hjust = 1),
      panel.grid = element_blank()
    ) +
    scale_colour_identity()
}
