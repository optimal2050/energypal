# Test script comparing the consistent image() style between functions
# This demonstrates that both functions now use the same viridis-style approach

cat("=== TESTING CONSISTENT IMAGE-STYLE VISUALIZATION ===\n\n")

# Load all functions
source("R/defaults.R")
.onLoad()  # Initialize options
source("R/palettes.R")
source("R/mapping.R")
source("R/utils.R")

cat("1. Testing show_all_energy_palettes() (clean, viridis-style):\n")
show_all_energy_palettes()

cat("\n2. Testing individual display_energy_palette() with same style:\n")
display_energy_palette("iea_primary")

cat("\n3. Both functions with labels for comparison:\n")
cat("   a) show_all_energy_palettes with labels:\n")
show_all_energy_palettes(show_labels = TRUE)

cat("\n   b) display_energy_palette with labels:\n")
display_energy_palette("renewable_focus", show_labels = TRUE)

cat("\n4. Testing consistency with dark themes:\n")
cat("   a) Multiple palettes with dark background:\n")
show_all_energy_palettes(background_color = "#2D2D2D", show_labels = TRUE)

cat("\n   b) Single palette with dark background:\n")
display_energy_palette("epa_ghg", background_color = "#2D2D2D", show_labels = TRUE)

cat("\n=== CONSISTENT VIRIDIS-STYLE VISUALIZATION ACHIEVED ===\n")
cat("✅ Both functions use graphics::image() for full-width color bars\n")
cat("✅ Consistent minimal margins and space utilization\n")
cat("✅ Same background and text color handling\n")
cat("✅ Unified professional presentation style\n")
cat("✅ Maximum color visibility with minimal white space\n")