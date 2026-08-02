# Create a fixed version of the dynamic palette function

library(ggplot2)
library(energypal)

cat("=== CREATING BETTER DYNAMIC PALETTE FUNCTION ===\n\n")

# The key insight: In dynamic mode, we need to return colors that work well
# for the most common energy sources when they appear in alphabetical order

# Most common energy sources in typical datasets, in alphabetical order:
common_sources_alphabetical <- c(
  "Bioenergy", "Coal", "Gas", "Geothermal", "Hydro", 
  "Natural Gas", "Nuclear", "Oil", "Other", "Solar", "Wind"
)

cat("Common sources in alphabetical order:\n")
print(common_sources_alphabetical)

# Get the IEA palette
iea_palette <- get_energy_palette("iea_primary")
cat("\nIEA palette sources:\n")
print(names(iea_palette))

# Map the alphabetical sources to good colors
alphabetical_colors <- character(0)
for (source in common_sources_alphabetical) {
  if (source %in% names(iea_palette)) {
    alphabetical_colors[source] <- iea_palette[source]
  } else {
    # Handle aliases
    if (source == "Gas") {
      alphabetical_colors[source] <- iea_palette["Natural Gas"]
    } else {
      alphabetical_colors[source] <- "#999999"  # fallback
    }
  }
}

cat("\nAlphabetical color mapping:\n")
print(alphabetical_colors)

cat("\n=== TESTING THE IMPROVED APPROACH ===\n")

# Test with our problematic case
test_sources <- c("Bioenergy", "Coal", "Solar")
cat("Test sources:", paste(test_sources, collapse = ", "), "\n")

# What colors should we return for n=3?
n <- length(test_sources)
colors_for_n <- alphabetical_colors[common_sources_alphabetical[1:n]]
cat("Colors to return for first", n, "alphabetical sources:\n")
print(colors_for_n)

cat("\nThis should give much better color matches!\n")