# Test to confirm the color assignment issue and create a better fix

library(ggplot2)
library(energypal)

cat("=== TESTING DYNAMIC COLOR ASSIGNMENT ISSUE ===\n\n")

# Create a simple test case with known factor order
test_data <- data.frame(
  source = factor(c("Bioenergy", "Coal", "Solar"), levels = c("Bioenergy", "Coal", "Solar")),
  value = c(30, 50, 20)
)

cat("1. Test data factor levels (this is what ggplot2 sees):\n")
print(levels(test_data$source))

cat("\n2. Creating plot with current scale_fill_energy():\n")
p1 <- ggplot(test_data, aes(x = source, y = value, fill = source)) +
  geom_col() +
  scale_fill_energy() +
  labs(title = "Current Implementation")

# Extract the colors that were actually used
built_plot <- ggplot_build(p1)
actual_colors <- built_plot$data[[1]]$fill
names(actual_colors) <- levels(test_data$source)

cat("Colors assigned by ggplot2:\n")
print(actual_colors)

cat("\n3. What colors SHOULD be assigned (direct palette lookup):\n")
iea_palette <- get_energy_palette("iea_primary")
expected_colors <- iea_palette[levels(test_data$source)]
print(expected_colors)

cat("\n4. Do they match?\n")
matches <- actual_colors == expected_colors[names(actual_colors)]
cat("Matches:", all(matches, na.rm = TRUE), "\n")
if (!all(matches, na.rm = TRUE)) {
  cat("MISMATCH DETECTED! This confirms the color assignment issue.\n")
}

# Save plot to see the visual result
ggsave("test_color_assignment.png", p1, width = 8, height = 5)
cat("\nPlot saved as test_color_assignment.png\n")