# Debug the specific palette function behavior
library(energypal)
library(ggplot2)

# Create simple test data
simple_data <- data.frame(
  year = c(2020, 2020, 2020),
  value = c(100, 50, 25),
  source = c("Coal", "Wind", "Solar"),
  stringsAsFactors = FALSE
)

cat("=== Testing scale_fill_energy internals ===\n")

# Test what happens when we call the scale manually
base_palette <- get_energy_palette("iea_primary")
cat("Base palette names:", head(names(base_palette), 10), "\n")

# Test the ordering function
default_sources <- get_canonical_order(method = "carbon_intensity")
cat("Default sources from get_canonical_order:", head(default_sources, 10), "\n")

# Test what get_canonical_order returns for our case
reversed_sources <- rev(default_sources)
cat("Reversed sources (direction = -1):", head(reversed_sources, 10), "\n")

# Test palette subset
palette_subset <- base_palette[intersect(reversed_sources, names(base_palette))]
cat("Palette subset size:", length(palette_subset), "\n")
cat("Palette subset names:", head(names(palette_subset), 10), "\n")

# Test if we have any issues with the palette function
cat("\n=== Testing manual palette function ===\n")
test_pal_vec <- palette_subset
test_pal_fun <- function(n) {
  cat("Palette function called with n =", n, "\n")
  if (length(test_pal_vec) == 0) {
    cat("Returning empty character vector\n")
    return(character(0))
  }
  needed <- names(test_pal_vec)[seq_len(min(length(test_pal_vec), n))]
  cat("Needed names:", needed, "\n")
  result <- test_pal_vec[needed]
  cat("Result:", result, "\n")
  result
}

# Test the palette function
cat("Testing palette function with n=3:\n")
test_result <- test_pal_fun(3)
cat("Palette function result:", test_result, "\n")

# Create a minimal ggplot2 scale to test
cat("\n=== Testing ggplot2 discrete_scale ===\n")
tryCatch({
  test_scale <- ggplot2::discrete_scale("fill", "test_energy", palette = test_pal_fun)
  cat("Created discrete_scale successfully\n")
  
  # Try to build a plot with it
  p_test <- ggplot(simple_data, aes(x = year, y = value, fill = source)) +
    geom_col() +
    test_scale
  
  built <- ggplot2::ggplot_build(p_test)
  cat("Built plot successfully\n")
  
  if (length(built$data) > 0) {
    layer_data <- built$data[[1]]
    cat("Fill colors in built plot:", unique(layer_data$fill), "\n")
  }
}, error = function(e) {
  cat("Error in ggplot2 test:", e$message, "\n")
})