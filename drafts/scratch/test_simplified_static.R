# Test simplified static approach
source("R/defaults.R")
source("R/utils.R")
source("R/scales.R")
source("R/palettes.R")

# Test data with Bioenergy, Coal, Solar
test_data <- data.frame(
  source = c("Bioenergy", "Coal", "Solar"),
  value = c(10, 20, 30),
  stringsAsFactors = FALSE
)

print("=== TEST DATA ===")
print(test_data)

# Test with data parameter (static approach)
print("=== STATIC APPROACH (with data) ===")

# Create scale_fill_energy with data
scale_obj <- scale_fill_energy(data = test_data)
print("Scale object created successfully")

# Extract the palette function
pal_fun <- scale_obj$palette

# Test the palette function with n=3 (matching our 3 sources)
colors_returned <- pal_fun(3)
print("Colors returned for n=3:")
print(colors_returned)

# Get expected colors
base_palette <- get_energy_palette("iea_primary")
expected_colors <- unname(base_palette[c("Bioenergy", "Coal", "Solar")])
print("Expected colors:")
print(expected_colors)

# Check if they match
matches <- colors_returned == expected_colors
print("Colors match expected:")
print(matches)
print("All match:", all(matches))

# Test the color scale too
print("=== TESTING scale_color_energy ===")
color_scale_obj <- scale_color_energy(data = test_data)
color_pal_fun <- color_scale_obj$palette
color_colors_returned <- color_pal_fun(3)
print("Color scale returned:")
print(color_colors_returned)
print("Matches fill scale:", all(color_colors_returned == colors_returned))