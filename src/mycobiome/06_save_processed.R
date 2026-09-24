# 06_save_processed.R: Final saves, including combined long-format taxa file

# ---- Setup ----
suppressPackageStartupMessages({
  library(dplyr)
})


# ---- Load Wrangled Taxa Data ----

taxa_long_list <- readRDS("./data/intermediate/taxa_long_list.rds")


# ---- Save Individual Taxa CSVs ----

objs <- c("genus", "family", "phylum", "species")
for (obj in objs) {
  write.csv(
    taxa_long_list[[obj]],
    file = paste0("./data/processed/", obj, ".csv"),
    row.names = FALSE
  )
}


# ---- Save Combined Long Taxa CSV ----

combined_taxa_long <- bind_rows(
  taxa_long_list$phylum |>
    mutate(level = "phylum", taxa = Phylum) |>
    select(-Phylum),
  taxa_long_list$family |>
    mutate(level = "family", taxa = Family) |>
    select(-Family),
  taxa_long_list$genus |>
    mutate(level = "genus", taxa = Genus) |>
    select(-Genus),
  taxa_long_list$species |>
    mutate(level = "species", taxa = Species) |>
    select(-Species)
)

str(combined_taxa_long)

write.csv(combined_taxa_long,
  "./data/processed/combined_taxa_long.csv",
  row.names = FALSE
)

message("06_save_processed.R completed: Processed data saved.")
