# Test the dynamic function manually
library(energypal)

# Try to recreate what the dynamic function should do
sources <- c("Coal", "Wind", "Solar")
palette_name <- get_default_energy_palette()

cat("Sources to map:", sources, "\n")
cat("Default palette:", palette_name, "\n")

# Test get_energy_palette
base_palette <- get_energy_palette(palette_name)
cat("Base palette size:", length(base_palette), "\n")
cat("Base palette sample names:", names(base_palette)[1:10], "\n")

# Test the mapping
if (exists("map_energy_colors")) {
  tryCatch({
    mapped_colors <- map_energy_colors(sources, palette_name = palette_name, method = "auto", unmapped_color = "#999999")
    cat("Mapped colors:\n")
    print(mapped_colors)
  }, error = function(e) {
    cat("Error in map_energy_colors:", e$message, "\n")
  })
} else {
  cat("map_energy_colors function not found\n")
}

# Test manual palette building
cat("\nTesting manual palette building...\n")
palette_subset <- base_palette[intersect(sources, names(base_palette))]
cat("Direct palette matches:\n")
print(palette_subset)

unmapped_sources <- setdiff(sources, names(palette_subset))
cat("Unmapped sources:", unmapped_sources, "\n")

if (length(unmapped_sources) > 0 && exists("map_energy_colors")) {
  tryCatch({
    fallback_colors <- map_energy_colors(unmapped_sources, palette_name = palette_name, method = "auto", unmapped_color = "#999999")
    cat("Fallback colors:\n")
    print(fallback_colors)
    
    final_palette <- c(palette_subset, fallback_colors)
    cat("Final combined palette:\n")
    print(final_palette)
  }, error = function(e) {
    cat("Error in fallback mapping:", e$message, "\n")
  })
}