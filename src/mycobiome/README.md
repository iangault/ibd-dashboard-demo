# Mycobiome documentation

This folder contains the workflow for importing, wrangling, and analyzing mycobiome data for the capstone project. The goal is to turn the raw fungal relative abundance export into cleaned taxa tables and a set of presentation-ready exploratory figures.

## Main points

-   `01_data_import.R`: reads the raw mycobiome Excel file (all sheets) and sample metadata, normalizes participant IDs, and saves intermediate RDS files.
-   `02_data_wrangling.R`: joins taxa data to metadata and inflammatory biomarkers, reshapes to long format, handles NAs, and saves the wrangled taxa list and metadata.
-   `04_abundance_analysis.R`: produces relative abundance plots and a summary of unidentified (NA) fungi proportions across taxonomic levels.
-   `05_heatmap_analysis.R`: builds z-score matrices and ComplexHeatmap figures at the phylum, family, genus, and species levels.
-   `06_save_processed.R`: writes individual per-level CSVs and a combined long-format taxa CSV to `data/processed/`.
-   `00_functions.R`: shared plot theme, taxa cleaning helpers, long-format reshaping, NA proportion calculators, and matrix builders used by the analysis scripts.

## Expected inputs

-   Raw mycobiome relative abundance file:
    -   `data/raw/SYN_stool mycobiota relative abund.xlsx`
-   Sample metadata:
    -   `data/raw/SYN_MBI sample IDs meta.xlsx`
-   Inflammatory biomarkers:
    -   `data/raw/SYN_Inflammatory biomarkers.xlsx`
-   Shared participant ID normalizer:
    -   `src/participant_id.R`

## Outputs

-   Intermediate RDS files:
    -   `data/intermediate/data_list.rds`
    -   `data/intermediate/meta_raw.rds`
    -   `data/intermediate/meta_data.rds`
    -   `data/intermediate/taxa_long_list.rds`
    -   `data/intermediate/heatmap_matrices.rds` (or equivalent, written by `05_heatmap_analysis.R`)
-   Processed taxa CSVs:
    -   `data/processed/phylum.csv`
    -   `data/processed/family.csv`
    -   `data/processed/genus.csv`
    -   `data/processed/species.csv`
    -   `data/processed/combined_taxa_long.csv`
-   Figures:
    -   `figures/mycobiome/*.png`

## Workflow order

Run the scripts in this order when rebuilding the mycobiome outputs from scratch:

1.  `src/mycobiome/01_data_import.R`
2.  `src/mycobiome/02_data_wrangling.R`
3.  `src/mycobiome/04_abundance_analysis.R`
4.  `src/mycobiome/05_heatmap_analysis.R`
5.  `src/mycobiome/06_save_processed.R`

## Extra notes

-   If raw sheet names or column names change in the source Excel file, update `01_data_import.R` and the `make_clean_names` mapping, and check that downstream scripts still find the expected list elements.
-   The wrangling logic intentionally removes non-participant rows and normalizes participant IDs.