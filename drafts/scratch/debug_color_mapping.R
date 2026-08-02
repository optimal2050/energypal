# Debug color mapping issue - why are sources showing as grey "Other" color?

library(ggplot2)
library(energypal)

cat("=== DEBUGGING COLOR MAPPING ISSUE ===\n\n")

# Test with the vignette data that should have proper colors
data(owid_energy_mix)
usa_data <- subset(owid_energy_mix, country == "United States")

cat("1. Sources in USA data:\n")
sources_in_data <- unique(usa_data$source)
print(sources_in_data)

cat("\n2. Check what's in the default palette:\n")
default_palette_name <- get_default_energy_palette()
default_palette <- get_energy_palette(default_palette_name)
cat("Default palette name:", default_palette_name, "\n")
cat("Palette sources:\n")
print(names(default_palette))

cat("\n3. Check mapping between data sources and palette:\n")
for (source in sources_in_data) {
  if (source %in% names(default_palette)) {
    cat("✓", source, "->", default_palette[source], "\n")
  } else {
    cat("✗", source, "-> NOT FOUND in palette\n")
  }
}

cat("\n4. Test map_energy_colors function:\n")
mapped_colors <- map_energy_colors(sources_in_data, palette_name = default_palette_name)
print(mapped_colors)

cat("\n5. Check the IEA primary palette specifically:\n")
iea_palette <- get_energy_palette("iea_primary")
cat("IEA primary palette sources:\n")
print(names(iea_palette))

cat("\n6. Check mapping to IEA palette:\n")
for (source in sources_in_data) {
  if (source %in% names(iea_palette)) {
    cat("✓", source, "->", iea_palette[source], "\n")
  } else {
    cat("✗", source, "-> NOT FOUND in IEA palette\n")
  }
}

cat("\n7. Test map_energy_colors with IEA palette:\n")
iea_mapped <- map_energy_colors(sources_in_data, palette_name = "iea_primary")
print(iea_mapped)