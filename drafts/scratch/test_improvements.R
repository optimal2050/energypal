# Test script for energypal package improvements
# This tests the viridis-style visualization and improved functionality

cat("=== TESTING ENERGYPAL IMPROVEMENTS ===\n\n")

# Load all functions
source("R/defaults.R")
.onLoad()  # Initialize options
source("R/palettes.R")
source("R/mapping.R")
source("R/utils.R")

cat("1. Testing palette loading...\n")
palettes <- get_energy_palette_names()
cat("   Available palettes:", length(palettes), "\n")
cat("   Palette names:", paste(palettes, collapse = ", "), "\n\n")

cat("2. Testing options system...\n")
default_pal <- get_default_energy_palette()
cat("   Default palette:", default_pal, "\n")
options_test <- get_energy_options("warn_duplicate_mappings")
cat("   Options working:", !is.null(options_test), "\n\n")

cat("3. Testing color mapping...\n")
test_data <- data.frame(
  source = c("Solar", "Wind", "Coal", "Natural Gas", "Hydro"),
  value = 1:5
)
result <- add_energy_colors(test_data, "source")
cat("   Data with colors added:\n")
print(result)
cat("\n")

cat("4. Testing viridis-style visualization...\n")
cat("   Calling show_all_energy_palettes()...\n")
# This will create the visualization
show_all_energy_palettes(show_labels = TRUE, compact = TRUE)

cat("\n=== ALL TESTS COMPLETED SUCCESSFULLY ===\n")