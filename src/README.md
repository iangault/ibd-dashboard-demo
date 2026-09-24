# src/

This folder contains all the analysis source code. Domain-specific subfolders each have their own README; this file describes the shared scripts at the src/ root that are used across domains.

## Shared scripts

-   `participant_id.R`: defines `normalize_participant_id()`, which standardizes participant ID strings to `PREFIX_NN` format (e.g. `SYN-7` → `SYN_07`). Sourced by most pipeline scripts.
-   `normalize_participant_ids.R`: standalone audit script that reads key raw tables and reports any participant IDs that `normalize_participant_id()` would change.
-   `merge_files.R`: joins the cleaned characteristics and dietary outputs to the mycobiome sample data and writes `data/processed/merged.csv`.

## Subfolders

| Folder | Purpose |
|------------------------------------|------------------------------------|
| `diet/` | Dietary data cleaning and EDA figures - see [diet/README.md](diet/README.md) |
| `mycobiome/` | Mycobiome import, wrangling, abundance plots, and heatmaps - see [mycobiome/README.md](mycobiome/README.md) |
| `characteristics/` | Participant characteristics cleaning and missingness EDA |
| `synth_data/` | Synthetic data generation for testing (`generate_fake_raw_data.py`) |