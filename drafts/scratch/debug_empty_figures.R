# Debug script to understand why figures are empty
library(energypal)
library(ggplot2)

# Load data
data("owid_energy_mix")

# Create simple test data
test_data <- data.frame(
  year = c(2020, 2020, 2020),
  value = c(100, 50, 25),
  source = c("Coal", "Wind", "Solar")
)

print("Test data:")
print(test_data)

# Test 1: Basic plot without any scale
cat("\n=== Test 1: Basic plot (no scale) ===\n")
p_basic <- ggplot(test_data, aes(x = year, y = value, fill = source)) +
  geom_col() +
  labs(title = "Basic plot - no custom scale") +
  theme_minimal()

tryCatch({
  ggsave("debug_basic.png", p_basic, width = 8, height = 6)
  cat("Basic plot: SUCCESS\n")
}, error = function(e) {
  cat("Basic plot: ERROR -", e$message, "\n")
})

# Test 2: With scale_fill_energy but explicit data
cat("\n=== Test 2: With scale_fill_energy(data = test_data) ===\n")
tryCatch({
  p_explicit <- ggplot(test_data, aes(x = year, y = value, fill = source)) +
    geom_col() +
    scale_fill_energy(data = test_data) +
    labs(title = "With explicit data parameter") +
    theme_minimal()
  
  ggsave("debug_explicit.png", p_explicit, width = 8, height = 6)
  cat("Explicit data: SUCCESS\n")
}, error = function(e) {
  cat("Explicit data: ERROR -", e$message, "\n")
})

# Test 3: With scale_fill_energy dynamic (no data parameter)
cat("\n=== Test 3: With scale_fill_energy() dynamic ===\n")
tryCatch({
  p_dynamic <- ggplot(test_data, aes(x = year, y = value, fill = source)) +
    geom_col() +
    scale_fill_energy() +
    labs(title = "Dynamic scale (no data parameter)") +
    theme_minimal()
  
  ggsave("debug_dynamic.png", p_dynamic, width = 8, height = 6)
  cat("Dynamic scale: SUCCESS\n")
}, error = function(e) {
  cat("Dynamic scale: ERROR -", e$message, "\n")
})

# Test 4: Let's also manually test what the palette function returns
cat("\n=== Test 4: Manual palette function test ===\n")
tryCatch({
  # Try to access the scale function internals
  sources <- c("Coal", "Wind", "Solar")
  base_palette <- get_energy_palette()
  cat("Base palette has", length(base_palette), "colors\n")
  cat("Base palette names:", names(base_palette)[1:10], "...\n")
  
  # Test the mapping function
  mapped_colors <- map_energy_colors(sources, palette_name = NULL, method = "auto")
  cat("Mapped colors for our sources:\n")
  print(mapped_colors)
  
}, error = function(e) {
  cat("Manual test: ERROR -", e$message, "\n")
})

cat("\nDebug completed!\n")