# Test if the static approach works correctly

library(ggplot2)
library(energypal)

cat("=== TESTING STATIC VS DYNAMIC APPROACHES ===\n\n")

# Create test data
test_data <- data.frame(
  source = factor(c("Bioenergy", "Coal", "Solar"), levels = c("Bioenergy", "Coal", "Solar")),
  value = c(30, 50, 20)
)

cat("1. Test data:\n")
print(test_data)
cat("Factor levels:", levels(test_data$source), "\n")

# Test 1: Static approach (with data parameter)
cat("\n2. Testing static approach (with data parameter):\n")
p_static <- ggplot(test_data, aes(x = source, y = value, fill = source)) +
  geom_col() +
  scale_fill_energy(data = test_data) +
  labs(title = "Static Approach")

built_static <- ggplot_build(p_static)
static_colors <- built_static$data[[1]]$fill
names(static_colors) <- levels(test_data$source)

cat("Static colors:\n")
print(static_colors)

# Test 2: Dynamic approach (no data parameter)
cat("\n3. Testing dynamic approach (no data parameter):\n")
p_dynamic <- ggplot(test_data, aes(x = source, y = value, fill = source)) +
  geom_col() +
  scale_fill_energy() +  # No data parameter
  labs(title = "Dynamic Approach")

built_dynamic <- ggplot_build(p_dynamic)
dynamic_colors <- built_dynamic$data[[1]]$fill
names(dynamic_colors) <- levels(test_data$source)

cat("Dynamic colors:\n")
print(dynamic_colors)

# Test 3: Expected colors
cat("\n4. Expected colors (direct palette lookup):\n")
iea_palette <- get_energy_palette("iea_primary")
expected_colors <- iea_palette[levels(test_data$source)]
print(expected_colors)

cat("\n5. Comparison:\n")
cat("Static matches expected:", all(static_colors == expected_colors, na.rm = TRUE), "\n")
cat("Dynamic matches expected:", all(dynamic_colors == expected_colors, na.rm = TRUE), "\n")

if (all(static_colors == expected_colors, na.rm = TRUE)) {
  cat("\n✅ Static approach works correctly!\n")
  cat("💡 Solution: Always use static approach when possible\n")
  cat("   For vignettes, pass the data explicitly: scale_fill_energy(data = usa_data)\n")
} else {
  cat("\n❌ Static approach also has issues\n")
}

# Save plots for visual inspection
ggsave("test_static_approach.png", p_static, width = 8, height = 5)
ggsave("test_dynamic_approach.png", p_dynamic, width = 8, height = 5)
cat("\nPlots saved for visual inspection\n")