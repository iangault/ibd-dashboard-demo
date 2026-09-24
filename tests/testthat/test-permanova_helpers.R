test_that("permanova_to_df formats adonis2 output for reporting", {
  load_permanova_helpers()

  out <- permanova_to_df(mock_permanova_result())

  expect_s3_class(out, "data.frame")
  expect_named(
    out,
    c("Term", "Df", "SumOfSqs", "R2", "F", "Pr(>F)")
  )
  expect_equal(out$Term, c("Study_group_new", "Residual", "Total"))
  expect_equal(out$Df, c(2, 10, 12))
  expect_equal(round(out$R2, 3), c(0.333, 0.667, 1.0))
  expect_equal(out$`Pr(>F)`[1], 0.041)
})

test_that("permanova_summary_text reports study-group effect size and p-value", {
  load_permanova_helpers()

  text <- permanova_summary_text(mock_permanova_result(), "Genus")

  expect_match(text, "Study group")
  expect_match(text, "Genus composition")
  expect_match(text, "33\\.3%")
  expect_match(text, "R² = 0\\.333")
  expect_match(text, "p = 0\\.0410")
})

test_that("run_permanova_study_group fits composition ~ Study_group_new", {
  load_permanova_helpers()

  wide_df <- tibble::tibble(
    Sample_ID = paste0("S", 1:6),
    Participant_ID = paste0("SYN_", sprintf("%02d", 1:6)),
    Sample_type = "stool",
    Study_group_new = rep(c("Non-IBD", "Active IBD", "Quiescent"), each = 2),
    Fiber_restriction = "None",
    g__TaxonA = c(0.50, 0.45, 0.10, 0.15, 0.30, 0.55),
    g__TaxonB = c(0.30, 0.35, 0.40, 0.55, 0.20, 0.15)
  )

  fit <- run_permanova_study_group(wide_df, "g__")

  expect_type(fit, "list")
  expect_true("permanova" %in% names(fit))
  expect_s3_class(fit$permanova, "anova.cca")
  expect_true("Pr(>F)" %in% names(fit$permanova))
  expect_equal(nrow(fit$metadata), 6L)
  expect_true(all(c("dist", "metadata", "permanova") %in% names(fit)))
})
