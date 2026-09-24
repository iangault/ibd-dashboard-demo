# Characteristics documentation 

This folder contains the characteristics cleaning and exploratory plotting workflow for the capstone project. The goal is to turn the raw characteristics export into a cleaned workbook and a small set of presentation-ready exploratory figures

## Main points

- `characteristics.R`: cleans the raw dietary file from `data/raw/` and writes `data/processed/cleaned_characteristics.csv`.
- `01_prepare_eda_data.R`: joins cleaned dietary data to study metadata and saves `data/intermediate/diet_eda_inputs.rds`.

## Expected inputs

- Raw dietary export in one of these locations:
  - `data/raw/SYN_Participant Characteristics.xlsx`
  - `data/raw/SYN_Participant Characteristics(Sheet1).csv`

## Outputs

- Cleaned characteristics workbook:
  - `data/processed/cleaned_characteristics.csv`
- Figures:
  - `figures/characteristics/*.png`

## Workflow order

Run the scripts in this order when rebuilding the characteristics visuals from scratch:

1. `src/diet/characteristics.R`
2. `src/diet/01_missingness_eda.R`

## Updating code when new characteristics columns are added

If the raw data export has *new* columns or variables, the first file to review is `src/characteristics/characteristics.R`.

1. Decide whether the new column should simply be carried through to the cleaned output, or whether downstream scripts should actively use it.
2. If downstream scripts depend on the new variable, add its exact raw column name to `required_output_columns` in `src/characteristics/characteristics.R`. This keeps `validate_required_columns()` failing early when the expected variable is missing.
3. If new variables have been added and a specific column name is desired for its implementation, inspect its cleaned post-import name and manually provide a rename in `characteristics_column_renames`
4. If the new variable should not be treated like a general numeric feature, exclude it explicitly in downstream scripts by using `extra_exclude` with `get_diet_numeric_cols()` or by filtering it out in the plot script.
5. If the new variable should appear in a exploratory plot or summary, update the `01_missingness_eda.R` script that creates that plot
6. Re-run the full workflow after the change so you can confirm the cleaned workbook, intermediate RDS, and figures still build without missing-column errors.

## extra notes

- If raw column names change, update `characteristics.R`, especially the required-column check and column rename steps
- Data processing is highly dependent on the specifc structure of functions contained in `characteristics.R`, so it is best to refrain from altering them unless a pointed fix is needed
