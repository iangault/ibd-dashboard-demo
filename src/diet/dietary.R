# dietary.R
# Clean the raw dietary export and save a processed workbook for downstream
# analysis and plotting.
#
# Inputs:
#   - one of the supported raw files in `data/raw/`
# Outputs:
#   - `data/processed/dietary_cleaned.xlsx` with:
#       * `Data`: cleaned continuous variables
#       * `Quartiles`: derived quantile bins for selected numeric variables
#
# Key cleaning rules:
#   - remove summary rows and rows without caloric intake
#   - propagate participant IDs only from valid SYN-style anchor cells
#   - normalize participant IDs to a consistent `SYN_NN` format
#   - derive quartile-like bins for numeric variables when variation exists

suppressPackageStartupMessages({
  library(openxlsx)
  library(readxl)
  library(zoo)
})

source("src/participant_id.R")

project_root <- normalizePath(".", winslash = "/", mustWork = TRUE)
data_candidates <- c(
  file.path(project_root, "data", "raw", "SYN_dietary data.xlsx"),
  file.path(project_root, "data", "raw", "SYN_dietary data.csv"),
  file.path(project_root, "data", "raw", "SYN_dietary data(ALL).csv")
)
output_path <- file.path(project_root, "data", "processed", "dietary_cleaned.xlsx")

pid_col <- "Participant ID (ESHA ID)"
required_data_columns <- c(
  pid_col,
  "Day",
  "Timepoint ",
  "TotFib (g)",
  "Sugar (g)",
  "SugAdd (g)",
  "MonSac (g)",
  "Gluc (g)",
  "Fruct (g)",
  "Disacc (g)",
  "Lact (g)",
  "Sucr (g)",
  "Trp (g)",
  "Vit A-IU (IU)",
  "Vit B1 (mg)",
  "Vit B2 (mg)",
  "Vit B3 (mg)",
  "Vit B6 (mg)",
  "Vit B12 (mcg)",
  "Vit C (mg)",
  "Vit D-mcg (mcg)",
  "Vit E-IU (IU)",
  "Folate (mcg)",
  "Vit K (mcg)",
  "TotSolFib (g)",
  "TotInsolFib (g)",
  "SolFib(16) (g)",
  "InsolFib(16) (g)",
  "Sol Non-Digest Carb (g)",
  "Insol Non-Digest Carb (g)",
  "Fat (g)",
  "SatFat (g)",
  "MonoFat (g)",
  "PolyFat (g)",
  "TransFat (g)",
  "Chol (mg)",
  "Omega3 (g)",
  "Omega6 (g)",
  "Phe (g)",
  "Tyr (g)",
  "Alc (g)",
  "Caff (mg)",
  "ArtSw (mg)",
  "Aspar (mg)",
  "Sacch (mg)",
  "SugAl (g)",
  "Eryth (g)",
  "Glyc (g)",
  "Inos (g)",
  "Lacti (g)",
  "Malti (g)",
  "Mann (g)",
  "Sorb (g)",
  "Xylit (g)",
  "MPGrain (oz-eq)",
  "MPVeg (c-eq)",
  "MPFruit (c-eq)",
  "MPDairy (c-eq)",
  "MPProt (oz-eq)"
)

pid_cell_valid <- function(x) {
  grepl("^\\s*SYN[_-]\\d{1,2}(?:_T\\d+)?\\s*$", x, ignore.case = TRUE)
}

