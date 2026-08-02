# Test the fixed dynamic scale (no data parameter)
library(energypal)
library(ggplot2)

# Load the same data as the vignette
data(owid_energy_mix)

# Filter for United States like in the vignette
usa_data <- subset(owid_energy_mix, country == "United States")

print("=== Testing Vignette-Style Usage ===")
print("Data sources in USA data:")
print(unique(usa_data$source))

# Test 1: Recreate the exact vignette scenario
cat("\n=== Test 1: Exact vignette usage (no data parameter) ===\n")
tryCatch({
  # This is similar to what's in the vignette
  p_vignette <- ggplot(usa_data, aes(x = year, y = percentage, fill = source)) +
    geom_col() +
    scale_fill_energy(palette = "iea_primary") +  # No data parameter like in vignette
    labs(
      title = "USA Energy Mix - Fixed Scale",
      subtitle = "Should show all sources present in data",
      x = "Year", y = "Percentage (%)", fill = "Energy Source"
    ) +
    theme_minimal()
  
  ggsave("test_vignette_fixed.png", p_vignette, width = 10, height = 6)
  cat("SUCCESS: Vignette-style usage works\n")
  
  # Check what colors were assigned
  built <- ggplot2::ggplot_build(p_vignette)
  layer_data <- built$data[[1]]
  unique_colors <- unique(layer_data$fill)
  cat("Colors assigned:", length(unique_colors), "colors\n")
  cat("Fill colors:", unique_colors, "\n")
  
  # Check how many sources are visible
  if (length(unique_colors) >= 5) {
    cat("✅ SUCCESS: Multiple sources visible (not just solar and other)\n")
  } else {
    cat("❌ STILL ISSUE: Only", length(unique_colors), "sources visible\n")
  }
  
}, error = function(e) {
  cat("ERROR:", e$message, "\n")
})

# Test 2: Compare with explicit data approach
cat("\n=== Test 2: With explicit data parameter ===\n")
tryCatch({
  p_explicit <- ggplot(usa_data, aes(x = year, y = percentage, fill = source)) +
    geom_col() +
    scale_fill_energy(palette = "iea_primary", data = usa_data) +
    labs(title = "USA Energy Mix - Explicit Data") +
    theme_minimal()
  
  ggsave("test_explicit_comparison.png", p_explicit, width = 10, height = 6)
  
  built2 <- ggplot2::ggplot_build(p_explicit)
  layer_data2 <- built2$data[[1]]
  unique_colors2 <- unique(layer_data2$fill)
  cat("Explicit data colors:", length(unique_colors2), "colors\n")
  
}, error = function(e) {
  cat("ERROR with explicit:", e$message, "\n")
})

cat("\nTest completed!\n")