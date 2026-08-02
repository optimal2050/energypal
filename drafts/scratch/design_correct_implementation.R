# Create a simple, correct implementation that just maps colors to factor names

library(ggplot2)
library(energypal)

cat("=== CREATING SIMPLE CORRECT IMPLEMENTATION ===\n\n")

# Test data
test_data <- data.frame(
  source = factor(c("Bioenergy", "Coal", "Solar"), levels = c("Bioenergy", "Coal", "Solar")),
  value = c(30, 50, 20)
)

present_sources <- unique(as.character(test_data$source))
cat("Present sources:", paste(present_sources, collapse = ", "), "\n")

# The correct approach for static case:
# 1. Get the base palette
base_palette <- get_energy_palette("iea_primary")

# 2. Map each present source to its color directly (no reordering!)
direct_mapping <- base_palette[present_sources]
direct_mapping <- direct_mapping[!is.na(direct_mapping)]

cat("Direct mapping (correct):\n")
print(direct_mapping)

# 3. For the palette function, return colors in the order that matches factor levels
factor_levels <- levels(test_data$source)
cat("\nFactor levels:", paste(factor_levels, collapse = ", "), "\n")

# The static palette function should work like this:
correct_static_function <- function(n) {
  # Get colors for the factor levels in their order
  factor_colors <- base_palette[factor_levels]
  factor_colors <- factor_colors[!is.na(factor_colors)]
  
  # Return only the number of colors requested (should match number of factors)
  if (n <= length(factor_colors)) {
    return(unname(factor_colors[seq_len(n)]))
  } else {
    # Pad if needed
    padded <- c(factor_colors, rep("#999999", n - length(factor_colors)))
    return(unname(padded[seq_len(n)]))
  }
}

cat("\nCorrect static function would return for n=3:\n")
result <- correct_static_function(3)
print(result)

cat("\nExpected:\n")
expected <- unname(base_palette[factor_levels])
print(expected)

cat("\nDo they match?", all(result == expected, na.rm = TRUE), "\n")

cat("\n💡 KEY INSIGHT: The static function should return colors in FACTOR LEVEL ORDER\n")
cat("   Not in canonical carbon intensity order!\n")
cat("   The direction parameter should only affect legend display, not color assignment.\n")