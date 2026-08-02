# Debug the fixed palette function

library(ggplot2)
library(energypal)

cat("=== DEBUGGING THE FIXED PALETTE FUNCTION ===\n\n")

# Test the corrected palette function logic
base_palette <- get_energy_palette("iea_primary")

# Corrected alphabetical sources
alphabetical_energy_sources <- c(
  "Bioenergy", "Coal", "Geothermal", "Hydro", "Natural Gas", 
  "Nuclear", "Oil", "Other", "Solar", "Wind"
)

cat("1. Alphabetical sources:\n")
print(alphabetical_energy_sources)

# Build the alphabetical colors
alphabetical_colors <- character(length(alphabetical_energy_sources))
names(alphabetical_colors) <- alphabetical_energy_sources

for (i in seq_along(alphabetical_energy_sources)) {
  source <- alphabetical_energy_sources[i]
  if (source %in% names(base_palette)) {
    alphabetical_colors[i] <- base_palette[source]
  } else {
    alphabetical_colors[i] <- "#999999"
  }
}

cat("\n2. Alphabetical colors built:\n")
print(alphabetical_colors)

# Test with n=3 (what our function should return)
n <- 3
colors_to_return <- unname(alphabetical_colors[seq_len(min(n, length(alphabetical_colors)))])

cat("\n3. Colors returned for n=3:\n")
print(colors_to_return)

cat("\n4. These should be assigned to factors in order:\n")
test_factors <- c("Bioenergy", "Coal", "Solar")
for (i in 1:3) {
  cat("  Factor", i, "(", test_factors[i], ") gets color", i, ":", colors_to_return[i], "\n")
}

cat("\n5. What we expect from direct lookup:\n")
expected <- base_palette[test_factors]
print(expected)

cat("\n6. The issue: We return colors 1,2,3 from alphabetical list\n")
cat("   But factors are Bioenergy(1), Coal(2), Solar(9 in alphabet)\n")
cat("   So we need to return colors at positions 1,2,9 not 1,2,3!\n")

# The correct approach: return colors that match the specific factors
cat("\n7. Correct approach - match actual factor positions:\n")
correct_colors <- character(3)
for (i in 1:3) {
  factor_name <- test_factors[i]
  pos <- match(factor_name, alphabetical_energy_sources)
  if (!is.na(pos)) {
    correct_colors[i] <- alphabetical_colors[pos]
    cat("  ", factor_name, "at position", pos, "gets", alphabetical_colors[pos], "\n")
  }
}

cat("\nCorrect colors to return:", paste(correct_colors, collapse = ", "), "\n")
cat("Expected colors:          ", paste(unname(expected), collapse = ", "), "\n")
cat("Do they match?", all(correct_colors == unname(expected), na.rm = TRUE), "\n")