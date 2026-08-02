# Test simplified dynamic approach (no data parameter)
source("R/defaults.R")
source("R/utils.R")
source("R/scales.R")
source("R/palettes.R")

print("=== DYNAMIC APPROACH (no data parameter) ===")

# Create scale_fill_energy without data parameter
scale_obj <- scale_fill_energy()
print("Scale object created successfully")

# Extract the palette function
pal_fun <- scale_obj$palette

# Test the palette function with n=3 
# This should return colors optimized for alphabetical assignment
colors_returned <- pal_fun(3)
print("Colors returned for n=3 (should be optimized for alphabetical order):")
print(colors_returned)

# Get the base palette to see what we expect
base_palette <- get_energy_palette("iea_primary")
print("Base palette:")
print(base_palette)

# The first 3 alphabetical energy sources should be:
# "Bioenergy", "Coal", "Geothermal"
alphabetical_sources <- c("Bioenergy", "Coal", "Geothermal")
expected_for_alphabetical <- unname(base_palette[alphabetical_sources])
print("Expected colors for first 3 alphabetical sources (Bioenergy, Coal, Geothermal):")
print(expected_for_alphabetical)

# Check if they match
matches <- colors_returned == expected_for_alphabetical
print("Colors match expected alphabetical assignment:")
print(matches)
print("All match:", all(matches))

# Test with n=5 to see more colors
print("=== Testing with n=5 ===")
colors_5 <- pal_fun(5)
print("Colors for n=5:")
print(colors_5)

alphabetical_5 <- c("Bioenergy", "Coal", "Geothermal", "Hydro", "Natural Gas")
expected_5 <- unname(base_palette[alphabetical_5])
print("Expected for first 5 alphabetical:")
print(expected_5)
print("Match:", all(colors_5 == expected_5))