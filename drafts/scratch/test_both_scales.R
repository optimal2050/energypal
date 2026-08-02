# Test both scale_fill_energy and scale_color_energy with the fixed interface

library(ggplot2)
library(energypal)

# Create test data
test_data <- data.frame(
  category = rep(c("A", "B", "C"), each = 3),
  source = rep(c("Coal", "Wind", "Solar"), 3),
  value = c(100, 50, 30, 90, 60, 40, 80, 70, 50)
)

print("Test Data:")
print(test_data)

# Test 1: scale_fill_energy without data parameter (dynamic case)
print("\n=== Test 1: scale_fill_energy dynamic case ===")
p1 <- ggplot(test_data, aes(x = category, y = value, fill = source)) +
  geom_col() +
  scale_fill_energy() +
  ggtitle("Fill: Dynamic Case")

print("Created fill plot with scale_fill_energy() - no data parameter")

# Test 2: scale_color_energy without data parameter (dynamic case)
print("\n=== Test 2: scale_color_energy dynamic case ===")
p2 <- ggplot(test_data, aes(x = category, y = value, color = source)) +
  geom_point(size = 4) +
  scale_color_energy() +
  ggtitle("Color: Dynamic Case")

print("Created color plot with scale_color_energy() - no data parameter")

# Test 3: Both with data parameter (static case)
print("\n=== Test 3: Both scales with data parameter ===")
p3 <- ggplot(test_data, aes(x = category, y = value, fill = source, color = source)) +
  geom_col(alpha = 0.7, size = 1) +
  scale_fill_energy(data = test_data) +
  scale_color_energy(data = test_data) +
  ggtitle("Both: Static Case")

print("Created plot with both scales using data parameter")

# Save plots
ggsave("test_fill_dynamic.png", p1, width = 8, height = 6)
ggsave("test_color_dynamic.png", p2, width = 8, height = 6)
ggsave("test_both_static.png", p3, width = 8, height = 6)

print("\nAll plots saved successfully!")
print("Both scale_fill_energy() and scale_color_energy() should work in dynamic mode now.")