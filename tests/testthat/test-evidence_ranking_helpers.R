test_that(".kw_formula backticks column names with spaces", {
  load_evidence_helpers()

  fml <- .kw_formula("TotFib (g)", "Study group")

  expect_s3_class(fml, "formula")
  expect_equal(deparse(fml), "`TotFib (g)` ~ `Study group`")
})
