# Test what's actually happening in the ggplot2 scale
library(energypal)
library(ggplot2)

# Create a simple subset to debug more easily
data(owid_energy_mix)
usa_data <- subset(owid_energy_mix, country == "United States")

# Create a smaller subset for easier debugging
test_data <- usa_data[usa_data$source %in% c("Coal", "Solar", "Wind", "Nuclear", "Natural Gas"), ]
test_data <- test_data[test_data$year >= 2015, ]

print("Test data sources:")
print(unique(test_data$source))

print("Sample of test data:")
print(head(test_data, 10))

# Test 1: Manual palette function test
cat("\n=== Testing manual palette function ===\n")
base_palette <- get_energy_palette("iea_primary")
canonical_sources <- rev(get_canonical_order(method = "carbon_intensity"))

# Simulate what should happen
test_levels <- c("Coal", "Solar", "Wind", "Nuclear", "Natural Gas")
canonical_present <- intersect(canonical_sources, test_levels)
ordered_sources <- canonical_present

print("Ordered sources:")
print(ordered_sources)

palette_subset <- base_palette[intersect(ordered_sources, names(base_palette))]
print("Palette subset:")
print(palette_subset)

# Test 2: Create a very simple plot
cat("\n=== Testing simple plot ===\n")
tryCatch({
  p_simple <- ggplot(test_data, aes(x = year, y = percentage, fill = source)) +
    geom_col() +
    scale_fill_energy(palette = "iea_primary") +
    labs(title = "Simple Test") +
    theme_minimal()
  
  # Save and analyze
  ggsave("debug_simple_plot.png", p_simple, width = 10, height = 6)
  
  # Build the plot to see what colors were actually used
  built <- ggplot2::ggplot_build(p_simple)
  layer_data <- built$data[[1]]
  
  print("Layer data columns:")
  print(names(layer_data))
  
  print("Unique fill values:")
  print(unique(layer_data$fill))
  
  print("Unique factor levels in fill aesthetic:")
  if ("fill" %in% names(layer_data)) {
    print(table(layer_data$fill))
  }
  
  # Check the scale
  print("Plot scales:")
  print(names(p_simple$scales$scales))
  
}, error = function(e) {
  print("Error:")
  print(e)
})

cat("Debug completed!\n")