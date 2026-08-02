# More thorough debug to find empty figure issue
library(energypal)
library(ggplot2)

# Test with the actual owid_energy_mix data like user would use
data("owid_energy_mix")

# Create subset similar to what user might create
user_data <- owid_energy_mix[owid_energy_mix$source %in% c("Coal", "Wind", "Solar", "Nuclear"), ]
user_data <- user_data[user_data$year >= 2015 & user_data$year <= 2017, ]
user_data <- head(user_data, 12)

print("User-like data:")
print(user_data)
print("Unique sources:", unique(user_data$source))

# Test typical user patterns
cat("\n=== Pattern 1: Stacked area chart ===\n")
tryCatch({
  p1 <- ggplot(user_data, aes(x = year, y = generation_twh, fill = source)) +
    geom_area() +
    scale_fill_energy() +
    labs(title = "Stacked Area Chart") +
    theme_minimal()
  
  ggsave("pattern1_area.png", p1, width = 10, height = 6)
  cat("Area chart: SUCCESS\n")
}, error = function(e) {
  cat("Area chart: ERROR -", e$message, "\n")
})

cat("\n=== Pattern 2: Stacked column chart ===\n")
tryCatch({
  p2 <- ggplot(user_data, aes(x = year, y = generation_twh, fill = source)) +
    geom_col(position = "stack") +
    scale_fill_energy() +
    labs(title = "Stacked Column Chart") +
    theme_minimal()
  
  ggsave("pattern2_col.png", p2, width = 10, height = 6)
  cat("Column chart: SUCCESS\n")
}, error = function(e) {
  cat("Column chart: ERROR -", e$message, "\n")
})

cat("\n=== Pattern 3: With carbon intensity ordering ===\n")
tryCatch({
  p3 <- ggplot(user_data, aes(x = year, y = generation_twh, fill = source)) +
    geom_col(position = "stack") +
    scale_fill_energy(order_method = "carbon_intensity") +
    labs(title = "Carbon Intensity Ordered") +
    theme_minimal()
  
  ggsave("pattern3_carbon.png", p3, width = 10, height = 6)
  cat("Carbon ordered: SUCCESS\n")
}, error = function(e) {
  cat("Carbon ordered: ERROR -", e$message, "\n")
})

# Check what colors are actually being assigned
cat("\n=== Debug: What colors are assigned? ===\n")
tryCatch({
  # Let's create a plot and try to extract the actual colors used
  p_debug <- ggplot(user_data, aes(x = year, y = generation_twh, fill = source)) +
    geom_col() +
    scale_fill_energy()
  
  # Build the plot to see what actually gets assigned
  built_plot <- ggplot2::ggplot_build(p_debug)
  
  cat("Plot data layers:\n")
  cat("Number of layers:", length(built_plot$data), "\n")
  if (length(built_plot$data) > 0) {
    layer_data <- built_plot$data[[1]]
    cat("Layer data columns:", names(layer_data), "\n")
    if ("fill" %in% names(layer_data)) {
      cat("Fill colors used:", unique(layer_data$fill), "\n")
    }
  }
}, error = function(e) {
  cat("Debug extraction: ERROR -", e$message, "\n")
})

cat("\nDebugging completed!\n")