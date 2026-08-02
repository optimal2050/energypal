# Test the exact vignette example that was problematic

library(ggplot2)
library(energypal)

# Load the OWID energy mix data
data(owid_energy_mix)

print("OWID Energy Mix Data structure:")
print(str(owid_energy_mix))
print("First few rows:")
print(head(owid_energy_mix))

# Filter for one country (United States) for clearer comparison
usa_data <- subset(owid_energy_mix, country == "United States")

print("\nUSA data structure:")
print(str(usa_data))
print("USA sources:")
print(unique(usa_data$source))

# Apply carbon intensity ordering for logical stacking
usa_data$source_ordered <- order_energy_sources(usa_data$source)

print("\nOrdered sources:")
print(unique(usa_data$source_ordered))

# Create the exact plot from the vignette
print("\n=== Creating the exact vignette plot ===")

p <- ggplot(usa_data, aes(x = year, y = percentage, fill = source_ordered)) +
  geom_col() +
  scale_fill_energy(palette = "iea_primary") +  # This was the problematic line
  labs(
    title = "USA Energy Mix - Colors Ordered by Carbon Intensity",
    subtitle = "Coal (high carbon) at bottom, solar/wind (low carbon) at top",
    x = "Year",
    y = "Percentage (%)",
    fill = "Energy Source"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA)
  )

print("Plot created successfully!")

# Save the plot
ggsave("vignette_exact.png", p, width = 10, height = 5)
print("Plot saved as vignette_exact.png")

print("\nIf successful, this plot should show all energy sources with proper colors!")
print("No more 'only solar and other' issue!")