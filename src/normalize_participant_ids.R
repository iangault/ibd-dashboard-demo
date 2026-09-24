# Audit participant ID strings across key tables, reporting any values
# that normalize_participant_id() would change.

# Usage (from project root):
#   Rscript src/normalize_participant_ids.R

suppressPackageStartupMessages({
  library(readr)
  library(readxl)
  library(dplyr)
})

root <- "."
src_path <- file.path(root, "src", "participant_id.R")
if (!file.exists(src_path)) {
  stop("Run from project root: missing ", src_path)
}
source(src_path)

intermediate_dir <- file.path(root, "data", "intermediate")
dir.create(intermediate_dir, showWarnings = FALSE, recursive = TRUE)

audit_chunk <- function(source, col_name, values) {
  u <- sort(unique(na.omit(trimws(as.character(values)))))
  u <- u[nzchar(u)]
  if (length(u) == 0L) {
    return(
      data.frame(
        source = character(),
        column = character(),
        raw = character(),
        normalized = character(),
        stringsAsFactors = FALSE
      )
    )
  }
  data.frame(
    source = source,
    column = col_name,
    raw = u,
    normalized = normalize_participant_id(u),
    stringsAsFactors = FALSE
  )
}

chunks <- list()

meta_path <- file.path(root, "data/raw/SYN_MBI sample IDs meta.xlsx")
if (file.exists(meta_path)) {
  meta <- suppressMessages(read_excel(meta_path))
  meta <- meta[grepl("SYN", meta[["Participant ID"]]), ]
  chunks[[length(chunks) + 1L]] <- audit_chunk(
    "raw_meta", "Participant ID", meta[["Participant ID"]]
  )
}

chars_raw_path <- file.path(root, "data/raw/SYN_Participant Characteristics.xlsx")
if (file.exists(chars_raw_path)) {
  chars_raw <- suppressMessages(read_excel(chars_raw_path, sheet = 1, na = c("", "NA")))
  pid_cols <- grep("^Participant ID:\\.\\.\\.\\d+$", names(chars_raw), value = TRUE)
  if (length(pid_cols) > 0L) {
    pid_col <- pid_cols[[1]]
    ids <- chars_raw[[pid_col]]
    ids <- ids[grepl("SYN", ids, ignore.case = TRUE)]
    chunks[[length(chunks) + 1L]] <- audit_chunk(
      "raw_characteristics", pid_col, ids
    )
  }
}

chars_path <- file.path(root, "data/processed/cleaned_characteristics.csv")
if (file.exists(chars_path)) {
  ch <- read_csv(chars_path, show_col_types = FALSE)
  if ("participant_id" %in% names(ch)) {
    chunks[[length(chunks) + 1L]] <- audit_chunk(
      "cleaned_characteristics", "participant_id", ch$participant_id
    )
  }
}

diet_path <- file.path(root, "data/processed/dietary_cleaned.xlsx")
if (file.exists(diet_path)) {
  di <- suppressMessages(read_excel(diet_path, sheet = "Data"))
  col <- "Participant ID (ESHA ID)"
  if (col %in% names(di)) {
    chunks[[length(chunks) + 1L]] <- audit_chunk(
      "dietary_cleaned", col, di[[col]]
    )
  }
}

inflam_path <- file.path(root, "data/raw/SYN_Inflammatory biomarkers.xlsx")
if (file.exists(inflam_path)) {
  inflam <- suppressMessages(read_excel(inflam_path))
  if ("Participant_ID" %in% names(inflam)) {
    ids <- inflam[["Participant_ID"]]
    ids <- ids[grepl("SYN", ids)]
    chunks[[length(chunks) + 1L]] <- audit_chunk(
      "raw_inflammatory_biomarkers", "Participant_ID", ids
    )
  }
}

chunks <- chunks[vapply(chunks, nrow, integer(1)) > 0L]
if (length(chunks) == 0L) {
  stop("No inputs found to audit (check data paths).")
}

audit <- bind_rows(chunks) |>
  distinct(source, column, raw, .keep_all = TRUE) |>
  filter(raw != normalized)

audit_path <- file.path(
  intermediate_dir,
  "participant_id_normalization_audit.csv"
)
write_csv(audit, audit_path)
message(
  "Wrote audit: ", audit_path,
  "\n",
  " (", nrow(audit), " IDs would change under normalization)",
  "\n"
)