# Confirm that the cleaned table still contains the columns required by the
# downstream diet workflow before writing output.
validate_required_columns <- function(df) {
  missing <- setdiff(required_data_columns, names(df))
  if (length(missing) > 0) {
    stop(
      "Cleaned dietary output is missing required downstream columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
}

# Repair a column name when the source file contains extra surrounding
# whitespace but the downstream workflow expects the canonical name.
rename_trimmed_column <- function(df, expected_name) {
  if (expected_name %in% names(df)) {
    return(df)
  }

  trimmed_matches <- names(df)[trimws(names(df)) == trimws(expected_name)]
  if (length(trimmed_matches) > 0) {
    names(df)[match(trimmed_matches[[1]], names(df))] <- expected_name
  }

  df
}

# Fill blank participant-ID rows using the most recent valid SYN anchor.
# Non-empty cells that do not look like participant IDs deliberately break the
# carry-forward chain so free-text notes are not assigned to the wrong person.
propagate_participant_ids <- function(x) {
  out <- rep(NA_character_, length(x))
  current <- NA_character_

  for (i in seq_along(x)) {
    value <- x[[i]]
    if (is.na(value) || !nzchar(trimws(as.character(value)))) {
      out[[i]] <- current
      next
    }

    value_chr <- trimws(as.character(value))
    if (pid_cell_valid(value_chr)) {
      current <- value_chr
      out[[i]] <- value_chr
    } else {
      current <- NA_character_
      out[[i]] <- NA_character_
    }
  }

  out
}

# Create zero-indexed quantile bins for numeric variables.
# Some dietary columns have too many ties for quartiles, so callers can fall
# back to fewer bins when needed.
assign_quantile_bins <- function(x, q) {
  if (all(is.na(x))) {
    return(rep(NA_real_, length(x)))
  }

  breaks <- unique(stats::quantile(
    x,
    probs = seq(0, 1, length.out = q + 1),
    na.rm = TRUE,
    names = FALSE,
    type = 7
  ))

  if (length(breaks) < 2) {
    stop("Not enough unique breakpoints for quantile binning.")
  }

  bins <- cut(
    x,
    breaks = breaks,
    include.lowest = TRUE,
    labels = FALSE,
    right = TRUE
  )

  as.numeric(bins) - 1
}

# Return the first available raw dietary input from the known candidate paths.
resolve_data_path <- function(paths) {
  existing <- paths[file.exists(paths)]
  if (length(existing) == 0) {
    stop(
      "Missing dietary raw input. Expected one of:\n",
      paste(paths, collapse = "\n"),
      call. = FALSE
    )
  }
  existing[[1]]
}

# Read either an Excel or CSV dietary export while preserving the original
# column names used throughout the project.
read_dietary_input <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext %in% c("xlsx", "xls")) {
    return(readxl::read_excel(path, .name_repair = "minimal", na = c("", "NA")))
  }
  if (ext == "csv") {
    return(readr::read_csv(path, name_repair = "minimal", na = c("", "NA")))
  }

  stop("Unsupported dietary input format: ", path, call. = FALSE)
}

data_path <- resolve_data_path(data_candidates)
df <- read_dietary_input(data_path)
df <- rename_trimmed_column(df, pid_col)
df <- rename_trimmed_column(df, "Timepoint ")

df <- df[!is.na(df[["Cals (kcal)"]]), , drop = FALSE]
df <- df[
  !(
    df[["Day"]] == "Average " |
      grepl("% Recommendation", df[["Day"]], fixed = TRUE)
  ),
  ,
  drop = FALSE
]

df[[pid_col]] <- propagate_participant_ids(df[[pid_col]])
if (length(df[["Timepoint "]]) > 0) {
  df[["Timepoint "]] <- zoo::na.locf(df[["Timepoint "]], na.rm = FALSE)
}
df[[pid_col]] <- sub("_T\\d+$", "", df[[pid_col]])
df[[pid_col]] <- normalize_participant_id(df[[pid_col]])

df <- df[
  grepl("^SYN_[0-9]{2}$", df[[pid_col]], ignore.case = TRUE),
  ,
  drop = FALSE
]

candidate_numeric_cols <- if (ncol(df) >= 4) {
  names(df)[seq.int(4, ncol(df))]
} else {
  character(0)
}
candidate_numeric_cols <- candidate_numeric_cols[
  !is.na(candidate_numeric_cols) &
    nzchar(candidate_numeric_cols) &
    candidate_numeric_cols %in% names(df)
]

numeric_cols <- if (length(candidate_numeric_cols) > 0) {
  candidate_numeric_cols[
    vapply(df[, candidate_numeric_cols, drop = FALSE], is.numeric, logical(1))
  ]
} else {
  character(0)
}

for (col in numeric_cols) {
  if (length(unique(stats::na.omit(df[[col]]))) <= 1) {
    next
  }

  quartile_col <- paste0(col, "_quartile")
  for (q in c(4, 2)) {
    result <- tryCatch(assign_quantile_bins(df[[col]], q), error = function(e) NULL)
    if (!is.null(result)) {
      df[[quartile_col]] <- result
      break
    }
  }
}

validate_required_columns(df)

all_names <- names(df)
valid_names <- !is.na(all_names) & nzchar(all_names)
quartile_cols <- all_names[valid_names & grepl("_quartile$", all_names)]
main_cols <- all_names[valid_names & !grepl("_quartile$", all_names)]
quartile_cols <- quartile_cols[quartile_cols %in% names(df)]
main_cols <- main_cols[main_cols %in% names(df)]

openxlsx::write.xlsx(
  x = list(
    Data = df[, main_cols, drop = FALSE],
    Quartiles = df[, unique(c(utils::head(main_cols, 2), quartile_cols)), drop = FALSE]
  ),
  file = output_path,
  overwrite = TRUE
)

message("dietary.R completed: processed dietary workbook saved from ", basename(data_path), ".")
