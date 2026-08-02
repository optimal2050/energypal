# Test the fixed palette function interface

library(ggplot2)
library(energypal)

# Create test data with energy sources
test_data <- data.frame(
  year = rep(2020:2022, each = 3),
  source = rep(c("Coal", "Wind", "Solar"), 3),
  value = c(100, 50, 30, 90, 60, 40, 80, 70, 50)
)

print("Test Data:")
print(test_data)

# Test 1: Using scale_fill_energy without data parameter (dynamic case)
print("\n=== Test 1: Dynamic case (no data parameter) ===")
p1 <- ggplot(test_data, aes(x = year, y = value, fill = source)) +
  geom_col() +
  scale_fill_energy() +
  ggtitle("Dynamic Case")

print("Created plot with scale_fill_energy() - no data parameter")

# Test 2: Using scale_fill_energy with data parameter (static case)
print("\n=== Test 2: Static case (with data parameter) ===")
p2 <- ggplot(test_data, aes(x = year, y = value, fill = source)) +
  geom_col() +
  scale_fill_energy(data = test_data) +
  ggtitle("Static Case")

print("Created plot with scale_fill_energy(data = test_data)")

# Test 3: Check what factors ggplot2 sees
print("\n=== Test 3: Factor analysis ===")
print("Unique sources in data:")
print(unique(test_data$source))
print("As factor levels:")
factor_sources <- as.factor(test_data$source)
print(levels(factor_sources))

# Save plots to check if they work
ggsave("test_dynamic.png", p1, width = 8, height = 6)
ggsave("test_static.png", p2, width = 8, height = 6)

print("\nPlots saved as test_dynamic.png and test_static.png")
print("If successful, both plots should show all three sources with proper colors")