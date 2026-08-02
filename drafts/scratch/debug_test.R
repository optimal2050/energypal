# Test both dynamic and explicit data cases
library(energypal)
library(ggplot2)

# Load available data
data("owid_energy_mix")

# Create a subset
test_data <- owid_energy_mix[owid_energy_mix$source %in% c("Coal", "Wind", "Solar"), ]
test_data <- test_data[test_data$year >= 2015, ]
test_data <- head(test_data, 15)

print("Test data sources:")
print(unique(test_data$source))
print("Sample data:")
print(head(test_data))

# Test 1: With explicit data parameter (this should work)
cat("\n=== Test 1: With explicit data parameter ===\n")
p1 <- ggplot(test_data, aes(x = year, y = generation_twh, fill = source)) +
  geom_col() +
  scale_fill_energy(data = test_data) +
  labs(title = "With explicit data parameter") +
  theme_minimal()

ggsave("test_explicit_data.png", p1, width = 8, height = 6)
cat("Explicit data test: SUCCESS - plot saved\n")

# Test 2: Without data parameter (dynamic - this might be the problem)
cat("\n=== Test 2: Without data parameter (dynamic) ===\n")
tryCatch({
  p2 <- ggplot(test_data, aes(x = year, y = generation_twh, fill = source)) +
    geom_col() +
    scale_fill_energy() +  # No data parameter
    labs(title = "Without data parameter (dynamic)") +
    theme_minimal()
  
  ggsave("test_dynamic.png", p2, width = 8, height = 6)
  cat("Dynamic test: SUCCESS - plot saved\n")
}, error = function(e) {
  cat("Dynamic test: ERROR -", e$message, "\n")
})

# Test 3: Let's also test if we can check what the dynamic function returns
cat("\n=== Test 3: Debug dynamic function ===\n")
tryCatch({
  # Create a minimal example that should trigger the dynamic path
  simple_data <- data.frame(
    x = 1:3,
    y = c(10, 20, 15),
    source = c("Coal", "Wind", "Solar")
  )
  
  p3 <- ggplot(simple_data, aes(x = x, y = y, fill = source)) +
    geom_col() +
    scale_fill_energy() +
    labs(title = "Simple dynamic test") +
    theme_minimal()
  
  ggsave("test_simple_dynamic.png", p3, width = 8, height = 6)
  cat("Simple dynamic test: SUCCESS - plot saved\n")
}, error = function(e) {
  cat("Simple dynamic test: ERROR -", e$message, "\n")
})

cat("\nAll tests completed!\n")