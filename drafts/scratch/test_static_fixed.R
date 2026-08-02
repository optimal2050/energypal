# Test the static approach after the fix

library(ggplot2)
library(energypal)

cat("=== TESTING STATIC APPROACH AFTER FIX ===\n\n")

# Create test data
test_data <- data.frame(
  source = factor(c("Bioenergy", "Coal", "Solar"), levels = c("Bioenergy", "Coal", "Solar")),
  value = c(30, 50, 20)
)

cat("1. Test data factor levels:\n")
print(levels(test_data$source))

# Test static approach
cat("\n2. Testing static approach (with data parameter):\n")
p_static <- ggplot(test_data, aes(x = source, y = value, fill = source)) +
  geom_col() +
  scale_fill_energy(data = test_data) +
  labs(title = "Static Approach After Fix")

built_static <- ggplot_build(p_static)
static_colors <- built_static$data[[1]]$fill
names(static_colors) <- levels(test_data$source)

cat("Static colors assigned:\n")
print(static_colors)

# Expected colors
cat("\n3. Expected colors:\n")
iea_palette <- get_energy_palette("iea_primary")
expected_colors <- iea_palette[levels(test_data$source)]
print(expected_colors)

# Check if they match
cat("\n4. Do they match?\n")
matches <- all(static_colors == expected_colors, na.rm = TRUE)
cat("Static matches expected:", matches, "\n")

if (matches) {
  cat("✅ STATIC APPROACH FIXED!\n")
} else {
  cat("❌ Static approach still broken\n")
  cat("Difference:\n")
  for (i in seq_along(static_colors)) {
    name <- names(static_colors)[i]
    cat("  ", name, ": got", static_colors[i], "expected", expected_colors[i], 
        if(static_colors[i] == expected_colors[i]) "✓" else "✗", "\n")
  }
}

# Save plot
ggsave("test_static_fixed.png", p_static, width = 8, height = 5)
cat("\nPlot saved as test_static_fixed.png\n")