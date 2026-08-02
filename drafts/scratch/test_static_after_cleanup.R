library(ggplot2)
library(energypal)

# Test static approach after removing complex logic
df <- data.frame(
  source = factor(c("Bioenergy", "Coal", "Solar"), levels = c("Bioenergy", "Coal", "Solar")),
  generation = c(100, 200, 150)
)

print("Factor levels:")
print(levels(df$source))

print("Unique sources (order they appear in data):")
print(unique(as.character(df$source)))

# Test the scale with data parameter (static approach)
p <- ggplot(df, aes(x = source, y = generation, fill = source)) +
  geom_bar(stat = "identity") +
  scale_fill_energy(data = df) +
  theme_minimal()

# Extract the colors actually assigned
pb <- ggplot_build(p)
colors_assigned <- pb$data[[1]]$fill

print("Colors assigned to factors in order:")
print(colors_assigned)

# Show the plot
print(p)

# Let's also test what the scale function creates
scale_func <- scale_fill_energy(data = df)
print("Scale created:")
print(str(scale_func))