# Fixed debug script
library(energypal)
library(ggplot2)

# Test with the actual owid_energy_mix data
data("owid_energy_mix")

# Create subset
user_data <- owid_energy_mix[owid_energy_mix$source %in% c("Coal", "Wind", "Solar", "Nuclear"), ]
user_data <- user_data[user_data$year >= 2015 & user_data$year <= 2017, ]
user_data <- head(user_data, 12)

print("User-like data:")
print(user_data)

cat("Unique sources:")
print(unique(user_data$source))

# Check for any issues with the data
cat("\nData validation:\n")
cat("Any NA values in generation_twh?", any(is.na(user_data$generation_twh)), "\n")
cat("Any infinite values?", any(is.infinite(user_data$generation_twh)), "\n")
cat("Data ranges - generation_twh:", range(user_data$generation_twh, na.rm = TRUE), "\n")

# Test a very simple case
cat("\n=== Simple test with minimal data ===\n")
simple_data <- data.frame(
  year = c(2020, 2020, 2020),
  value = c(100, 50, 25),
  source = c("Coal", "Wind", "Solar"),
  stringsAsFactors = FALSE
)

cat("Simple test data:\n")
print(simple_data)

tryCatch({
  p_simple <- ggplot(simple_data, aes(x = year, y = value, fill = source)) +
    geom_col() +
    scale_fill_energy() +
    labs(title = "Simple test") +
    theme_minimal()
  
  ggsave("debug_simple_test.png", p_simple, width = 8, height = 6)
  cat("Simple test: SUCCESS\n")
  
  # Try to build and inspect
  built <- ggplot2::ggplot_build(p_simple)
  cat("Built plot successfully\n")
  
  if (length(built$data) > 0) {
    layer_data <- built$data[[1]]
    cat("Layer has", nrow(layer_data), "rows\n")
    if ("fill" %in% names(layer_data)) {
      cat("Fill colors:", unique(layer_data$fill), "\n")
    }
    if ("y" %in% names(layer_data)) {
      cat("Y values:", layer_data$y, "\n")
    }
  }
  
}, error = function(e) {
  cat("Simple test: ERROR -", e$message, "\n")
  cat("Full error details:\n")
  print(e)
})

cat("\nTest completed!\n")