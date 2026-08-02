# Test the static approach specifically

library(ggplot2)
library(energypal)

cat("=== TESTING STATIC APPROACH SPECIFICALLY ===\n\n")

# Create test data
test_data <- data.frame(
  source = factor(c("Bioenergy", "Coal", "Solar"), levels = c("Bioenergy", "Coal", "Solar")),
  value = c(30, 50, 20)
)

cat("1. Test data factor levels:\n")
print(levels(test_data$source))

cat("\n2. Creating plot with static approach (data parameter provided):\n")
p_static <- ggplot(test_data, aes(x = source, y = value, fill = source)) +
  geom_col() +
  scale_fill_energy(data = test_data) +  # EXPLICIT data parameter
  labs(title = "Static Approach Test")

built_static <- ggplot_build(p_static)
static_colors <- built_static$data[[1]]$fill
names(static_colors) <- levels(test_data$source)

cat("Static colors assigned:\n")
print(static_colors)

cat("\n3. Expected colors:\n")
iea_palette <- get_energy_palette("iea_primary")
expected_colors <- iea_palette[levels(test_data$source)]
print(expected_colors)

cat("\n4. Do they match?\n")
matches <- static_colors == expected_colors
cat("Matches:", all(matches, na.rm = TRUE), "\n")

if (all(matches, na.rm = TRUE)) {
  cat("✅ STATIC APPROACH WORKS!\n")
} else {
  cat("❌ Static approach still broken\n")
  cat("Let me debug the static palette function...\n")
  
  # Debug what the static function should return
  present_sources <- unique(as.character(test_data$source))
  base_palette <- get_energy_palette("iea_primary")
  
  cat("Present sources:", paste(present_sources, collapse = ", "), "\n")
  cat("Expected palette vec:\n")
  pal_vec <- base_palette[present_sources]
  pal_vec <- pal_vec[!is.na(pal_vec)]
  print(pal_vec)
  
  cat("Static function should return for n=3:\n")
  static_result <- unname(pal_vec[seq_len(3)])
  print(static_result)
  
  cat("But ggplot2 got:\n")
  print(unname(static_colors))
}

ggsave("debug_static_approach.png", p_static, width = 8, height = 5)
cat("\nPlot saved for visual inspection\n")