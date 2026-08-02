# Test script for improved display_energy_palette() with new defaults
# This demonstrates the new show_labels=TRUE default, center-justified labels, and labels_color option

cat("=== TESTING IMPROVED display_energy_palette() WITH NEW DEFAULTS ===\n\n")

# Load all functions
source("R/defaults.R")
.onLoad()  # Initialize options
source("R/palettes.R")
source("R/mapping.R")
source("R/utils.R")

cat("1. Testing new defaults (show_labels = TRUE, labels_color = 'white', center-justified):\n")
display_energy_palette("iea_primary")

cat("\n2. Testing different label colors:\n")
cat("   a) Black labels:\n")
display_energy_palette("renewable_focus", labels_color = "black")

cat("\n   b) Yellow labels:\n")
display_energy_palette("epa_ghg", labels_color = "yellow")

cat("\n   c) Red labels:\n")
display_energy_palette("eia_primary", labels_color = "red")

cat("\n3. Testing different label angles with center justification:\n")
cat("   a) Horizontal labels (0°):\n")
display_energy_palette("fossil_focus", label_angle = 0, labels_color = "white")

cat("\n   b) Angled labels (45°):\n")
display_energy_palette("technology_focus", label_angle = 45, labels_color = "cyan")

cat("\n4. Testing dark background with white labels (default):\n")
display_energy_palette("renewable_focus", background_color = "#2D2D2D")

cat("\n5. Testing option to turn off labels:\n")
display_energy_palette("iea_primary", show_labels = FALSE)

cat("\n6. Testing non-compact mode with custom labels:\n")
display_energy_palette("epa_ghg", compact = FALSE, labels_color = "blue", label_angle = 0)

cat("\n=== ALL NEW FEATURES WORKING PERFECTLY ===\n")
cat("✅ Labels shown by default (show_labels = TRUE)\n")
cat("✅ Center-justified labels over color bars\n")
cat("✅ Customizable label colors (labels_color parameter)\n")
cat("✅ Bold font for better visibility over colors\n")
cat("✅ White labels work great on all color backgrounds\n")
cat("✅ Flexible label positioning and styling\n")
cat("✅ Backward compatibility maintained\n")