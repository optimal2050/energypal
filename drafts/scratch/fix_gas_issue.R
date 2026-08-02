# Quick patch to fix the "Gas" issue in both scale functions

# Read the current file
original_file <- "R/scales.R"
content <- readLines(original_file)

# Replace all instances of the problematic line
old_line <- '        "Bioenergy", "Coal", "Gas", "Geothermal", "Hydro",'
new_line <- '        "Bioenergy", "Coal", "Geothermal", "Hydro", "Natural Gas",'

# Replace in content
content <- gsub(old_line, new_line, content, fixed = TRUE)

# Also remove the Gas handling logic
old_gas_logic <- '        } else if (source == "Gas") {\n          # Handle common alias\n          alphabetical_colors[i] <- base_palette["Natural Gas"]'
new_gas_logic <- ''

# This is a bit tricky with multi-line, so let's just fix the specific issue
content <- gsub('} else if \\(source == "Gas"\\) {', '} else {', content)
content <- gsub('# Handle common alias', '# Fallback to unmapped color', content)
content <- gsub('alphabetical_colors\\[i\\] <- base_palette\\["Natural Gas"\\]', 'alphabetical_colors[i] <- unmapped_color', content)

# Write back
writeLines(content, original_file)

cat("Fixed the Gas duplication issue in both scale functions\n")