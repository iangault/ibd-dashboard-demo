# 05_heatmap_analysis.R: Heatmap prep and plots

# ---- Setup ----

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(ComplexHeatmap)
  library(grid)
})

source("src/mycobiome/00_functions.R")


# ---- Load Wrangled Data ----

taxa_long_list <- readRDS("./data/intermediate/taxa_long_list.rds")
meta_data <- readRDS("./data/intermediate/meta_data.rds")


# ---- Prepare Heatmap Matrices ----

family_z <- make_taxa_matrix(taxa_long_list$family, "Family")
genus_z <- make_taxa_matrix(taxa_long_list$genus, "Genus")
species_z <- make_taxa_matrix(taxa_long_list$species, "Species")
phylum_z <- make_taxa_matrix(taxa_long_list$phylum, "Phylum")


# ---- Save Heatmap Matrices ----

saveRDS(family_z, "./data/intermediate/family_z.rds")
saveRDS(genus_z, "./data/intermediate/genus_z.rds")
saveRDS(species_z, "./data/intermediate/species_z.rds")
saveRDS(phylum_z, "./data/intermediate/phylum_z.rds")


# ---- Plot Heatmaps ----

png("./figures/mycobiome/heat_family.png",
  width = 10, height = 8, units = "in", res = 300
)
plot_taxa_heatmap(family_z, meta_data, row_label = "Fungal Family")
dev.off()

png("./figures/mycobiome/heat_genus.png",
  width = 10, height = 8, units = "in", res = 300
)
plot_taxa_heatmap(genus_z, meta_data, row_label = "Fungal Genus")
dev.off()

png("./figures/mycobiome/heat_species.png",
  width = 10, height = 8, units = "in", res = 300
)
plot_taxa_heatmap(species_z, meta_data, row_label = "Fungal Species")
dev.off()

png("./figures/mycobiome/heat_phylum.png",
  width = 10, height = 8, units = "in", res = 300
)
plot_taxa_heatmap(phylum_z, meta_data, row_label = "Fungal Phylum")
dev.off()

message("05_heatmap_analysis.R completed: Heatmaps generated.")
