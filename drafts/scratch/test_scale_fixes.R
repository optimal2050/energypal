# Test script to verify scale fixes
library(energypal)
library(ggplot2)
library(dplyr)

# Load some example data 
data("owid_energy_global")

# Test 1: Create a subset with only a few sources to check legend doesn't show unused sources
test_data <- owid_energy_global %>%
  filter(source %in% c("Coal", "Wind", "Solar", "Nuclear")) %>%
  filter(year >= 2010) %>%
  head(20)

print("Test data sources:")
print(unique(test_data$source))

# Test 2: Create a stacked area chart to see if legend only shows present sources
# Pass the data explicitly to avoid the dynamic function path
p1 <- ggplot(test_data, aes(x = year, y = twh, fill = source)) +
  geom_area() +
  scale_fill_energy(data = test_data) +
  labs(title = "Should only show Coal, Wind, Solar, Nuclear in legend",
       subtitle = "No unused sources should appear") +
  theme_minimal()

print("Creating plot with scale_fill_energy(data = test_data)...")
print(p1)

# Test 3: Test ordering - coal should be at bottom by default (direction = -1)
p2 <- ggplot(test_data, aes(x = year, y = twh, fill = source)) +
  geom_area(position = "stack") +
  scale_fill_energy(order_method = "carbon_intensity", data = test_data) +
  labs(title = "Coal should be at bottom of stack (lowest carbon first)",
       subtitle = "Default direction = -1 should place coal at bottom") +
  theme_minimal()

print("Creating plot with carbon_intensity ordering...")
print(p2)

# Test 4: Test color scale as well
p3 <- ggplot(test_data, aes(x = year, y = twh, color = source)) +
  geom_point(size = 3) +
  scale_color_energy(data = test_data) +
  labs(title = "Color scale should also only show present sources") +
  theme_minimal()

print("Creating plot with scale_color_energy(data = test_data)...")
print(p3)

cat("All tests completed! Check that:\n")
cat("1. Legends only show sources actually present in the data\n")
cat("2. Coal appears at the bottom of stacked charts by default\n")
cat("3. No unused source names appear in legends\n")