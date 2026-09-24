# Makefile for multi-omics project

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
CYAN := \033[0;36m
RESET := \033[0m

# Locations
R_SRC := src
DASH := dashboard
MYCO_SRC := src/mycobiome
DIET_SRC := src/diet

.PHONY: all help setup snapshot status renv-clean r-check test \
        mycobiome dietary characteristics \
        merge normalize-ids \
        app dashboard-data deploy stats stats-diversity stats-permanova stats-symptoms stats-nutrients \
        stats-abundance stats-domain stats-evidence stats-pca \
        clean

# Use R for small file operations and opening local HTML so these targets work
# the same way across macOS, Linux, Git Bash, and Windows.
R_COPY_FILE = Rscript -e "args <- commandArgs(trailingOnly = TRUE); dir.create(dirname(args[2]), recursive = TRUE, showWarnings = FALSE); ok <- file.copy(args[1], args[2], overwrite = TRUE); if (!ok) stop(sprintf('Failed to copy %s to %s', args[1], args[2]))" "$<" "$@"
R_OPEN_STATS_SITE = Rscript -e "browseURL(normalizePath('stats/_site/index.html', winslash = '/', mustWork = TRUE))"

help:
	@printf "%b\n" "$(CYAN)Available commands:$(RESET)"
	@printf "%b\n" ""
	@printf "%b\n" "$(CYAN)Environment Setup & Testing :$(RESET)"
	@printf "%b\n" "  $(YELLOW)make setup$(RESET)            - Install the exact R package versions recorded in renv.lock"
	@printf "%b\n" "  $(YELLOW)make snapshot$(RESET)         - Update renv.lock after adding or updating packages"
	@printf "%b\n" "  $(YELLOW)make status$(RESET)           - Show whether renv.lock and the library are in sync"
	@printf "%b\n" "  $(YELLOW)make renv-clean$(RESET)       - Interactively remove packages unused by the project"
	@printf "%b\n" "  $(YELLOW)make test$(RESET)             - Run unit tests for stats helper functions"
	@printf "%b\n" ""
	@printf "%b\n" "$(CYAN)Developer - R formatting:$(RESET)"
	@printf "%b\n" "  $(YELLOW)make r-check$(RESET)          - Format R files with styler and run lintr checks"
	@printf "%b\n" ""
	@printf "%b\n" "$(CYAN)Step 1 - Shared processing (required by both data products):$(RESET)"
	@printf "%b\n" "  $(YELLOW)make mycobiome$(RESET)        - Core processing: import raw data, wrangle/filter taxa,"
	@printf "%b\n" "                              generate EDA figures and save processed datasets"
	@printf "%b\n" "  $(YELLOW)make dietary$(RESET)          - Clean dietary data and generate EDA figures (heatmaps,"
	@printf "%b\n" "                              box plots, KDE, deficiency barplot)"
	@printf "%b\n" "  $(YELLOW)make characteristics$(RESET)  - Clean participant characteristics (R)"
	@printf "%b\n" ""
	@printf "%b\n" "$(CYAN)Step 2 - Domain relationships:$(RESET)"
	@printf "%b\n" "  $(YELLOW)make merge$(RESET)            - Merge domain datasets, audit of normalized IDs"
	@printf "%b\n" ""
	@printf "%b\n" "$(CYAN)Step 3 - Data products:$(RESET)"
	@printf "%b\n" "  $(YELLOW)make app$(RESET)              - Launch the Shiny dashboard (copies data into dashboard/data/ first)"
	@printf "%b\n" "  $(YELLOW)make stats$(RESET)            - Render Quarto stats site (all posts incl. evidence-ranking matrix)"
	@printf "%b\n" ""
	@printf "%b\n" "$(CYAN)Run as required - Stats sub-targets (use sparingly):$(RESET)"
	@printf "%b\n" "  $(YELLOW)make stats-diversity$(RESET)  - Re-run alpha diversity (Kruskal-Wallis) analysis"
	@printf "%b\n" "  $(YELLOW)make stats-permanova$(RESET)  - Re-run all beta diversity (PERMANOVA) analyses"
	@printf "%b\n" "  $(YELLOW)make stats-symptoms$(RESET)   - Re-run symptoms x fungal composition (Spearman + PERMANOVA)"
	@printf "%b\n" "  $(YELLOW)make stats-nutrients$(RESET)  - Re-run nutrients x diversity by disease group (Spearman)"
	@printf "%b\n" "  $(YELLOW)make stats-domain$(RESET)     - Re-run domain relationships analysis (LM + p-value + R²)"
	@printf "%b\n" "  $(YELLOW)make stats-evidence$(RESET)   - Re-run evidence-ranking matrix (disease-group validation)"
	@printf "%b\n" "  $(YELLOW)make stats-pca$(RESET)        - Re-run diet + mycobiome PCA / clustering"
	@printf "%b\n" ""
	@printf "%b\n" "$(CYAN)Run as required - Dashboard Deployment:$(RESET)"
	@printf "%b\n" "  $(YELLOW)make deploy$(RESET)           - Redeploy the dashboard to Posit Connect Cloud"
	@printf "%b\n" ""
	@printf "%b\n" "$(CYAN)Maintenance:$(RESET)"
	@printf "%b\n" "  $(YELLOW)make clean$(RESET)            - Remove all intermediate, processed, figure, and site files"

# ─── renv setup ──────────────────────────────────────────────────────────────

setup:
	@printf "%b\n" "$(CYAN)Restoring renv environment from renv.lock...$(RESET)"
	@export FLIBS="-lR" && Rscript -e "options(repos=c(CRAN='https://cran.rstudio.com/')); if (!requireNamespace('renv', quietly=TRUE)) install.packages('renv'); renv::restore(prompt = FALSE)" || { \
		printf "%b\n" "$(YELLOW)Setup hint: If Matrix/compilation failed (Mac/Conda), ensure gfortran is updated. If BiocVersion failed (Windows), manually run 'BiocManager::install(\"BiocVersion\")' in an active R session before running make setup again.$(RESET)"; \
		exit 1; \
	}
	@printf "%b\n" "$(GREEN)renv restore complete.$(RESET)"

snapshot:
	@printf "%b\n" "$(CYAN)Updating renv.lock from installed project packages...$(RESET)"
	Rscript -e "renv::snapshot(prompt = FALSE)"
	@printf "%b\n" "$(GREEN)renv snapshot complete.$(RESET)"

status:
	@printf "%b\n" "$(CYAN)Checking renv status...$(RESET)"
	Rscript -e "renv::status()"

renv-clean:
	@printf "%b\n" "$(CYAN)Checking for packages unused by this project...$(RESET)"
	Rscript -e "renv::clean()"

# ─── R checks ────────────────────────────────────────────────────────────────

r-check:
	@printf "%b\n" "$(CYAN)Formatting R files with styler...$(RESET)"
	XDG_CACHE_HOME=/tmp Rscript --vanilla -e "styler::style_dir('$(R_SRC)')"
	@printf "%b\n" "$(CYAN)Running lintr checks...$(RESET)"
	Rscript --vanilla -e "lints <- lintr::lint_dir('$(R_SRC)'); print(lints); quit(status = length(lints) > 0)"
	@printf "%b\n" "$(GREEN)R formatting and lint checks complete.$(RESET)"

test:
	@printf "%b\n" "$(CYAN)Running unit tests...$(RESET)"
	Rscript -e "if (!requireNamespace('testthat', quietly = TRUE)) install.packages('testthat', repos = 'https://cran.rstudio.com/')"
	Rscript tests/testthat.R
	@printf "%b\n" "$(GREEN)Unit tests complete.$(RESET)"

# ─── Shared processing ───────────────────────────────────────────────────────

mycobiome:
	@printf "%b\n" "$(CYAN)Running mycobiome processing pipeline...$(RESET)"
	@printf "%b\n" "$(CYAN)  01 Import raw mycobiome files and metadata$(RESET)"
	Rscript $(MYCO_SRC)/01_data_import.R
	@printf "\n%b\n" "$(CYAN)  02 Wrangle and filter taxa$(RESET)"
	Rscript $(MYCO_SRC)/02_data_wrangling.R
	@printf "%b\n" "$(CYAN)  04 Generate abundance analysis and figures$(RESET)"
	Rscript $(MYCO_SRC)/04_abundance_analysis.R
	@printf "%b\n" "$(CYAN)  05 Generate heatmap EDA figures$(RESET)"
	Rscript $(MYCO_SRC)/05_heatmap_analysis.R
	@printf "\n%b\n" "$(CYAN)  06 Save processed datasets and combined taxa table to data/processed/$(RESET)"
	Rscript $(MYCO_SRC)/06_save_processed.R
	@printf "\n%b\n" "$(GREEN)Mycobiome processing complete. Run make stats-* targets to render analyses.$(RESET)"

dietary:
	@printf "%b\n" "$(CYAN)Running dietary processing pipeline...$(RESET)"
	@printf "%b\n" "$(CYAN)  00 Clean dietary raw data and export processed workbook$(RESET)"
	Rscript $(DIET_SRC)/dietary.R
	@printf "\n%b\n" "$(CYAN)  01 Prepare dietary EDA inputs for figure scripts$(RESET)"
	Rscript $(DIET_SRC)/01_prepare_eda_data.R
	@printf "\n%b\n" "$(CYAN)  02 Generate correlation matrix heatmap$(RESET)"
	Rscript $(DIET_SRC)/02_correlation_heatmap.R
	@printf "\n%b\n" "$(CYAN)  03 Generate scaled boxplots$(RESET)"
	Rscript $(DIET_SRC)/03_scaled_boxplots.R
	@printf "\n%b\n" "$(CYAN)  04 Generate KDE plots by study group$(RESET)"
	Rscript $(DIET_SRC)/04_group_kde_plots.R
	@printf "\n%b\n" "$(CYAN)  05 Generate deficiency score barplot$(RESET)"
	Rscript $(DIET_SRC)/05_deficiency_barplot.R
	@printf "\n%b\n" "$(GREEN)Dietary processing complete.$(RESET)"

characteristics:
	@printf "%b\n" "$(CYAN)Running characteristics processing pipeline...$(RESET)"
	@printf "%b\n" "$(CYAN)  00 Clean participant characteristics raw data and export CSV$(RESET)"
	Rscript src/characteristics/characteristics.R
	@printf "\n%b\n" "$(CYAN)  01 Generate missingness EDA figures$(RESET)"
	Rscript src/characteristics/01_missingness_eda.R
	@printf "\n%b\n" "$(GREEN)Characteristics processing complete.$(RESET)"

# ─── Domain relationships ────────────────────────────────────────────────────

merge: normalize-ids
	@printf "%b\n" "$(CYAN)Merging domain datasets...$(RESET)"
	Rscript $(R_SRC)/merge_files.R
	@printf "%b\n" "$(GREEN)Merge complete.$(RESET)"
	@printf "\n"
	@printf "%b\n" "$(CYAN)Auditing and normalizing participant IDs...$(RESET)"
	Rscript $(R_SRC)/normalize_participant_ids.R
	@printf "%b\n" "$(GREEN)Participant ID audit complete.$(RESET)"

# Steps 1 and 2 in order: shared processing, then merge
all: mycobiome dietary characteristics merge

# ─── Data products ───────────────────────────────────────────────────────────

# Dashboard reads its data from dashboard/data/ so the dashboard/ folder is
# self-contained and deployable on its own (e.g. to Posit Connect Cloud).
$(DASH)/data/merged.csv: data/processed/merged.csv
	@$(R_COPY_FILE)

$(DASH)/data/participants_all.csv: data/processed/participants_all.csv
	@$(R_COPY_FILE)

$(DASH)/data/inflammatory_markers.rds: data/intermediate/inflammatory_markers.rds
	@$(R_COPY_FILE)

dashboard-data: $(DASH)/data/merged.csv $(DASH)/data/participants_all.csv $(DASH)/data/inflammatory_markers.rds
	@printf "%b\n" "$(GREEN)Dashboard data up to date in $(DASH)/data/.$(RESET)"

app: dashboard-data
	@printf "%b\n" "$(CYAN)Launching Shiny dashboard...$(RESET)"
	Rscript -e "shiny::runApp('$(DASH)', launch.browser = TRUE)"

# appName is hardcoded so this finds or updates the one canonical app by name on
# Connect Cloud (rsconnect looks it up server-side even with no local
# deployment record — i.e., dashboard/rsconnect/ is gitignored)
# rather than creating a second app named after the folder.
# Requires rsconnect::connectCloudUser() to have been run once already,
# linked to the account that owns "ibd-dashboard-demo" — see HANDOVER.md § 9.
deploy: dashboard-data
	@printf "%b\n" "$(CYAN)Deploying dashboard to Posit Connect Cloud...$(RESET)"
	Rscript -e "rsconnect::deployApp('$(DASH)', appName = 'ibd-dashboard-demo', appTitle = 'IBD Mycobiome Dashboard (Demo)', launch.browser = TRUE)"

stats:
	@printf "%b\n" "$(CYAN)Rendering statistical analysis site...$(RESET)"
	@test -f data/intermediate/alpha_long.rds || (printf "%b\n" "$(RED)Missing data/intermediate/alpha_long.rds — run make mycobiome (and make diet / characteristics) first.$(RESET)" && exit 1)
	quarto render stats
	@printf "%b\n" "$(GREEN)Site output: stats/_site/index.html$(RESET)"
	@$(R_OPEN_STATS_SITE)

# ─── Stats sub-targets (re-run analysis code, use sparingly) ─────────────────
# These force re-execution of the statistical code (--no-freeze).
# Run make stats afterward to rebuild the full site HTML.

stats-diversity:
	@printf "%b\n" "$(CYAN)Re-running alpha diversity (Kruskal-Wallis) analysis...$(RESET)"
	quarto render stats/posts/2026-05-19-alpha-diversity-kruskal-wallis/index.qmd
	@printf "%b\n" "$(GREEN)Done. Run make stats to rebuild the site.$(RESET)"

stats-permanova:
	@printf "%b\n" "$(CYAN)Re-running beta diversity (PERMANOVA) analyses...$(RESET)"
	quarto render stats/posts/2026-05-19-permanova-family-beta-diversity/index.qmd
	quarto render stats/posts/2026-05-19-permanova-genus-beta-diversity/index.qmd
	quarto render stats/posts/2026-05-19-permanova-phylum-beta-diversity/index.qmd
	quarto render stats/posts/2026-05-19-permanova-species-beta-diversity/index.qmd
	@printf "%b\n" "$(GREEN)Done. Run make stats to rebuild the site.$(RESET)"

stats-symptoms:
	@printf "%b\n" "$(CYAN)Re-running symptoms x fungal composition...$(RESET)"
	quarto render stats/posts/2026-05-22-symptoms-fungal-composition/index.qmd
	@printf "%b\n" "$(GREEN)Done. Run make stats to rebuild the site.$(RESET)"

stats-nutrients:
	@printf "%b\n" "$(CYAN)Re-running nutrients x diversity by disease group...$(RESET)"
	quarto render stats/posts/2026-05-29-nutrients-diversity-disease-group/index.qmd
	@printf "%b\n" "$(GREEN)Done. Run make stats to rebuild the site.$(RESET)"

stats-domain:
	@printf "%b\n" "$(CYAN)Re-running domain relationships analysis...$(RESET)"
	quarto render stats/posts/2026-06-09-domain-relationship-scatter-plots/index.qmd
	@printf "%b\n" "$(GREEN)Done. Run make stats to rebuild the site.$(RESET)"

stats-evidence:
	@printf "%b\n" "$(CYAN)Re-running evidence-ranking matrix (disease-group validation)...$(RESET)"
	quarto render stats/posts/2026-05-29-evidence-ranking-disease-group/index.qmd
	@printf "%b\n" "$(GREEN)Done. Run make stats to rebuild the site.$(RESET)"

stats-pca:
	@printf "%b\n" "$(CYAN)Re-running diet + mycobiome PCA / clustering...$(RESET)"
	quarto render stats/posts/2026-05-29-diet-mycobiome-pca-clustering/index.qmd
	@printf "%b\n" "$(GREEN)Done. Run make stats to rebuild the site.$(RESET)"

# ─── Maintenance ──────────────────────────────────────────────────────────────

clean:
	@printf "%b\n" "$(YELLOW)Cleaning all intermediate, processed, and generated files...$(RESET)"
	@rm -f data/intermediate/*.rds data/intermediate/*.csv data/intermediate/*.xlsx
	@rm -f data/processed/*.rds data/processed/*.csv data/processed/*.xlsx
	@rm -f figures/mycobiome/*.png figures/diet/*.png figures/characteristics/*.png
	@rm -rf stats/_site
	@rm -f notebooks/*.nb.html notebooks/*.html notebooks/*.pdf
	@rm -f $(DASH)/data/*.csv $(DASH)/data/*.rds
	@printf "%b\n" "$(GREEN)Clean complete.$(RESET)"
