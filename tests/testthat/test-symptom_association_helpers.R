test_that("parse_symptom_score extracts numeric scores from survey labels", {
  load_symptom_helpers()

  labels <- c("Mild = 1", "4\tSOME OF THE TIME", "Poor = 0", NA, "", "3.5")
  out <- parse_symptom_score(labels)

  expect_equal(out, c(1, 4, 0, NA, NA, 3.5))
})

test_that("spearman_symptom_alpha returns NA when fewer than four complete pairs", {
  load_symptom_helpers()

  sample_df <- tibble::tibble(
    harvey_bradshaw_index = c(1, 2, 3),
    Shannon = c(1.1, 1.2, 1.3),
    Simpson = c(0.8, 0.7, 0.6),
    Chao1 = c(10, 11, 12)
  )

  out <- spearman_symptom_alpha(sample_df)
  hbi_shannon <- out |>
    dplyr::filter(symptom == "harvey_bradshaw_index", metric == "Shannon")

  expect_equal(hbi_shannon$n, 3L)
  expect_true(is.na(hbi_shannon$rho))
  expect_true(is.na(hbi_shannon$p))
})

test_that("spearman_symptom_alpha computes rho for sufficient complete pairs", {
  load_symptom_helpers()

  sample_df <- tibble::tibble(
    harvey_bradshaw_index = 1:5,
    Shannon = c(1.0, 1.5, 2.0, 2.5, 3.0),
    Simpson = c(0.5, 0.6, 0.7, 0.8, 0.9),
    Chao1 = c(10, 12, 14, 16, 18)
  )

  out <- spearman_symptom_alpha(sample_df)
  hbi_shannon <- out |>
    dplyr::filter(symptom == "harvey_bradshaw_index", metric == "Shannon")

  expect_equal(hbi_shannon$n, 5L)
  expect_false(is.na(hbi_shannon$rho))
  expect_equal(hbi_shannon$rho, 1)
  expect_true(hbi_shannon$p < 0.05)
  expect_true(all(out$p_adj >= out$p, na.rm = TRUE))
})
