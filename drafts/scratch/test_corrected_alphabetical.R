# Test the corrected alphabetical ordering

library(ggplot2)
library(energypal)

cat("=== TESTING CORRECTED ALPHABETICAL ORDERING ===\n\n")

# Corrected alphabetical energy sources (removing "Gas" to avoid duplication)
alphabetical_energy_sources <- c(
  "Bioenergy", "Coal", "Geothermal", "Hydro", "Natural Gas", 
  "Nuclear", "Oil", "Other", "Solar", "Wind"
)

cat("Corrected alphabetical sources:\n")
print(alphabetical_energy_sources)

# Test with our problematic case: factors are "Bioenergy", "Coal", "Solar"
# In alphabetical order among our list:
# Position 1: Bioenergy 
# Position 2: Coal
# Position 9: Solar (this is the key fix!)

test_factors <- c("Bioenergy", "Coal", "Solar")
cat("\nTest factors:", paste(test_factors, collapse = ", "), "\n")

# Find positions in our alphabetical list
positions <- match(test_factors, alphabetical_energy_sources)
cat("Positions in alphabetical list:", paste(positions, collapse = ", "), "\n")

# Get IEA palette
iea_palette <- get_energy_palette("iea_primary")

# Build the corrected color assignment
colors_for_positions <- character(3)
for (i in 1:3) {
  pos <- positions[i]
  if (!is.na(pos)) {
    source <- alphabetical_energy_sources[pos]
    if (source %in% names(iea_palette)) {
      colors_for_positions[i] <- iea_palette[source]
    } else {
      colors_for_positions[i] <- "#999999"
    }
  } else {
    colors_for_positions[i] <- "#999999"
  }
}

cat("\nColors that would be assigned:\n")
for (i in 1:3) {
  cat(" ", test_factors[i], "->", colors_for_positions[i], "\n")
}

cat("\nExpected colors from direct palette lookup:\n")
expected_colors <- iea_palette[test_factors]
for (i in 1:3) {
  cat(" ", test_factors[i], "->", expected_colors[i], "\n")
}

cat("\nDo they match?", all(colors_for_positions == expected_colors, na.rm = TRUE), "\n")

# The issue is that we're not matching the factors directly!
# We need a completely different approach...