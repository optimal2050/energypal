# Test the specific vignette example that was showing only "solar and other"

library(ggplot2)
library(energypal)

# Recreate the problematic example from palettes.Rmd
# This should be similar to the "Energy Mix Visualization" example

# Create sample energy mix data
energy_mix <- data.frame(
  country = rep(c("USA", "Germany", "Japan"), each = 4),
  source = rep(c("Coal", "Natural Gas", "Nuclear", "Renewables"), 3),
  percentage = c(
    # USA
    23, 35, 20, 22,
    # Germany  
    28, 25, 12, 35,
    # Japan
    32, 38, 7, 23
  )
)

print("Energy Mix Data:")
print(energy_mix)

# Test the exact pattern that was failing - using scale_fill_energy() without data parameter
print("\n=== Testing vignette-style plot ===")

p <- ggplot(energy_mix, aes(x = country, y = percentage, fill = source)) +
  geom_col(position = "stack") +
  scale_fill_energy() +  # This was the problematic case - no data parameter
  labs(
    title = "Energy Mix by Country",
    x = "Country",
    y = "Percentage (%)",
    fill = "Energy Source"
  ) +
  theme_minimal()

print("Plot created successfully!")

# Check what sources are present
print("\nSources in data:")
print(unique(energy_mix$source))

# Save the plot
ggsave("vignette_test.png", p, width = 10, height = 6)
print("\nPlot saved as vignette_test.png")

# Let's also test with the exact sources mentioned by user: "only solar and other"
print("\n=== Testing with Solar and Other scenario ===")

limited_data <- data.frame(
  year = 2020:2022,
  source = rep(c("Solar", "Other"), c(3, 3)),
  value = c(10, 15, 20, 90, 85, 80)
)

print("Limited data (Solar and Other):")
print(limited_data)

p2 <- ggplot(limited_data, aes(x = year, y = value, fill = source)) +
  geom_col() +
  scale_fill_energy() +
  labs(title = "Solar and Other Test")

ggsave("solar_other_test.png", p2, width = 8, height = 6)
print("Solar+Other plot saved as solar_other_test.png")