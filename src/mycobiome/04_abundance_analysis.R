# 04_abundance_analysis.R: Relative abundance plots

# ---- Setup ----
suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
})

source("src/mycobiome/00_functions.R")


# ---- Load Wrangled Taxa Data ----

taxa_long_list <- readRDS("./data/intermediate/taxa_long_list.rds")


# ---- Plot Proportion of Unidentified Fungi ----

# Calculate the proportion of unidentified fungi per taxa
na_prop <- bind_rows(
  calc_na_prop_abund(taxa_long_list$phylum, "Phylum"),
  calc_na_prop_abund(taxa_long_list$family, "Family"),
  calc_na_prop_abund(taxa_long_list$genus, "Genus"),
  calc_na_prop_abund(taxa_long_list$species, "Species")
) |>
  mutate(
    Taxonomic_Level = factor(
      Taxonomic_Level,
      levels = c("Phylum", "Family", "Genus", "Species")
    )
  )

# plot results
p <- ggplot(na_prop, aes(
  x = Taxonomic_Level, y = prop_na,
  fill = Taxonomic_Level
)) +
  geom_boxplot() +
  scale_y_continuous(labels = scales::percent_format(), limits = c(0, 1)) +
  labs(
    y = "Proportion of Unidentified Fungi",
    x = "Taxonomic Level",
    title = "Proportion of Unidentified Fungi per Taxonomic Level"
  ) +
  theme_micro() +
  theme(legend.position = "none")

ggsave(
  file = "./figures/mycobiome/unidentified_taxa.png",
  p,
  width = 6,
  height = 4,
  dpi = 300
)


# ---- Plot Top Families ----

p <- plot_top_taxa(taxa_long_list$family, "Family", n_top = 10) +
  labs(
    title = "Relative Abundance of Top Ten Fungi Families",
    x = "Study Group",
    y = "Mean Relative Abundance"
  )
ggsave(
  file = "./figures/mycobiome/abundance_family.png",
  p, width = 6, height = 4, dpi = 300
)


# ---- Plot Phyla ----

p <- plot_top_taxa(taxa_long_list$phylum, "Phylum") +
  labs(
    title = "Relative Abundance of Fungi Phyla",
    x = "Study Group",
    y = "Mean Relative Abundance"
  )
ggsave(
  file = "./figures/mycobiome/abundance_phylum.png",
  p, width = 6, height = 4, dpi = 300
)


# ---- Plot Top Genera ----

p <- plot_top_taxa(taxa_long_list$genus, "Genus") +
  labs(
    title = "Relative Abundance of Top Ten Fungi Genus",
    x = "Study Group",
    y = "Mean Relative Abundance"
  )
ggsave(
  file = "./figures/mycobiome/abundance_genus.png",
  p, width = 6, height = 4, dpi = 300
)


# ---- Plot Top Species ----

p <- plot_top_taxa(taxa_long_list$species, "Species", n_top = 10) +
  labs(
    title = "Relative Abundance of Top Ten Fungi Species",
    x = "Study Group",
    y = "Mean Relative Abundance"
  )
ggsave(
  file = "./figures/mycobiome/abundance_species.png",
  p, width = 6, height = 4, dpi = 300
)

message("04_abundance_analysis.R completed: Abundance plots saved.")
