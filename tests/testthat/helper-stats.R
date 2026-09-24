# Load stats helper scripts with here() anchored to stats/.
.stats_dir <- normalizePath(
  file.path(testthat::test_path(), "..", "..", "stats"),
  winslash = "/",
  mustWork = TRUE
)

with_stats_wd <- function(expr) {
  owd <- getwd()
  on.exit(setwd(owd), add = TRUE)
  setwd(.stats_dir)
  force(expr)
}

load_permanova_helpers <- function() {
  with_stats_wd(source("R/permanova_helpers.R", local = parent.frame()))
}

load_symptom_helpers <- function() {
  with_stats_wd(source("R/symptom_association_helpers.R", local = parent.frame()))
}

load_nutrient_helpers <- function() {
  with_stats_wd(source("R/nutrient_association_helpers.R", local = parent.frame()))
}

load_evidence_helpers <- function() {
  with_stats_wd(source("R/evidence_ranking_helpers.R", local = parent.frame()))
}

mock_permanova_result <- function() {
  mock <- data.frame(
    Df = c(2, 10, 12),
    SumOfSqs = c(0.5, 1.0, 1.5),
    R2 = c(0.333333, 0.666667, 1.0),
    F = c(2.5, NA_real_, NA_real_),
    `Pr(>F)` = c(0.041, NA_real_, NA_real_),
    row.names = c("Study_group_new", "Residual", "Total"),
    check.names = FALSE
  )
  class(mock) <- c("adonis2", "anova.cca", "data.frame")
  mock
}
