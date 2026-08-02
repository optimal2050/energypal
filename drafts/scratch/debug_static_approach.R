# Debug the static approach to find the bug

library(ggplot2)
library(energypal)

cat("=== DEBUGGING STATIC APPROACH ===\n\n")

# Recreate the test data
test_data <- data.frame(
  source = factor(c("Bioenergy", "Coal", "Solar"), levels = c("Bioenergy", "Coal", "Solar")),
  value = c(30, 50, 20)
)

cat("1. Test data sources:\n")
print(unique(test_data$source))

# Simulate what happens in the static case
present_sources <- unique(as.character(test_data$source))
cat("\n2. Present sources detected:\n")
print(present_sources)

# Get base palette
base_palette <- get_energy_palette("iea_primary")
cat("\n3. Base palette (relevant sources):\n")
relevant_palette <- base_palette[intersect(present_sources, names(base_palette))]
print(relevant_palette)

# Simulate the static function logic (this comes from scale_fill_energy when data is provided)
# Apply ordering and direction
auto_order <- TRUE
order_method <- "carbon_intensity"
direction <- -1

if (auto_order && !is.null(order_method) && order_method != "data") {
  canonical <- get_canonical_order(method = order_method, reverse = FALSE)
  canonical_limits <- intersect(canonical, present_sources)
  non_canonical <- setdiff(present_sources, canonical_limits)
  
  if (direction == -1) {
    all_canonical_sources <- c(non_canonical, rev(canonical_limits))
  } else {
    all_canonical_sources <- c(canonical_limits, non_canonical)
  }
} else {
  all_canonical_sources <- present_sources
}

cat("\n4. Canonical ordering applied:\n")
cat("All canonical sources:", paste(all_canonical_sources, collapse = ", "), "\n")

# Build palette subset
palette_subset <- base_palette[intersect(all_canonical_sources, names(base_palette))]
cat("\n5. Palette subset:\n")
print(palette_subset)

# Apply direction to the order
if (direction == -1) {
  all_canonical_sources <- rev(all_canonical_sources)
  cat("\n6. After direction=-1 reversal:\n")
  cat("Canonical sources:", paste(all_canonical_sources, collapse = ", "), "\n")
}

# Final values for scale
values_for_scale <- palette_subset[all_canonical_sources]
values_for_scale <- values_for_scale[!is.na(values_for_scale)]

cat("\n7. Final values for scale:\n")
print(values_for_scale)

cat("\n8. Expected values:\n")
expected <- base_palette[c("Bioenergy", "Coal", "Solar")]
print(expected)

cat("\n9. The issue is in the ordering logic!\n")
cat("   The canonical ordering and direction=-1 is scrambling the source order\n")