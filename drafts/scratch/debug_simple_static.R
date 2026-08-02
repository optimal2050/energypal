# Debug the simple static logic

library(ggplot2)
library(energypal)

cat("=== DEBUGGING SIMPLE STATIC LOGIC ===\n\n")

# Simulate what my simple static logic does
test_data <- data.frame(
  source = factor(c("Bioenergy", "Coal", "Solar"), levels = c("Bioenergy", "Coal", "Solar")),
  value = c(30, 50, 20)
)

# Detect present sources (this is what my code does)
present_sources <- unique(as.character(test_data$source))
cat("1. Present sources detected:\n")
print(present_sources)

# Get base palette
base_palette <- get_energy_palette("iea_primary")

# My simple logic: values_for_scale <- base_palette[present_sources]
values_for_scale <- base_palette[present_sources]
cat("\n2. values_for_scale from my simple logic:\n")
print(values_for_scale)

# This is what should be returned by pal_fun
cat("\n3. What pal_fun should return for n=3:\n")
pal_vec <- values_for_scale
n <- 3
if (n <= length(pal_vec)) {
  result <- unname(pal_vec[seq_len(n)])
} else {
  result <- unname(rep(pal_vec, length.out = n))
}
print(result)

cat("\n4. Expected result:\n")
expected <- unname(base_palette[c("Bioenergy", "Coal", "Solar")])
print(expected)

cat("\n5. Do they match?\n")
cat("Match:", all(result == expected, na.rm = TRUE), "\n")

if (all(result == expected, na.rm = TRUE)) {
  cat("✅ Simple static logic is correct!\n")
  cat("💡 The issue must be elsewhere - maybe the pal_fun isn't being used correctly\n")
} else {
  cat("❌ Simple static logic is wrong\n")
  cat("The issue might be in the present_sources detection order\n")
}

# Check the order of present_sources vs factor levels
cat("\n6. Order comparison:\n")
factor_levels <- levels(test_data$source)
cat("Factor levels order:", paste(factor_levels, collapse = ", "), "\n")
cat("Present sources order:", paste(present_sources, collapse = ", "), "\n")
cat("Same order:", all(factor_levels == present_sources), "\n")