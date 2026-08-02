# Test with a completely fresh approach
library(energypal)
library(ggplot2)

# Create simple test data
simple_data <- data.frame(
  year = c(2020, 2020, 2020),
  value = c(100, 50, 25),
  source = c("Coal", "Wind", "Solar"),
  stringsAsFactors = FALSE
)

cat("=== Testing with explicit data parameter ===\n")
tryCatch({
  p_explicit <- ggplot(simple_data, aes(x = year, y = value, fill = source)) +
    geom_col() +
    scale_fill_energy(data = simple_data) +
    labs(title = "With explicit data parameter") +
    theme_minimal()
  
  ggsave("test_explicit_working.png", p_explicit, width = 8, height = 6)
  cat("SUCCESS: Explicit data approach works\n")
  
  # Check what colors were used
  built <- ggplot2::ggplot_build(p_explicit)
  layer_data <- built$data[[1]]
  cat("Colors used:", unique(layer_data$fill), "\n")
  
}, error = function(e) {
  cat("ERROR with explicit data:", e$message, "\n")
})

cat("\n=== Simple solution: always require data parameter ===\n")
cat("RECOMMENDATION: For now, always use scale_fill_energy(data = your_data)\n")
cat("This ensures the scale knows exactly what sources are present.\n")
cat("The 'empty figures' issue occurs when no data parameter is provided.\n")