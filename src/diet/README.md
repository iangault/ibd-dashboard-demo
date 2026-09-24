# Diet documentation 

This folder contains the dietary cleaning and exploratory plotting workflow for the capstone project. The goal is to turn the raw dietary export into a cleaned workbook and a small set of presentation-ready exploratory figures

## Main points

- `dietary.R`: cleans the raw dietary file from `data/raw/` and writes `data/processed/dietary_cleaned.xlsx`.
- `01_prepare_eda_data.R`: joins cleaned dietary data to study metadata and saves `data/intermediate/diet_eda_inputs.rds`.
- `02_correlation_heatmap.R`: creates a heatmap of correlations across dietary numeric variables
- `03_scaled_boxplots.R`: creates min-max scaled boxplots so variables on different units can be visually compared
- `04_group_kde_plots.R`: creates density plots by study group for a curated subset of dietary variables
- `05_deficiency_barplot.R`: summarizes participant-level deficiencies against a set of dietary targets
- `00_functions.R`: shared path helpers, loaders, plotting helpers, and small transformations used by the EDA scripts

## Expected inputs

- Raw dietary export in one of these locations:
  - `data/raw/SYN_dietary data.xlsx`
  - `data/raw/SYN_dietary data.csv`
  - `data/raw/SYN_dietary data(ALL).csv`
- Project metadata from either:
  - `data/intermediate/meta_data.rds` (ignore if confusing)
  - `data/processed/merged.csv`

## Outputs

- Cleaned dietary workbook:
  - `data/processed/dietary_cleaned.xlsx`
- EDA intermediate file:
  - `data/intermediate/diet_eda_inputs.rds`
- Figures:
  - `figures/diet/*.png`

## Workflow order

Run the scripts in this order when rebuilding the diet visuals from scratch:

1. `src/diet/dietary.R`
2. `src/diet/01_prepare_eda_data.R`
3. `src/diet/02_correlation_heatmap.R`
4. `src/diet/03_scaled_boxplots.R`
5. `src/diet/04_group_kde_plots.R`
6. `src/diet/05_deficiency_barplot.R`

## Updating code when new dietary columns are added

If the raw data export has *new* columns or variables, the first file to review is `src/diet/dietary.R`.

1. Decide whether the new column should simply be carried through to the cleaned output, or whether downstream scripts should actively use it.
2. If downstream scripts depend on the new variable, add its exact raw column name to `required_data_columns` in `src/diet/dietary.R`. This keeps `validate_required_columns()` failing early when the expected variable is missing.
3. If the raw header changed only by whitespace, follow the existing `rename_trimmed_column()` pattern rather than rewriting the cleaning logic.
4. If the new variable is numeric and appears after the first three identifier columns, it will usually flow automatically into the cleaned `Data` sheet and be eligible for quartile creation because `dietary.R` detects numeric columns from column 4 onward.
5. If the new variable should not be treated like a general numeric feature, exclude it explicitly in downstream scripts by using `extra_exclude` with `get_diet_numeric_cols()` or by filtering it out in the plot script.
6. If the new variable should appear in a curated plot or summary, update the script that creates that plot:
   - `04_group_kde_plots.R` for selected density-plot variables
   - `05_deficiency_barplot.R` for recommendation-based food-group summaries
   - any other script with a manual `select()`, `all_of()`, or named vector of columns
7. Re-run the full workflow after the change so you can confirm the cleaned workbook, intermediate RDS, and figures still build without missing-column errors.

## extra notes

- If a new plot needs dietary numeric variables, prefer using `get_diet_numeric_cols()` instead of manually slicing columns
- If a script writes a new figure or intermediate file, use the helpers in `00_functions.R` so outputs stay in the expected project locations
- If raw column names change, update `dietary.R`, especially the required-column checks and participant-ID handling
- The cleaning logic intentionally drops non-participant note rows and summary rows. Preserve that behavior unless there is a clear data reason to change it
