# Debug what's happening after the fix

library(ggplot2)
library(energypal)

cat("=== DEBUGGING AFTER THE FIX ===\n\n")

# Test the palette function directly
test_pal_fun <- function(n) {
  if (n == 0) return(character(0))
  
  # Get base palette
  base_palette <- get_energy_palette("iea_primary")
  
  # For dynamic case, provide colors optimized for alphabetical assignment
  alphabetical_energy_sources <- c(
    "Bioenergy", "Coal", "Gas", "Geothermal", "Hydro", 
    "Natural Gas", "Nuclear", "Oil", "Other", "Solar", "Wind"
  )
  
  # Build a palette optimized for alphabetical assignment
  alphabetical_colors <- character(length(alphabetical_energy_sources))
  names(alphabetical_colors) <- alphabetical_energy_sources
  
  for (i in seq_along(alphabetical_energy_sources)) {
    source <- alphabetical_energy_sources[i]
    if (source %in% names(base_palette)) {
      alphabetical_colors[i] <- base_palette[source]
    } else if (source == "Gas") {
      alphabetical_colors[i] <- base_palette["Natural Gas"]
    } else {
      alphabetical_colors[i] <- "#999999"
    }
  }
  
  cat("Alphabetical colors built:\n")
  print(alphabetical_colors)
  
  # Return the first n colors
  colors_to_return <- unname(alphabetical_colors[seq_len(min(n, length(alphabetical_colors)))])
  cat("Colors to return for n =", n, ":\n")
  print(colors_to_return)
  
  return(colors_to_return)
}

cat("1. Testing our palette function with n=3:\n")
result_colors <- test_pal_fun(3)

cat("\n2. Expected assignment:\n")
cat("ggplot2 should assign these to factors in alphabetical order:\n")
cat("  Position 1 (Bioenergy) gets:", result_colors[1], "\n")
cat("  Position 2 (Coal) gets:", result_colors[2], "\n")
cat("  Position 3 (Solar) gets:", result_colors[3], "\n")

cat("\n3. But our test data has factor levels: Bioenergy, Coal, Solar\n")
cat("   So the assignment should be:\n")
cat("   Bioenergy (1st factor) <- 1st color:", result_colors[1], "\n")
cat("   Coal (2nd factor) <- 2nd color:", result_colors[2], "\n")
cat("   Solar (3rd factor) <- 3rd color:", result_colors[3], "\n")

cat("\n4. Expected colors from palette:\n")
iea_pal <- get_energy_palette("iea_primary")
cat("   Bioenergy should be:", iea_pal["Bioenergy"], "\n")
cat("   Coal should be:", iea_pal["Coal"], "\n")
cat("   Solar should be:", iea_pal["Solar"], "\n")

cat("\n5. Do our returned colors match?\n")
expected <- c(iea_pal["Bioenergy"], iea_pal["Coal"], iea_pal["Solar"])
cat("Expected:", paste(expected, collapse = ", "), "\n")
cat("Returned:", paste(result_colors, collapse = ", "), "\n")
cat("Match:", all(expected == result_colors, na.rm = TRUE), "\n")