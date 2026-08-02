# Debug the present_sources detection and ordering

library(ggplot2)
library(energypal)

cat("=== DEBUGGING PRESENT_SOURCES DETECTION ===\n\n")

# Create test data exactly as before
test_data <- data.frame(
  source = factor(c("Bioenergy", "Coal", "Solar"), levels = c("Bioenergy", "Coal", "Solar")),
  value = c(30, 50, 20)
)

cat("1. Test data:\n")
print(test_data)

cat("\n2. Factor levels:\n")
print(levels(test_data$source))

# Simulate the present_sources detection logic from scale_fill_energy
present_sources <- NULL
if (!is.null(test_data) && is.data.frame(test_data)) {
  guess_cols <- c("source","technology","fuel","energy_source")
  col_found <- intersect(guess_cols, names(test_data))
  if (length(col_found) > 0) {
    present_sources <- unique(as.character(test_data[[col_found[1]]]))
  }
}

cat("\n3. Detected present_sources:\n")
print(present_sources)

cat("\n4. Order of present_sources:\n")
for (i in seq_along(present_sources)) {
  cat("  Position", i, ":", present_sources[i], "\n")
}

# The issue might be in the unique() call - does it preserve the original order?
cat("\n5. Testing unique() behavior:\n")
original_order <- as.character(test_data$source)
cat("Original order in data:", paste(original_order, collapse = ", "), "\n")

unique_order <- unique(original_order)
cat("After unique():", paste(unique_order, collapse = ", "), "\n")

cat("Does unique() preserve order?", identical(original_order, c("Bioenergy", "Coal", "Solar")), "\n")
cat("Does unique() result match factor levels?", identical(unique_order, levels(test_data$source)), "\n")

# Get the base palette
base_palette <- get_energy_palette("iea_primary")

# Simulate the static palette function
cat("\n6. Simulating static palette function:\n")
pal_vec <- base_palette[present_sources]
pal_vec <- pal_vec[!is.na(pal_vec)]

cat("pal_vec (from present_sources order):\n")
print(pal_vec)

cat("\n7. What we return for n=3:\n")
result <- unname(pal_vec[seq_len(3)])
print(result)

cat("\n8. The issue: present_sources might be in the wrong order!\n")
cat("   Let me check if there are other parts of the code still interfering...\n")