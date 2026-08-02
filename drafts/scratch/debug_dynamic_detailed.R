# Debug the dynamic function more thoroughly
library(energypal)
library(ggplot2)

# Load the data
data(owid_energy_mix)
usa_data <- subset(owid_energy_mix, country == "United States")

print("USA data sources:")
print(sort(unique(usa_data$source)))

# Test what the palette function should receive and return
print("\n=== Manual test of palette function logic ===")

# Simulate what ggplot2 would pass to the palette function
actual_levels <- sort(unique(usa_data$source))
print("Actual factor levels:")
print(actual_levels)

# Test the ordering logic manually
canonical_sources <- get_canonical_order(method = "carbon_intensity")
print("\nCanonical sources (first 10):")
print(head(canonical_sources, 10))

# Apply direction = -1 (reverse)
canonical_sources_reversed <- rev(canonical_sources)
print("\nCanonical sources reversed (first 10):")
print(head(canonical_sources_reversed, 10))

# Find intersection
canonical_present <- intersect(canonical_sources_reversed, actual_levels)
non_canonical <- setdiff(actual_levels, canonical_sources_reversed)

print("\nCanonical present:")
print(canonical_present)
print("\nNon-canonical:")
print(non_canonical)

ordered_sources <- c(canonical_present, non_canonical)
print("\nFinal ordered sources:")
print(ordered_sources)

# Test the palette mapping
base_palette <- get_energy_palette("iea_primary")
print("\nBase palette (first 10):")
print(head(base_palette, 10))

palette_subset <- base_palette[intersect(ordered_sources, names(base_palette))]
print("\nPalette subset:")
print(palette_subset)

unmapped_sources <- setdiff(ordered_sources, names(palette_subset))
print("\nUnmapped sources:")
print(unmapped_sources)

# Test mapping for unmapped sources
if (length(unmapped_sources) > 0) {
  fallback_colors <- map_energy_colors(unmapped_sources, palette_name = "iea_primary", method = "auto", unmapped_color = "#999999")
  print("\nFallback colors:")
  print(fallback_colors)
  
  final_palette <- c(palette_subset, fallback_colors)
  print("\nFinal combined palette:")
  print(final_palette)
}