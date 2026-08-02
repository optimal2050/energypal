# Debug the palette function interface
library(energypal)
library(ggplot2)

# Test data
test_data <- data.frame(
  x = c(1, 1, 1),
  y = c(10, 20, 30),
  source = c("Coal", "Wind", "Solar"),
  stringsAsFactors = FALSE
)

print("=== Understanding ggplot2 palette function interface ===")

# Create a simple test palette function to see what ggplot2 passes
debug_palette <- function(x) {
  cat("Palette function called with:\n")
  cat("Class of x:", class(x), "\n")
  cat("Length of x:", length(x), "\n")
  cat("Content of x:", x, "\n")
  
  # Return simple colors for testing
  colors <- c("red", "blue", "green")[seq_along(x)]
  cat("Returning colors:", colors, "\n")
  return(colors)
}

cat("Testing debug palette function...\n")
tryCatch({
  p_debug <- ggplot(test_data, aes(x = x, y = y, fill = source)) +
    geom_col() +
    scale_fill_manual(values = c("Coal" = "red", "Wind" = "blue", "Solar" = "green")) +
    labs(title = "Manual colors test")
  
  ggsave("debug_manual.png", p_debug, width = 8, height = 6)
  cat("Manual colors work\n")
  
  built <- ggplot2::ggplot_build(p_debug)
  layer_data <- built$data[[1]]
  cat("Manual fill colors:", unique(layer_data$fill), "\n")
  
}, error = function(e) {
  cat("Error with manual:", e$message, "\n")
})

cat("\nTesting with discrete_scale and debug function...\n")
tryCatch({
  p_debug2 <- ggplot(test_data, aes(x = x, y = y, fill = source)) +
    geom_col() +
    discrete_scale("fill", "debug", palette = debug_palette) +
    labs(title = "Debug palette test")
  
  ggsave("debug_palette.png", p_debug2, width = 8, height = 6)
  
}, error = function(e) {
  cat("Error with debug palette:", e$message, "\n")
})