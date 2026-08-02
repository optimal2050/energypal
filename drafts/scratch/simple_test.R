# Simple test to verify scale fixes
library(energypal)
library(ggplot2)

# Load available data
data("owid_energy_mix")

# Create a subset with only a few sources
test_data <- owid_energy_mix[owid_energy_mix$source %in% c("Coal", "Wind", "Solar", "Nuclear"), ]
test_data <- test_data[test_data$year >= 2015, ]
test_data <- head(test_data, 20)

print("Test data structure:")
str(test_data)
print("Unique sources in test data:")
print(unique(test_data$source))

# Test plot with explicit data parameter
cat("Creating test plot...\n")
p1 <- ggplot(test_data, aes(x = year, y = generation_twh, fill = source)) +
  geom_col() +
  scale_fill_energy(data = test_data) +
  labs(title = "Test plot - should show only present sources") +
  theme_minimal()

# Try to save the plot to see if it works
ggsave("test_plot.png", p1, width = 8, height = 6)
cat("Plot saved as test_plot.png\n")

cat("Test completed!\n")