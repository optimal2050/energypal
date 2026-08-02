# Debug the actual scale function to see what's happening

library(ggplot2)
library(energypal)

cat("=== DEBUGGING SCALE FUNCTION BEHAVIOR ===\n\n")

# Create a test plot and capture what colors are actually being used
data(owid_energy_mix)
usa_data <- subset(owid_energy_mix, country == "United States")
usa_data$source_ordered <- order_energy_sources(usa_data$source)

cat("1. Original sources:\n")
print(unique(usa_data$source))

cat("\n2. Ordered sources:\n")
print(levels(usa_data$source_ordered))

# Let's create a simple test to see what the palette function returns
cat("\n3. Testing palette function directly:\n")

# Get the palette that would be used
base_palette <- get_energy_palette("iea_primary")
cat("Base palette has", length(base_palette), "colors\n")

# Simulate what happens in our dynamic palette function
test_sources <- levels(usa_data$source_ordered)
cat("Test sources:", paste(test_sources, collapse = ", "), "\n")

# Test the canonical ordering
canonical_sources <- get_canonical_order(method = "carbon_intensity")
cat("Canonical order (first 10):", paste(head(canonical_sources, 10), collapse = ", "), "\n")

# Apply direction = -1 (reverse)
canonical_sources_rev <- rev(canonical_sources)
cat("Reversed canonical (first 10):", paste(head(canonical_sources_rev, 10), collapse = ", "), "\n")

# See what happens when we intersect with actual data
n_sources <- length(test_sources)
selected_sources <- canonical_sources_rev[seq_len(min(n_sources, length(canonical_sources_rev)))]
cat("Selected sources for", n_sources, "factors:", paste(selected_sources, collapse = ", "), "\n")

# Check what colors these get
palette_subset <- base_palette[intersect(selected_sources, names(base_palette))]
cat("Colors found in palette:", length(palette_subset), "\n")
print(palette_subset)

# Check for unmapped sources
unmapped_sources <- setdiff(selected_sources, names(palette_subset))
cat("Unmapped sources:", paste(unmapped_sources, collapse = ", "), "\n")

if (length(unmapped_sources) > 0) {
  fallback_colors <- map_energy_colors(unmapped_sources, palette_name = "iea_primary", unmapped_color = "#999999")
  cat("Fallback colors for unmapped:\n")
  print(fallback_colors)
}

cat("\n4. The issue might be that we're using canonical order instead of actual data order!\n")
cat("   ggplot2 assigns colors to factors in alphabetical order by default.\n")
cat("   But our function returns colors based on canonical (carbon intensity) order.\n")
cat("   This mismatch could cause wrong color assignments!\n")